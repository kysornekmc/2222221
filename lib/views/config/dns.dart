import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/providers/config.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/models/clash_config.dart';

class OverrideItem extends ConsumerWidget {
  const OverrideItem({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final override = ref.watch(overrideDnsProvider);
    return ListItem.switchItem(
           leading: Icon(
        Icons.dns_outlined,
        color: Theme.of(context).colorScheme.primary, // 添加颜色属性
      ),     //覆写DNS
      title: Text(appLocalizations.overrideDns),
      subtitle: Text(appLocalizations.overrideDnsDesc),
      delegate: SwitchDelegate(
        value: override,
        onChanged: (bool value) async {
          ref.read(overrideDnsProvider.notifier).value = value;
        },
      ),
    );
  }
}

class StatusItem extends ConsumerWidget {
  const StatusItem({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final enable =
        ref.watch(patchClashConfigProvider.select((state) => state.dns.enable));
    return ListItem.switchItem(
           leading: Icon(
        Icons.tune,
        color: Theme.of(context).colorScheme.primary, // 添加颜色属性
      ),//状态
      title: Text(appLocalizations.status),
      subtitle: Text(appLocalizations.statusDesc),
      delegate: SwitchDelegate(
        value: enable,
        onChanged: (bool value) async {
          ref
              .read(patchClashConfigProvider.notifier)
              .updateState((state) => state.copyWith.dns(enable: value));
        },
      ),
    );
  }
}

class ListenItem extends ConsumerWidget {
  const ListenItem({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final listen =
        ref.watch(patchClashConfigProvider.select((state) => state.dns.listen));
    return ListItem.input(
         leading: Icon(
        Icons.hearing,
        color: Theme.of(context).colorScheme.primary, // 添加颜色属性
      ),//监听
      title: Text(appLocalizations.listen),
      subtitle: Text(listen),
      delegate: InputDelegate(
        title: appLocalizations.listen,
        value: listen,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return appLocalizations.emptyTip(appLocalizations.listen);
          }
          return null;
        },
        onChanged: (String? value) {
          if (value == null) {
            return;
          }
          ref
              .read(patchClashConfigProvider.notifier)
              .updateState((state) => state.copyWith.dns(listen: value));
        },
      ),
    );
  }
}

class PreferH3Item extends ConsumerWidget {
  const PreferH3Item({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final preferH3 = ref
        .watch(patchClashConfigProvider.select((state) => state.dns.preferH3));
    return ListItem.switchItem(
          leading: Icon(
        Icons.filter_3,
        color: Theme.of(context).colorScheme.primary, // 添加颜色属性
      ),//PreferH3优先级
      title: const Text("PreferH3"),
      subtitle: Text(appLocalizations.preferH3Desc),
      delegate: SwitchDelegate(
        value: preferH3,
        onChanged: (bool value) async {
          ref
              .read(patchClashConfigProvider.notifier)
              .updateState((state) => state.copyWith.dns(preferH3: value));
        },
      ),
    );
  }
}

class IPv6Item extends ConsumerWidget {
  const IPv6Item({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final ipv6 = ref.watch(
      patchClashConfigProvider.select((state) => state.dns.ipv6),
    );
    return ListItem.switchItem(
            leading: Icon(
        Icons.looks_6_outlined,
        color: Theme.of(context).colorScheme.primary, // 添加颜色属性
      ),  //IPV6
      title: const Text("IPv6"),
      delegate: SwitchDelegate(
        value: ipv6,
        onChanged: (bool value) async {
          ref
              .read(patchClashConfigProvider.notifier)
              .updateState((state) => state.copyWith.dns(ipv6: value));
        },
      ),
    );
  }
}

class RespectRulesItem extends ConsumerWidget {
  const RespectRulesItem({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final respectRules = ref.watch(
      patchClashConfigProvider.select((state) => state.dns.respectRules),
    );
    return ListItem.switchItem(
               leading: Icon(
        Icons.rule,
        color: Theme.of(context).colorScheme.primary, // 添加颜色属性
      ), //遵守规则
      title: Text(appLocalizations.respectRules),
      subtitle: Text(appLocalizations.respectRulesDesc),
      delegate: SwitchDelegate(
        value: respectRules,
        onChanged: (bool value) async {
          ref
              .read(patchClashConfigProvider.notifier)
              .updateState((state) => state.copyWith.dns(respectRules: value));
        },
      ),
    );
  }
}

class DnsModeItem extends ConsumerWidget {
  const DnsModeItem({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final enhancedMode = ref.watch(
      patchClashConfigProvider.select((state) => state.dns.enhancedMode),
    );
    return ListItem<DnsMode>.options(
            leading: Icon(
        Icons.menu_open,
        color: Theme.of(context).colorScheme.primary, // 添加颜色属性
      ),
          title: Text(appLocalizations.dnsMode),  //DNS模式
      subtitle: Text(enhancedMode.name),
      delegate: OptionsDelegate(
        title: appLocalizations.dnsMode,
        options: DnsMode.values,
        onChanged: (value) {
          if (value == null) {
            return;
          }
          ref
              .read(patchClashConfigProvider.notifier)
              .updateState((state) => state.copyWith.dns(enhancedMode: value));
        },
        textBuilder: (dnsMode) => dnsMode.name,
        value: enhancedMode,
      ),
    );
  }
}

class FakeIpRangeItem extends ConsumerWidget {
  const FakeIpRangeItem({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final fakeIpRange = ref.watch(
      patchClashConfigProvider.select((state) => state.dns.fakeIpRange),
    );
    return ListItem.input(
               leading: Icon(
        Icons.expand_outlined,
        color: Theme.of(context).colorScheme.primary, // 添加颜色属性
      ),  //fake IP范围
      title: Text(appLocalizations.fakeipRange),
      subtitle: Text(fakeIpRange),
      delegate: InputDelegate(
        title: appLocalizations.fakeipRange,
        value: fakeIpRange,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return appLocalizations.emptyTip(appLocalizations.fakeipRange);
          }
          return null;
        },
        onChanged: (String? value) {
          if (value == null) {
            return;
          }
          ref
              .read(patchClashConfigProvider.notifier)
              .updateState((state) => state.copyWith.dns(fakeIpRange: value));
        },
      ),
    );
  }
}

class FakeIpFilterItem extends StatelessWidget {
  const FakeIpFilterItem({super.key});

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
         leading: Icon(
        Icons.filter_alt_outlined,
        color: Theme.of(context).colorScheme.primary, // 添加颜色属性
      ), //fakeIP过滤
      title: Text(appLocalizations.fakeipFilter),
      delegate: OpenDelegate(
        blur: false,
        title: appLocalizations.fakeipFilter,
        widget: Consumer(
          builder: (_, ref, __) {
            final fakeIpFilter = ref.watch(
              patchClashConfigProvider
                  .select((state) => state.dns.fakeIpFilter),
            );
            return ListInputPage(
              title: appLocalizations.fakeipFilter,
              items: fakeIpFilter,
              titleBuilder: (item) => Text(item),
              onChange: (items) {
                ref
                    .read(patchClashConfigProvider.notifier)
                    .updateState((state) => state.copyWith.dns(
                          fakeIpFilter: List.from(items),
                        ));
              },
            );
          },
        ),
      ),
    );
  }
}

class DefaultNameserverItem extends StatelessWidget {
  const DefaultNameserverItem({super.key});

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
           leading: Icon(
        Icons.laptop_chromebook_outlined,
        color: Theme.of(context).colorScheme.primary, // 添加颜色属性
      ),
      title: Text(appLocalizations.defaultNameserver),  //默认域名服务器
      subtitle: Text(appLocalizations.defaultNameserverDesc),
      delegate: OpenDelegate(
        blur: false,
        title: appLocalizations.defaultNameserver,
        widget: Consumer(builder: (_, ref, __) {
          final defaultNameserver = ref.watch(
            patchClashConfigProvider
                .select((state) => state.dns.defaultNameserver),
          );
          return ListInputPage(
            title: appLocalizations.defaultNameserver,
            items: defaultNameserver,
            titleBuilder: (item) => Text(item),
            onChange: (items) {
              ref.read(patchClashConfigProvider.notifier).updateState(
                    (state) => state.copyWith.dns(
                      defaultNameserver: List.from(items),
                    ),
                  );
            },
          );
        }),
      ),
    );
  }
}

class NameserverItem extends StatelessWidget {
  const NameserverItem({super.key});

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
           leading: Icon(
        Icons.edit_note,
        color: Theme.of(context).colorScheme.primary, // 添加颜色属性
      ),// 域名服务器
      title: Text(appLocalizations.nameserver),
      subtitle: Text(appLocalizations.nameserverDesc),
      delegate: OpenDelegate(
        title: appLocalizations.nameserver,
        blur: false,
        widget: Consumer(builder: (_, ref, __) {
          final nameserver = ref.watch(
            patchClashConfigProvider.select((state) => state.dns.nameserver),
          );
          return ListInputPage(
            title: appLocalizations.nameserver,
            items: nameserver,
            titleBuilder: (item) => Text(item),
            onChange: (items) {
              ref.read(patchClashConfigProvider.notifier).updateState(
                    (state) => state.copyWith.dns(
                      nameserver: List.from(items),
                    ),
                  );
            },
          );
        }),
      ),
    );
  }
}

class UseHostsItem extends ConsumerWidget {
  const UseHostsItem({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final useHosts = ref.watch(
      patchClashConfigProvider.select((state) => state.dns.useHosts),
    );
    return ListItem.switchItem(
             leading: Icon(
        Icons.format_list_bulleted,
        color: Theme.of(context).colorScheme.primary, // 添加颜色属性
      ),
          title: Text(appLocalizations.useHosts),  //使用Hosts
      delegate: SwitchDelegate(
        value: useHosts,
        onChanged: (bool value) async {
          ref
              .read(patchClashConfigProvider.notifier)
              .updateState((state) => state.copyWith.dns(useHosts: value));
        },
      ),
    );
  }
}

class UseSystemHostsItem extends ConsumerWidget {
  const UseSystemHostsItem({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final useSystemHosts = ref.watch(
      patchClashConfigProvider.select((state) => state.dns.useSystemHosts),
    );
    return ListItem.switchItem(
               leading: Icon(
        Icons.format_list_bulleted,
        color: Theme.of(context).colorScheme.primary, // 添加颜色属性
      ), //使用系统host
      title: Text(appLocalizations.useSystemHosts),
      delegate: SwitchDelegate(
        value: useSystemHosts,
        onChanged: (bool value) async {
          ref
              .read(patchClashConfigProvider.notifier)
              .updateState((state) => state.copyWith.dns(
                    useSystemHosts: value,
                  ));
        },
      ),
    );
  }
}

class NameserverPolicyItem extends StatelessWidget {
  const NameserverPolicyItem({super.key});

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
           leading: Icon(
        Icons.edit_note,
        color: Theme.of(context).colorScheme.primary, // 添加颜色属性
      ),
      title: Text(appLocalizations.nameserverPolicy),
      subtitle: Text(appLocalizations.nameserverPolicyDesc),  //指定对应域名服务器策略
      delegate: OpenDelegate(
        blur: false,
        title: appLocalizations.nameserverPolicy,
        widget: Consumer(builder: (_, ref, __) {
          final nameserverPolicy = ref.watch(
            patchClashConfigProvider
                .select((state) => state.dns.nameserverPolicy),
          );
          return MapInputPage(
            title: appLocalizations.nameserverPolicy,
            map: nameserverPolicy,
            titleBuilder: (item) => Text(item.key),
            subtitleBuilder: (item) => Text(item.value),
            onChange: (value) {
              ref.read(patchClashConfigProvider.notifier).updateState(
                    (state) => state.copyWith.dns(
                      nameserverPolicy: value,
                    ),
                  );
            },
          );
        }),
      ),
    );
  }
}

class ProxyServerNameserverItem extends StatelessWidget {
  const ProxyServerNameserverItem({super.key});

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
           leading: Icon(
        Icons.edit_note,
        color: Theme.of(context).colorScheme.primary, // 添加颜色属性
      ),
      title: Text(appLocalizations.proxyNameserver),  //代理域名服务器
      subtitle: Text(appLocalizations.proxyNameserverDesc),
      delegate: OpenDelegate(
        blur: false,
        title: appLocalizations.proxyNameserver,
        widget: Consumer(
          builder: (_, ref, __) {
            final proxyServerNameserver = ref.watch(
              patchClashConfigProvider
                  .select((state) => state.dns.proxyServerNameserver),
            );
            return ListInputPage(
              title: appLocalizations.proxyNameserver,
              items: proxyServerNameserver,
              titleBuilder: (item) => Text(item),
              onChange: (items) {
                ref.read(patchClashConfigProvider.notifier).updateState(
                      (state) => state.copyWith.dns(
                        proxyServerNameserver: List.from(items),
                      ),
                    );
              },
            );
          },
        ),
      ),
    );
  }
}

class FallbackItem extends StatelessWidget {
  const FallbackItem({super.key});

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
            leading: Icon(
        Icons.u_turn_right,
        color: Theme.of(context).colorScheme.primary, // 添加颜色属性
      ),  //fallback 
      title: Text(appLocalizations.fallback),
      subtitle: Text(appLocalizations.fallbackDesc),
      delegate: OpenDelegate(
        blur: false,
        title: appLocalizations.fallback,
        widget: Consumer(builder: (_, ref, __) {
          final fallback = ref.watch(
            patchClashConfigProvider.select((state) => state.dns.fallback),
          );
          return ListInputPage(
            title: appLocalizations.fallback,
            items: fallback,
            titleBuilder: (item) => Text(item),
            onChange: (items) {
              ref.read(patchClashConfigProvider.notifier).updateState(
                    (state) => state.copyWith.dns(
                      fallback: List.from(items),
                    ),
                  );
            },
          );
        }),
      ),
    );
  }
}

class GeoipItem extends ConsumerWidget {
  const GeoipItem({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final geoip = ref.watch(
      patchClashConfigProvider
          .select((state) => state.dns.fallbackFilter.geoip),
    );
    return ListItem.switchItem(
            leading: Icon(
        Icons.query_stats,
        color: Theme.of(context).colorScheme.primary, // 添加颜色属性
      ),
      title: const Text("Geoip"),
      delegate: SwitchDelegate(
        value: geoip,
        onChanged: (bool value) async {
          ref
              .read(patchClashConfigProvider.notifier)
              .updateState((state) => state.copyWith.dns.fallbackFilter(
                    geoip: value,
                  ));
        },
      ),
    );
  }
}

class GeoipCodeItem extends ConsumerWidget {
  const GeoipCodeItem({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final geoipCode = ref.watch(
      patchClashConfigProvider
          .select((state) => state.dns.fallbackFilter.geoipCode),
    );
    return ListItem.input(
             leading: Icon(
        Icons.code,
        color: Theme.of(context).colorScheme.primary, // 添加颜色属性
      ), //Geoip code
      title: Text(appLocalizations.geoipCode),
      subtitle: Text(geoipCode),
      delegate: InputDelegate(
        title: appLocalizations.geoipCode,
        value: geoipCode,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return appLocalizations.emptyTip(appLocalizations.geoipCode);
          }
          return null;
        },
        onChanged: (String? value) {
          if (value == null) {
            return;
          }
          ref.read(patchClashConfigProvider.notifier).updateState(
                (state) => state.copyWith.dns.fallbackFilter(
                  geoipCode: value,
                ),
              );
        },
      ),
    );
  }
}

class GeositeItem extends StatelessWidget {
  const GeositeItem({super.key});

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
           leading: Icon(
        Icons.edit_note,
        color: Theme.of(context).colorScheme.primary, // 添加颜色属性
      ),  //Geosite
      title: const Text("Geosite"),
      delegate: OpenDelegate(
        blur: false,
        title: "Geosite",
        widget: Consumer(builder: (_, ref, __) {
          final geosite = ref.watch(
            patchClashConfigProvider
                .select((state) => state.dns.fallbackFilter.geosite),
          );
          return ListInputPage(
            title: "Geosite",
            items: geosite,
            titleBuilder: (item) => Text(item),
            onChange: (items) {
              ref.read(patchClashConfigProvider.notifier).updateState(
                    (state) => state.copyWith.dns.fallbackFilter(
                      geosite: List.from(items),
                    ),
                  );
            },
          );
        }),
      ),
    );
  }
}

class IpcidrItem extends StatelessWidget {
  const IpcidrItem({super.key});

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
          leading: Icon(
        Icons.edit_note,
        color: Theme.of(context).colorScheme.primary, // 添加颜色属性
      ),
      title: Text(appLocalizations.ipcidr),    //IP/掩码
      delegate: OpenDelegate(
        blur: false,
        title: appLocalizations.ipcidr,
        widget: Consumer(builder: (_, ref, ___) {
          final ipcidr = ref.watch(
            patchClashConfigProvider
                .select((state) => state.dns.fallbackFilter.ipcidr),
          );
          return ListInputPage(
            title: appLocalizations.ipcidr,
            items: ipcidr,
            titleBuilder: (item) => Text(item),
            onChange: (items) {
              ref
                  .read(patchClashConfigProvider.notifier)
                  .updateState((state) => state.copyWith.dns.fallbackFilter(
                        ipcidr: List.from(items),
                      ));
            },
          );
        }),
      ),
    );
  }
}

class DomainItem extends StatelessWidget {
  const DomainItem({super.key});

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
          leading: Icon(
        Icons.domain_verification,
        color: Theme.of(context).colorScheme.primary, // 添加颜色属性
      ),  //域名
      title: Text(appLocalizations.domain),
      delegate: OpenDelegate(
        blur: false,
        title: appLocalizations.domain,
        widget: Consumer(builder: (_, ref, __) {
          final domain = ref.watch(
            patchClashConfigProvider
                .select((state) => state.dns.fallbackFilter.domain),
          );
          return ListInputPage(
            title: appLocalizations.domain,
            items: domain,
            titleBuilder: (item) => Text(item),
            onChange: (items) {
              ref.read(patchClashConfigProvider.notifier).updateState(
                    (state) => state.copyWith.dns.fallbackFilter(
                      domain: List.from(items),
                    ),
                  );
            },
          );
        }),
      ),
    );
  }
}

class DnsOptions extends StatelessWidget {
  const DnsOptions({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: generateSection(
        title: appLocalizations.options,
        items: [
          const StatusItem(),
          const ListenItem(),
          const UseHostsItem(),
          const UseSystemHostsItem(),
          const IPv6Item(),
          const RespectRulesItem(),
          const PreferH3Item(),
          const DnsModeItem(),
          const FakeIpRangeItem(),
          const FakeIpFilterItem(),
          const DefaultNameserverItem(),
          const NameserverPolicyItem(),
          const NameserverItem(),
          const FallbackItem(),
          const ProxyServerNameserverItem(),
        ],
      ),
    );
  }
}

class FallbackFilterOptions extends StatelessWidget {
  const FallbackFilterOptions({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: generateSection(
        title: appLocalizations.fallbackFilter,
        items: [
          const GeoipItem(),
          const GeoipCodeItem(),
          const GeositeItem(),
          const IpcidrItem(),
          const DomainItem(),
        ],
      ),
    );
  }
}

const dnsItems = <Widget>[
  OverrideItem(),
  DnsOptions(),
  FallbackFilterOptions(),
];

class DnsListView extends ConsumerWidget {
  const DnsListView({super.key});

  _initActions(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      context.commonScaffoldState?.actions = [
        IconButton(
          onPressed: () async {
            final res = await globalState.showMessage(
              title: appLocalizations.reset,
              message: TextSpan(
                text: appLocalizations.resetTip,
              ),
            );
            if (res != true) {
              return;
            }
            ref.read(patchClashConfigProvider.notifier).updateState(
                  (state) => state.copyWith(
                    dns: defaultDns,
                  ),
                );
          },
          tooltip: appLocalizations.reset,
           icon: Icon(  // 移除 const 关键字
           Icons.replay,
           color: Theme.of(context).colorScheme.primary,  // 添加颜色属性
          ),
        )
      ];
    });
  }

  @override
  Widget build(BuildContext context, ref) {
    _initActions(context, ref);
    return generateListView(
      dnsItems,
    );
  }
}
