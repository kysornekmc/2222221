import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/providers/app.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_clash/models/profile.dart';
import 'package:fl_clash/widgets/subscription_info_viewsmall.dart';

class SubscriptionInformationsmall extends ConsumerWidget {
  const SubscriptionInformationsmall({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 获取当前选中的 Profile 的 ID
    final currentProfileId = ref.watch(currentProfileIdProvider);
    // 获取所有的 Profile
    final profiles = ref.watch(profilesProvider);

    // 手动实现 firstWhereOrNull 逻辑(不是很懂)
    Profile? currentProfile;
    for (var profile in profiles) {
      if (profile.id == currentProfileId) {
        currentProfile = profile;
        break;
      }
    }
    final label = currentProfile?.label ?? appLocalizations.noInfo;
    final subscriptionInfo = currentProfile?.subscriptionInfo; // 获取订阅信息

    // 获取当前组名
    final currentGroupName = currentProfile?.currentGroupName;
    // 根据当前组名从 selectedMap 中获取选定的代理名称
    String? selectedProxyName;
    if (currentGroupName != null && currentProfile?.selectedMap != null) {
      selectedProxyName = currentProfile!.selectedMap[currentGroupName];
    }
    final proxyLabel = selectedProxyName ?? appLocalizations.noProxySelected;

    // 定义统一的间距高度
    const spacingHeight = 13.0;

    return SizedBox(
      height: getWidgetHeight(2),
      child: CommonCard(
        onPressed: () {},
        info: Info(
          label: appLocalizations.subscriptionInformation,
          iconData: Icons.content_paste_outlined,
        ),
        child: Column(
           crossAxisAlignment: CrossAxisAlignment.start, // 修改为左对齐
           children: [
            Padding(
              padding: baseInfoEdgeInsets.copyWith(
                    bottom: 0,
                    top: 8,  //对齐IP等信息
		    left: 16, // 设置左边的内边距为 16 像素，可根据需求调整
              ),
              child: Container(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
		  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 显示 机场名称
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodyMedium?.toLight.adjustSize(1).copyWith(height: 1),
                    ),
                    const SizedBox(height: spacingHeight), // 使用统一的间距
                    // 显示 代理名称
                    Text(
                      proxyLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodyMedium?.toLight.adjustSize(1).copyWith(height: 1),
                    ),
                    if (subscriptionInfo != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: spacingHeight), // 使用统一的间距
                          SubscriptionInfoViewsmall(
                            subscriptionInfo: subscriptionInfo,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
