import 'package:fl_clash/common/common.dart'; // 确保导入了包含 getWidgetHeight 的文件
import 'package:fl_clash/providers/app.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/widgets/widgets.dart'; // 已包含SpeedTestPage的导出
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NetworkSpeedTest extends StatelessWidget {
  const NetworkSpeedTest({super.key});

  // 跳转到测速页面
  void _navigateToSpeedTest(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SpeedTestPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: getWidgetHeight(1),
      child: CommonCard(
        info: Info(
          label: appLocalizations.networkSpeedtest,
          iconData: Icons.keyboard_double_arrow_right,
        ),
        onPressed: () => _navigateToSpeedTest(context),
        child: Container(
          padding: baseInfoEdgeInsets.copyWith(top: 0),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                height: globalState.measure.bodyMediumHeight + 2,
                child: FadeThroughBox( // 与network_detection.dart保持动画一致性
                  child: Text(
                    appLocalizations.clickSpeedtest,
                    style: context.textTheme.bodyMedium?.toLight.adjustSize(1),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.left, // 明确左对齐
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
