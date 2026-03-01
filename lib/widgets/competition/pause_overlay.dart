import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';

class PauseOverlay extends StatelessWidget {
  final int remainingSeconds;
  final VoidCallback onResume;
  final VoidCallback onReset;

  const PauseOverlay({
    super.key,
    required this.remainingSeconds,
    required this.onResume,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),
            const Icon(
              Icons.pause_circle_outline_rounded,
              size: 80,
              color: Colors.white54,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.competitionPaused,
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.competitionSafetyHalt,
              style: const TextStyle(fontSize: 16, color: Colors.white54),
            ),
            const SizedBox(height: 32),
            Text(
              l10n.competitionRemainingTime(remainingSeconds),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white70,
              ),
            ),
            const Spacer(flex: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: onResume,
                  icon: const Icon(Icons.play_arrow_rounded, size: 28),
                  label: Text(
                    l10n.competitionResume,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.timerGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmReset(context),
                  icon: const Icon(Icons.refresh_rounded, size: 24),
                  label: Text(
                    l10n.competitionResetEnd,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.timerRed,
                    side: const BorderSide(color: AppColors.timerRed, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.competitionResetEndTitle),
        content: Text(l10n.competitionResetEndMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onReset();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.timerRed),
            child: Text(l10n.reset),
          ),
        ],
      ),
    );
  }
}
