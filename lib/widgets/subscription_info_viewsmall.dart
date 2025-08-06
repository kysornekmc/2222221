import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/models/models.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionInfoViewsmall extends StatefulWidget {
  final SubscriptionInfo? subscriptionInfo;

  const SubscriptionInfoViewsmall({
    super.key,
    this.subscriptionInfo, 
  });

  @override
  State<SubscriptionInfoViewsmall> createState() => _SubscriptionInfoViewsmallState();
}

class _SubscriptionInfoViewsmallState extends State<SubscriptionInfoViewsmall> {

  @override
  Widget build(BuildContext context) {
    if (widget.subscriptionInfo == null) {
      return Container();
    }
    if (widget.subscriptionInfo?.total == 0) {
      return Container();
    }
    final use = widget.subscriptionInfo!.upload + widget.subscriptionInfo!.download;
    final total = widget.subscriptionInfo!.total;
    final progress = use / total;

    final useShow = TrafficValue(value: use).show; 
    final totalShow = TrafficValue(value: total).show;
    final expireShow = widget.subscriptionInfo?.expire != null &&
            widget.subscriptionInfo!.expire != 0
        ? DateTime.fromMillisecondsSinceEpoch(widget.subscriptionInfo!.expire * 1000)
            .show3
        : appLocalizations.infiniteTime;
    final daysShow = appLocalizations.days;
    DateTime now = DateTime.now();    //获取现在的时间
    DateTime specificDate = DateTime.fromMillisecondsSinceEpoch(widget.subscriptionInfo!.expire * 1000);
    Duration difference = now.difference(specificDate);                      //计算天数差
    final daysDifference = widget.subscriptionInfo?.expire != null &&
            widget.subscriptionInfo!.expire != 0
        ? ' · ' + difference.inDays.abs().toString() + ' ' + daysShow            //   显示“ · +天数差+天 “  difference.inDays.abs()差值并绝对值化
        : appLocalizations.Space;                                                // 长期套餐不显示天数差，附加一个空格

    // 定义 strutStyle
    final strutStyle = StrutStyle(
      fontSize: context.textTheme.bodyMedium?.fontSize?? 12,
      height: 1,
    );

    // 定义统一的间距高度
    const spacingHeight = 13.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "$useShow / $totalShow",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.bodyMedium?.toLight.adjustSize(1).copyWith(height: 1),
          strutStyle: strutStyle, // 添加 strutStyle
        ),  
        const SizedBox(height: 9.75),
        Text(
          "$expireShow$daysDifference",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.bodyMedium?.toLight.adjustSize(1).copyWith(height: 1),
          strutStyle: strutStyle, // 添加 strutStyle
        ),
        const SizedBox(height: spacingHeight),
        // 移除 LinearProgressIndicator 可能的外边距
        Container(
          margin: EdgeInsets.zero,
          child: LinearProgressIndicator(
            minHeight: 5,
            value: progress,
            backgroundColor: context.colorScheme.primary.opacity15,
          ),
        ),
      ],
    );
  }
}