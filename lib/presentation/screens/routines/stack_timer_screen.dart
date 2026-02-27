import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:earnjoy/core/theme.dart';
import 'package:earnjoy/data/models/habit_stack.dart';
import 'package:earnjoy/presentation/providers/habit_stack_provider.dart';

class StackTimerScreen extends StatefulWidget {
  final HabitStack stack;

  const StackTimerScreen({super.key, required this.stack});

  @override
  State<StackTimerScreen> createState() => _StackTimerScreenState();
}

class _StackTimerScreenState extends State<StackTimerScreen> {
  Timer? _timer;
  int _secondsRemaining = 0;
  bool _isRunning = false;
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HabitStackProvider>().startStack(widget.stack);
      _setupTimerForCurrentItem();
      setState(() {
        _isInit = true;
      });
    });
  }

  void _setupTimerForCurrentItem() {
    final provider = context.read<HabitStackProvider>();
    final currentItem = provider.currentActiveItem;
    if (currentItem != null) {
      setState(() {
        // For testing we could use seconds instead of minutes
        // _secondsRemaining = currentItem.durationMinutes; 
        _secondsRemaining = currentItem.durationMinutes * 60;
        _isRunning = false;
      });
      _timer?.cancel();
    }
  }

  void _startTimer() {
    if (_isRunning) return;
    setState(() => _isRunning = true);
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _completeItem();
      }
    });
  }

  void _pauseTimer() {
    setState(() => _isRunning = false);
    _timer?.cancel();
  }

  void _completeItem() {
    _timer?.cancel();
    
    final provider = context.read<HabitStackProvider>();
    provider.completeCurrentItem();
    
    if (provider.activeStack == null) {
      // Stack is finished
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Routine ${widget.stack.name} finished! Earned +${widget.stack.bonusPoints} points.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } else {
      // Setup for next item
      _setupTimerForCurrentItem();
    }
  }

  void _cancelStack() {
    context.read<HabitStackProvider>().cancelStack();
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _formattedTime {
    int minutes = _secondsRemaining ~/ 60;
    int seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInit) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _cancelStack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.stack.name),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _cancelStack,
          ),
        ),
        body: Consumer<HabitStackProvider>(
          builder: (context, provider, child) {
            final currentItem = provider.currentActiveItem;

            if (currentItem == null) {
              return const Center(child: Text('Routine Finished!'));
            }

            final progress = (provider.activeItemIndex) / widget.stack.items.length;

            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.surface,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Step ${provider.activeItemIndex + 1} of ${widget.stack.items.length}',
                    style: const TextStyle(color: AppColors.textDisabled),
                  ),
                  const SizedBox(height: 32),
                  
                  // Big Timer Circle
                  Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isRunning ? AppColors.primary : AppColors.surfaceHigh,
                        width: 8,
                      ),
                      color: AppColors.surface,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            IconData(
                              int.parse(currentItem.category.target?.icon ?? 'e871', radix: 16),
                              fontFamily: 'MaterialIcons',
                            ),
                            size: 48,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _formattedTime,
                            style: const TextStyle(
                              fontSize: 64,
                              fontWeight: FontWeight.w300,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            currentItem.activityTitle,
                            style: Theme.of(context).textTheme.titleLarge,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      FloatingActionButton.large(
                        onPressed: _isRunning ? _pauseTimer : _startTimer,
                        backgroundColor: _isRunning ? AppColors.warning : AppColors.primary,
                        child: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                      ),
                      FloatingActionButton.large(
                        onPressed: _completeItem,
                        backgroundColor: AppColors.success,
                        child: const Icon(Icons.check),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
