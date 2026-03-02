import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/competition_provider.dart';
import '../../theme/app_colors.dart';

class CompetitionTimerDisplay extends StatelessWidget {
  final CompetitionPhase phase;
  final int currentEnd;
  final int totalEnds;
  final int remainingSeconds;
  final int totalShootingTime;
  final VoidCallback onStart;
  final VoidCallback onSkip;
  final VoidCallback onPause;

  const CompetitionTimerDisplay({
    super.key,
    required this.phase,
    required this.currentEnd,
    required this.totalEnds,
    required this.remainingSeconds,
    required this.totalShootingTime,
    required this.onStart,
    required this.onSkip,
    required this.onPause,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        color: _backgroundColor,
        child: SafeArea(
          child: _buildContent(context),
        ),
      ),
    );
  }

  Color get _backgroundColor {
    switch (phase) {
      case CompetitionPhase.wait:
        return const Color(0xFF1A1A2E);
      case CompetitionPhase.preparation:
      case CompetitionPhase.timesUp:
        return AppColors.timerRed;
      case CompetitionPhase.shooting:
        return AppColors.timerGreen;
      case CompetitionPhase.warning:
        return AppColors.timerYellow;
      default:
        return const Color(0xFF1A1A2E);
    }
  }

  Widget _buildContent(BuildContext context) {
    switch (phase) {
      case CompetitionPhase.wait:
        return _buildWaitView(context);
      case CompetitionPhase.preparation:
        return _buildPreparationView(context);
      case CompetitionPhase.shooting:
      case CompetitionPhase.warning:
        return _buildShootingView(context);
      case CompetitionPhase.timesUp:
        return _buildTimesUpView(context);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildWaitView(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final size = MediaQuery.of(context).size;
    final short = size.shortestSide;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(flex: 2),
        Text(
          '${l10n.endNumber} $currentEnd',
          style: GoogleFonts.barlowSemiCondensed(
            textStyle: TextStyle(
              fontSize: short * 0.08,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.5),
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.competitionReady,
          style: GoogleFonts.barlowSemiCondensed(
            textStyle: TextStyle(
              fontSize: short * 0.12,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$currentEnd / $totalEnds',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),
        const Spacer(flex: 2),
        GestureDetector(
          onTap: onStart,
          child: Container(
            width: short * 0.4,
            height: short * 0.4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.timerGreen,
              boxShadow: [
                BoxShadow(
                  color: AppColors.timerGreen.withValues(alpha: 0.4),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              Icons.play_arrow_rounded,
              size: short * 0.2,
              color: Colors.white,
            ),
          ),
        ),
        const Spacer(flex: 3),
      ],
    );
  }

  Widget _buildPreparationView(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final size = MediaQuery.of(context).size;
    final short = size.shortestSide;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(flex: 2),
        Text(
          l10n.competitionGetReady,
          style: GoogleFonts.barlowSemiCondensed(
            textStyle: TextStyle(
              fontSize: short * 0.06,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.7),
              letterSpacing: 1.4,
            ),
          ),
        ),
        const Spacer(),
        GestureDetector(
          onLongPress: onPause,
          child: Text(
            '$remainingSeconds',
            style: GoogleFonts.robotoMono(
              textStyle: TextStyle(
                fontSize: short * 0.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -1.0,
                height: 1,
              ),
            ),
          ),
        ),
        const Spacer(),
        Text(
          l10n.competitionDoNotRaiseBow,
          style: GoogleFonts.barlowSemiCondensed(
            textStyle: TextStyle(
              fontSize: short * 0.04,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.6),
              letterSpacing: 0.6,
            ),
          ),
        ),
        const SizedBox(height: 14),
        TextButton.icon(
          onPressed: onSkip,
          icon: const Icon(Icons.skip_next_rounded, color: Colors.white70),
          label: Text(
            l10n.competitionSkip,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),
        const Spacer(flex: 2),
      ],
    );
  }

  Widget _buildShootingView(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final size = MediaQuery.of(context).size;
    final short = size.shortestSide;
    final dialSize = short * 0.68;
    final ringSize = dialSize * 0.92;
    final timeBoxWidth = ringSize * 0.62;
    final timeBoxHeight = ringSize * 0.46;
    final ringStroke = (ringSize * 0.03).clamp(6.0, 10.0).toDouble();
    final isWarning = phase == CompetitionPhase.warning;
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    final timeText = remainingSeconds > 60
        ? '$minutes:${seconds.toString().padLeft(2, '0')}'
        : '$remainingSeconds';
    final progress =
        totalShootingTime > 0 ? remainingSeconds / totalShootingTime : 0.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        Text(
          isWarning ? l10n.competitionHurryUp : l10n.competitionShoot,
          style: GoogleFonts.barlowSemiCondensed(
            textStyle: TextStyle(
              fontSize: short * 0.055,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.7),
              letterSpacing: 1.2,
            ),
          ),
        ),
        const Spacer(),
        GestureDetector(
          onLongPress: onPause,
          child: SizedBox(
            width: dialSize,
            height: dialSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: ringSize,
                  height: ringSize,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: ringStroke,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                SizedBox(
                  width: timeBoxWidth,
                  height: timeBoxHeight,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Text(
                      timeText,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.robotoMono(
                        textStyle: const TextStyle(
                          fontSize: 200,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -2.2,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: onSkip,
          icon: const Icon(Icons.skip_next_rounded, color: Colors.white70),
          label: Text(
            l10n.competitionSkip,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildTimesUpView(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final size = MediaQuery.of(context).size;
    final short = size.shortestSide;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.front_hand_rounded,
          size: short * 0.2,
          color: Colors.white.withValues(alpha: 0.8),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.competitionStop,
          style: GoogleFonts.barlowSemiCondensed(
            textStyle: TextStyle(
              fontSize: short * 0.18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 1.0,
            ),
          ),
        ),
        Text(
          l10n.competitionShooting,
          style: GoogleFonts.barlowSemiCondensed(
            textStyle: TextStyle(
              fontSize: short * 0.1,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.7),
              letterSpacing: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}
