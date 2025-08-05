import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/state.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Request {
  late final Dio _dio;
  late final Dio _clashDio;
  String? userAgent;
  bool _isPollingQuery = true; // 新增属性，用于存储查询模式

  Request() {
    _dio = Dio(
      BaseOptions(
        headers: {
          "User-Agent": browserUa,
        },
      ),
    );
    _clashDio = Dio();
    _clashDio.httpClientAdapter = IOHttpClientAdapter(createHttpClient: () {
      final client = HttpClient();
      client.findProxy = (Uri uri) {
        client.userAgent = globalState.ua;
        return FlClashHttpOverrides.handleFindProxy(uri);
      };
      return client;
    });

    // 从持久化存储中读取查询模式
    _loadQueryMode();
  }

  Future<void> _loadQueryMode() async {
    final prefs = await SharedPreferences.getInstance();
    _isPollingQuery = prefs.getBool('isPollingQuery') ?? true;
  }

  // 更新查询模式并保存到持久化存储
  void setQueryMode(bool isPollingQuery) {
    _isPollingQuery = isPollingQuery;
    // 保存到持久化存储（无错误捕获和日志）
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('isPollingQuery', isPollingQuery);
    });
  }

  Future<Response> getFileResponseForUrl(String url) async {
    final response = await _clashDio.get(
      url,
      options: Options(
        responseType: ResponseType.bytes,
      ),
    );
    return response;
  }

  Future<Response> getTextResponseForUrl(String url) async {
    final response = await _clashDio.get(
      url,
      options: Options(
        responseType: ResponseType.plain,
      ),
    );
    return response;
  }

  Future<MemoryImage?> getImage(String url) async {
    if (url.isEmpty) return null;
    final response = await _dio.get<Uint8List>(
      url,
      options: Options(
        responseType: ResponseType.bytes,
      ),
    );
    final data = response.data;
    if (data == null) return null;
    return MemoryImage(data);
  }

  Future<Map<String, dynamic>?> checkForUpdate() async {
    final response = await _dio.get(
      "https://api.github.com/repos/$repository/releases/latest",
      options: Options(
        responseType: ResponseType.json,
      ),
    );
    if (response.statusCode != 200) return null;
    final data = response.data as Map<String, dynamic>;
    final remoteVersion = data['tag_name'];
    final version = globalState.packageInfo.version;
    final hasUpdate =
        utils.compareVersions(remoteVersion.replaceAll('v', ''), version) > 0;
    if (!hasUpdate) return null;
    return data;
  }

  final Map<String, IpInfo Function(Map<String, dynamic>)> _ipInfoSources = {
    "https://v6.ipinfo.io/json?token=74c2217e68fac9": IpInfo.fromv6IpInfoIoJson,  //50000每月
    "http://ip-api.com/json/": IpInfo.fromIpAPIJson,                              //每分钟查询次数限制为45次
    "https://ipwho.is/": IpInfo.fromIpwhoIsJson,                                  //每月最多可以免费使用我们的 API 10,000 个请求（通过 IP 地址和 Referer 标头识别）
    "https://ipinfo.io/json/": IpInfo.fromIpInfoIoJson,                           //50000每月
    "https://ipapi.co/json/": IpInfo.fromIpApiCoJson,                             //30000每月
    "https://api.ip.sb/geoip/": IpInfo.fromIpSbJson,
  };
//并发查询
  // 合并后的 checkIp 方法，根据查询模式选择不同的查询方式
  Future<IpInfo?> checkIp({CancelToken? cancelToken}) async {
    if (_isPollingQuery) {
      // 并发查询
      final internalCancelToken = CancelToken();

    // 同步外部传入的cancelToken取消事件到内部token
    cancelToken?.whenCancel.then((_) {
      if (!internalCancelToken.isCancelled) {
        internalCancelToken.cancel();
      }
    });

    final futures = _ipInfoSources.entries.map((source) async {
      try {
        final response = await _dio.get<Map<String, dynamic>>(
          source.key,
          cancelToken: internalCancelToken,
        ).timeout(const Duration(seconds: 15));
        if (response.statusCode == 200 && response.data != null) {
          // 成功获取数据后立即取消其他请求
          internalCancelToken.cancel();
          return source.value(response.data!);
        }
        return null;
      } catch (e) {
        if (e is DioException && e.type == DioExceptionType.cancel) {
          return null; // 请求被取消，忽略异常
        }
        commonPrint.log("checkIp error for ${source.key} ===> $e");
        return null;
      }
    }).toList();

      final results = await Future.wait(futures);
      // 返回第一个非空结果
      for (final result in results) {
        if (result != null) return result;
      }
      return null;
    } else {
      // 顺序查询
      for (final source in _ipInfoSources.entries) {
        try {
          final response = await Dio()
              .get<Map<String, dynamic>>(
                source.key,
                cancelToken: cancelToken,
                options: Options(
                  responseType: ResponseType.json,
                ),
              )
              .timeout(
                Duration(
                  seconds: 15,
                ),
              );
          if (response.statusCode != 200 || response.data == null) {
            continue;
          }
          if (response.data == null) {
            continue;
          }
          return source.value(response.data!);
        } catch (e) {
          commonPrint.log("checkIp error ===> $e");
          if (e is DioException && e.type == DioExceptionType.cancel) {
            throw "cancelled";
          }
        }
      }
      return null;
    }
  }

  Future<bool> pingHelper() async {
    try {
      final response = await _dio
          .get(
            "http://$localhost:$helperPort/ping",
            options: Options(
              responseType: ResponseType.plain,
            ),
          )
          .timeout(
            const Duration(
              milliseconds: 2000,
            ),
          );
      if (response.statusCode != HttpStatus.ok) {
        return false;
      }
      return (response.data as String) == globalState.coreSHA256;
    } catch (_) {
      return false;
    }
  }

  Future<bool> startCoreByHelper(String arg) async {
    try {
      final response = await _dio
          .post(
            "http://$localhost:$helperPort/start",
            data: json.encode({
              "path": appPath.corePath,
              "arg": arg,
            }),
            options: Options(
              responseType: ResponseType.plain,
            ),
          )
          .timeout(
            const Duration(
              milliseconds: 2000,
            ),
          );
      if (response.statusCode != HttpStatus.ok) {
        return false;
      }
      final data = response.data as String;
      return data.isEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> stopCoreByHelper() async {
    try {
      final response = await _dio
          .post(
            "http://$localhost:$helperPort/stop",
            options: Options(
              responseType: ResponseType.plain,
            ),
          )
          .timeout(
            const Duration(
              milliseconds: 2000,
            ),
          );
      if (response.statusCode != HttpStatus.ok) {
        return false;
      }
      final data = response.data as String;
      return data.isEmpty;
    } catch (_) {
      return false;
    }
  }
}

final request = Request();
