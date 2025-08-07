import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/plugins/app.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http; // 引入 http 包

class AccessView extends ConsumerStatefulWidget {
  const AccessView({super.key});

  @override
  ConsumerState<AccessView> createState() => _AccessViewState();
}

class _AccessViewState extends ConsumerState<AccessView> {
  List<String> acceptList = [];
  List<String> rejectList = [];
  late ScrollController _controller;
  final _completer = Completer();

  @override
  void initState() {
    super.initState();
    _updateInitList();
    _controller = ScrollController();
    _completer.complete(globalState.appController.getPackages());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  _updateInitList() {
    acceptList = globalState.config.vpnProps.accessControl.acceptList;
    rejectList = globalState.config.vpnProps.accessControl.rejectList;
  }

  Widget _buildSearchButton() {
    return IconButton(
      tooltip: appLocalizations.search,
      onPressed: () {
        showSearch(
          context: context,
          delegate: AccessControlSearchDelegate(
            acceptList: acceptList,
            rejectList: rejectList,
          ),
        ).then(
          (_) => setState(
            () {
              _updateInitList();
            },
          ),
        );
      },
      icon: const Icon(Icons.search),
    );
  }

  Widget _buildSelectedAllButton({
    required bool isSelectedAll,
    required List<String> allValueList,
  }) {
    final tooltip = isSelectedAll
        ? appLocalizations.cancelSelectAll
        : appLocalizations.selectAll;
    return IconButton(
      tooltip: tooltip,
      onPressed: () {
        ref.read(vpnSettingProvider.notifier).updateState((state) {
          final isAccept =
              state.accessControl.mode == AccessControlMode.acceptSelected;
          if (isSelectedAll) {
            return switch (isAccept) {
              true => state.copyWith.accessControl(
                  acceptList: [],
                ),
              false => state.copyWith.accessControl(
                  rejectList: [],
                ),
            };
          } else {
            return switch (isAccept) {
              true => state.copyWith.accessControl(
                  acceptList: allValueList,
                ),
              false => state.copyWith.accessControl(
                  rejectList: allValueList,
                ),
            };
          }
        });
      },
      icon: isSelectedAll
          ? const Icon(Icons.deselect)
          : const Icon(Icons.select_all),
    );
  }

  _intelligentSelected() async {
    final packageNames = ref.read(
      packageListSelectorStateProvider.select(
        (state) => state.list.map((item) => item.packageName),
      ),
    );
    final commonScaffoldState = context.commonScaffoldState;
    if (commonScaffoldState?.mounted != true) return;
    final selectedPackageNames =
        (await commonScaffoldState?.loadingRun<List<String>>(
              () async {
                return await app?.getChinaPackageNames() ?? [];
              },
            ))
                ?.toSet() ??
            {};
    final acceptList = packageNames
        .where((item) => !selectedPackageNames.contains(item))
        .toList();
    final rejectList = packageNames
        .where((item) => selectedPackageNames.contains(item))
        .toList();
    ref.read(vpnSettingProvider.notifier).updateState(
          (state) => state.copyWith.accessControl(
            acceptList: acceptList,
            rejectList: rejectList,
          ),
        );
  }

  Widget _buildSettingButton() {
    return IconButton(
      onPressed: () async {
        final res = await showSheet<int>(
          context: context,
          props: SheetProps(
            isScrollControlled: true,
          ),
          builder: (_, type) {
            return AdaptiveSheetScaffold(
              type: type,
              body: AccessControlPanel(),
              title: appLocalizations.proxiesSetting,
            );
          },
        );
        if (res == 1) {
          _intelligentSelected();
        }
      },
      icon: const Icon(Icons.tune),
    );
  }

  _handleSelected(List<String> valueList, Package package, bool? value) {
    if (value == true) {
      valueList.add(package.packageName);
    } else {
      valueList.remove(package.packageName);
    }
    ref.read(vpnSettingProvider.notifier).updateState((state) {
      return switch (
          state.accessControl.mode == AccessControlMode.acceptSelected) {
        true => state.copyWith.accessControl(
            acceptList: valueList,
          ),
        false => state.copyWith.accessControl(
            rejectList: valueList,
          ),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(packageListSelectorStateProvider);
    final accessControl = state.accessControl;
    final accessControlMode = accessControl.mode;
    final packages = state.getSortList(
      accessControlMode == AccessControlMode.acceptSelected
          ? acceptList
          : rejectList,
    );
    final currentList = accessControl.currentList;
    final packageNameList = packages.map((e) => e.packageName).toList();
    final valueList = currentList.intersection(packageNameList);
    final describe = accessControlMode == AccessControlMode.acceptSelected
        ? appLocalizations.accessControlAllowDesc
        : appLocalizations.accessControlNotAllowDesc;
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        // 1. 应用访问控制开关
        Flexible(
          flex: 0,
          child: ListItem.switchItem(
            title: Text(appLocalizations.appAccessControl),
            delegate: SwitchDelegate(
              value: accessControl.enable,
              onChanged: (enable) {
                ref.read(vpnSettingProvider.notifier).updateState(
                      (state) => state.copyWith.accessControl(
                        enable: enable,
                      ),
                    );
              },
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Divider(
            height: 12,
          ),
        ),
        Flexible(
          child: DisabledMask(
            status: !accessControl.enable,
            child: Column(
              children: [
                ActivateBox(
                  active: accessControl.enable,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 4,
                      bottom: 4,
                      left: 16,
                      right: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Expanded(
                          child: IntrinsicHeight(
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          appLocalizations.selected,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                              ),
                                        ),
                                      ),
                                      const Flexible(
                                        child: SizedBox(
                                          width: 8,
                                        ),
                                      ),
                                      Flexible(
                                        child: Text(
                                          "${valueList.length}",
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Flexible(
                                  child: Text(describe),
                                )
                              ],
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Flexible(
                              child: _buildSearchButton(),
                            ),
                            Flexible(
                              child: _buildSelectedAllButton(
                                isSelectedAll:
                                    valueList.length == packageNameList.length,
                                allValueList: packageNameList,
                              ),
                            ),
                            Flexible(
                              child: _buildSettingButton(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: FutureBuilder(
                      future: _completer.future,
                      builder: (_, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return Center(
                          child: CircularProgressIndicator(),
                          );
                        }
                        return packages.isEmpty
                            ? NullStatus(
                                label: appLocalizations.noData,
                        )
                      : CommonScrollBar(
                          controller: _controller,
                          child: ListView.separated(
                            controller: _controller,
                    padding: EdgeInsets.only(
                     // top: 8,
                    //  left: 16,
                    //  right: 16,
                      bottom: 16, // 增加底部内边距，确保最后一项不被遮挡,安全距离
                    ),
                            itemCount: packages.length,
                            separatorBuilder: (context, index) => const Divider(
                              height: 1,
                              thickness: 1,
                            //  color: Colors.grey,
                            ),
                            itemBuilder: (_, index) {
                              final package = packages[index];
                              final listItem = PackageListItem(
                                key: Key(package.packageName),
                                package: package,
                                    value: valueList
                                        .contains(package.packageName),
                                    isActive: accessControl.enable,
                                    onChanged: (value) {
                                      _handleSelected(
                                          valueList, package, value);
                                    },
                                  );
                                  
                              // 最后一项添加底部分隔线
                              if (index == packages.length - 1) {
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    listItem,
                                    const Divider(
                                      height: 1,
                                      thickness: 1,
                                    ),
                                  ],
                                );
                              }
                              return listItem;
                            },
                          ),
                        );
                      }),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class PackageListItem extends StatelessWidget {
  final Package package;
  final bool value;
  final bool isActive;
  final void Function(bool?) onChanged;

  const PackageListItem({
    super.key,
    required this.package,
    required this.value,
    required this.isActive,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return FadeScaleEnterBox(
      child: ActivateBox(
        active: isActive,
        child: ListItem.checkbox(
          leading: SizedBox(
            width: 48,
            height: 48,
            child: FutureBuilder<ImageProvider?>(
              future: app?.getPackageIcon(package.packageName),
              builder: (_, snapshot) {
                if (!snapshot.hasData && snapshot.data == null) {
                  return Container();
                } else {
                  return Image(
                    image: snapshot.data!,
                    gaplessPlayback: true,
                    width: 48,
                    height: 48,
                  );
                }
              },
            ),
          ),
          title: Text(
            package.label,
            style: const TextStyle(
              overflow: TextOverflow.ellipsis,
            ),
            maxLines: 1,
          ),
          subtitle: Text(
            package.packageName,
            style: const TextStyle(
              overflow: TextOverflow.ellipsis,
            ),
            maxLines: 1,
          ),
          delegate: CheckboxDelegate(
            value: value,
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}

class AccessControlSearchDelegate extends SearchDelegate {
  List<String> acceptList = [];
  List<String> rejectList = [];

  AccessControlSearchDelegate({
    required this.acceptList,
    required this.rejectList,
  });

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () {
          if (query.isEmpty) {
            close(context, null);
            return;
          }
          query = '';
        },
        icon: const Icon(Icons.clear),
      ),
      const SizedBox(
        width: 8,
      )
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () {
        close(context, null);
      },
      icon: const Icon(Icons.arrow_back),
    );
  }

  _handleSelected(
      WidgetRef ref, List<String> valueList, Package package, bool? value) {
    if (value == true) {
      valueList.add(package.packageName);
    } else {
      valueList.remove(package.packageName);
    }
    ref.read(vpnSettingProvider.notifier).updateState((state) {
      return switch (
          state.accessControl.mode == AccessControlMode.acceptSelected) {
        true => state.copyWith.accessControl(
            acceptList: valueList,
          ),
        false => state.copyWith.accessControl(
            rejectList: valueList,
          ),
      };
    });
  }

  Widget _packageList() {
    final lowQuery = query.toLowerCase();
    return Consumer(
      builder: (context, ref, __) {
        final vm3 = ref.watch(
          packageListSelectorStateProvider.select(
            (state) => VM3(
              a: state.getSortList(
                state.accessControl.mode == AccessControlMode.acceptSelected
                    ? acceptList
                    : rejectList,
              ),
              b: state.accessControl.enable,
              c: state.accessControl.currentList,
            ),
          ),
        );
        final packages = vm3.a;
        final queryPackages = packages
            .where(
              (package) =>
                  package.label.toLowerCase().contains(lowQuery) ||
                  package.packageName.contains(lowQuery),
            )
            .toList();
        final isAccessControl = vm3.b;
        final currentList = vm3.c;
        final packageNameList = packages.map((e) => e.packageName).toList();
        final valueList = currentList.intersection(packageNameList);
        return DisabledMask(
          status: !isAccessControl,
          child: ListView.separated(
            itemCount: queryPackages.length,
            separatorBuilder: (context, index) => const Divider(
              height: 1,
              thickness: 1,
             // color: Colors.grey,
            ),
            itemBuilder: (_, index) {
              final package = queryPackages[index];
              final listItem = PackageListItem(
                key: Key(package.packageName),
                package: package,
                value: valueList.contains(package.packageName),
                isActive: isAccessControl,
                onChanged: (value) {
                  _handleSelected(
                    ref,
                    valueList,
                    package,
                    value,
                  );
                },
              );
              
              // 最后一项添加底部分隔线
              if (index == queryPackages.length - 1) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    listItem,
                    const Divider(
                      height: 1,
                      thickness: 1,
                    ),
                  ],
                );
              }
              return listItem;
            },
          ),
        );
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return buildSuggestions(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _packageList();
  }
}

class AccessControlPanel extends ConsumerStatefulWidget {
  const AccessControlPanel({
    super.key,
  });

  @override
  ConsumerState createState() => _AccessControlPanelState();
}

class _AccessControlPanelState extends ConsumerState<AccessControlPanel> {
  IconData _getIconWithAccessControlMode(AccessControlMode mode) {
    return switch (mode) {
      AccessControlMode.acceptSelected => Icons.adjust_outlined,
      AccessControlMode.rejectSelected => Icons.block_outlined,
    };
  }

  String _getTextWithAccessControlMode(AccessControlMode mode) {
    return switch (mode) {
      AccessControlMode.acceptSelected => appLocalizations.whitelistMode,
      AccessControlMode.rejectSelected => appLocalizations.blacklistMode,
    };
  }

  String _getTextWithAccessSortType(AccessSortType type) {
    return switch (type) {
      AccessSortType.none => appLocalizations.defaultText,
      AccessSortType.name => appLocalizations.name,
      AccessSortType.time => appLocalizations.time,
    };
  }

  IconData _getIconWithProxiesSortType(AccessSortType type) {
    return switch (type) {
      AccessSortType.none => Icons.sort,
      AccessSortType.name => Icons.sort_by_alpha,
      AccessSortType.time => Icons.timeline,
    };
  }

  List<Widget> _buildModeSetting() {
    return generateSection(
      title: appLocalizations.mode,
      items: [
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          child: Consumer(
            builder: (_, ref, __) {
              final accessControlMode = ref.watch(
                vpnSettingProvider.select((state) => state.accessControl.mode),
              );
              return Wrap(
                spacing: 16,
                children: [
                  for (final item in AccessControlMode.values)
                    SettingInfoCard(
                      Info(
                        label: _getTextWithAccessControlMode(item),
                        iconData: _getIconWithAccessControlMode(item),
                      ),
                      isSelected: accessControlMode == item,
                      onPressed: () {
                        ref.read(vpnSettingProvider.notifier).updateState(
                              (state) => state.copyWith.accessControl(
                                mode: item,
                              ),
                            );
                      },
                    )
                ],
              );
            },
          ),
        )
      ],
    );
  }

  List<Widget> _buildSortSetting() {
    return generateSection(
      title: appLocalizations.sort,
      items: [
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          child: Consumer(
            builder: (_, ref, __) {
              final accessSortType = ref.watch(
                vpnSettingProvider.select((state) => state.accessControl.sort),
              );
              return Wrap(
                spacing: 16,
                children: [
                  for (final item in AccessSortType.values)
                    SettingInfoCard(
                      Info(
                        label: _getTextWithAccessSortType(item),
                        iconData: _getIconWithProxiesSortType(item),
                      ),
                      isSelected: accessSortType == item,
                      onPressed: () {
                        ref.read(vpnSettingProvider.notifier).updateState(
                              (state) => state.copyWith.accessControl(
                                sort: item,
                              ),
                            );
                      },
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  List<Widget> _buildSourceSetting() {
    return generateSection(
      title: appLocalizations.source,
      items: [
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          child: Consumer(
            builder: (_, ref, __) {
              final vm2 = ref.watch(
                vpnSettingProvider.select(
                  (state) => VM2(
                    a: state.accessControl.isFilterSystemApp,
                    b: state.accessControl.isFilterNonInternetApp,
                  ),
                ),
              );
              return Wrap(
                spacing: 16,
                children: [
                  SettingTextCard(
                    appLocalizations.systemApp,
                    isSelected: vm2.a == false,
                    onPressed: () {
                      ref.read(vpnSettingProvider.notifier).updateState(
                            (state) => state.copyWith.accessControl(
                              isFilterSystemApp: !vm2.a,
                            ),
                          );
                    },
                  ),
                  SettingTextCard(
                    appLocalizations.noNetworkApp,
                    isSelected: vm2.b == false,
                    onPressed: () {
                      ref.read(vpnSettingProvider.notifier).updateState(
                            (state) => state.copyWith.accessControl(
                              isFilterNonInternetApp: !vm2.b,
                            ),
                          );
                    },
                  )
                ],
              );
            },
          ),
        )
      ],
    );
  }

  _copyToClipboard() async {
    await globalState.safeRun(() {
      final data = globalState.config.vpnProps.accessControl.toJson();
      Clipboard.setData(
        ClipboardData(
          text: json.encode(data),
        ),
      );
    });
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  _pasteToClipboard() async {
    await globalState.safeRun(
      () async {
        final data = await Clipboard.getData('text/plain');
        final text = data?.text;
        if (text == null) return;
        ref.read(vpnSettingProvider.notifier).updateState(
              (state) => state.copyWith(
                accessControl: AccessControl.fromJson(
                  json.decode(text),
                ),
              ),
            );
      },
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

Future<void> _importFromFile() async {
  final filePickerResult = await FilePicker.platform.pickFiles(
    withData: true,
    allowMultiple: false,
    type: FileType.custom,
    allowedExtensions: ['json'], // 假设文件格式为 JSON
  );

  if (filePickerResult != null && filePickerResult.files.isNotEmpty) {
    final file = filePickerResult.files.first;
    final bytes = file.bytes;
    if (bytes != null) {
      try {
        final String content = utf8.decode(bytes);
        final data = json.decode(content);
        final accessControl = AccessControl.fromJson(data);

        ref.read(vpnSettingProvider.notifier).updateState(
              (state) => state.copyWith.accessControl(
                acceptList: accessControl.acceptList,
                rejectList: accessControl.rejectList,
              ),
            );

        if (!mounted) return;
        // 显示导入成功的提示信息
        globalState.showNotifier(appLocalizations.importSuccess); 
        Navigator.of(context).pop();
      } catch (e) {
        // 处理解析错误
        print('Failed to parse file: $e');
      }
    }
  }
}

Future<void> _exportToFile() async {
  final accessControl = globalState.config.vpnProps.accessControl;
  final data = accessControl.toJson();
  final jsonString = json.encode(data);

  final now = DateTime.now();
  final formattedDate = DateFormat('yyyy-MM-dd_HH-mm-ss').format(now);
  final fileName = '$formattedDate.json';

  try {
    // 让用户选择保存路径
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: appLocalizations.selectSaveLocation,  
    );

    if (selectedDirectory == null) {
      // 用户取消了选择
      if (!mounted) return;
      globalState.showNotifier(appLocalizations.exportCanceled); 
      return;
    }

    // 拼接完整路径
    final filePath = '$selectedDirectory/$fileName';
    final file = File(filePath);

    // 写入文件
    await file.writeAsString(jsonString);
    print('Exported to $filePath');

    if (!mounted) return;
    globalState.showNotifier(appLocalizations.exportSuccess);
    Navigator.of(context).pop();
  } catch (e) {
    print('Failed to export file: $e');
    if (!mounted) return;
    globalState.showNotifier('${appLocalizations.exportFailed}: $e');
  }
}

  // 新增通过链接导入的方法
  Future<void> _importFromUrl() async {
    const url = 'https://raw.githubusercontent.com/kysornekmc/Access_settings_list/refs/heads/main/Access_settings_list.json';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final accessControl = AccessControl.fromJson(data);

        ref.read(vpnSettingProvider.notifier).updateState(
              (state) => state.copyWith.accessControl(
                acceptList: accessControl.acceptList,
                rejectList: accessControl.rejectList,
              ),
            );

        if (!mounted) return;
        // 显示导入成功的提示信息
        globalState.showNotifier(appLocalizations.importSuccess);
        Navigator.of(context).pop();
      } else {
        print('Failed to fetch data from URL: ${response.statusCode}');
        if (!mounted) return;
        globalState.showNotifier('${appLocalizations.importFailed}: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching data from URL: $e');
      if (!mounted) return;
      globalState.showNotifier('${appLocalizations.importFailed}: $e');
    }
  }

  List<Widget> _buildActionSetting() {
    return generateSection(
      title: appLocalizations.action,
      items: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
          ),
          child: Wrap(
            runSpacing: 16,
            spacing: 16,
            children: [
              CommonChip(
                avatar: const Icon(Icons.auto_awesome),
                label: appLocalizations.intelligentSelected,
                onPressed: () {
                  Navigator.of(context).pop(1);
                },
              ),
              CommonChip(
                avatar: const Icon(Icons.paste),
                label: appLocalizations.clipboardImport,
                onPressed: _pasteToClipboard,
              ),
              CommonChip(
                avatar: const Icon(Icons.content_copy),
                label: appLocalizations.clipboardExport,
                onPressed: _copyToClipboard,
            ),
            // 新增从本地文件导入按钮
            CommonChip(
              avatar: const Icon(Icons.file_download),
              label: appLocalizations.importFile,
              onPressed: _importFromFile,
            ),
              // 新增导出到文件按钮
              CommonChip(
                avatar: const Icon(Icons.file_upload),
                label: appLocalizations.exportFile,
                onPressed: _exportToFile,
              ),
              // 新增通过链接导入按钮
              CommonChip(
                avatar: const Icon(Icons.link),
                label: appLocalizations.importFromURL,
                onPressed: _importFromUrl,
              ),
            ],
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ..._buildModeSetting(),
            ..._buildSortSetting(),
            ..._buildSourceSetting(),
            ..._buildActionSetting(),
          ],
        ),
      ),
    );
  }
}
