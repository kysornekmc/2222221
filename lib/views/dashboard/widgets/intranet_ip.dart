import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/providers/app.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 定义一个 StateNotifier 来管理 IP 隐藏状态
final ipHiddenProvider = StateNotifierProvider<IPHiddenNotifier, bool>((ref) {
  return IPHiddenNotifier();
});

class IPHiddenNotifier extends StateNotifier<bool> {
  IPHiddenNotifier() : super(false) {
    _loadIpHiddenState();
  }

  // 加载 IP 隐藏状态
  Future<void> _loadIpHiddenState() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('isIpHidden') ?? false;
  }

  // 保存 IP 隐藏状态
  Future<void> saveIpHiddenState(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isIpHidden', value);
    state = value;
  }
}

class IntranetIP extends StatelessWidget {
  const IntranetIP({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: getWidgetHeight(1),
      child: CommonCard(
        info: Info(
          label: appLocalizations.intranetIP,
          iconData: Icons.devices,
        ),
        onPressed: () {},
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
                child: Consumer(
                  builder: (_, ref, __) {
                    final localIp = ref.watch(localIpProvider);
                    final isIpHidden = ref.watch(ipHiddenProvider);
                    final ipHiddenNotifier = ref.read(ipHiddenProvider.notifier);

                    return FadeThroughBox(
                      child: GestureDetector(
                        onTap: () async {
                          await ipHiddenNotifier.saveIpHiddenState(!isIpHidden);
                        },
                        child: localIp != null
                            ? TooltipText(
                                text: Text(
                                  isIpHidden
                                      ? '**** **** ****'
                                      : (localIp.isNotEmpty
                                          ? localIp
                                          : appLocalizations.noNetwork),
                                  style: context.textTheme.bodyMedium?.toLight
                                      .adjustSize(1),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )
                            : Container(
                                padding: EdgeInsets.all(2),
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                      ),
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
