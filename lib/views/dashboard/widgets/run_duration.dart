import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/providers/app.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RunDuration extends StatelessWidget {
  const RunDuration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: getWidgetHeight(1),
      child: CommonCard(
        info: Info(
          label: appLocalizations.runDuration, // 修改标签为运行时间
          iconData: Icons.timer_outlined, // 更换为计时器图标
        ),
        onPressed: () {},
        child: Container(
          padding: baseInfoEdgeInsets.copyWith(
            top: 0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                height: globalState.measure.bodyMediumHeight + 2,
                child: Consumer(
                  builder: (_, ref, __) {
                    final runTime = ref.watch(runTimeProvider);
                    
                    // 无论是否有运行时间，都显示文本（未运行时显示00:00:00）
                    final displayText = runTime != null 
                        ? utils.getTimeText(runTime) 
                        : "00:00:00";
                    return FadeThroughBox(
                      child: TooltipText(
                        text: Text(
                          displayText,
                          style: context.textTheme.bodyMedium?.toLight.adjustSize(1),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
