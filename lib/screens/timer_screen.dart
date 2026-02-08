import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../providers/timer_provider.dart';

class TimerScreen extends StatelessWidget {
  const TimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final timerProvider = Provider.of<TimerProvider>(context);
    final theme = Theme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Mode Selector
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ModeButton(
              title: 'Focus',
              isSelected: timerProvider.mode == TimerMode.work,
              onTap: () => timerProvider.switchMode(TimerMode.work),
            ),
            const SizedBox(width: 10),
            _ModeButton(
              title: 'Short Break',
              isSelected: timerProvider.mode == TimerMode.shortBreak,
              onTap: () => timerProvider.switchMode(TimerMode.shortBreak),
            ),
            const SizedBox(width: 10),
            _ModeButton(
              title: 'Long Break',
              isSelected: timerProvider.mode == TimerMode.longBreak,
              onTap: () => timerProvider.switchMode(TimerMode.longBreak),
            ),
          ],
        ),
        const SizedBox(height: 50),

        // Circular Timer
        CircularPercentIndicator(
          radius: 140.0,
          lineWidth: 15.0,
          percent: timerProvider.progress,
          center: timerProvider.status == TimerStatus.initial
              ? SizedBox(
                  height: 120,
                  width: 200, // Widened for two wheels
                  child: _TimePicker(
                    minutes: timerProvider.remainingTime ~/ 60,
                    seconds: timerProvider.remainingTime % 60,
                    onChanged: (m, s) => timerProvider.setDuration(m, s),
                  ),
                )
              : Text(
                  timerProvider.timeString,
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
          progressColor: theme.colorScheme.primary,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          circularStrokeCap: CircularStrokeCap.round,
          animation: true,
          animateFromLastPercent: true,
          animationDuration: 1000, // Smooth transition
        ),
        const SizedBox(height: 50),

        // Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (timerProvider.status == TimerStatus.running)
              FloatingActionButton.large(
                heroTag: "timer_pause",
                onPressed: timerProvider.isStrictMode
                    ? null
                    : timerProvider.pauseTimer, // Disable pause in strict mode
                backgroundColor: timerProvider.isStrictMode
                    ? Colors.grey
                    : theme.colorScheme.secondary,
                child: const Icon(Icons.pause, size: 40),
              )
            else
              FloatingActionButton.large(
                heroTag: "timer_start",
                onPressed: timerProvider.startTimer,
                backgroundColor: theme.colorScheme.primary,
                child: const Icon(
                  Icons.play_arrow,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            const SizedBox(width: 20),
            FloatingActionButton(
              heroTag: "timer_stop",
              onPressed: () {
                if (timerProvider.isStrictMode &&
                    timerProvider.status == TimerStatus.running) {
                  // Strict Mode Give Up Dialog
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Give Up?"),
                      content: const Text(
                        "Your tree will wither if you give up now!",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text("Keep Focusing"),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            timerProvider.stopTimer();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text("I Give Up"),
                        ),
                      ],
                    ),
                  );
                } else {
                  timerProvider.stopTimer();
                }
              },
              backgroundColor: theme.colorScheme.error,
              child: const Icon(Icons.stop, color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 30),

        // Strict Mode Toggle
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Switch(
              value: timerProvider.isStrictMode,
              onChanged: timerProvider.status == TimerStatus.initial
                  ? (val) => timerProvider.toggleStrictMode(val)
                  : null, // Disable toggle while running
            ),
            const Text("Strict Mode"),
            if (timerProvider.isStrictMode)
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Icon(Icons.lock, size: 16, color: Colors.grey),
              ),
          ],
        ),

        const SizedBox(height: 20),
        Text(
          'Completed Pomodoros: ${timerProvider.completedPomodoros}',
          style: theme.textTheme.titleMedium,
        ),
      ],
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected
            ? theme.colorScheme.primary.withAlpha(25)
            : null,
        side: BorderSide(
          color: isSelected ? theme.colorScheme.primary : Colors.grey,
          width: 2,
        ),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.textTheme.bodyMedium?.color,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

class _TimePicker extends StatefulWidget {
  final int minutes;
  final int seconds;
  final Function(int, int) onChanged;

  const _TimePicker({
    required this.minutes,
    required this.seconds,
    required this.onChanged,
  });

  @override
  State<_TimePicker> createState() => _TimePickerState();
}

class _TimePickerState extends State<_TimePicker> {
  late FixedExtentScrollController _minutesController;
  late FixedExtentScrollController _secondsController;
  bool _isProgrammaticUpdate = false;

  @override
  void initState() {
    super.initState();
    _minutesController = FixedExtentScrollController(
      initialItem: widget.minutes,
    );
    _secondsController = FixedExtentScrollController(
      initialItem: widget.seconds,
    );
  }

  @override
  void didUpdateWidget(_TimePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync controllers if external state changed drastically (e.g. mode switch)
    // We check if the controller's item matches the widget's value.
    if (_minutesController.hasClients &&
        _minutesController.selectedItem != widget.minutes) {
      _isProgrammaticUpdate = true;
      _minutesController.jumpToItem(widget.minutes);
      _isProgrammaticUpdate = false;
    }
    if (_secondsController.hasClients &&
        _secondsController.selectedItem != widget.seconds) {
      _isProgrammaticUpdate = true;
      _secondsController.jumpToItem(widget.seconds);
      _isProgrammaticUpdate = false;
    }
  }

  @override
  void dispose() {
    _minutesController.dispose();
    _secondsController.dispose();
    super.dispose();
  }

  void _notifyChange() {
    if (_isProgrammaticUpdate) return;
    if (!_minutesController.hasClients || !_secondsController.hasClients)
      return;

    final m = _minutesController.selectedItem;
    final s = _secondsController.selectedItem;
    widget.onChanged(m, s);
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Minutes
        SizedBox(
          width: 70,
          child: _buildWheel(
            controller: _minutesController,
            count: 120,
            label: "m",
            selectedValue: widget.minutes,
          ),
        ),
        const Text(
          ":",
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        // Seconds
        SizedBox(
          width: 70,
          child: _buildWheel(
            controller: _secondsController,
            count: 60,
            label: "s",
            selectedValue: widget.seconds,
          ),
        ),
      ],
    );
  }

  Widget _buildWheel({
    required FixedExtentScrollController controller,
    required int count,
    required String label,
    required int selectedValue,
  }) {
    final theme = Theme.of(context);
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: 50,
      perspective: 0.005,
      diameterRatio: 1.2,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: (_) => _notifyChange(),
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: count,
        builder: (context, index) {
          final isSelected = index == selectedValue;
          return Center(
            child: Text(
              index.toString().padLeft(2, '0'),
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? theme.colorScheme.primary : Colors.grey,
                fontSize: 32,
              ),
            ),
          );
        },
      ),
    );
  }
}
