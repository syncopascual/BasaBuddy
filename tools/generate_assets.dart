import 'dart:io';

void main() async {
  final storyDir = Directory('assets/story_pages');
  final pubspec = File('pubspec.yaml');

  if (!storyDir.existsSync()) {
    print('story_pages folder not found');
    return;
  }

  final folders = storyDir
      .listSync()
      .whereType<Directory>()
      .map((d) => '    - ${d.path}/')
      .join('\n');

  final pubspecText = pubspec.readAsStringSync();

  final startTag = '# STORY_ASSETS_START';
  final endTag = '# STORY_ASSETS_END';

  final newSection = '''
$startTag
$folders
    - assets/story_pages/
$endTag
''';

  final regex = RegExp('$startTag[\\s\\S]*$endTag');

  final updated = pubspecText.replaceAll(regex, newSection);

  pubspec.writeAsStringSync(updated);

  print('✅ pubspec.yaml updated with story folders');
}