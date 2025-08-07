import 'dart:math';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/common/utils.dart'; // 引入 Utils 类
import 'package:fl_clash/providers/app.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_clash/models/models.dart'; // 导入 Proxy 类型定义文件
import 'package:fl_clash/models/profile.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:fl_clash/enum/enum.dart'; // 导入 Mode 枚举类型
import 'package:shared_preferences/shared_preferences.dart';

class SelectProxy extends ConsumerWidget {
  const SelectProxy({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final utils = Utils(); // 创建 Utils 实例

    // 获取当前模式
    final mode = ref.watch(patchClashConfigProvider.select((state) => state.mode));

    // 监听模式变化并刷新选中状态
    ref.listen(patchClashConfigProvider.select((state) => state.mode), (previous, next) {
      if (previous != next) {
        ref.refresh(selectedMapProvider);
      }
    });

    // 获取当前选中的 Profile ID 并监听变化
    final currentProfileId = ref.watch(currentProfileIdProvider);
    ref.listen(currentProfileIdProvider, (previous, next) {
      if (previous != next) {
        ref.refresh(selectedMapProvider);
      }
    });

    // 获取所有的 Profile 并找到当前选中的 Profile
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
    
    // 从 provider 获取选中的代理名称，确保状态同步
    String? selectedProxyName;
    if (currentGroupName != null) {
      selectedProxyName = ref.watch(getSelectedProxyNameProvider(currentGroupName));
    }
    final proxyLabel = selectedProxyName ?? appLocalizations.noProxySelected;

    // 获取测试 URL
    final appController = globalState.appController;
    final testUrl = appController.getRealTestUrl(null);

    // 获取当前组的所有代理
    List<Proxy> currentGroupProxies = [];
    if (currentGroupName != null) {
      final group = ref.watch(
        currentGroupsStateProvider.select(
          (state) => state.value.getGroup(currentGroupName),
        ),
      );
      currentGroupProxies = group?.all ?? [];
    }

    // 获取每个代理的延时信息
    final delayFutures = currentGroupProxies.map((proxy) {
      return ref.watch(getDelayProvider(
        proxyName: proxy.name,
        testUrl: testUrl,
      ));
    }).toList();

    // 创建一个包含代理和延时信息的列表
    final proxyWithDelay = <(Proxy, int?)>[];
    for (int i = 0; i < currentGroupProxies.length; i++) {
      proxyWithDelay.add((currentGroupProxies[i], delayFutures[i]));
    }

    // 按延时从低到高排序，没有数据或 timeout 的排有数据的后面
    proxyWithDelay.sort((a, b) {
      final delayA = a.$2;
      final delayB = b.$2;
      if (delayA == null || delayA == -1) {
        return 1; // 将延时为 null 或 -1 的项排在后面
      }
      if (delayB == null || delayB == -1) {
        return -1; // 将延时为 null 或 -1 的项排在后面
      }
      return delayA.compareTo(delayB);
    });

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
//	color: utils.getDelayColor(delay), // 使用 getDelayColor 方法
      );
    } else {
      //delayText = "$delay ms";
      delayText = "${delay}ms"; //去掉空格
      delayTextStyle = context.textTheme.bodySmall?.copyWith(
        color: context.colorScheme.onSurfaceVariant.opacity80,
//	color: utils.getDelayColor(delay), // 使用 getDelayColor 方法
      );
    }

    // 参考 card.dart 中的 getBackgroundColor 方法
    Color getBackgroundColor(BuildContext context, bool isSelected) {
      final colorScheme = Theme.of(context).colorScheme;
      if (isSelected) {
        return colorScheme.secondaryContainer;
      }
      return colorScheme.surface.opacity10;
    }

    // 参考 card.dart 中的 getBorderSide 方法
    BorderSide getBorderSide(BuildContext context, bool isSelected) {
      final colorScheme = Theme.of(context).colorScheme;
      final hoverColor = isSelected
        ? colorScheme.primary.opacity80
        : colorScheme.primary.opacity60;
      return BorderSide(
        color: isSelected
          ? colorScheme.primary
          : colorScheme.surfaceContainerHighest,
      );
    }

    void showProxySelector() async {
      if (currentGroupName == null) return;

showSheet(
  context: context,
  props: const SheetProps(
      isScrollControlled: true, // 允许底部弹窗高度自适应
  ),
  builder: (context, type) {
   // final bottomPadding = MediaQuery.of(context).padding.bottom;
    // 将底部安全区域高度固定为16像素
    final bottomPadding = 16.0;

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return AdaptiveSheetScaffold(
          type: type,
          title: label,
            body: SingleChildScrollView( // 外层滚动容器，解决整体滚动问题
              physics: const ClampingScrollPhysics(),
              child: Container(
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
              //    const Divider(),
                      // 直接使用ListView.builder，不包裹Expanded
                      ListView.builder(
                        shrinkWrap: true, // 关键：让列表高度适应内容
                        physics: const NeverScrollableScrollPhysics(), // 禁用内部滚动
                      itemCount: proxyWithDelay.length,
                      itemBuilder: (context, index) {
                        final pair = proxyWithDelay[index];
                        final proxy = pair.$1;
                        final delay = pair.$2;
                        final delayStr = delay == null
                            ? appLocalizations.Space
                            : delay == -1
                                ? "timeout"
                                : "${delay}ms";
                        final isSelected = proxy.name == selectedProxyName;

                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: CommonCard(
                            type: CommonCardType.filled,
                            isSelected: isSelected,
                            child: ListTile(  
                                    // 直接使用Icon作为leading，不嵌套Row
                                    leading: Icon(
                                      isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                      size: 18,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    // 关键：设置图标与文字的间距为4
                                    horizontalTitleGap: 3,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, // 减小左侧内边距，缩小图标与文字间距
                                vertical: 0,
                              ),
                              title: Text(
                                proxy.name ?? '',
                                style: context.textTheme.titleMedium?.copyWith(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              trailing: Text(
                                delayStr,
                                style: context.textTheme.bodyMedium?.copyWith(
                                  color: utils.getDelayColor(delay),
                                ),
                              ),
                              onTap: () {
                                if (proxy.name != null) {
                                  appController.updateCurrentSelectedMap(
                                    currentGroupName,
                                    proxy.name,
                                  );
                                  ref.refresh(selectedMapProvider);
                                  appController.changeProxyDebounce(
                                    currentGroupName,
                                    proxy.name,
                                  );
                                  Navigator.pop(context);
                                }
                              },
                            ),
                          ),
                        );
                      },
                            ),
                    ],
                    ),
              ),
            ),
          ),
        );
      },
    );
  },
);
    }


    return SizedBox(
      height: getWidgetHeight(1),
      child: CommonCard(
        info: Info(
          label: appLocalizations.selectproxy,
          iconData: Icons.article_outlined,
        ),
        onPressed: showProxySelector,
        child: Stack(
          children: [
            Container(
              padding: baseInfoEdgeInsets.copyWith(top: 0),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (mode == Mode.direct)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          appLocalizations.direct,
                          style: context.textTheme.bodyMedium,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 限制文本宽度
                            Flexible(
                              child: Text(
                                selectedProxyName ?? appLocalizations.noProxySelected,
                                style: context.textTheme.bodyMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        //    const SizedBox(width: 4),
                        //    Icon(Icons.arrow_drop_down, size: 16),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (mode != Mode.direct)
              Positioned(
                top: 0,
                right: 0,
                child: Transform.translate(
                  offset: const Offset(-16, -16.5),
                  child: Text(
                    delayText, 
                    style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant.opacity80,),      
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
