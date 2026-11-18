import 'package:eye_health/pages/statistics_screen/ai_statistics_screen.dart';
import 'package:eye_health/theme/app_theme.dart';
import 'package:flutter/material.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final TextEditingController _messageController = TextEditingController();

  final List<Map<String, dynamic>> monthlyData = [
    {'month': 'Month 1', 'risk': 'Low'},
    {'month': 'Month 2', 'risk': 'Low-medium'},
    {'month': 'Month 3', 'risk': 'Medium'},
    {'month': 'Month 4', 'risk': 'Low high'},
    {'month': 'Month 5', 'risk': 'Medium High'},
    {'month': 'Month 6', 'risk': 'High'},
    {'month': 'Month 7', 'risk': 'Very high'},
    {'month': 'Month 8', 'risk': 'Severe'},
    {'month': 'Month 9', 'risk': 'High severe'},
    {'month': 'Month 10', 'risk': 'High severe'},
    {'month': 'Month 11', 'risk': 'High severe'},
    {'month': 'Month 12', 'risk': 'High severe'},
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Personal Health Statistics',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        titleSpacing: 0,
        centerTitle: false,
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 12,
                  // Square image + two caption lines underneath
                  childAspectRatio: 0.78,
                ),
                itemCount: monthlyData.length,
                itemBuilder: (context, index) {
                  final data = monthlyData[index];
                  return _GalleryTile(
                    month: data['month'] as String,
                    risk: data['risk'] as String,
                  );
                },
              ),
            ),
            _AskBottomBar(
              controller: _messageController,
              onSend: _navigateToAIChat,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAIChat() {
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AiStatisticsScreen(
            question: _messageController.text,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to start AI chat: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

/// Standard gallery-style tile: square thumbnail + captions below.
class _GalleryTile extends StatelessWidget {
  final String month;
  final String risk;

  const _GalleryTile({
    required this.month,
    required this.risk,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2F6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/images/sample_1.png',
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                alignment: Alignment.center,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          month,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          risk,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }
}

class _AskBottomBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _AskBottomBar({
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 12,
            offset: Offset(0, -3),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You may ask about the statistics of eye health progression over time.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText: 'Ask a question',
                        hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => onSend(),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Material(
                  color: AppColors.primary,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onSend,
                    child: const SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
