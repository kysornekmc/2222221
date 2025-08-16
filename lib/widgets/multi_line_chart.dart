// 新建文件：lib/widgets/multi_line_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_clash/widgets/line_chart.dart';

class MultiLineChart extends StatelessWidget {
  final List<Point> uploadPoints;
  final List<Point> downloadPoints;
  final Color uploadColor;
  final Color downloadColor;
  final Duration duration;
  final bool gradient;

  const MultiLineChart({
    super.key,
    required this.uploadPoints,
    required this.downloadPoints,
    required this.uploadColor,
    required this.downloadColor,
    this.duration = Duration.zero,
    this.gradient = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 下载曲线（下层）
        LineChart(
          points: downloadPoints,
          color: downloadColor,
          duration: duration,
          gradient: gradient,
        ),
        // 上传曲线（上层）
        LineChart(
          points: uploadPoints,
          color: uploadColor,
          duration: duration,
          gradient: gradient,
        ),
      ],
    );
  }
}