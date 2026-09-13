// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:mazilon/util/styles.dart';

class NotificationToggleCard extends StatefulWidget {
  static const TimeOfDay defaultReminderTime = TimeOfDay(hour: 8, minute: 30);

  final String emoji;
  final String badgeText;
  final String title;
  final String subtitle;
  final String setTimeLabel;
  final Future<bool> Function(bool value)? onToggle;
  final Future<bool> Function(TimeOfDay value)? onTimeSelected;
  final TimeOfDay? initialTime;
  final bool initialEnabled;

  const NotificationToggleCard({
    super.key,
    required this.emoji,
    required this.badgeText,
    required this.title,
    required this.subtitle,
    required this.setTimeLabel,
    this.onToggle,
    this.onTimeSelected,
    this.initialTime,
    this.initialEnabled = false,
  });

  @override
  State<NotificationToggleCard> createState() => _NotificationToggleCardState();
}

class _NotificationToggleCardState extends State<NotificationToggleCard> {
  bool _isEnabled = false;
  bool _isMutating = false;
  bool _hasDeferredWidgetUpdate = false;
  late TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _isEnabled = widget.initialEnabled;
    _selectedTime = widget.initialTime;
  }

  void _syncFromWidget() {
    _isEnabled = widget.initialEnabled;
    _selectedTime = widget.initialTime;
  }

  @override
  void didUpdateWidget(covariant NotificationToggleCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isMutating) {
      _hasDeferredWidgetUpdate =
          _hasDeferredWidgetUpdate ||
          widget.initialEnabled != oldWidget.initialEnabled ||
          widget.initialTime != oldWidget.initialTime;
      return;
    }
    _syncFromWidget();
  }

  Future<void> _toggleEnabled() async {
    if (_isMutating) return;
    final requestedValue = !_isEnabled;
    setState(() => _isMutating = true);
    var applied = true;
    try {
      applied =
          await (widget.onToggle?.call(requestedValue) ??
              Future<bool>.value(true));
    } catch (_) {
      applied = false;
    }
    if (!mounted) return;
    setState(() {
      _isMutating = false;
      if (_hasDeferredWidgetUpdate) {
        _hasDeferredWidgetUpdate = false;
        _syncFromWidget();
      } else if (applied) {
        _isEnabled = requestedValue;
        if (!requestedValue) {
          _selectedTime = NotificationToggleCard.defaultReminderTime;
        }
      }
    });
  }

  Future<void> _selectTime() async {
    if (_isMutating) return;
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked == null || !mounted) return;

    setState(() => _isMutating = true);
    var applied = true;
    try {
      applied =
          await (widget.onTimeSelected?.call(picked) ??
              Future<bool>.value(true));
    } catch (_) {
      applied = false;
    }
    if (!mounted) return;
    setState(() {
      _isMutating = false;
      if (_hasDeferredWidgetUpdate) {
        _hasDeferredWidgetUpdate = false;
        _syncFromWidget();
      } else if (applied) {
        _selectedTime = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheduleLabelStyle = TextStyle(
      color: Theme.of(context).colorScheme.primary,
      fontSize: 12,
      fontWeight: FontWeight.bold,
    );
    return Container(
      alignment: Alignment.center,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.emoji),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: myText(
                          widget.badgeText,
                          TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                          TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 8),
                      myText(
                        widget.title,
                        TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                        TextAlign.start,
                      ),
                    ],
                  ),
                  myText(
                    widget.subtitle,
                    TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                    TextAlign.start,
                  ),
                  if (_isEnabled)
                    GestureDetector(
                      onTap: _isMutating ? null : _selectTime,
                      child: Row(
                        children: [
                          if (_selectedTime != null)
                            Icon(
                              Icons.access_time,
                              size: 12,
                              color: scheduleLabelStyle.color,
                            ),
                          Text(
                            _selectedTime?.format(context) ??
                                widget.setTimeLabel,
                            style: scheduleLabelStyle,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            GestureDetector(
              onTap: _isMutating ? null : _toggleEnabled,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 250),
                width: 55,
                height: 30,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: _isEnabled
                      ? LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.secondary,
                          ],
                        )
                      : null,
                  color: _isEnabled
                      ? null
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: AnimatedAlign(
                  duration: Duration(milliseconds: 250),
                  alignment: _isEnabled
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: _isMutating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Container(
                          width: 22,
                          height: 22,
                          margin: EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.onPrimary,
                            shape: BoxShape.circle,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
