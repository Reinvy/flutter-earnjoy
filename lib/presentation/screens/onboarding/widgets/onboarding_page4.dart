import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:earnjoy/core/theme.dart';
import 'package:earnjoy/core/widgets/gradient_button.dart';

class _TimeSlot {
  final String label;
  final String range;
  final String emoji;
  final int hour; // representative starting hour
  const _TimeSlot(this.label, this.range, this.emoji, this.hour);
}

const _slots = [
  _TimeSlot('Pagi', '06:00–10:00', '🌅', 6),
  _TimeSlot('Siang', '10:00–14:00', '☀️', 10),
  _TimeSlot('Sore', '14:00–18:00', '🌤️', 14),
  _TimeSlot('Malam', '18:00–22:00', '🌙', 18),
];

/// Page 4 — Preferred active hours selection for smart notification scheduling.
class OnboardingPage4 extends StatelessWidget {
  final int selectedSlotIndex; // -1 = none selected
  final ValueChanged<int> onSlotSelected;
  final VoidCallback onNext;

  const OnboardingPage4({
    super.key,
    required this.selectedSlotIndex,
    required this.onSlotSelected,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xl),

          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                gradient: AppGradients.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_active_outlined, color: Colors.white, size: 36),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          const Center(child: Text('Kapan kamu paling\naktif?', style: AppText.displaySmall, textAlign: TextAlign.center)),
          const SizedBox(height: AppSpacing.xs),
          const Center(
            child: Text(
              'Ini digunakan untuk mengirim reminder\ndi waktu yang paling relevan.',
              style: AppText.body,
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: AppSpacing.sectionGap),

          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              childAspectRatio: 1.4,
              children: List.generate(_slots.length, (i) {
                final slot = _slots[i];
                final isSelected = selectedSlotIndex == i;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onSlotSelected(i);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      gradient: isSelected ? AppGradients.primary : null,
                      color: isSelected ? null : AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: isSelected ? Colors.transparent : AppColors.glassBorder,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(slot.emoji, style: const TextStyle(fontSize: 32)),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          slot.label,
                          style: AppText.title.copyWith(
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          slot.range,
                          style: AppText.caption.copyWith(
                            color: isSelected ? Colors.white70 : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: AppSpacing.sectionGap),

          GradientButton(
            label: 'Lanjut',
            icon: Icons.arrow_forward_rounded,
            onTap: selectedSlotIndex >= 0 ? onNext : null,
          ),

          Center(
            child: TextButton(
              onPressed: onNext,
              child: const Text(
                'Lewati',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

/// Returns the representative hour for slot index [i], or -1 if none.
int activeHourFromSlotIndex(int slotIndex) {
  if (slotIndex < 0 || slotIndex >= _slots.length) return -1;
  return _slots[slotIndex].hour;
}
