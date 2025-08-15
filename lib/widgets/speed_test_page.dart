import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/providers/app.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_inappwebview_platform_interface/flutter_inappwebview_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 测速网站列表
const List<Map<String, String>> speedTestSites = [
  {
    'name': 'Cloudflare',
    'url': 'https://speed.cloudflare.com/'
  },
  {
    'name': 'Speedis',
    'url': 'https://speed.is/'
  },
  {
    'name': 'Ustcspeed',
    'url': 'https://test.ustc.edu.cn/'
  },
 // {
  //  'name': 'Librespeed',
   // 'url': 'https://librespeed.org/'
//  },    
 // {
 //   'name': 'CFSpeed',
 //   'url': 'https://www.cfspeed.com/'
 // },
];

class SpeedTestPage extends StatefulWidget {
  const SpeedTestPage({super.key});

  @override
  State<SpeedTestPage> createState() => _SpeedTestPageState();
}

class _SpeedTestPageState extends State<SpeedTestPage> {
  InAppWebViewController? webViewController;
  double progress = 0;
  int selectedSiteIndex = 0;

  @override
  void initState() {
    super.initState();
    // 先加载保存的网站索引，再初始化WebView内容
    _loadSavedSite().then((_) {
      // 确保在Widget构建完成后再加载网站
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadSelectedSite();
      });
    });
  }

  // 优化：添加资源释放逻辑
  @override
  void dispose() {
    _disposeWebView();
    super.dispose();
  }

  // 单独抽离WebView销毁逻辑
  void _disposeWebView() {
    if (webViewController != null) {
      webViewController?.stopLoading();
      webViewController?.clearCache();
      webViewController?.clearHistory();
      webViewController = null;
    }
  }

  Future<void> _loadSavedSite() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedIndex = prefs.getInt('selected_speed_test_site');
      if (savedIndex != null && 
          savedIndex >= 0 && 
          savedIndex < speedTestSites.length) {
        setState(() {
          selectedSiteIndex = savedIndex;
        });
      }
    } catch (_) {
      // 保持默认值，不影响功能，移除调试打印
    }
  }

  // 保存选中的网站到本地存储
  Future<void> _saveSelectedSite(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('selected_speed_test_site', index);
    } catch (_) {
      // 保存失败不影响主要功能，仅下次启动不会记住选择，移除调试打印
    }
  }

  // 优化：切换网站时增加加载状态提示
  void _loadSelectedSite() {
    if (webViewController != null && 
        selectedSiteIndex >= 0 && 
        selectedSiteIndex < speedTestSites.length) {
      setState(() {
        progress = 0;
      });
      webViewController!.stopLoading();
      webViewController!.loadUrl(
        urlRequest: URLRequest(
          url: WebUri(speedTestSites[selectedSiteIndex]['url']!),
        ),
      ).catchError((_) {
        // 移除调试打印
      });
    }
  }

  // 显示网站选择对话框
  void _showSiteSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(appLocalizations.networkSpeedtest),  //selectSpeedTestSite 
        content: SingleChildScrollView(
          child: ListBody(
            children: List.generate(speedTestSites.length, (index) {
              return RadioListTile<int>(
                title: Text(speedTestSites[index]['name']!),
                value: index,
                groupValue: selectedSiteIndex,
                onChanged: (value) {
                  if (value != null && value != selectedSiteIndex) {
                    setState(() {
                      selectedSiteIndex = value;
                    });
                    _saveSelectedSite(value); // 保存选择
                    _loadSelectedSite(); // 加载新网站
                    Navigator.pop(context);
                  }
                },
              );
            }),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      appBar: AppBar(
        title: Text(appLocalizations.networkSpeedtest), 
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        // 右上角设置按钮
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSiteSelectionDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          if (progress < 1.0)
            LinearProgressIndicator(value: progress),
          Expanded(
            child: InAppWebView(
              // 移除初始URL加载，改为通过代码控制加载
              initialUrlRequest: null,
              initialOptions: InAppWebViewGroupOptions(
                crossPlatform: InAppWebViewOptions(
                  javaScriptEnabled: true,
                  useShouldOverrideUrlLoading: true,
                  mediaPlaybackRequiresUserGesture: false,
                  cacheEnabled: true, // 保留缓存提升重复访问速度
                ),
                android: AndroidInAppWebViewOptions(
                  useHybridComposition: true,
                  // 解决release模式下的HTTPS问题
                  mixedContentMode: AndroidMixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
                ),
                ios: IOSInAppWebViewOptions(
                  allowsInlineMediaPlayback: true,
                ),
              ),
              onWebViewCreated: (controller) {
                webViewController = controller;
                // WebView创建后检查是否需要加载网站（防止初始化顺序问题）
                if (selectedSiteIndex >= 0 && selectedSiteIndex < speedTestSites.length) {
                  _loadSelectedSite();
                }
              },
              onProgressChanged: (controller, progress) {
                setState(() {
                  this.progress = progress / 100;
                });
              },
              onLoadError: (controller, url, code, message) {
                // 移除调试打印
              },
            ),
          ),
        ],
      ),
    );
  }
}