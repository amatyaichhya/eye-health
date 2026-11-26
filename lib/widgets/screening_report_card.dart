import 'dart:io';

import 'package:eye_health/theme/app_theme.dart';
import 'package:eye_health/widgets/app_card.dart';
import 'package:flutter/material.dart';

/// Screening report: one card with fundus image on top, DR / glaucoma dropdowns below.
class ScreeningReportCard extends StatelessWidget {
  final Map<String, dynamic> result;
  final String? imagePath;

  static const _disclaimer =
      'Screening support only. A qualified clinician makes the diagnosis.';

  /// DR grades 0–4 (multi-class).
  static const drGradeLabels = {
    0: 'No DR',
    1: 'Mild NPDR',
    2: 'Moderate NPDR',
    3: 'Severe NPDR',
    4: 'Proliferative DR',
  };

  const ScreeningReportCard({
    super.key,
    required this.result,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final dr = _asMap(result['diabetic_retinopathy']);
    final gl = _asMap(result['glaucoma']);
    final imageName = _imageName(result, imagePath);

    return AppCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (imagePath != null) ...[
            _FundusImage(path: imagePath!),
            const SizedBox(height: 8),
          ],
          if (imageName != null) ...[
            Text(
              imageName,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (dr != null) _DrReportSection(dr: dr),
          if (dr != null && gl != null) const SizedBox(height: 8),
          if (gl != null) _GlaucomaReportSection(gl: gl),
          const SizedBox(height: 10),
          Text(
            _disclaimer,
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  static String? _imageName(Map<String, dynamic> result, String? imagePath) {
    final fromResult = result['filename']?.toString().trim();
    if (fromResult != null && fromResult.isNotEmpty) return fromResult;
    if (imagePath == null || imagePath.isEmpty) return null;
    return imagePath.split(RegExp(r'[/\\]')).last;
  }
}

class _FundusImage extends StatelessWidget {
  final String path;

  const _FundusImage({required this.path});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: ColoredBox(
        color: Colors.black,
        child: AspectRatio(
          aspectRatio: 16 / 10,
          child: Image.file(
            File(path),
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(Icons.image_not_supported, color: Colors.white54),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpandableResultSection extends StatefulWidget {
  final String title;
  final String resultLabel;
  final String subtitle;
  final List<Widget> detailChildren;
  final bool initiallyExpanded;

  const _ExpandableResultSection({
    required this.title,
    required this.resultLabel,
    required this.subtitle,
    required this.detailChildren,
    this.initiallyExpanded = false,
  });

  @override
  State<_ExpandableResultSection> createState() =>
      _ExpandableResultSectionState();
}

class _ExpandableResultSectionState extends State<_ExpandableResultSection> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: widget.initiallyExpanded,
          tilePadding: const EdgeInsets.fromLTRB(12, 4, 8, 4),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          onExpansionChanged: (open) => setState(() => _expanded = open),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.resultLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          trailing: Icon(
            _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            color: AppColors.primaryDark,
            size: 22,
          ),
          children: widget.detailChildren,
        ),
      ),
    );
  }
}

class _DrReportSection extends StatelessWidget {
  final Map<String, dynamic> dr;

  const _DrReportSection({required this.dr});

  @override
  Widget build(BuildContext context) {
    final grade = _asInt(dr['grade']) ?? 0;
    final label = (dr['label'] ??
            ScreeningReportCard.drGradeLabels[grade] ??
            'Grade $grade')
        .toString();
    final probs = _asMap(dr['probabilities']) ?? {};
    final referablePct =
        _asDouble(dr['referable_probability']) ?? _referableProbability(probs);
    final isReferable =
        dr['referable'] is bool ? dr['referable'] as bool : grade >= 2;
    final gradeConf = _asDouble(probs['$grade']) ?? 0;

    return _ExpandableResultSection(
      title: 'Diabetic retinopathy',
      resultLabel: label,
      subtitle: isReferable
          ? 'Referable (${_pct(referablePct)}) · Confidence ${_pct(gradeConf)}'
          : 'Not referable (${_pct(referablePct)}) · Confidence ${_pct(gradeConf)}',
      detailChildren: [
        const Padding(
          padding: EdgeInsets.only(bottom: 6),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Class probabilities',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
        ...List.generate(5, (i) {
          final p = _asDouble(probs['$i']) ?? 0;
          final name = ScreeningReportCard.drGradeLabels[i] ?? 'Class $i';
          return _probRow(
            name,
            p,
            highlight: i == grade,
          );
        }),
      ],
    );
  }

  double _referableProbability(Map<String, dynamic> probs) {
    double sum = 0;
    for (final i in [2, 3, 4]) {
      sum += _asDouble(probs['$i']) ?? 0;
    }
    return sum;
  }
}

class _GlaucomaReportSection extends StatelessWidget {
  final Map<String, dynamic> gl;

  const _GlaucomaReportSection({required this.gl});

  @override
  Widget build(BuildContext context) {
    final label = (gl['label'] ?? 'Glaucoma screen').toString();
    final probs = _asMap(gl['probabilities']) ?? {};
    final positive = gl['positive'] == true;
    final conf =
        _asDouble(positive ? probs['positive'] : probs['negative']) ?? 0;

    return _ExpandableResultSection(
      title: 'Glaucoma',
      resultLabel: label,
      subtitle: 'Confidence ${_pct(conf)}',
      detailChildren: [
        _probRow('Negative', _asDouble(probs['negative']) ?? 0),
        _probRow('Positive', _asDouble(probs['positive']) ?? 0),
      ],
    );
  }
}

Widget _probRow(String label, double probability, {bool highlight = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w400,
              color: highlight ? AppColors.primaryDark : AppColors.textPrimary,
            ),
          ),
        ),
        Text(
          _pct(probability),
          style: TextStyle(
            fontSize: 13,
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
            color: highlight ? AppColors.primaryDark : AppColors.textPrimary,
          ),
        ),
      ],
    ),
  );
}

String _pct(double value) => '${(value * 100).toStringAsFixed(1)}%';

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

double? _asDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}
