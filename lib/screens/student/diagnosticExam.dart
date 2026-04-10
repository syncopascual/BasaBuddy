import 'package:basabuddy/components/Page.dart';
import 'package:basabuddy/components/ProgressBar.dart';
import 'package:basabuddy/components/question_components/MulchoExercise.dart';
import 'package:basabuddy/models/mulcho.dart';
import 'package:basabuddy/models/story.dart';
import 'package:basabuddy/models/storyPage.dart';
import 'package:basabuddy/utils/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../colors.dart';
import '../../components/DiagnosticPageContainer.dart';
import '../../components/diagnostic_question.dart';

class DiagnosticExamScreen extends StatefulWidget {
  const DiagnosticExamScreen({super.key});

  @override
  State<DiagnosticExamScreen> createState() => _DiagnosticExamScreenState();
}

class _DiagnosticExamScreenState extends State<DiagnosticExamScreen> {
  int _currentLevel = 1;
  Story? _currentStory;
  List<Storypage> _pages = [];
  List<Mulcho> _questions = [];
  int _currentPageIndex = 0;
  bool _isOnQuestion = false;
  int _currentQuestionIndex = 0;
  int _correctAnswers = 0;
  bool _isLoading = true;
  bool _isCompleted = false;
  int _finalLevel = 1;

  /// Tracks whether we're showing story pages or questions
  DiagnosticState _state = DiagnosticState.loading;
  ImageProvider<Object> determineBg() {
    int? pageNum;

      switch (_state) {
        case DiagnosticState.loading:
          return AssetImage("assets/bg_images/grassy.png");

        case DiagnosticState.storyPage:
          if (_pages.isEmpty) {
            return AssetImage("assets/bg_images/grassy.png");
          }

          final currentPage = _pages[_currentPageIndex];
          String url = 'assets/story_pages/${currentPage.storyId}/${currentPage.pageNum}.png';
          return AssetImage(url);

        case DiagnosticState.question:
          return AssetImage("assets/bg_images/grassy.png");

        case DiagnosticState.completed:
          return AssetImage("assets/bg_images/grassy.png");

        case DiagnosticState.error:
          return AssetImage("assets/bg_images/grassy.png");

    }

    return AssetImage("assets/bg_images/grassy.png");
  }
  @override
  void initState() {
    super.initState();
    _loadLevel(_currentLevel);
  }

  Future<void> _loadLevel(int level) async {
    print("Diagnostic Exam: Loading level");
    setState(() {
      _isLoading = true;
      _state = DiagnosticState.loading;
    });

    try {
      /// Fetch the diagnostic story for this level
      final stories = await DatabaseHelper.instance.queryWhere(
        'list_stories',
        Story.fromJson,
        'module = ? AND level = ?',
        ['diagnostic', level],
      );


      if (stories.isEmpty) {
        /// No more levels - student completed all
        setState(() {
          _finalLevel = level - 1;
          _state = DiagnosticState.completed;
          _isLoading = false;
        });
        return;
      }

      _currentStory = stories.first;
      _correctAnswers = 0;
      _currentPageIndex = 0;
      _currentQuestionIndex = 0;
      print('HELLO');

      /// Fetch story pages
      _pages = await DatabaseHelper.instance.queryWhere(
        'story_page',
        Storypage.fromJson,
        'story_id = ?',
        [_currentStory!.storyId],
      );
      print('HAII');

      /// Fetch multiple choice questions
      _questions = await DatabaseHelper.instance.queryWhere(
        'mulcho_exercise',
        Mulcho.fromJson,
        'story_id = ?',
        [_currentStory!.storyId],
      );


      print('pages n exercises queried');
      /// Sort pages by page number
      _pages.sort((a, b) => a.pageNum.compareTo(b.pageNum));

      print('Diagnostic Level $level loaded:');
      print('  Story: ${_currentStory!.title}');
      print('  Pages: ${_pages.length}');
      print('  Questions: ${_questions.length}');

      /// Start with the first story page
      _state = DiagnosticState.storyPage;
      _isOnQuestion = false;
    } catch (e) {
      print('Error loading diagnostic level $level: $e');
      setState(() {
        _state = DiagnosticState.error;
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _onNextPage() {
    if (_state == DiagnosticState.storyPage) {
      if (_currentPageIndex < _pages.length - 1) {
        /// Go to next story page
        setState(() {
          _currentPageIndex++;
        });
      } else {
        /// All pages read, start questions
        setState(() {
          _state = DiagnosticState.question;
          _currentQuestionIndex = 0;
          _isOnQuestion = true;
        });
      }
    } else if (_state == DiagnosticState.question) {
      /// Already handled by question callbacks
    }
  }

  void _onPreviousPage() {
    if (_state == DiagnosticState.storyPage && _currentPageIndex > 0) {
      setState(() {
        _currentPageIndex--;
      });
    }
  }

  void _onQuestionCorrect() {
    setState(() {
      _correctAnswers++;
    });
    _advanceQuestion();
  }

  void _onQuestionWrong() {
    /// Just advance without incrementing correct count
    _advanceQuestion();
  }

  void _advanceQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      /// All questions answered - evaluate level
      _evaluateLevel();
    }
  }

  Future<void> _evaluateLevel() async {
    print('Level $_currentLevel completed with $_correctAnswers/3 correct');

    int placedLevel;
    if (_correctAnswers == 3) {
      /// Perfect score - try next level
      if (_currentLevel < 5) {
        await _loadLevel(_currentLevel + 1);
        return;
      } else {
        /// Completed all 5 levels perfectly
        placedLevel = 5;
      }
    } else if (_correctAnswers == 2) {
      /// Placed at current level
      placedLevel = _currentLevel;
    } else {
      /// 0 or 1 correct - demote to level 1 (or current - 1)
      placedLevel = _currentLevel > 1 ? _currentLevel - 1 : 1;
    }

    /// Save the result
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      await DatabaseHelper.instance.setDiagnosticCompleted(user.id);
      /// Also update user_level_info with the placed level
      await _updateUserLevel(user.id, placedLevel);
    }

    setState(() {
      _finalLevel = placedLevel;
      _state = DiagnosticState.completed;
    });
  }

  Future<void> _updateUserLevel(String userId, int level) async {
    final db = await DatabaseHelper.instance.db;
    final now = DateTime.now().toUtc().toIso8601String();

    /// Update local SQLite
    await db.update(
      'user_level_info',
      {
        'vocab_lvl': level,
        'narrative_lvl': level,
        'information_lvl': level,
        'updated_at': now,
      },
      where: 'user_id = ?',
      whereArgs: [userId],
    );

  }

  double get _progress {
    if (_state == DiagnosticState.loading) return 0.0;
    if (_state == DiagnosticState.completed) return 1.0;

    if (_state == DiagnosticState.storyPage) {
      return (_currentPageIndex + 1).toDouble() / (_pages.length + _questions.length).toDouble();
    } else if (_state == DiagnosticState.question) {
      double pagesDone = _pages.length.toDouble();
      double questionsDone = (_currentQuestionIndex + 1).toDouble();
      return (pagesDone + questionsDone) / (_pages.length + _questions.length).toDouble();
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: determineBg(),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              /// Header with level indicator and progress
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [

                    const SizedBox(height: 12),
                    GradientLinearProgressBar(
                      value: _progress,
                      leftColor: const Color(0xFF22C03A),
                      rightColor: const Color(0xFFB2FF3E),
                      unfilledColor: Colors.grey,
                    ),
                  ],
                ),
              ),

              /// Content
              Expanded(
                child: _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_state) {
      case DiagnosticState.loading:
        return const Center(
          child: CircularProgressIndicator(),
        );

      case DiagnosticState.storyPage:
        return _buildStoryPage();

      case DiagnosticState.question:
        return _buildQuestion();

      case DiagnosticState.completed:
        return _buildCompleted();

      case DiagnosticState.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Something went wrong.',
                style: TextStyle(fontSize: 18, color: textColor),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: selected),
                onPressed: () => _loadLevel(_currentLevel),
                child: Text('Retry', style: TextStyle(color: textColor)),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildStoryPage() {
    if (_pages.isEmpty) {
      return const Center(child: Text('No pages available'));
    }

    final currentPage = _pages[_currentPageIndex];

    return Container(
      height:500,
      child: Column(
        children: [
          /// Story page content
          DiagnosticPageContainer(
            storyPage: currentPage,
            imageURL: '',
          ),

          /// Navigation buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                /// Back button
                SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selected,
                    ),
                    onPressed: _currentPageIndex > 0 ? _onPreviousPage : null,
                    child: Text(
                      'Back',
                      style: TextStyle(color: textColor),
                    ),
                  ),
                ),

                /// Next button
                SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selected,
                    ),
                    onPressed: _onNextPage,
                    child: Text(
                      _currentPageIndex < _pages.length - 1 ? 'Next' : 'Next',
                      style: TextStyle(color: textColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion() {
    if (_questions.isEmpty) {
      return const Center(child: Text('No questions available'));
    }

    final currentQuestion = _questions[_currentQuestionIndex];

    return DiagnosticExercise(
      mulcho: currentQuestion,
      bgImage: 'grassy',
      onCorrectAnswer: _onQuestionCorrect,
      onWrongAnswer: _onQuestionWrong,
    );
  }

  Widget _buildCompleted() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.emoji_events,
              size: 100,
              color: Color(0xFFFFD351),
            ),
            const SizedBox(height: 24),
            Text(
              'Diagnostic Complete!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'You\'ve been placed at Level $_finalLevel',
              style: TextStyle(
                fontSize: 20,
                color: textColor.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: selected,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                onPressed: () {
                  context.go('/student/home');
                },
                child: Text(
                  'Go to Home',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum DiagnosticState {
  loading,
  storyPage,
  question,
  completed,
  error,
}
