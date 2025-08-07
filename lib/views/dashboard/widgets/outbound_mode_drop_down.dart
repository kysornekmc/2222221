import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/providers/config.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_clash/common/utils.dart'; // 新增导入

class OutboundModeDropDown extends StatelessWidget {
  const OutboundModeDropDown({super.key});

  // 参考 selectproxy.dart 中的 getBackgroundColor 方法
  Color getBackgroundColor(BuildContext context, bool isSelected) {
    final colorScheme = Theme.of(context).colorScheme;
    if (isSelected) {
      return colorScheme.secondaryContainer;
    }
    return colorScheme.surface.opacity10;
  }

  // 参考 selectproxy.dart 中的 getBorderSide 方法
  BorderSide getBorderSide(BuildContext context, bool isSelected) {
    final colorScheme = Theme.of(context).colorScheme;
    return BorderSide(
      color: isSelected
          ? colorScheme.primary
          : colorScheme.surfaceContainerHighest,
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = getWidgetHeight(1);
    final utils = Utils(); // 创建Utils实例，与selectproxy保持一致
    return SizedBox(
      height: height,
      child: Consumer(
        builder: (_, ref, __) {
          final mode = ref.watch(
            patchClashConfigProvider.select(
              (state) => state.mode,
            ),
          );
          return Theme(
            data: Theme.of(context).copyWith(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
            ),
            child: CommonCard(
              onPressed: () {
                showSheet(
                  context: context,
                  props: const SheetProps(
                    isScrollControlled: true,
                  ),
                  builder: (context, type) {
                    // 将底部安全区域高度固定为16像素
                    final bottomPadding = 16.0;
                    
                    return StatefulBuilder(
                      builder: (BuildContext context, StateSetter setState) {
                        return AdaptiveSheetScaffold(
                          type: type,
                          title: appLocalizations.outboundModeSelecte,
                          body: Container(
                            padding: EdgeInsets.only(bottom: bottomPadding),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                              //    const Divider(),
                                  // 添加SingleChildScrollView包裹ListView
                                  SingleChildScrollView(
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(), // 禁用内部滚动
                                      itemCount: Mode.values.length,
                                      itemBuilder: (context, index) {
                                        final item = Mode.values[index];
                                        final isSelected = item == mode;
                                        
                                        return Container(
                                          padding: const EdgeInsets.symmetric(vertical: 4),
                                          child: CommonCard(
                                            type: CommonCardType.filled,
                                            isSelected: isSelected,
                                            child: ListTile(
                                              leading: Icon(
                                                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                                size: 18,
                                                color: Theme.of(context).primaryColor,
                                              ),
                                              horizontalTitleGap: 3,
                                              contentPadding: const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 0,
                                              ),
                                              title: Text(
                                                "${Intl.message(item.name)}${appLocalizations.modese}",
                                                style: context.textTheme.titleMedium?.copyWith(
                                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              onTap: () async {
                                                try {
                                                  globalState.appController.changeMode(item);
                                                  Navigator.pop(context);
                                                } catch (e) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text('Failed to change mode: $e')),
                                                  );
                                                }
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
              info: Info(
                label: appLocalizations.outboundModeSelecte,
                iconData: Icons.call_split_sharp,
              ),
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
                      child: InkWell(
                        onTap: () {
                          // 触发showSheet的逻辑已经在CommonCard的onPressed中实现
                        },
                        child: Row(
                          children: [
                            Text(
                              " ${Intl.message(mode.name)}${appLocalizations.modese}",
                              style: context.textTheme.bodyMedium?.toLight.adjustSize(1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
