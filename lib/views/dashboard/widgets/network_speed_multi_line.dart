import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/app.dart';
import 'package:fl_clash/state.dart'; // 导入全局状态
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// 导入新创建的多曲线组件
import 'package:fl_clash/widgets/multi_line_chart.dart';

class NetworkSpeedMultiLine extends StatefulWidget {
  const NetworkSpeedMultiLine({super.key});

  @override
  State<NetworkSpeedMultiLine> createState() => _NetworkSpeedStateMultiLine();
}

class _NetworkSpeedStateMultiLine extends State<NetworkSpeedMultiLine> {
  List<Point> initPoints = const [Point(0, 0), Point(1, 0)];

  // 修正：使用 up.value 获取上传速度数值
  List<Point> _getUploadPoints(List<Traffic> traffics) {
    List<Point> trafficPoints = traffics
        .toList()
        .asMap()
        .map(
          (index, e) => MapEntry(
            index,
            Point(
              (index + initPoints.length).toDouble(),
              e.up.value.toDouble(), // 关键修正：up是TrafficValue类型，通过value获取数值
            ),
          ),
        )
        .values
        .toList();
    return [...initPoints, ...trafficPoints];
  }

  // 修正：使用 down.value 获取下载速度数值
  List<Point> _getDownloadPoints(List<Traffic> traffics) {
    List<Point> trafficPoints = traffics
        .toList()
        .asMap()
        .map(
          (index, e) => MapEntry(
            index,
            Point(
              (index + initPoints.length).toDouble(),
              e.down.value.toDouble(), // 关键修正：down是TrafficValue类型，通过value获取数值
            ),
          ),
        )
        .values
        .toList();
    return [...initPoints, ...trafficPoints];
  }

  Traffic _getLastTraffic(List<Traffic> traffics) {
    if (traffics.isEmpty) return Traffic();
    return traffics.last;
  }

  // 新增：创建曲线标识组件
Widget _buildLegend(Color uploadColor, Color downloadColor) {
  return Positioned(
    top: 8, // 向上移动（原16，减少为8）
    right: 16, // 靠右对齐（原left:16改为right:16）
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.end, // 文本右对齐
      children: [
        // 下载标识（移到上面）
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              appLocalizations.download,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 20,
              height: 8,
              decoration: BoxDecoration(
                color: downloadColor, // 下载仍用primary颜色
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // 上传标识（移到下面）
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              appLocalizations.upload,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 20,
              height: 8,
              decoration: BoxDecoration(
                color: uploadColor, // 上传仍用secondary颜色
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}


@override
Widget build(BuildContext context) {
    // 颜色映射调整：上传用secondary，下载用primary
  final primaryColor = Theme.of(context).colorScheme.primary; // 主色（上传曲线）
  final secondaryColor = Theme.of(context).colorScheme.secondary; // 辅助色（下载曲线）
  final color = Theme.of(context).colorScheme.onSurfaceVariant.opacity80;

  return SizedBox(
    height: getWidgetHeight(2),
    child: CommonCard(
      onPressed: () {},
      info: Info(
        label: appLocalizations.networkSpeed,
        iconData: Icons.speed_sharp,
      ),
      child: Consumer(
        builder: (_, ref, __) {
          final traffics = ref.watch(trafficsProvider).list;
          return Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.all(16).copyWith(
                    bottom: 0,
                    left: 0,
                    right: 0,
                  ),
                  child: MultiLineChart(
                    gradient: true,
                      uploadColor: secondaryColor, // 上传曲线用secondary
                      downloadColor: primaryColor, // 下载曲线用primary
                    uploadPoints: _getUploadPoints(traffics),
                    downloadPoints: _getDownloadPoints(traffics),
                    duration: const Duration(milliseconds: 300),
                  ),
                ),
              ),
                _buildLegend(secondaryColor, primaryColor), // 图例颜色同步调整
                Positioned(
                  top: 0,
                  right: 0,
                  child: Transform.translate(
                    offset: const Offset(-16, -16.5), // 向左偏移16像素，向上偏移18像素
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 上传速度 + 向上箭头
                        Text(
                          "${_getLastTraffic(traffics).up.shortShowse}",
                          style: context.textTheme.bodySmall?.copyWith(
                            color: color,
                          ),
                        ),
                        Icon(
                          Icons.arrow_upward,
                          size: 14, // 图标大小与文本匹配
                          color: color,
                        ),
                        const SizedBox(width: 8), // 两个部分之间的间距
                        // 下载速度 + 向下箭头
                        Text(
                          "${_getLastTraffic(traffics).down.shortShowse}",
                          style: context.textTheme.bodySmall?.copyWith(
                            color: color,
                          ),
                        ),
                        Icon(
                          Icons.arrow_downward,
                          size: 14, // 图标大小与文本匹配
                          color: color,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
