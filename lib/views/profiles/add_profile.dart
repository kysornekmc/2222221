import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/pages/scan.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 导入Clipboard所在的包

class AddProfileView extends StatelessWidget {
  final BuildContext context;

  const AddProfileView({
    super.key,
    required this.context,
  });

  _handleAddProfileFormFile() async {
    globalState.appController.addProfileFormFile();
  }

  _handleAddProfileFormURL(String url) async {
    globalState.appController.addProfileFormURL(url);
  }

  _toScan() async {
    if (system.isDesktop) {
      globalState.appController.addProfileFormQrCode();
      return;
    }
    final url = await BaseNavigator.push(
      context,
      const ScanPage(),
    );
    if (url != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleAddProfileFormURL(url);
      });
    }
  }

  _toAdd() async {
    final url = await globalState.showCommonDialog<String>(
      child: InputDialog(
        autovalidateMode: AutovalidateMode.onUnfocus,
        title: appLocalizations.importFromURL,
        labelText: appLocalizations.url,
        value: '',
        validator: (value) {
          if (value == null || value.isEmpty) {
            return appLocalizations.emptyTip("").trim();
          }
          if (!value.isUrl) {
            return appLocalizations.urlTip("").trim();
          }
          return null;
        },
      ),
    );
    if (url != null) {
      _handleAddProfileFormURL(url);
    }
  }
  // 新增方法：从剪贴板导入订阅链接
  _handleAddProfileFromClipboard() async {
    final clipboardData = await Clipboard.getData('text/plain');
    if (clipboardData != null && clipboardData.text != null) {
      final url = clipboardData.text!;
      if (url.isNotEmpty) {
        _handleAddProfileFormURL(url);
      }
    }
  }

  @override
  Widget build(context) {
    return ListView(
      children: [
        ListItem(
          leading: Icon(
            Icons.qr_code_sharp,
            color: Theme.of(context).colorScheme.primary, // 使用主题主色调
          ),
          title: Text(appLocalizations.qrcode),
          subtitle: Text(appLocalizations.qrcodeDesc),
          onTap: _toScan,
        ),
        ListItem(
          leading: Icon(
            Icons.upload_file_sharp,
            color: Theme.of(context).colorScheme.primary, // 使用主题主色调
          ),
          title: Text(appLocalizations.file),
          subtitle: Text(appLocalizations.fileDesc),
          onTap: _handleAddProfileFormFile,
        ),
        ListItem(
          leading: Icon(
            Icons.cloud_download_sharp,
            color: Theme.of(context).colorScheme.primary, // 使用主题主色调
          ),
          title: Text(appLocalizations.url),
          subtitle: Text(appLocalizations.urlDesc),
          onTap: _toAdd,
        ),
        // 新增菜单项：从剪贴板导入
        ListItem(
          leading: Icon(
            Icons.content_paste_sharp,
            color: Theme.of(context).colorScheme.primary, // 使用主题主色调
          ),
          title: Text(appLocalizations.clipboardcode),      //剪贴板导入
          subtitle: Text(appLocalizations.clipboardDesc),   //从剪贴板导入订阅链接
          onTap: _handleAddProfileFromClipboard,
        )
      ],
    );
  }
}

class URLFormDialog extends StatefulWidget {
  const URLFormDialog({super.key});

  @override
  State<URLFormDialog> createState() => _URLFormDialogState();
}

class _URLFormDialogState extends State<URLFormDialog> {
  final urlController = TextEditingController();

  _handleAddProfileFormURL() async {
    final url = urlController.value.text;
    if (url.isEmpty) return;
    Navigator.of(context).pop<String>(url);
  }

  @override
  Widget build(BuildContext context) {
    return CommonDialog(
      title: appLocalizations.importFromURL,
      actions: [
        TextButton(
          onPressed: _handleAddProfileFormURL,
          child: Text(appLocalizations.submit),
        )
      ],
      child: SizedBox(
        width: 300,
        child: Wrap(
          runSpacing: 16,
          children: [
            TextField(
              keyboardType: TextInputType.url,
              minLines: 1,
              maxLines: 5,
              onSubmitted: (_) {
                _handleAddProfileFormURL();
              },
              onEditingComplete: _handleAddProfileFormURL,
              controller: urlController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: appLocalizations.url,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
