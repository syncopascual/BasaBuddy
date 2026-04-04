import 'package:flutter/material.dart';

class StudentDataDialogBox extends StatelessWidget {
  final String name;
  final String storiesRead;
  final String accuracyRate;
  final String averageRetryRate;
  final List<Map<String, double>> strengths;
  final List<Map<String, double>> needsReview;

  const StudentDataDialogBox({
    super.key,
    required this.name,
    required this.storiesRead,
    required this.accuracyRate,
    required this.averageRetryRate,
    required this.strengths,
    required this.needsReview,
  });

  static const List<_AvatarTheme> _avatarThemes = [
    _AvatarTheme(bg: Color(0xFFB5D4F4), text: Color(0xFF0C447C)),
    _AvatarTheme(bg: Color(0xFF9FE1CB), text: Color(0xFF085041)),
    _AvatarTheme(bg: Color(0xFFF4C0D1), text: Color(0xFF72243E)),
    _AvatarTheme(bg: Color(0xFFCECBF6), text: Color(0xFF3C3489)),
    _AvatarTheme(bg: Color(0xFFFAC775), text: Color(0xFF633806)),
  ];
 
  _AvatarTheme get _avatarTheme {
    final index = name.isNotEmpty ? name.codeUnitAt(0) % _avatarThemes.length : 0;
    return _avatarThemes[index];
  }
 
  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts[0].isNotEmpty) return parts[0][0].toUpperCase();
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
            _buildHeader(),
            _buildBody(),
            _buildCloseButton(context),
          ],
        ),
    );
  }

  Widget _buildHeader() {
    final theme = _avatarTheme;
 
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar + name
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: theme.bg,
                child: Text(
                  _initials,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: theme.text,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Metric grid
          Row(
            children: [
              Expanded(child: _metricTile('Stories read', storiesRead, null)),
              const SizedBox(width: 8),
              Expanded(child: _metricTile('Accuracy', accuracyRate, _isGoodAccuracy())),
              const SizedBox(width: 8),
              Expanded(child: _metricTile('Avg retries', averageRetryRate, _isGoodRetry())),
            ],
          ),
        ],
      ),
    );
  }
 
  // Returns true = good (teal), false = warn (amber), null = neutral
  bool? _isGoodAccuracy() {
    final num = double.tryParse(accuracyRate.replaceAll('%', '').replaceAll('×', ''));
    if (num == null) return null;
    return num >= 70;
  }
 
  bool? _isGoodRetry() {
    final num = double.tryParse(averageRetryRate.replaceAll('%', '').replaceAll('×', ''));
    if (num == null) return null;
    return num <= 1.5;
  }
 
  Widget _metricTile(String label, String value, bool? isGood) {
    final Color valueColor;
    if (isGood == null) {
      valueColor = Colors.black87;
    } else if (isGood) {
      valueColor = const Color(0xFF0F6E56);
    } else {
      valueColor = const Color(0xFF854F0B);
    }
 
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          const SizedBox(height: 3),
          Text(value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: valueColor,
              )),
        ],
      ),
    );
  }
 
  // ── Body: skill sections ─────────────────────────
 
  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (strengths.isNotEmpty) ...[
            _skillSection(
              label: 'Excelling in',
              skills: strengths,
              chipBg: const Color(0xFFEAF3DE),
              chipText: const Color(0xFF27500A),
            ),
          ],
          if (strengths.isNotEmpty && needsReview.isNotEmpty)
            const SizedBox(height: 14),
          if (needsReview.isNotEmpty) ...[
            _skillSection(
              label: 'Needs focus',
              skills: needsReview,
              chipBg: const Color(0xFFFBEAF0),
              chipText: const Color(0xFF72243E),
            ),
          ],
          if (strengths.isEmpty && needsReview.isEmpty)
            Text(
              'No skill data yet.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
        ],
      ),
    );
  }
 
  Widget _skillSection({
    required String label,
    required List<Map<String, double>> skills,
    required Color chipBg,
    required Color chipText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.05,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: skills.map((skillMap) {
            final entry = skillMap.entries.first;
            final score = entry.value.toStringAsFixed(0);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: chipBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: entry.key,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: chipText,
                      ),
                    ),
                    TextSpan(
                      text: '  $score%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: chipText.withOpacity(0.65),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
 
  // ── Close button ─────────────────────────────────
 
  Widget _buildCloseButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade200, width: 0.5),
        ),
      ),
      child: TextButton(
        onPressed: () => Navigator.of(context).pop(),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
        ),
        child: Text(
          'Close',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}

class _AvatarTheme {
  final Color bg;
  final Color text;
  const _AvatarTheme({required this.bg, required this.text});
}