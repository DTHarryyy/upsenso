import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:pos/core/routes/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';

class Onboarding extends StatefulWidget {
  const Onboarding({super.key});

  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  late final PageController _controller;
  int _index = 0;

  final _pages = const <_OnboardPageData>[
    _OnboardPageData(
      lottieAsset: 'assets/lotties/Guy talking to Robot _ AI Help.json',
      title: 'Your Smart Business Assistant',
      description:
          'Get AI-powered insights, instant answers, and real-time alerts. Ledgify helps you understand your sales, inventory, and expenses — and detects suspicious activity before it becomes fraud.',
    ),
    _OnboardPageData(
      lottieAsset: 'assets/lotties/No Connection.json',
      title: 'Run Your Business — Even Offline',
      description:
          'Keep selling without internet. Transactions and inventory updates are saved locally and sync automatically when you’re back online.',
    ),
    _OnboardPageData(
      lottieAsset: 'assets/lotties/Open Business.json',
      title: 'Built for Multi-Branch Businesses',
      description:
          'Monitor sales, inventory, and expenses across all branches. View branch-level reports and keep every store in sync—anytime, anywhere.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding', true);

    if (!mounted) return;

    // TODO: Replace with your real next screen (Login/Dashboard)
    context.go(AppRoutes.signUp);
  }

  void _next() {
    final isLast = _index == _pages.length - 1;

    if (!isLast) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _back() {
    if (_index == 0) return;
    _controller.previousPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  Future<void> _skip() async {
    await _completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _pages.length - 1;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppColors.background,

        // Show back icon only after first page
        leading: _index == 0
            ? null
            : IconButton(onPressed: _back, icon: const Icon(Icons.arrow_back)),

        actionsPadding: const EdgeInsets.only(right: 20),

        actions: [
          if (!isLast)
            GestureDetector(
              onTap: _skip,
              child: Text(
                'Skip',
                style: AppTextStyles.subtitle(
                  context,
                ).copyWith(color: AppColors.textSecondary),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) {
                    final p = _pages[i];
                    return _OnboardPage(
                      lottieAsset: p.lottieAsset,
                      title: p.title,
                      description: p.description,
                    );
                  },
                ),
              ),
              Row(
                children: [
                  PageIndicator(currentIndex: _index, count: _pages.length),
                  const Spacer(),

                  // Next / Get Started button
                  FilledButton(
                    onPressed: _next,
                    style: FilledButton.styleFrom(
                      shape: isLast ? const StadiumBorder() : CircleBorder(),
                      padding: EdgeInsets.all(isLast ? 12 : 15),
                    ),
                    child: isLast
                        ? Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              'Get Started',
                              style: AppTextStyles.subtitle(context).copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        : const Icon(Icons.arrow_forward),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardPage extends StatelessWidget {
  final String lottieAsset;
  final String title;
  final String description;

  const _OnboardPage({
    required this.lottieAsset,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Lottie.asset(lottieAsset),
          Text(
            title,
            style: AppTextStyles.headline(
              context,
            ).copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: AppTextStyles.subtitle(context).copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardPageData {
  final String lottieAsset;
  final String title;
  final String description;

  const _OnboardPageData({
    required this.lottieAsset,
    required this.title,
    required this.description,
  });
}

class PageIndicator extends StatelessWidget {
  final int currentIndex;
  final int count;

  const PageIndicator({super.key, required this.currentIndex, this.count = 3});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(count, (index) {
        final isActive = index == currentIndex;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.only(right: 6),
          width: isActive ? 24 : 12,
          height: 6,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.brand
                : Theme.of(context).colorScheme.onSurface.withAlpha(40),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}
