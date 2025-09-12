import 'dart:async';
import 'dart:typed_data';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/models/models.dart';
import 'package:intl/intl.dart';
import 'package:webdav_client/webdav_client.dart';

class DAVClient {
  late Client client;
  Completer<bool> pingCompleter = Completer();
  late String fileName;

  DAVClient(DAV dav) {
    client = newClient(
      dav.uri,
      user: dav.user,
      password: dav.password,
    );
    fileName = dav.fileName;
    client.setHeaders(
      {
        'accept-charset': 'utf-8',
        'Content-Type': 'text/xml',
      },
    );
    client.setConnectTimeout(8000);
    client.setSendTimeout(60000);
    client.setReceiveTimeout(60000);
    pingCompleter.complete(_ping());
  }

  Future<bool> _ping() async {
    try {
      await client.ping();
      return true;
    } catch (_) {
      return false;
    }
  }

  get root => "/$appName";

  get backupFile {
    // 生成当前时间的格式化字符串（例如：20240520_153045）
    final timeSuffix = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    // 分离文件名和扩展名
    final fileNameParts = fileName.split('.');
    String baseName;
    String extension;
    if (fileNameParts.length > 1) {
      extension = fileNameParts.last;
      baseName = fileNameParts.sublist(0, fileNameParts.length - 1).join('.');
      return "$root/${baseName}_$timeSuffix.$extension";
    } else {
      // 没有扩展名的情况
      return "$root/${fileName}_$timeSuffix";
    }
  }

  backup(Uint8List data) async {
    await client.mkdir("$root");
    await client.write("$backupFile", data);
    return true;
  }

  Future<List<int>> recovery() async {
    await client.mkdir("$root");
    final data = await client.read(backupFile);
    return data;
  }
}
