import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/providers/app.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class SpeedTestPage extends StatefulWidget {
  const SpeedTestPage({super.key});

  @override
  State<SpeedTestPage> createState() => _SpeedTestPageState();
}

class _SpeedTestPageState extends State<SpeedTestPage> {
  late final WebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    
    // 初始化WebView控制器（兼容不同平台）
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _webViewController = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // 可添加加载进度指示器逻辑
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {},
        ),
      )
      ..loadRequest(Uri.parse("https://speed.cloudflare.com/"));

    // Android平台特定配置
    if (_webViewController.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (_webViewController.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      appBar: AppBar(
        title: Text(appLocalizations.networkSpeedtest), //网速测速
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: CommonScrollBar(
        controller: ScrollController(),
        child: WebViewWidget(
          controller: _webViewController,
        ),
      ),
    );
  }
}