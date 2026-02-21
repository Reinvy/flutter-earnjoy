import 'package:flutter/material.dart';
import '../../core/theme.dart';

class RewardScreen extends StatelessWidget {
  const RewardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: const SafeArea(
        child: Center(child: Text('Rewards', style: AppText.displaySmall)),
      ),
    );
  }
}
