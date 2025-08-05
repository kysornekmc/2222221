import 'dart:typed_data';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/common/dav_client.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/config.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/widgets/dialog.dart';
import 'package:fl_clash/widgets/fade_box.dart';
import 'package:fl_clash/widgets/input.dart';
import 'package:fl_clash/widgets/list.dart';
import 'package:fl_clash/widgets/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackupAndRecovery extends ConsumerStatefulWidget {
  const BackupAndRecovery({super.key});

  @override
  ConsumerState<BackupAndRecovery> createState() => _BackupAndRecoveryState();
}

class _BackupAndRecoveryState extends ConsumerState<BackupAndRecovery> {
  DateTime? _lastBackupTime;  // 默认格式时间格式为yyyy-MM-dd HH:mm:ss.SSS
  DateTime? _lastLocalBackupTime;  // 新增：记录本地上次备份时间

  @override
  void initState() {
    super.initState();
    _loadwebdavLastBackupTime(); // 加载上次备份时间
    _loadLocalLastBackupTime(); // 新增：加载本地上次备份时间
  }

  // 加载上次备份时间
  Future<void> _loadwebdavLastBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    final lastBackupTimeString = prefs.getString('lastBackupTime');
    if (lastBackupTimeString != null) {
      setState(() {
        _lastBackupTime = DateTime.parse(lastBackupTimeString);
      });
    }
  }

  // 新增：加载本地上次备份时间
  Future<void> _loadLocalLastBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    final lastLocalBackupTimeString = prefs.getString('lastLocalBackupTime');
    if (lastLocalBackupTimeString != null) {
      setState(() {
        _lastLocalBackupTime = DateTime.parse(lastLocalBackupTimeString);
      });
    }
  }

  // 保存上次备份时间
  Future<void> _saveLastBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    if (_lastBackupTime != null) {
      await prefs.setString('lastBackupTime', _lastBackupTime!.toIso8601String());
    }
  }

  // 新增：保存本地上次备份时间
  Future<void> _saveLocalLastBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    if (_lastLocalBackupTime != null) {
      await prefs.setString('lastLocalBackupTime', _lastLocalBackupTime!.toIso8601String());
    }
  }

  _showAddWebDAV(DAV? dav) async {
    await globalState.showCommonDialog<String>(
      child: WebDAVFormDialog(
        dav: dav?.copyWith(),
      ),
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
    // 更新上次备份时间
    setState(() {
      _lastBackupTime = DateTime.now();
    });
    await _saveLastBackupTime(); // 保存时间
    globalState.showNotifier(appLocalizations.backupSuccess);
 /*   globalState.showMessagese( 
      title: appLocalizations.backup,
      message: TextSpan(text: appLocalizations.backupSuccess),
    ); */
  }

  _recoveryOnWebDAV(
    BuildContext context,
    DAVClient client,
    RecoveryOption recoveryOption,
  ) async {
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
  /*  globalState.showMessagese(  
      title: appLocalizations.recovery,
      message: TextSpan(text: appLocalizations.recoverySuccess),
    ); */
  }

  _handleRecoveryOnWebDAV(BuildContext context, DAVClient client) async {
    final recoveryOption = await globalState.showCommonDialog<RecoveryOption>(
      child: const RecoveryOptionsDialog(),
    );
    if (recoveryOption == null || !context.mounted) return;
    _recoveryOnWebDAV(context, client, recoveryOption);
  }

  _backupOnLocal(BuildContext context) async {
    final commonScaffoldState = context.commonScaffoldState;
    final res = await commonScaffoldState?.loadingRun<bool>(
      () async {
        final backupData = await globalState.appController.backupData();
        final value = await picker.saveFile(
          utils.getBackupFileName(),
          Uint8List.fromList(backupData),
        );
        if (value == null) return false;
        return true;
      },
      title: appLocalizations.backup,
    );
    if (res != true) return;
    // 新增：更新本地上次备份时间
    setState(() {
      _lastLocalBackupTime = DateTime.now();
    });
    await _saveLocalLastBackupTime(); // 新增：保存本地上次备份时间
    globalState.showNotifier(appLocalizations.backupSuccess);
 /*   globalState.showMessagese(
      title: appLocalizations.backup,
      message: TextSpan(text: appLocalizations.backupSuccess),
    ); */
  }

  _recoveryOnLocal(
    BuildContext context,
    RecoveryOption recoveryOption,
  ) async {
    final file = await picker.pickerFile();
    final data = file?.bytes;
    if (data == null || !context.mounted) return;
    final commonScaffoldState = context.commonScaffoldState;
    final res = await commonScaffoldState?.loadingRun<bool>(
      () async {
        await globalState.appController.recoveryData(
          List<int>.from(data),
          recoveryOption,
        );
        return true;
      },
      title: appLocalizations.recovery,
    );
    if (res != true) return;
    globalState.showNotifier(appLocalizations.recoverySuccess);
 /*   globalState.showMessagese(  
      title: appLocalizations.recovery,
      message: TextSpan(text: appLocalizations.recoverySuccess),
    ); */
  }

  _handleRecoveryOnLocal(BuildContext context) async {
    final recoveryOption = await globalState.showCommonDialog<RecoveryOption>(
      child: const RecoveryOptionsDialog(),
    );
    if (recoveryOption == null || !context.mounted) return;
    _recoveryOnLocal(context, recoveryOption);
  }

  _handleChange(String? value, WidgetRef ref) {
    if (value == null) {
      return;
    }
    ref.read(appDAVSettingProvider.notifier).updateState(
          (state) => state?.copyWith(
            fileName: value,
          ),
        );
  }

  _handleUpdateRecoveryStrategy(WidgetRef ref) async {
    final recoveryStrategy = ref.read(appSettingProvider.select(
      (state) => state.recoveryStrategy,
    ));
    final res = await globalState.showCommonDialog(//恢复策略
      child: OptionsDialog<RecoveryStrategy>(
        title: appLocalizations.recoveryStrategy,
        options: RecoveryStrategy.values,
        textBuilder: (mode) => Intl.message(
          "recoveryStrategy_${mode.name}",
        ),
        value: recoveryStrategy,
      ),
    );
    if (res == null) {
      return;
    }
    ref.read(appSettingProvider.notifier).updateState(
          (state) => state.copyWith(
            recoveryStrategy: res,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final dav = ref.watch(appDAVSettingProvider);
    final client = dav != null ? DAVClient(dav) : null;
    return ListView(
      children: [
        ListHeader(title: appLocalizations.remote),
        if (dav == null)
          ListItem(
            leading: const Icon(Icons.account_box),
            title: Text(appLocalizations.noInfo),
            subtitle: Text(appLocalizations.pleaseBindWebDAV),
            trailing: FilledButton.tonal(
              onPressed: () {
                _showAddWebDAV(dav);
              },
              child: Text(
                appLocalizations.bind,
              ),
            ),
          )
        else ...[
          ListItem(
            leading: const Icon(Icons.account_box),
            title: TooltipText(
              text: Text(
                dav.user,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(appLocalizations.connectivity),
                  FutureBuilder<bool>(
                    future: client!.pingCompleter.future,
                    builder: (_, snapshot) {
                      return Center(
                        child: FadeThroughBox(
                          child:
                              snapshot.connectionState != ConnectionState.done
                                  ? const SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1,
                                      ),
                                    )
                                  : Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: snapshot.data == true
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                      width: 12,
                                      height: 12,
                                    ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            trailing: FilledButton.tonal(
              onPressed: () {
                _showAddWebDAV(dav);
              },
              child: Text(
                appLocalizations.edit,
              ),
            ),
          ),
          const SizedBox(
            height: 4,
          ),
          const Divider(height: 0,), 
          ListItem.input(
            leading: const Icon(Icons.drive_file_move), // 远程备份文件名
            title: Text(appLocalizations.davfileName),
            subtitle: Text(dav.fileName),
            delegate: InputDelegate(
              title: appLocalizations.davfileName,
              value: dav.fileName,
              resetValue: defaultDavFileName,
              onChanged: (value) {
                _handleChange(value, ref);
              },
            ),
          ),
          const Divider(height: 0,),  
          ListItem(
            onTap: () {
              _backupOnWebDAV(context, client); 
            },
            leading: const Icon(Icons.cloud_upload), // 远程备份图标
            title: Text(appLocalizations.backup),
            subtitle: Text(_lastBackupTime != null
              ? '${appLocalizations.lastbackuptime} ${DateFormat('yyyy-MM-dd HH:mm:ss').format(_lastBackupTime!)}'
              : appLocalizations.remoteBackupDesc), 
          ),
          const Divider(height: 0,),  	  
          ListItem(
            onTap: () {
              _handleRecoveryOnWebDAV(context, client);
            },
	   leading: const Icon(Icons.cloud_download),
            title: Text(appLocalizations.recovery),
            subtitle: Text(appLocalizations.remoteRecoveryDesc),
          ),
        ],
        ListHeader(title: appLocalizations.local),
        ListItem(
          onTap: () {
            _backupOnLocal(context);
          },
          leading: const Icon(Icons.save), // 本地备份图标
          title: Text(appLocalizations.backup),
          subtitle: Text(_lastLocalBackupTime != null
            ? '${appLocalizations.lastbackuptime} ${DateFormat('yyyy-MM-dd HH:mm:ss').format(_lastLocalBackupTime!)}'
            : appLocalizations.localBackupDesc), 
        ),
        const Divider(height: 0,),  	
        ListItem(
          onTap: () {
            _handleRecoveryOnLocal(context);
          },
	  leading: const Icon(Icons.settings_backup_restore),  //本地恢复图标
          title: Text(appLocalizations.recovery),
          subtitle: Text(appLocalizations.localRecoveryDesc),
        ),
        ListHeader(title: appLocalizations.options),
        Consumer(builder: (_, ref, __) {
          final recoveryStrategy = ref.watch(appSettingProvider.select(
            (state) => state.recoveryStrategy,
          ));
          return ListItem(
	    leading: Icon(Icons.info), // 添加图标
            onTap: () {
              _handleUpdateRecoveryStrategy(ref);
            },
            title: Text(appLocalizations.recoveryStrategy),
            trailing: FilledButton(
              onPressed: () {
                _handleUpdateRecoveryStrategy(ref);
              },
              child: Text(
                Intl.message("recoveryStrategy_${recoveryStrategy.name}"),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class RecoveryOptionsDialog extends StatefulWidget {
  const RecoveryOptionsDialog({super.key});

  @override
  State<RecoveryOptionsDialog> createState() => _RecoveryOptionsDialogState();
}

class _RecoveryOptionsDialogState extends State<RecoveryOptionsDialog> {
  _handleOnTab(RecoveryOption? value) {
    if (value == null) return;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return CommonDialog(
      title: appLocalizations.recovery,
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 16,
      ),
      child: Wrap(
        children: [
          ListItem(
            onTap: () {
              _handleOnTab(RecoveryOption.onlyProfiles);
            },
            title: Text(appLocalizations.recoveryProfiles),
          ),
          ListItem(
            onTap: () {
              _handleOnTab(RecoveryOption.all);
            },
            title: Text(appLocalizations.recoveryAll),
          )
        ],
      ),
    );
  }
}

class WebDAVFormDialog extends ConsumerStatefulWidget {
  final DAV? dav;

  const WebDAVFormDialog({super.key, this.dav});

  @override
  ConsumerState<WebDAVFormDialog> createState() => _WebDAVFormDialogState();
}

class _WebDAVFormDialogState extends ConsumerState<WebDAVFormDialog> {
  late TextEditingController uriController;
  late TextEditingController userController;
  late TextEditingController passwordController;
  final _obscureController = ValueNotifier<bool>(true);
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

@override
void initState() {
  super.initState();
  uriController = TextEditingController(
    text: widget.dav?.uri ?? 'https://dav.jianguoyun.com/dav/' // 添加默认值
  );
  userController = TextEditingController(text: widget.dav?.user);
  passwordController = TextEditingController(text: widget.dav?.password);
}

  _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(appDAVSettingProvider.notifier).value = DAV(
      uri: uriController.text,
      user: userController.text,
      password: passwordController.text,
    );
    Navigator.pop(context);
  }

  _delete() {
    ref.read(appDAVSettingProvider.notifier).value = null;
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _obscureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CommonDialog(
      title: appLocalizations.webDAVConfiguration,
      actions: [
        if (widget.dav != null)
          TextButton(
            onPressed: _delete,
            child: Text(appLocalizations.delete),
          ),
        TextButton(
          onPressed: _submit,
          child: Text(appLocalizations.save),
        )
      ],
      child: Form(
        key: _formKey,
        child: Wrap(
          runSpacing: 16,
          children: [
            TextFormField(
              controller: uriController,
              maxLines: 5,
              minLines: 1,
              decoration: InputDecoration(
            //    prefixIcon: const Icon(Icons.link),
                border: const OutlineInputBorder(),
                labelText: appLocalizations.address,
                helperText: appLocalizations.addressHelp,
              ),
              validator: (String? value) {
                if (value == null || value.isEmpty || !value.isUrl) {
                  return appLocalizations.addressTip;
                }
                return null;
              },
            ),
            TextFormField(
              controller: userController,
              decoration: InputDecoration(
           //     prefixIcon: const Icon(Icons.account_circle),
                border: const OutlineInputBorder(),
                labelText: appLocalizations.account,
              ),
              validator: (String? value) {
                if (value == null || value.isEmpty) {
                  return appLocalizations.emptyTip(appLocalizations.account);
                }
                return null;
              },
            ),
            ValueListenableBuilder(
              valueListenable: _obscureController,
              builder: (_, obscure, __) {
                return TextFormField(
                  controller: passwordController,
                  obscureText: obscure,
                  decoration: InputDecoration(
              //      prefixIcon: const Icon(Icons.password),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscure ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        _obscureController.value = !obscure;
                      },
                    ),
                    labelText: appLocalizations.password,
                  ),
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return appLocalizations
                          .emptyTip(appLocalizations.password);
                    }
                    return null;
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
