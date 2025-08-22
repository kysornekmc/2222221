import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/models/models.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionInfoViewdetail extends StatefulWidget {
  final SubscriptionInfo? subscriptionInfo;
  final Profile? profile; // 添加 Profile 类型的参数

  const SubscriptionInfoViewdetail({
    super.key,
    this.subscriptionInfo, 
    this.profile, // 初始化新参数
  });

  @override
  State<SubscriptionInfoViewdetail> createState() => _SubscriptionInfoViewdetailState();
}

class _SubscriptionInfoViewdetailState extends State<SubscriptionInfoViewdetail> {

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
    final percent = 100*progress; // 百分比化
    double number = percent;
    String formattedNumber = number.toStringAsFixed(1);  // 双精度浮点数number保留到小数点后一位
    
    final useShow = TrafficValue(value: use).show; 
    final totalShow = TrafficValue(value: total).show;
    final expireShow = widget.subscriptionInfo?.expire != null &&
            widget.subscriptionInfo!.expire != 0
        ? DateTime.fromMillisecondsSinceEpoch(widget.subscriptionInfo!.expire * 1000)
            .show
            .replaceAll('T', ' ') // 替换 T 为空格
        : appLocalizations.infiniteTime;
    final daysShow = appLocalizations.days;
    DateTime now = DateTime.now();    //获取现在的时间
    DateTime specificDate = DateTime.fromMillisecondsSinceEpoch(widget.subscriptionInfo!.expire * 1000);
    Duration difference = now.difference(specificDate);                      //计算天数差
    final daysDifference = widget.subscriptionInfo?.expire != null &&
            widget.subscriptionInfo!.expire != 0
        ? ' · ' + difference.inDays.abs().toString() + ' ' + daysShow            //   显示“ · +天数差+天 “  difference.inDays.abs()差值并绝对值化
        : appLocalizations.Space;                                                // 长期套餐不显示天数差，附加一个空格

    // 定义统一的文本样式
    final textStyle = context.textTheme.bodyMedium?.toLight.adjustSize(1).copyWith(height: 1);
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              appLocalizations.trafficUsageSe,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
              strutStyle: strutStyle,
              textAlign: TextAlign.center,
            ),
            Text(
              ": ",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
              strutStyle: strutStyle,
              textAlign: TextAlign.center,
            ),
            Text(
              "$useShow / $totalShow · $formattedNumber%",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
              strutStyle: strutStyle,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        const SizedBox(height: spacingHeight-2),  
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // 新增，使内容两端对齐
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              appLocalizations.expire,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
              strutStyle: strutStyle,
              textAlign: TextAlign.center,
            ),
            Text(
              ": ",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
              strutStyle: strutStyle,
              textAlign: TextAlign.center,
            ),
            Text(
              "$expireShow$daysDifference",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
              strutStyle: strutStyle,
              textAlign: TextAlign.center,
            ),
          ],
        ),
            ),
            // 修改此处，使用 widget.profile 访问传入的 profile
            if (widget.profile != null)
            Text(
             widget.profile!.lastUpdateDate?.lastUpdateTimeDesc ?? "",  // 显示更新时间
              style: textStyle,
              strutStyle: strutStyle,
              textAlign: TextAlign.end,
            ),
          ],
        ),
        const SizedBox(height: spacingHeight+1), 
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