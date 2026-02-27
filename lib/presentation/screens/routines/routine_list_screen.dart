import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:earnjoy/core/theme.dart';
import 'package:earnjoy/presentation/providers/habit_stack_provider.dart';
import 'package:earnjoy/data/models/habit_stack.dart';
import 'package:earnjoy/presentation/screens/routines/stack_timer_screen.dart';

class RoutineListScreen extends StatelessWidget {
  const RoutineListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Routines'),
        centerTitle: false,
      ),
      body: Consumer<HabitStackProvider>(
        builder: (context, provider, child) {
          final stacks = provider.habitStacks;

          if (stacks.isEmpty) {
            return const Center(child: Text('No Routines yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: stacks.length,
            itemBuilder: (context, index) {
              final stack = stacks[index];
              return _RoutineCard(stack: stack);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Open Custom Builder
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Custom Stack Builder coming soon!')),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Routine'),
      ),
    );
  }
}

class _RoutineCard extends StatelessWidget {
  final HabitStack stack;

  const _RoutineCard({required this.stack});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: AppColors.surfaceHigh,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StackTimerScreen(stack: stack),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Expanded(
                    child: Text(
                      stack.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  if (stack.bonusPoints > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.bolt, size: 16, color: AppColors.primary),
                          Text(
                            '+${stack.bonusPoints}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                stack.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 16),
              // Items preview
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: stack.items.take(3).map((item) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: Text(
                      '${item.activityTitle} (${item.durationMinutes}m)',
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                }).toList(),
              ),
              if (stack.items.length > 3) ...[
                const SizedBox(height: 8),
                Text(
                  '+ ${stack.items.length - 3} more',
                  style: const TextStyle(fontSize: 12, color: AppColors.textDisabled),
                )
              ]
            ],
          ),
        ),
      ),
    );
  }
}
