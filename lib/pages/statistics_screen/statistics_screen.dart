import 'dart:io';

import 'package:camera/camera.dart';
import 'package:eye_health/global_widget/eye_health_appbar.dart';
import 'package:eye_health/utils/utility_methods/color_print.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../image_processing_screen/static_image_processing_screen.dart';
import 'ai_statistics_screen.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  static const String _appTitle = 'EYEHEALTH';
  final TextEditingController _messageController = TextEditingController();

  final List<Map<String, dynamic>> monthlyData = [
    {'month': 'Month 1', 'risk': 'Low', 'color': Colors.green.shade600},
    {'month': 'Month 2', 'risk': 'Low-medium', 'color': Colors.orange.shade600},
    {'month': 'Month 3', 'risk': 'Medium', 'color': Colors.orange.shade700},
    {'month': 'Month 4', 'risk': 'Low high', 'color': Colors.red.shade600},
    {'month': 'Month 5', 'risk': 'Medium High', 'color': Colors.red.shade700},
    {'month': 'Month 6', 'risk': 'High', 'color': Colors.red.shade800},
    {'month': 'Month 7', 'risk': 'Very high', 'color': Colors.red.shade900},
    {'month': 'Month 8', 'risk': 'Severe', 'color': Colors.red.shade900},
    {'month': 'Month 9', 'risk': 'High severe', 'color': Colors.red.shade900},
    {'month': 'Month 10', 'risk': 'High severe', 'color': Colors.red.shade900},
    {'month': 'Month 11', 'risk': 'High severe', 'color': Colors.red.shade900},
    {'month': 'Month 12', 'risk': 'High severe', 'color': Colors.red.shade900},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: EyeHealthAppbar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const Text(
              'Personal Health Statistics',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 24),

            // Grid of monthly data
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 20,
                  childAspectRatio: 0.8,
                ),
                itemCount: monthlyData.length,
                itemBuilder: (context, index) {
                  final data = monthlyData[index];
                  return Column(
                    children: [
                      // Month label
                      Text(
                        data['month'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Fundus image container
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            children: [
                              // Base asset image
                              Image.asset(
                                'assets/images/sample_1.png',
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                              // Red gradient overlay for fundus effect
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  // gradient: RadialGradient(
                                  //   center: const Alignment(0.2, -0.2),
                                  //   radius: 0.8,
                                  //   colors: [
                                  //     if (index % 2 == 0)
                                  //       Colors.red.withOpacity(0.3),
                                  //     if (index % 3 == 0)
                                  //       Colors.red.shade600.withOpacity(0.5),
                                  //     if (index % 4 == 0)
                                  //       Colors.red.shade900.withOpacity(0.7),
                                  //     Colors.red.shade50,
                                  //   ],
                                  // ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Risk level
                      Text(
                        data['risk'],
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                },
              ),
            ),


            //   'You may ask about the statistics of eye health progression over time.

            Column(
              spacing: 6,
              children: [
                //  Hi, I’m your Eye Health Assistant. Ask me anything about your eyes or vision care!
                Column(
                  children: [
                    Text(
                     'You may ask about the statistics of eye health progression over time.'
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            // Your fundus examination report has been generated. I can answer any questions you may have
                            hintText: 'Ask a question',
                            hintStyle: TextStyle(color: Colors.grey.shade500),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          onSubmitted: (_) => _navigateToAIChat(),
                          maxLines: null,
                          textCapitalization: TextCapitalization.sentences,
                        ),
                      ),
                    ),

                    SizedBox(width: 12),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Colors.teal,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: _navigateToAIChat,
                        icon: const Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 15,)

          ],
        ),
      ),
    );
  }

  void _navigateToAIChat() async {
    try {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) =>  AiStatisticsScreen(
          question: _messageController.text,
        )),
      );
      // // Load the asset as bytes
      // final ByteData assetData = await rootBundle.load(
      //   'assets/images/sample_1.png',
      // );
      // final Uint8List bytes = assetData.buffer.asUint8List();
      //
      // // Create a temporary file
      // final Directory tempDir = Directory.systemTemp;
      // final String tempPath =
      //     '${tempDir.path}/demo_fundus_${DateTime.now().millisecondsSinceEpoch}.png';
      // final File tempFile = File(tempPath);
      //
      // // Write the asset bytes to the temporary file
      // await tempFile.writeAsBytes(bytes);
      //
      // // Create XFile from the temporary file
      // final List<XFile> demoPhotos = [XFile(tempPath)];
      //
      // // Navigate to StaticImageProcessingScreen
      // if (!mounted) return; // Check if the widget is still mounted
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => StaticImageProcessingScreen(photos: demoPhotos),
      //   ),
      // );
    } catch (e) {
      // Fallback if navigation fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to start AI chat: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
