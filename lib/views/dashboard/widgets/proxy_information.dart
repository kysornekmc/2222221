import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/providers/app.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_clash/models/profile.dart';

class ProxyInformation extends ConsumerWidget {
  const ProxyInformation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 获取当前选中的 Profile 的 ID
    final currentProfileId = ref.watch(currentProfileIdProvider);
    // 获取所有的 Profile
    final profiles = ref.watch(profilesProvider);

    // 手动实现 firstWhereOrNull 逻辑
    Profile? currentProfile;
    for (var profile in profiles) {
      if (profile.id == currentProfileId) {
        currentProfile = profile;
        break;
      }
    }

    final label = currentProfile?.label ?? appLocalizations.noInfo;
  
    // 获取当前组名
    final currentGroupName = currentProfile?.currentGroupName;
    // 根据当前组名从 selectedMap 中获取选定的代理名称
    String? selectedProxyName;
    if (currentGroupName != null && currentProfile?.selectedMap != null) {
      selectedProxyName = currentProfile!.selectedMap[currentGroupName];
    }
    final proxyLabel = selectedProxyName ?? appLocalizations.noProxySelected;

    // 获取测试 URL
    final appController = globalState.appController;
    final testUrl = appController.getRealTestUrl(null);

    // 获取延时信息
    final delay = ref.watch(getDelayProvider(
      proxyName: selectedProxyName ?? "",
      testUrl: testUrl,
    ));

    String delayText;
    TextStyle? delayTextStyle;
    if (delay == null) {
      delayText = appLocalizations.Space;
      delayTextStyle = context.textTheme.bodySmall?.copyWith(
        color: context.colorScheme.onSurfaceVariant.opacity80,
      );
    } else if (delay == -1) {
      delayText = "timeout";
      delayTextStyle = context.textTheme.bodySmall?.copyWith(
        color: Colors.red,
      );
    } else {
      //delayText = "$delay ms";
      delayText = "${delay}ms"; //去掉空格
      delayTextStyle = context.textTheme.bodySmall?.copyWith(
        color: context.colorScheme.onSurfaceVariant.opacity80,
      );
    }

    return SizedBox(
      height: getWidgetHeight(1),
      child: CommonCard(
        info: Info(
          label: appLocalizations.proxyInformation,
          iconData: Icons.airline_stops,
        ),
        onPressed: () {},
        child: Stack(
          children: [
            Container(
              padding: baseInfoEdgeInsets.copyWith(
                top: 0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    height: globalState.measure.bodyMediumHeight + 2,
                    child: FadeThroughBox(
                      child: TooltipText(
                        text: Text(
                          proxyLabel,
                          style: context.textTheme.bodyMedium?.toLight.adjustSize(1),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Transform.translate(
                offset: Offset(
                  -16,
                  -16.5,
                ),
                child: Text(
                  delayText,
                  style: delayTextStyle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
