import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/app.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NetworkSpeedSmall extends StatefulWidget {  
  const NetworkSpeedSmall({super.key});  

  @override
  State<NetworkSpeedSmall> createState() => _NetworkSpeedStateSmall();  
}

class _NetworkSpeedStateSmall extends State<NetworkSpeedSmall> {  
  List<Point> initPoints = const [Point(0, 0), Point(1, 0)];

  List<Point> _getPoints(List<Traffic> traffics) {
    List<Point> trafficPoints = traffics
        .toList()
        .asMap()
        .map(
          (index, e) => MapEntry(
            index,
            Point(
              (index + initPoints.length).toDouble(),
              e.speed.toDouble(),
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

  @override
  Widget build(BuildContext context) {
    final color = context.colorScheme.onSurfaceVariant.opacity80;
    return SizedBox(
      height: getWidgetHeight(1),
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
                    child: LineChart(
                      gradient: true,
                      color: Theme.of(context).colorScheme.primary,
                      points: _getPoints(traffics),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Transform.translate(
                    offset: Offset(
                      -16,             //默认值-16
                      -16.5,           //默认值-20
                    ),
                    child: Text(
		      "${_getLastTraffic(traffics).down.shortShowse}/s",
                      style: context.textTheme.bodySmall?.copyWith(
                        color: color,
                      ),
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
