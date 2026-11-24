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

  const ScreeningReportCard({
    super.key,
    required this.result,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final dr = _asMap(result['diabetic_retinopathy']);
    final gl = _asMap(result['glaucoma']);

    return AppCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (imagePath != null) ...[
            _FundusImage(path: imagePath!),
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

  const _ExpandableResultSection({
    required this.title,
    required this.resultLabel,
    required this.subtitle,
    required this.detailChildren,
  });

  @override
  State<_ExpandableResultSection> createState() =>
      _ExpandableResultSectionState();
}

class _ExpandableResultSectionState extends State<_ExpandableResultSection> {
  bool _expanded = false;

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

  static const _drShortLabels = {
    0: 'No DR',
    1: 'Mild',
    2: 'Moderate',
    3: 'Severe',
    4: 'Proliferative',
  };

  const _DrReportSection({required this.dr});

  @override
  Widget build(BuildContext context) {
    final grade = _asInt(dr['grade']) ?? 0;
    final label =
        (dr['label'] ?? _drShortLabels[grade] ?? 'Grade $grade').toString();
    final probs = _asMap(dr['probabilities']) ?? {};
    final referablePct = _referableProbability(probs);
    final isReferable = grade >= 2;

    return _ExpandableResultSection(
      title: 'Diabetic retinopathy',
      resultLabel: label,
      subtitle: isReferable
          ? 'Referable (${_pct(referablePct)})'
          : 'Not referable (${_pct(referablePct)})',
      detailChildren: List.generate(5, (i) {
        final p = _asDouble(probs['$i']) ?? 0;
        return _probRow(_drShortLabels[i] ?? 'Grade $i', p);
      }),
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

Widget _probRow(String label, double probability) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Text(
          _pct(probability),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
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
