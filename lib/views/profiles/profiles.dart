import 'dart:ui';
import 'dart:async'; // 引入异步相关库

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/profiles/edit_profile.dart';
import 'package:fl_clash/views/profiles/override_profile.dart';
import 'package:fl_clash/views/profiles/scripts.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart'; // 引入 qr_flutter 包
import 'package:fl_clash/views/backup_and_recovery.dart';
import 'package:fl_clash/common/dav_client.dart';

import 'add_profile.dart';
import 'package:fl_clash/widgets/scroll.dart';

class ProfilesView extends StatefulWidget {
  const ProfilesView({super.key});

  @override
  State<ProfilesView> createState() => _ProfilesViewState();
}

class _ProfilesViewState extends State<ProfilesView> with PageMixin {
  Function? applyConfigDebounce;
  Set<String> hiddenProfileIds = {}; // 用于存储隐藏的配置文件 ID
  Timer? _refreshTimer;
  DateTime? _lastRefreshTime; // 记录上一次刷新的时间
  
  @override
  void initState() {
    super.initState();
    _loadHiddenProfileIds();
    _lastRefreshTime = DateTime.now(); // 初始化上一次刷新时间为当前时间
    // 初始时不启动定时器，等待监听状态
  }

  @override
  void dispose() {
    _refreshTimer?.cancel(); 
    super.dispose();
  }

  // 加载隐藏的配置文件 ID
  _loadHiddenProfileIds() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList('hiddenProfileIds') ?? [];
    setState(() {
      hiddenProfileIds = Set<String>.from(ids);
    });
  }

  // 保存隐藏的配置文件 ID
  _saveHiddenProfileIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('hiddenProfileIds', hiddenProfileIds.toList());
  }

  _handleShowAddExtendPage() {
    showExtend(
      globalState.navigatorKey.currentState!.context,
      builder: (_, type) {
        return AdaptiveSheetScaffold(
          type: type,
          body: AddProfileView(
            context: globalState.navigatorKey.currentState!.context,
          ),
          title: "${appLocalizations.add}${appLocalizations.profile}",//添加配置
        );
      },
    );
  }

 _updateProfiles() async {
    final profiles = globalState.config.profiles;
    final messages = [];
    final updateProfiles = profiles.map<Future>(
      (profile) async {
      // 如果配置文件是隐藏的，则跳过更新
      if (hiddenProfileIds.contains(profile.id)) return;  //删除这一句，则更新所有显示/隐藏的订阅
      if (profile.type == ProfileType.file || profile.neverUpdate) return; // 新增检查
      try {
        globalState.appController.setProfile(
          profile.copyWith(isUpdating: true),
        );
          await globalState.appController.updateProfile(profile);
        } catch (e) {
          messages.add("${profile.label ?? profile.id}: $e \n");
          globalState.appController.setProfile(
            profile.copyWith(
              isUpdating: false,
            ),
          );
        }
      },
    );
    final titleMedium = context.textTheme.titleMedium;
    await Future.wait(updateProfiles);
    if (messages.isNotEmpty) {
      globalState.showMessagese( 
        title: appLocalizations.tip,
        message: TextSpan(
          children: [
            for (final message in messages)
              TextSpan(text: message, style: titleMedium)
          ],
        ),
      );
    }
  }

  // 显示隐藏配置文件选择对话框//
_showProfileSelectionDialog() {
  final profiles = globalState.config.profiles;
  showSheet(
    context: context,
    builder: (_, type) {
      final bottomPadding = MediaQuery.of(context).padding.bottom;

      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AdaptiveSheetScaffold(
            type: type,
            // 移除关闭按钮相关的actions配置
            actions: [], // 清空actions数组
            body: Container(
              // 添加底部 padding 以避免被虚拟导航栏遮挡
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),  //（左、上、右、下）
                // 移除外层Column的Expanded和SingleChildScrollView嵌套
                child: ListView.builder(
                  shrinkWrap: true, // 关键：让列表视图适应内容高度
                  physics: const ClampingScrollPhysics(), // 保留滚动能力
                  itemCount: profiles.length,
                  itemBuilder: (BuildContext context, int index) {
                    final profile = profiles[index];
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: CommonCard(
                        type: CommonCardType.filled,
                        child: ListTile(
                          contentPadding: const EdgeInsets.only(
                                  right: 4, //默认16
                            left: 16,
                          ),
                          title: Text(profile.label ?? profile.id),
                          trailing: Checkbox(
                            value: !hiddenProfileIds.contains(profile.id),
                            onChanged: (bool? value) {
                              if (value != null) {
                                setState(() => value 
                                  ? hiddenProfileIds.remove(profile.id) 
                                  : hiddenProfileIds.add(profile.id)
                                );
                                _saveHiddenProfileIds();
                                if (mounted) this.setState(() {});
                              }
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            title: appLocalizations.showhideProfiles,
          );
        },
      );
    },
  );
}


  _backupOnWebDAV(BuildContext context, DAVClient client) async {
    final commonScaffoldState = context.commonScaffoldState;
    final res = await commonScaffoldState?.loadingRun<bool>(
      () async {
        final backupData = await globalState.appController.backupData();
        return await client.backup(Uint8List.fromList(backupData));
      },
      title: appLocalizations.backup,
    );
    if (res != true) return;
    globalState.showNotifier(appLocalizations.backupSuccess);
  }

  _handleRecoveryOnWebDAV(BuildContext context, DAVClient client) async {
    final recoveryOption = await globalState.showCommonDialog<RecoveryOption>(
      child: const RecoveryOptionsDialog(),
    );
    if (recoveryOption == null || !context.mounted) return;
    final commonScaffoldState = context.commonScaffoldState;
    final res = await commonScaffoldState?.loadingRun<bool>(
      () async {
        final data = await client.recovery();
        await globalState.appController.recoveryData(data, recoveryOption);
        return true;
      },
      title: appLocalizations.recovery,
    );
    if (res != true) return;
    globalState.showNotifier(appLocalizations.recoverySuccess); 
  }

  @override
  List<Widget> get actions => [
      IconButton(
        onPressed: () {
          _handleShowAddExtendPage();  //添加
        },
        icon: const Icon(Icons.add),
	color: Theme.of(context).colorScheme.primary, // 添加颜色属性
      ),
      Consumer(
        builder: (context, ref, __) {
          final dav = ref.watch(appDAVSettingProvider);
          final client = dav != null ? DAVClient(dav) : null;
          return CommonPopupBox(
            targetBuilder: (open) {
              return IconButton(
                onPressed: () {
                  open(
                    offset: Offset(0, 20),
                  );
                },
                icon: Icon(
                  Icons.more_vert,
		  color: Theme.of(context).colorScheme.primary, // 添加颜色属性
                ),
              );
            },
            popup: CommonPopupMenu(
     //   minWidth: 180,
              items: [
                PopupMenuItemData(
                  icon: Icons.cloud_upload,
                  label: appLocalizations.webdavbackup,
                  onPressed: client != null 
                    ? () => _backupOnWebDAV(context, client) 
                    : null,
                ),
                PopupMenuItemData(
                  icon: Icons.cloud_download,
                  label: appLocalizations.webdavrecovery,
                  onPressed: client != null 
                    ? () => _handleRecoveryOnWebDAV(context, client) 
                    : null,
                ),
                PopupMenuItemData(
                  icon: Icons.functions,
                  label: appLocalizations.Script, // 脚本设置
                  onPressed: () {
                    showExtend(
                      context,
                      builder: (_, type) {
                        return ScriptsView();
                      },
                    );
                  },
                ),	
                PopupMenuItemData(
                  icon: Icons.sort,
                  label: appLocalizations.profilesSort,
                  onPressed: () {
                    final profiles = globalState.config.profiles;
                    showSheet(
                      context: context,
                      builder: (_, type) {
                        return ReorderableProfilesSheet(
                          type: type,
                          profiles: profiles,
                        );
                      },
                    );
                  },
                ),
                PopupMenuItemData(
                  icon: Icons.visibility,
                  label: appLocalizations.showhideProfiles,
                  onPressed: () {
                    _showProfileSelectionDialog();//
                  },
                ),
              ],
            ),
          );
        },
      ),
    ];


  @override
  Widget? get floatingActionButton => FloatingActionButton(
        heroTag: null,
        onPressed: _updateProfiles,  //add
	backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        child:  Icon(
         // Icons.sync,
          Icons.sync,color: Theme.of(context).colorScheme.primary,// 颜色同主题色
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (_, ref, __) {
        ref.listenManual(
          isCurrentPageProvider(PageLabel.profiles),
          (prev, next) {
            if (prev != next && next == true) {
              initPageState();
            }
          },
          fireImmediately: true,
        );
        final profilesSelectorState = ref.watch(profilesSelectorStateProvider);
        final autoRefreshEnabled = ref.watch(
          appSettingProvider.select((state) => state.autoRefreshEnabled),
        );

        // 根据自动刷新状态控制定时器
        if (autoRefreshEnabled) {
          if (_refreshTimer == null || _refreshTimer!.isActive == false) {
            _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
              if (mounted) {
                setState(() {});
                // 检查刷新间隔是否超过1小时
                final now = DateTime.now();
                if (now.difference(_lastRefreshTime!).inHours >= 1) {
                  // 超过1小时，重新设置定时器为每1小时刷新一次
                  _refreshTimer?.cancel();
                  _refreshTimer = Timer.periodic(const Duration(hours: 1), (_) {
                    if (mounted) setState(() {});
                  });
                  _lastRefreshTime = now; // 更新上一次刷新时间
                }
              }
            });
          }
        } else {
          _refreshTimer?.cancel();
        }

        if (profilesSelectorState.profiles.isEmpty) {
          return NullStatus(
            label: appLocalizations.nullProfileDesc,
          );
        }
        ScrollController scrollController = ScrollController(); // 创建 ScrollController
        return Align(
          alignment: Alignment.topCenter,
          child: CommonAutoHiddenScrollBar( // 使用 CommonAutoHiddenScrollBar 包裹 SingleChildScrollView
          controller: scrollController,
          child: SingleChildScrollView(
          controller: scrollController, // 将 ScrollController 传递给 SingleChildScrollView
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 88,
            ),
            child: Grid(
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              crossAxisCount: profilesSelectorState.columns,
              children: [
                for (int i = 0; i < profilesSelectorState.profiles.length; i++)
                  if (!hiddenProfileIds.contains(profilesSelectorState.profiles[i].id)) // 过滤隐藏的配置文件
                  GridItem(
                    child: ProfileItem(
                      key: Key(profilesSelectorState.profiles[i].id),
                      profile: profilesSelectorState.profiles[i],
                      groupValue: profilesSelectorState.currentProfileId,
                      onChanged: (profileId) {
                        ref.read(currentProfileIdProvider.notifier).value =
                            profileId;
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
  }
}

class ProfileItem extends StatelessWidget {
  final Profile profile;
  final String? groupValue;
  final void Function(String? value) onChanged;

  const ProfileItem({
    super.key,
    required this.profile,
    required this.groupValue,
    required this.onChanged,
  });

  _handleDeleteProfile(BuildContext context) async {
    final res = await globalState.showMessage(
      title: appLocalizations.tip,
      message: TextSpan(
        text: appLocalizations.deleteTip(appLocalizations.profile),
      ),
    );
    if (res != true) {
      return;
    }
    await globalState.appController.deleteProfile(profile.id);
  }

  Future updateProfile() async {
    final appController = globalState.appController;
    if (profile.type == ProfileType.file) return;
    await globalState.safeRun(silence: false, () async {
      try {
        appController.setProfile(
          profile.copyWith(
            isUpdating: true,
          ),
        );
        await appController.updateProfile(profile);
      } catch (e) {
        appController.setProfile(
          profile.copyWith(
            isUpdating: false,
          ),
        );
        rethrow;
      }
    });
  }

  _handleShowEditExtendPage(BuildContext context) {
    showExtend(
      context,
      builder: (_, type) {
        return AdaptiveSheetScaffold(
          type: type,
          body: EditProfileView(
            profile: profile,
            context: context,
          ),
          title: "${appLocalizations.edit}${appLocalizations.profile}",
        );
      },
    );
  }

  List<Widget> _buildUrlProfileInfo(BuildContext context) {
    final subscriptionInfo = profile.subscriptionInfo;
    return [
      const SizedBox(
        height: 6,
      ),
      if (subscriptionInfo != null)
        SubscriptionInfoView(
          subscriptionInfo: subscriptionInfo,
        ),
   //   Text(
   //     profile.lastUpdateDate?.lastUpdateTimeDesc ?? "",
    //    style: context.textTheme.labelMedium?.toLight,
    //  ),
    ];
  }

  List<Widget> _buildFileProfileInfo(BuildContext context) {
    return [
      const SizedBox(
        height: 0,
      ),
    //  Text(
     //   profile.lastUpdateDate?.lastUpdateTimeDesc ?? "",
    //    style: context.textTheme.labelMedium?.toLight,
   //   ),
    ];
  }

   _handleCopyLink(BuildContext context) async {
     await Clipboard.setData(
       ClipboardData(
         text: profile.url,
       ),
     );
     if (context.mounted) {
       context.showNotifier(appLocalizations.copySuccess);
     }
   }

  _handleShareQrCode(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          contentPadding: EdgeInsets.all(25),
          children: [
            Container(
              width: 225,
              height: 225,
              child: Center(
                child: QrImageView(
                  data: profile.url,
                  foregroundColor: isDarkMode ? Colors.white : Colors.black,
                  size: 200,
                ),
              ),
            ),
          ],
        );
      },
    );
  } 

  _handleExportFile(BuildContext context) async {
    final commonScaffoldState = context.commonScaffoldState;
    final res = await commonScaffoldState?.loadingRun<bool>(
      () async {
        final file = await profile.getFile();
        final value = await picker.saveFile(
          profile.label ?? profile.id,
          file.readAsBytesSync(),
        );
        if (value == null) return false;
        return true;
      },
      title: appLocalizations.tip,
    );
    if (res == true && context.mounted) {
      context.showNotifier(appLocalizations.exportSuccess);
    }
  }

  _handlePushGenProfilePage(BuildContext context, String id) {
    final overrideProfileView = OverrideProfileView(
      profileId: id,
    );
    BaseNavigator.modal(
      context,
      overrideProfileView,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CommonCard(
      isSelected: profile.id == groupValue,
      onPressed: () {
        onChanged(profile.id);
      },
      child: ListItem(
        key: Key(profile.id),
        horizontalTitleGap: 16,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        trailing: SizedBox(
          height: 40,
          width: 40,
          child: FadeThroughBox(
            child: profile.isUpdating
                ? const Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(strokeWidth: 2,),
                  )
                : CommonPopupBox(
                    popup: CommonPopupMenu(
                      items: [
                        PopupMenuItemData(
                          icon: Icons.edit_outlined,
                          label: appLocalizations.edit,// 编辑
                          onPressed: () {
                            _handleShowEditExtendPage(context);
                          },
                        ),
                        if (profile.type == ProfileType.url) ...[
                          PopupMenuItemData(
                            icon: Icons.sync_outlined,
                            label: appLocalizations.sync, //同步
                            onPressed: profile.neverUpdate ? null : () {  //从不更新时，同步不可以显示灰色
                              updateProfile();
                            },
                          ),
                        ],
                        PopupMenuItemData( //覆写
                          icon: Icons.extension_outlined,
                          label: appLocalizations.override,
                          onPressed: () {
                            _handlePushGenProfilePage(context, profile.id);
                          },
                        ),
			if (profile.type == ProfileType.url) ...[  //判断是URL还是文件决定是否显示部分菜单
                        PopupMenuItemData(  //复制链接
                          icon: Icons.content_copy_outlined,
                          label: appLocalizations.copyLink,
                          onPressed: () {
                            _handleCopyLink(context);
                          },
                        ),
			],
			if (profile.type == ProfileType.url) ...[
                        PopupMenuItemData(  //新增的二维码分享订阅
                          icon: Icons.qr_code_outlined,
                          label: appLocalizations.shareQrCode,
                          onPressed: () {
                            _handleShareQrCode(context);
                          },
                        ),
			],						
                        PopupMenuItemData(  //导出文件
                          icon: Icons.file_copy_outlined,
                          label: appLocalizations.exportFile,
                          onPressed: () {
                            _handleExportFile(context);
                          },
                        ),
                        PopupMenuItemData( //删除
                          icon: Icons.delete_outlined,
                          label: appLocalizations.delete,
                          onPressed: () {
                            _handleDeleteProfile(context);
                          },
                        ),
                      ],
                    ),
                    targetBuilder: (open) {
                      return IconButton(
                        onPressed: () {
                          open();
                        },
                        icon: Icon(Icons.more_vert),
			color: Theme.of(context).colorScheme.primary, // 添加颜色属性
                      );
                    },
                  ),
          ),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
	    // 1***********************************************************更新显示在右上角
            Row(
	    mainAxisAlignment: MainAxisAlignment.spaceBetween,            // 两端对其
            crossAxisAlignment: CrossAxisAlignment.center,                // 水平居中
         //   textBaseline: TextBaseline.alphabetic,
	 //   mainAxisSize: MainAxisSize.max,	    
            children: [
              Flexible(
                child: Text(
                  profile.label ?? profile.id,                            // 机场名字
                style: context.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                profile.lastUpdateDate?.lastUpdateTimeDesc ?? '',         // 更新时间
                style: context.textTheme.labelMedium?.toLight,
              ),
            ],
          ),
	  
	  // 1***********************************************************更新显示在右上角

              Column(                                                    // 注释掉这里及一下就只有机场标题了
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ...switch (profile.type) {
                    ProfileType.file => _buildFileProfileInfo(context),
                    ProfileType.url => _buildUrlProfileInfo(context),
                  },
                ],
              ),
            ],
          ),
        ),
        tileTitleAlignment: ListTileTitleAlignment.titleHeight,
      ),
    );
  }
}

class ReorderableProfilesSheet extends StatefulWidget {
  final List<Profile> profiles;
  final SheetType type;

  const ReorderableProfilesSheet({
    super.key,
    required this.profiles,
    required this.type,
  });

  @override
  State<ReorderableProfilesSheet> createState() =>
      _ReorderableProfilesSheetState();
}

class _ReorderableProfilesSheetState extends State<ReorderableProfilesSheet> {
  late List<Profile> profiles;

  @override
  void initState() {
    super.initState();
    profiles = List.from(widget.profiles);
  }

  Widget proxyDecorator(
    Widget child,
    int index,
    Animation<double> animation,
  ) {
    final profile = profiles[index];
    return AnimatedBuilder(
      animation: animation,
      builder: (_, Widget? child) {
        final double animValue = Curves.easeInOut.transform(animation.value);
        final double scale = lerpDouble(1, 1.02, animValue)!;
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Container(
        key: Key(profile.id),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: CommonCard(
          type: CommonCardType.filled,
          child: ListTile(
            contentPadding: const EdgeInsets.only(
              right: 44,
              left: 16,
            ),
            title: Text(profile.label ?? profile.id),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveSheetScaffold(
      type: widget.type,
      actions: [
        IconButton(
          onPressed: () {
            Navigator.of(context).pop();
            globalState.appController.setProfiles(profiles);
          },
          icon: Icon(
            Icons.save,
	    color: Theme.of(context).colorScheme.primary, // 添加颜色属性
          ),
        )
      ],
      body: Padding(
     //   padding: EdgeInsets.only(bottom: 16),
	padding: const EdgeInsets.all(16).copyWith(
            top: 12,
	    left: 12,
	    right: 12,
          ),
        child: SingleChildScrollView(
          // 允许内容自适应高度
            child: ReorderableListView.builder(
              // 禁用列表自身滚动，使用外部SingleChildScrollView
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
          buildDefaultDragHandles: false,
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
          ),
          proxyDecorator: proxyDecorator,
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (oldIndex < newIndex) {
                newIndex -= 1;
              }
              final profile = profiles.removeAt(oldIndex);
              profiles.insert(newIndex, profile);
            });
          },
          itemBuilder: (_, index) {
            final profile = profiles[index];
            return Container(
              key: Key(profile.id),
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: CommonCard(
                type: CommonCardType.filled,
                child: ListTile(
                  contentPadding: const EdgeInsets.only(
                    right: 16,
                    left: 16,
                  ),
                  title: Text(profile.label ?? profile.id),
                  trailing: ReorderableDragStartListener(
                    index: index,
                    child: Icon(
                    Icons.drag_handle,
                    color: Theme.of(context).colorScheme.primary, // 使用主题主色
                    ),
                  ),
                ),
              ),
            );
          },
          itemCount: profiles.length,
        ),
      ),
      ),
      title: appLocalizations.profilesSort,
    );
  }
}
