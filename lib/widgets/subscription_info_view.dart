import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/models/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionInfoView extends ConsumerWidget {
  final SubscriptionInfo? subscriptionInfo;

  const SubscriptionInfoView({
    super.key,
    this.subscriptionInfo, 
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (subscriptionInfo == null) {
      return Container();
    }
    if (subscriptionInfo?.total == 0) {
      return Container();
    }
    final use = subscriptionInfo!.upload + subscriptionInfo!.download;
    final total = subscriptionInfo!.total;
    final progress = use / total;

    final useShow = TrafficValue(value: use).show;
    final totalShow = TrafficValue(value: total).show;
    final expireShow = subscriptionInfo?.expire != null &&
            subscriptionInfo!.expire != 0
        ? DateTime.fromMillisecondsSinceEpoch(subscriptionInfo!.expire * 1000)
            .show
        : appLocalizations.infiniteTime;
    String formattedString = expireShow.replaceFirst("T", " ");  //将转换而来的日期时间中的字母T去掉
    final daysShow = appLocalizations.days;
    DateTime now = DateTime.now();    //获取现在的时间
    DateTime specificDate = DateTime.fromMillisecondsSinceEpoch(subscriptionInfo!.expire * 1000);
    Duration difference = now.difference(specificDate);                      //计算天数差
    final daysDifference = subscriptionInfo?.expire != null &&
            subscriptionInfo!.expire != 0
        ? ' · ' + difference.inDays.abs().toString() + ' ' + daysShow            //   显示“ · +天数差+天 “  difference.inDays.abs()差值并绝对值化
        : appLocalizations.Space;                                                // 长期套餐不显示天数差，附加一个空格
    final expireShowse = subscriptionInfo?.expire != null &&
            subscriptionInfo!.expire != 0
        ? DateTime.fromMillisecondsSinceEpoch(subscriptionInfo!.expire * 1000)
            .show3
        : appLocalizations.infiniteTime;
    final strutStyle = StrutStyle(
      fontSize: context.textTheme.bodyMedium?.fontSize?? 12,
      height: 1,
    );

    final showFormattedText = ref.watch(
      appSettingProvider.select((state) => state.showFormattedText),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          minHeight: 6,
          value: progress,
          backgroundColor: context.colorScheme.primary.opacity15,
        ),
        const SizedBox(
          height: 8,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Text(
                "$useShow / $totalShow · ",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.labelMedium?.toLight?.copyWith(
                  height: 1.0, // 设置行高为 1.0
                ),
                strutStyle: strutStyle, // 添加 strutStyle
              ),
            ),
            Center(
              child: Text(
                showFormattedText ? "$formattedString$daysDifference" : "$expireShowse",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.labelMedium?.toLight?.copyWith(
                  height: 1.0, // 设置行高为 1.0
                ),
                strutStyle: strutStyle, // 添加 strutStyle
              ),
            ),
          ],
        ),
        const SizedBox(
          height: 4,
        ),
      ],
    );
  }
}
