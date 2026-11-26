import 'dart:io';

import 'package:eye_health/services/health_statistics_store.dart';
import 'package:eye_health/theme/app_theme.dart';
import 'package:flutter/material.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  late final Future<List<SavedChatImage>> _photosFuture;

  @override
  void initState() {
    super.initState();
    _photosFuture = HealthStatisticsStore.load();
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
        child: FutureBuilder<List<SavedChatImage>>(
          future: _photosFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            final photos = snapshot.data ?? const <SavedChatImage>[];
            if (photos.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'Fundus photos from your chats will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.4,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 12,
                childAspectRatio: 0.78,
              ),
              itemCount: photos.length,
              itemBuilder: (context, index) {
                final photo = photos[index];
                return _GalleryTile(
                  imagePath: photo.imagePath,
                  title: photo.dateLabel,
                  subtitle: photo.detailLabel,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Standard gallery-style tile: square thumbnail + captions below.
class _GalleryTile extends StatelessWidget {
  final String imagePath;
  final String title;
  final String subtitle;

  const _GalleryTile({
    required this.imagePath,
    required this.title,
    required this.subtitle,
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
              child: Image.file(
                File(imagePath),
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                alignment: Alignment.center,
                errorBuilder:
                    (_, __, ___) => const Icon(
                      Icons.image_not_supported,
                      color: Color(0xFF9CA3AF),
                    ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
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
          subtitle,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }
}
