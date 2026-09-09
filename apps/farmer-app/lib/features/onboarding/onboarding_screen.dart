import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_language.dart';
import '../../core/config/app_settings_provider.dart';
import '../../core/config/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/citadel_logo.dart';

/// Data model for a single onboarding page.
class _PageData {
  final String titleKey;
  final String subtitleKey;
  final String imageAsset;
  final Color accentColor;
  final Color accentBgColor;

  const _PageData({
    required this.titleKey,
    required this.subtitleKey,
    required this.imageAsset,
    required this.accentColor,
    required this.accentBgColor,
  });
}

const _pages = [
  _PageData(
    titleKey: 'Monitor Your Farm in Real-time',
    subtitleKey:
        'Get live soil moisture, temperature, and humidity readings from IoT sensors placed across your fields.',
    imageAsset: 'assets/images/onboarding_sensors.png',
    accentColor: Color(0xFF0F7A3E),
    accentBgColor: Color(0xFFE8F5E9),
  ),
  _PageData(
    titleKey: 'Scan Crops for Disease',
    subtitleKey:
        'Point your camera at any leaf. Our AI detects diseases like blight, whitefly, and rust — with instant treatment advice.',
    imageAsset: 'assets/images/onboarding_scan.png',
    accentColor: Color(0xFF0F7A3E),
    accentBgColor: Color(0xFFF0FDF4),
  ),
  _PageData(
    titleKey: 'Never Miss an Irrigation Cycle',
    subtitleKey:
        'Receive automated irrigation advisories based on soil data. Approve with one tap — the system controls your drip valves.',
    imageAsset: 'assets/images/onboarding_irrigation.png',
    accentColor: Color(0xFF00838F),
    accentBgColor: Color(0xFFE0F7FA),
  ),
  _PageData(
    titleKey: 'Your Language, Your Farm',
    subtitleKey:
        'Use Citadel in English, Hindi, Haryanvi, or Punjabi — built for Indian farmers.',
    imageAsset: 'assets/images/onboarding_language.png',
    accentColor: Color(0xFF6A1B9A),
    accentBgColor: Color(0xFFF3E5F5),
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _finishOnboarding() async {
    final settings = context.read<AppSettingsProvider>();
    await settings.completeOnboarding();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsProvider>();
    final lang = settings.language;
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button row
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo
                  Row(
                    children: [
                      const CitadelLogo(size: 34),
                      const SizedBox(width: 8),
                      Text(
                        'Citadel',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  // Skip
                  if (!isLastPage)
                    TextButton(
                      onPressed: _finishOnboarding,
                      child: Text(
                        AppStrings.translate('Skip', lang),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 48),
                ],
              ),
            ),

            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return _buildPage(page, lang, index);
                },
              ),
            ),

            // Bottom controls
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  // Dot indicators
                  _buildDotIndicators(),
                  const SizedBox(height: 24),
                  // Navigation button
                  _buildNavigationButton(lang, isLastPage),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_PageData page, AppLanguage lang, int index) {
    final isLastPage = index == _pages.length - 1;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          children: [
            SizedBox(height: isLastPage ? 8 : 20),
            _buildIllustration(page, isCompact: isLastPage),
            SizedBox(height: isLastPage ? 14 : 24),
            Text(
              AppStrings.translate(page.titleKey, lang),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: isLastPage ? 23 : 26,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.translate(page.subtitleKey, lang),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            if (isLastPage) ...[
              const SizedBox(height: 18),
              _buildLanguagePicker(lang),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildIllustration(_PageData page, {bool isCompact = false}) {
    final double boxSize = isCompact ? 195 : 220;
    final double imgSize = isCompact ? 185 : 210;

    return SizedBox(
      height: boxSize,
      width: boxSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer pulsing glow
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: imgSize * 0.85,
                  height: imgSize * 0.85,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: page.accentColor.withValues(alpha: 0.25),
                        blurRadius: 28,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Image.asset(
            page.imageAsset,
            width: imgSize,
            height: imgSize,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }


  Widget _buildLanguagePicker(AppLanguage currentLang) {
    return Column(
      children: [
        Text(
          AppStrings.translate('Choose your language', currentLang),
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: AppLanguage.values.map((lang) {
            final isSelected = lang == currentLang;
            return GestureDetector(
              onTap: () {
                context.read<AppSettingsProvider>().setLanguage(lang);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryGreen
                      : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryGreen
                        : Colors.grey.shade300,
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color:
                                AppColors.primaryGreen.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  lang.displayLabel,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDotIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pages.length, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primaryGreen
                : AppColors.primaryGreen.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildNavigationButton(AppLanguage lang, bool isLastPage) {
    if (isLastPage) {
      return SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: _finishOnboarding,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
            foregroundColor: Colors.white,
            elevation: 4,
            shadowColor: AppColors.primaryGreen.withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppStrings.translate('Get Started', lang),
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, size: 20),
            ],
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Page counter
        Text(
          '${_currentPage + 1} / ${_pages.length}',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textTertiary,
          ),
        ),
        // Next button
        SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: _nextPage,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              elevation: 2,
              shadowColor: AppColors.primaryGreen.withValues(alpha: 0.3),
              padding: const EdgeInsets.symmetric(horizontal: 28),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppStrings.translate('Next', lang),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
