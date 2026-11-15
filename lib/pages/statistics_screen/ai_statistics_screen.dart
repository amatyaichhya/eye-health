import 'package:eye_health/global_widget/eye_health_appbar.dart';
import 'package:eye_health/pages/image_processing_screen/static_image_processing_screen.dart';
import 'package:eye_health/utils/utility_methods/color_print.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AiStatisticsScreen extends StatefulWidget {
  final String question;
  const AiStatisticsScreen({super.key,required this.question,});

  @override
  State<AiStatisticsScreen> createState() => _AiStatisticsScreenState();
}

class _AiStatisticsScreenState extends State<AiStatisticsScreen> {
  static const String _appTitle = 'EYEHEALTH';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: EyeHealthAppbar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              const Text(
                'Personal Health Statistics',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
               Text(
                widget.question,
                style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.4),
              ),
              const Text(
                'Eye Disease Progression',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 0,
                    vertical: 32,
                  ),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),

                  decoration: BoxDecoration(color: Colors.transparent),
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          axisNameWidget: Text(
                            'Months Since First Screening',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: 2,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 12,
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          axisNameWidget: Text(
                            'Estimated Risk of Disease Progression (%)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),

                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 20,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 12,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: const Border(
                          bottom: BorderSide(color: Colors.grey, width: 1),
                          left: BorderSide(color: Colors.grey, width: 1),
                        ),
                      ),
                      minX: 1,
                      maxX: 12,
                      minY: 0,
                      maxY: 100,
                      lineBarsData: [
                        // Left Eye Line
                        LineChartBarData(
                          spots: const [
                            FlSpot(1, 10),
                            FlSpot(3, 15),
                            FlSpot(5, 22),
                            FlSpot(7, 35),
                            FlSpot(9, 50),
                            FlSpot(11, 65),
                            FlSpot(12, 70),
                          ],
                          isCurved: true,
                          color: const Color(0xFF4A9EC1),
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(show: false),
                        ),
                        // Right Eye Line
                        LineChartBarData(
                          spots: const [
                            FlSpot(1, 8),
                            FlSpot(3, 12),
                            FlSpot(5, 18),
                            FlSpot(7, 25),
                            FlSpot(9, 35),
                            FlSpot(12, 65),
                          ],
                          isCurved: true,
                          color: const Color(0xFF7B68C7),
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(show: false),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 20,
                        height: 3,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A9EC1),
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Left Eye',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 40),
                  Row(
                    children: [
                      Container(
                        width: 20,
                        height: 3,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7B68C7),
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Right Eye',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      // floatingActionButton: InkWell(
      //   onTap: (){
      //     Navigator.push(
      //       context,
      //       MaterialPageRoute(
      //         builder: (context) => StaticImageProcessingScreen(photos: [],),
      //       ),
      //     );
      //   },
      //   child: Container(
      //     width: 60,
      //     height: 60,
      //     decoration: const BoxDecoration(
      //       color: Color(0xFF4A9EC1),
      //       shape: BoxShape.circle,
      //     ),
      //     child: const Icon(
      //       Icons.chat_bubble_outline,
      //       color: Colors.white,
      //       size: 28,
      //     ),
      //   ),
      // ),
    );
  }
}
