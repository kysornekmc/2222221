import 'dart:math';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/app.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_clash/enum/enum.dart';

class TrafficUsageSimple extends StatelessWidget {
  const TrafficUsageSimple({super.key});

  // 获取流量数据项的Widget
  Widget getTrafficDataItem(
    BuildContext context,
    IconData iconData,
    TrafficValue trafficValue,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Icon(
          iconData,
          size: 18,
        ),
        const SizedBox(
          width: 0,  //箭头与流量数字之间的间距
        ),
        Flexible(
          child: Text(
                  // 将流量数字和单位拼接在一起显示
                  //  '${trafficValue.showValue}${trafficValue.showUnitse}', //    }$之间添加间距即数字与MB之间的间距
		   '${trafficValue.shortShowse}',
		  //${trafficValue.shortShow}',  //完整单位
                  style: context.textTheme.bodyMedium?.toLight.adjustSize(1),
                  maxLines: 1,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = globalState.theme.darken3PrimaryContainer;
    final secondaryColor = globalState.theme.darken2SecondaryContainer;
    return SizedBox(
      height: getWidgetHeight(1),
      child: CommonCard(
        info: Info(
          label: appLocalizations.trafficUsage,
          iconData: Icons.data_saver_off,
        ),
        onPressed: () {},
        child: Consumer(
          builder: (_, ref, __) {
            final totalTraffic = ref.watch(totalTrafficProvider);
            final upTotalTrafficValue = totalTraffic.up;
            final downTotalTrafficValue = totalTraffic.down;
            return Container(
              padding: baseInfoEdgeInsets.copyWith(
                top: 0, // 与 intranet_ip.dart 保持一致
              ),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.end, // 与 intranet_ip.dart 保持一致
                children: [
                  SizedBox(
                    height: globalState.measure.bodyMediumHeight + 2, // 与 intranet_ip.dart 保持一致
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          flex: 1,
                          child: getTrafficDataItem(
                            context,
                            Icons.arrow_upward,
                            upTotalTrafficValue,
                          ),
                        ),
                        Flexible(
                          flex: 1,
                          child: getTrafficDataItem(
                            context,
                            Icons.arrow_downward,
                            downTotalTrafficValue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
