import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      'title': 'Welcome to basabuddy!',
      'description': 'Your reading adventure starts here.',
      'emoji': '📚',
    },
    {
      'title': 'Learn, read, grow',
      'description': 'Discover new stories and build your skills every day.',
      'emoji': '🌱',
    },
    {
      'title': 'Before we start, let\'s read a bit!',
      'description': 'We\'ll ask you a few questions about some short stories so we can find the perfect level for you.',
      'emoji': '✏️',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFFEA940),
              const Color(0xFFFFD351),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              /// Skip button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextButton(
                    onPressed: () => _goToDiagnostic(context),
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

              /// Page view
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _buildPage(_pages[index]);
                  },
                ),
              ),

              /// Page indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => _buildDot(index),
                ),
              ),
              const SizedBox(height: 24),

              /// Next / Start button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selected,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 4,
                    ),
                    onPressed: () {
                      if (_currentPage < _pages.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _goToDiagnostic(context);
                      }
                    },
                    child: Text(
                      _currentPage == _pages.length - 1 ? "Let's Go!" : 'Next',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(Map<String, String> page) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        /// Emoji/Icon
        Text(
          page['emoji']!,
          style: const TextStyle(fontSize: 100),
        ),
        const SizedBox(height: 32),

        /// Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Text(
            page['title']!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
        const SizedBox(height: 16),

        /// Description
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Text(
            page['description']!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: textColor.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 6),
      width: _currentPage == index ? 24 : 10,
      height: 10,
      decoration: BoxDecoration(
        color: _currentPage == index ? textColor : textColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }

  void _goToDiagnostic(BuildContext context) {
    context.go('/student/diagnostic');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
