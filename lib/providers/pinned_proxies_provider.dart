import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final pinnedProxiesProvider = StateNotifierProvider<PinnedProxiesNotifier, Set<String>>((ref) {
  return PinnedProxiesNotifier();
});

class PinnedProxiesNotifier extends StateNotifier<Set<String>> {
  PinnedProxiesNotifier() : super(<String>{}) {
    _loadPinnedProxies();
  }

  // 从本地加载置顶数据（使用Set避免重复）
  Future<void> _loadPinnedProxies() async {
    final prefs = await SharedPreferences.getInstance();
    final pinnedProxies = prefs.getStringList('pinnedProxies') ?? [];
    state = Set.from(pinnedProxies); // 转为Set处理
  }

  // 保存置顶数据到本地
  Future<void> savePinnedProxies() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('pinnedProxies', state.toList());
  }

  // 添加置顶（使用组名+节点名作为唯一标识）
  void addPinnedProxy(String groupName, String proxyName) {
    final key = '$groupName|$proxyName';
    if (!state.contains(key)) {
      state = {...state, key};
      savePinnedProxies();
    }
  }

  // 移除置顶
  void removePinnedProxy(String groupName, String proxyName) {
    final key = '$groupName|$proxyName';
    if (state.contains(key)) {
      state = state.where((k) => k != key).toSet();
      savePinnedProxies();
    }
  }

  // 检查是否置顶
  bool isPinned(String groupName, String proxyName) {
    return state.contains('$groupName|$proxyName');
  }
}