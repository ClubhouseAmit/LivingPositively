import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/features/personal_plan/ui/my_plan_section.dart';
import 'package:mazilon/util/async/logger_service.dart';
import 'package:mazilon/util/async/persistent_memory_service.dart';
import 'package:mazilon/util/userInformation.dart';

/// Renders custom Personal Plan categories from the selected persistence source.
class PersonalPlanCustomCategoriesSection extends StatefulWidget {
  const PersonalPlanCustomCategoriesSection({
    required this.userInformation,
    this.memoryService,
    super.key,
  });

  final UserInformation userInformation;
  final PersistentMemoryService? memoryService;

  @override
  State<PersonalPlanCustomCategoriesSection> createState() =>
      _PersonalPlanCustomCategoriesSectionState();
}

class _PersonalPlanCustomCategoriesSectionState
    extends State<PersonalPlanCustomCategoriesSection> {
  List<MapEntry<String, String>> _alternateCategories = const [];
  int _loadGeneration = 0;

  bool get _usesAlternateSource =>
      widget.memoryService != null &&
      !identical(widget.memoryService, widget.userInformation.service);

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(PersonalPlanCustomCategoriesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.memoryService, widget.memoryService) ||
        !identical(oldWidget.userInformation, widget.userInformation)) {
      _alternateCategories = const [];
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    final generation = ++_loadGeneration;
    final source = widget.memoryService ?? widget.userInformation.service;
    try {
      final categories = await widget.userInformation.loadCustomCategories(
        memoryService: source,
      );
      if (!mounted || generation != _loadGeneration) return;
      if (_usesAlternateSource) {
        setState(() {
          _alternateCategories = categories;
        });
      }
    } catch (error, stackTrace) {
      if (!GetIt.instance.isRegistered<IncidentLoggerService>()) return;
      try {
        await GetIt.instance<IncidentLoggerService>().captureLog(
          error,
          stackTrace: stackTrace,
        );
      } catch (_) {
        // Loading and diagnostic reporting are best effort during startup.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = _usesAlternateSource
        ? _alternateCategories
        : widget.userInformation.customCategories;
    return Column(
      children: [
        for (final category in categories)
          MyPlanSection(
            title: category.key,
            subTitle: '',
            answers: [category.value],
          ),
      ],
    );
  }
}
