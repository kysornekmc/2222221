import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/models/profile.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 新增导入

class ProfileSelecte extends ConsumerWidget {
  const ProfileSelecte({super.key});

  // 新增方法：获取隐藏的订阅ID集合
  Future<Set<String>> _getHiddenProfileIds() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList('hiddenProfileIds') ?? [];
    return Set<String>.from(ids);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 获取当前选中的Profile ID和所有Profiles
    final currentProfileId = ref.watch(currentProfileIdProvider);
    final profiles = ref.watch(profilesProvider);

    // 查找当前选中的Profile
    Profile? currentProfile;
    for (var profile in profiles) {
      if (profile.id == currentProfileId) {
        currentProfile = profile;
        break;
      }
    }

    final profileLabel = currentProfile?.label ?? appLocalizations.noProfileSelected;  //无配置文件

    // 显示订阅选择弹窗
    void showProfileSelector() {
      // 先获取隐藏的订阅ID再显示弹窗
      _getHiddenProfileIds().then((hiddenProfileIds) {
        // 过滤隐藏的订阅
        final visibleProfiles = profiles.where((profile) => 
          !hiddenProfileIds.contains(profile.id)
        ).toList();

        showSheet(
          context: context,
          props: const SheetProps(
            isScrollControlled: true,
          ),
          builder: (context, type) {
            return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return AdaptiveSheetScaffold(
                  type: type,
                  title: appLocalizations.selectProfile, //selectProfile 选择订阅
                  body: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Container(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                         //   const Divider(),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              // 使用过滤后的可见订阅数量
                              itemCount: visibleProfiles.length,
                              itemBuilder: (context, index) {
                                final profile = visibleProfiles[index];
                                final isSelected = profile.id == currentProfileId;

                              return Container(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: CommonCard(
                                  type: CommonCardType.filled,
                                  isSelected: isSelected,
                                  child: ListTile(
                                    leading: Icon(
                                      isSelected 
                                          ? Icons.radio_button_checked 
                                          : Icons.radio_button_unchecked,
                                      size: 18,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    horizontalTitleGap: 3,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 0,
                                    ),
                                    title: Text(
                                      profile.label ?? profile.id,
                                      style: context.textTheme.titleMedium?.copyWith(
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                    trailing: profile.type == ProfileType.url
                                        ? const Icon(Icons.cloud_outlined, size: 18)
                                        : const Icon(Icons.file_copy_outlined, size: 18),
                                    onTap: () {
                                      // 切换选中的订阅
                                      ref.read(currentProfileIdProvider.notifier).state = profile.id;
                                      // 刷新相关状态
                                      ref.refresh(selectedMapProvider);
                                      Navigator.pop(context);
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
      });
    }

    // 卡片背景色逻辑
    Color getBackgroundColor(BuildContext context, bool isSelected) {
      final colorScheme = Theme.of(context).colorScheme;
      return colorScheme.surface.opacity10;
    }

    // 卡片边框逻辑
    BorderSide getBorderSide(BuildContext context, bool isSelected) {
      final colorScheme = Theme.of(context).colorScheme;
      return BorderSide(
        color: colorScheme.surfaceContainerHighest,
      );
    }

    final cardPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 12);
    
    return SizedBox(
      height: getWidgetHeight(1), // 与outbound_mode_drop_down保持一致高度
      child: CommonCard(
        onPressed: showProfileSelector,
        info: Info(
          label: appLocalizations.selectProfile,// 选择配置
          iconData: Icons.folder_outlined,
        ),
        child: Container(
          // 匹配outbound_mode_drop_down的内边距
          padding: baseInfoEdgeInsets.copyWith(top: 0),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                // 精确匹配文字区域高度
                height: globalState.measure.bodyMediumHeight + 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    profileLabel,
                    // 完全匹配outbound_mode_drop_down的文字样式
                    style: context.textTheme.bodyMedium?.toLight.adjustSize(1),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
