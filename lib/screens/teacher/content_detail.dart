import 'package:basabuddy/wrappers/ClassData.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../components/StudentDataDialogBox.dart';
import '../../models/student.dart';
import '../../wrappers/StudentData.dart';

class StoryPage {
  final int pageNum;
  final String text;
  final String tagalogText;
 
  const StoryPage({
    required this.pageNum,
    required this.text,
    required this.tagalogText,
  });
 
  factory StoryPage.fromJson(Map<String, dynamic> json) => StoryPage(
        pageNum: json['page_num'] as int? ?? 0,
        text: json['text'] as String? ?? '',
        tagalogText: json['tagalog_text'] as String? ?? '',
      );
}
 
class ExerciseItem {
  final String type;   // 'mulcho' | 'ordering' | 'matching' | 'fill_in_blanks'
  final String skill;
  final int afterPage; // 0 for stages (no pages)
  final String preview;
  final int itemCount; // choices / pairs count
 
  const ExerciseItem({
    required this.type,
    required this.skill,
    required this.afterPage,
    required this.preview,
    required this.itemCount,
  });
}
 
class ContentDetail {
  final String title;
  final bool isStory;
  final List<StoryPage> pages;
  final List<ExerciseItem> exercises;
 
  const ContentDetail({
    required this.title,
    required this.isStory,
    required this.pages,
    required this.exercises,
  });
}


Future<ContentDetail> fetchContentDetail(String storyId, bool isStory) async {
  final supabase = Supabase.instance.client;
 
  // Fetch title
  final meta = await supabase
      .from('list_stories')
      .select('title')
      .eq('story_id', storyId)
      .single();
 
  final title = meta['title'] as String? ?? 'Untitled';
 
  // Fetch pages (stories only)
  List<StoryPage> pages = [];
  if (isStory) {
    final pagesRes = await supabase
        .from('story_page')
        .select()
        .eq('story_id', storyId)
        .order('page_num');
    pages = (pagesRes as List).map((e) => StoryPage.fromJson(e)).toList();
  }
 
  // Fetch exercises from all four tables
  final exercises = <ExerciseItem>[];
 
  // mulcho_exercise
  final mulchoRes = await supabase
      .from('mulcho_exercise')
      .select()
      .eq('story_id', storyId);
  for (final row in mulchoRes as List) {
    final choices = row['choices'] as Map? ?? {};
    exercises.add(ExerciseItem(
      type: 'mulcho',
      skill: row['skill'] as String? ?? '',
      afterPage: row['after_page'] as int? ?? 0,
      preview: row['question'] as String? ?? '',
      itemCount: choices.length,
    ));
  }
 
  // ordering_exercise
  final orderRes = await supabase
      .from('ordering_exercise')
      .select()
      .eq('story_id', storyId);
  for (final row in orderRes as List) {
    final data = row['data'] as Map? ?? {};
    exercises.add(ExerciseItem(
      type: 'ordering',
      skill: row['skill'] as String? ?? '',
      afterPage: row['after_page'] as int? ?? 0,
      preview: 'Ordering exercise',
      itemCount: data.length,
    ));
  }
 
  // matching_exercise
  final matchRes = await supabase
      .from('matching_exercise')
      .select()
      .eq('story_id', storyId);
  for (final row in matchRes as List) {
    final pairs = row['pairs'] as Map? ?? {};
    exercises.add(ExerciseItem(
      type: 'matching',
      skill: row['skill'] as String? ?? '',
      afterPage: row['after_page'] as int? ?? 0,
      preview: 'Matching exercise',
      itemCount: pairs.length,
    ));
  }
 
  // fill_in_blank
  final fillRes = await supabase
      .from('fill_in_blank')
      .select()
      .eq('story_id', storyId);
  for (final row in fillRes as List) {
    final choices = row['choices'] as List? ?? [];
    final s1 = row['statement_1'] as String? ?? '';
    final s2 = row['statement_2'] as String? ?? '';
    exercises.add(ExerciseItem(
      type: 'fill_in_blanks',
      skill: row['skill'] as String? ?? '',
      afterPage: row['after_page'] as int? ?? 0,
      preview: '$s1 _____ $s2'.trim(),
      itemCount: choices.length,
    ));
  }
 
  // Sort exercises by after_page so they appear in reading order
  exercises.sort((a, b) => a.afterPage.compareTo(b.afterPage));
 
  return ContentDetail(
    title: title,
    isStory: isStory,
    pages: pages,
    exercises: exercises,
  );
}

String _exLabel(String type) {
  switch (type) {
    case 'mulcho':        return 'MC';
    case 'ordering':      return 'ORD';
    case 'matching':      return 'MAT';
    case 'fill_in_blanks': return 'FIB';
    default:              return '?';
  }
}
 
String _exTypeName(String type) {
  switch (type) {
    case 'mulcho':         return 'Multiple choice';
    case 'ordering':       return 'Ordering';
    case 'matching':       return 'Matching';
    case 'fill_in_blanks': return 'Fill in the blank';
    default:               return type;
  }
}
 
String _exCountLabel(String type, int count) {
  switch (type) {
    case 'mulcho':         return '$count choice${count != 1 ? 's' : ''}';
    case 'ordering':       return '$count item${count != 1 ? 's' : ''}';
    case 'matching':       return '$count pair${count != 1 ? 's' : ''}';
    case 'fill_in_blanks': return '$count choice${count != 1 ? 's' : ''}';
    default:               return '$count items';
  }
}
 
Color _exBadgeBg(String type) {
  switch (type) {
    case 'mulcho':         return const Color(0xFFE1F5EE);
    case 'ordering':       return const Color(0xFFFAEEDA);
    case 'matching':       return const Color(0xFFEEEDFE);
    case 'fill_in_blanks': return const Color(0xFFFBEAF0);
    default:               return const Color(0xFFF0EFE8);
  }
}
 
Color _exBadgeText(String type) {
  switch (type) {
    case 'mulcho':         return const Color(0xFF085041);
    case 'ordering':       return const Color(0xFF633806);
    case 'matching':       return const Color(0xFF3C3489);
    case 'fill_in_blanks': return const Color(0xFF72243E);
    default:               return const Color(0xFF5F5E5A);
  }
}

class ContentDetailPage extends StatelessWidget {
  final String storyId;
  final bool isStory;

  const ContentDetailPage({
    super.key,
    required this.storyId,
    required this.isStory,
  });

  Color get _appBarColor =>
      isStory ? const Color(0xFF185FA5) : const Color(0xFF534AB7);
 
  Color get _appBarLight =>
      isStory ? const Color(0xFFB5D4F4) : const Color(0xFFCECBF6);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ContentDetail>(
      future: fetchContentDetail(storyId, isStory),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(backgroundColor: _appBarColor),
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }
        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(backgroundColor: _appBarColor),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        final detail = snapshot.data!;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: _buildAppBar(context, detail),
          body: _buildBody(detail),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, ContentDetail detail) {
    return AppBar(
      backgroundColor: _appBarColor,
      foregroundColor:_appBarLight,
      elevation: 0,
      title: Row(
        children: [
          Expanded(
            child: Text(
              detail.title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: _appBarLight,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isStory ? 'Story' : 'Stage',
              style: TextStyle(
                fontSize: 12,
                color: _appBarLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildBody(ContentDetail detail) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildMetaRow(detail),
        const SizedBox(height: 16),
        if (isStory && detail.pages.isNotEmpty) ...[
          _sectionLabel('Pages'),
          const SizedBox(height: 8),
          ..._buildPageCards(detail),
          const SizedBox(height: 16),
        ],
        _sectionLabel('Exercises'),
        const SizedBox(height: 8),
        if (detail.exercises.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text('No exercises.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          )
        else
          ...detail.exercises.map((ex) => _buildExerciseCard(ex, isStory)),
      ],
    );
  }
  Widget _buildMetaRow(ContentDetail detail) {
    final chips = <Widget>[];
 
    if (isStory) {
      chips.add(_metaChip('Pages', '${detail.pages.length}'));
    }
    chips.add(_metaChip('Exercises', '${detail.exercises.length}'));
 
    if (detail.exercises.isNotEmpty) {
      final uniqueSkills = detail.exercises
          .map((e) => e.skill)
          .where((s) => s.isNotEmpty)
          .toSet()
          .length;
      chips.add(_metaChip('Skills', '$uniqueSkills'));
    }
 
    return Row(
      children: chips
          .expand((w) => [Expanded(child: w), const SizedBox(width: 8)])
          .toList()
        ..removeLast(),
    );
  }
 
  Widget _metaChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EFE8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          const SizedBox(height: 3),
          Text(value,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.05,
        color: Colors.grey.shade500,
      ),
    );
  }

  List<Widget> _buildPageCards(ContentDetail detail) {
    // Show first 3 pages, collapse the rest
    const maxVisible = 3;
    final pages = detail.pages;
    final visible = pages.take(maxVisible).toList();
    final remaining = pages.length - maxVisible;
 
    return [
      ...visible.map((page) => _pageCard(page)),
      if (remaining > 0)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200, width: 0.5),
            ),
            child: Text(
              '+ $remaining more page${remaining != 1 ? 's' : ''}',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            ),
          ),
        ),
    ];
  }
 
  Widget _pageCard(StoryPage page) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200, width: 0.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page number badge
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFFE6F1FB),
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Text(
                '${page.pageNum}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0C447C),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Page text preview
            Expanded(
              child: Text(
                page.text,
                style: const TextStyle(fontSize: 13, height: 1.5),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildExerciseCard(ExerciseItem ex, bool showAfterPage) {
    final badgeBg   = _exBadgeBg(ex.type);
    final badgeText = _exBadgeText(ex.type);
    final typeName  = _exTypeName(ex.type);
    final countLabel = _exCountLabel(ex.type, ex.itemCount);
    final subtitle = showAfterPage && ex.afterPage > 0
        ? '$typeName · $countLabel · after page ${ex.afterPage}'
        : '$typeName · $countLabel';
 
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200, width: 0.5),
        ),
        child: Row(
          children: [
            // Type badge
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                _exLabel(ex.type),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: badgeText,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Preview + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ex.preview.isNotEmpty ? ex.preview : typeName,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Skill pill
            if (ex.skill.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EFE8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  ex.skill,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF5F5E5A),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}