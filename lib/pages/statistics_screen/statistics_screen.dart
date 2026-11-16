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
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Personal Health Statistics'),
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
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                itemCount: monthlyData.length,
                itemBuilder: (context, index) {
                  final data = monthlyData[index];
                  return _MonthCard(
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

class _MonthCard extends StatelessWidget {
  final String month;
  final String risk;

  const _MonthCard({
    required this.month,
    required this.risk,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 8, 6, 4),
            child: Text(
              month,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/sample_1.png',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 4, 6, 8),
            child: Text(
              risk,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
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
