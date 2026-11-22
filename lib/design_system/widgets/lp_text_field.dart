import 'package:flutter/widgets.dart' hide Text;

import 'package:mazilon/design_system/tokens/color_tokens.dart';
import 'package:mazilon/design_system/tokens/spacing.dart';
import 'package:mazilon/design_system/tokens/type_scale.dart';
import 'package:mazilon/design_system/widgets/text.dart';

part 'lp_text_field_looks.dart';

/// [LpTextField.line] sizes: Figma `text field`'s `sub header` switch.
enum LpTextFieldSize {
  /// 16 text under a hairline separator (`sub header=false`).
  m,

  /// 14 text, no separator (`sub header=true`): the subtitle under an [m]
  /// line, as in Figma `text field list`.
  s,
}

enum _Family { box, line }

/// The LP-DS text field. One widget for the two Figma text-entry components,
/// the way `LpButton` covers `Button-primary` and `Button-icon`:
///
/// - `LpTextField(...)`: `Input Field` (68:2106). A filled box whose [label]
///   sits inside it while empty and moves above the value once focused or
///   filled, an optional end [icon], and [errorText] under it.
/// - `LpTextField.line(...)`: `text field` (111:910). Bare text on a line,
///   the building block of `text field list` and the `List` typing bar
///   (#450), with an optional clear button while typing.
///
/// Focused, filled, error and disabled are state, not variants. Built on
/// `EditableText`, with no Material (AGENTS.md 0.15).
class LpTextField extends StatefulWidget {
  const LpTextField({
    super.key,
    required String this.label,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.icon,
    this.errorText,
    this.enabled = true,
    this.obscureText = false,
    this.keyboardType,
  }) : _family = _Family.box,
       placeholder = null,
       size = LpTextFieldSize.m,
       clearIcon = null,
       clearLabel = null;

  const LpTextField.line({
    super.key,
    required String this.placeholder,
    this.size = LpTextFieldSize.m,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.clearIcon,
    this.clearLabel,
    this.enabled = true,
    this.keyboardType,
  }) : _family = _Family.line,
       label = null,
       icon = null,
       errorText = null,
       obscureText = false;

  // Block-bodied and right after the constructors: check_guidelines' text
  // scan reads an initializer list as open until the next `  }` line.
  @override
  State<LpTextField> createState() {
    return _LpTextFieldState();
  }

  final _Family _family;

  /// The box field's name, also what a screen reader announces. Null only
  /// for [LpTextField.line].
  final String? label;

  /// The line field's hint while empty, also what a screen reader
  /// announces. Null only for the box field.
  final String? placeholder;

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;

  /// Box field only: a decorative icon at the end. Figma swaps the icon.
  final IconData? icon;

  /// Box field only: non-null draws the error look and shows this under it.
  final String? errorText;

  final bool enabled;
  final bool obscureText;
  final TextInputType? keyboardType;

  final LpTextFieldSize size;

  /// Line field only: the clear button's icon (Figma XCircle). Null: no
  /// button. It shows while the field is focused and not empty.
  final IconData? clearIcon;

  /// What a screen reader announces for the clear button. Required with
  /// [clearIcon]; release builds fall back to [placeholder].
  final String? clearLabel;

  // Figma measurements, owned here like ListRow's.
  static const radius = 18.0;
  static const boxHeight = 56.0;
  static const lineHeight = 33.0;
  static const subLineHeight = 24.0;
  static const iconSize = 24.0;
}

class _LpTextFieldState extends State<LpTextField>
    implements TextSelectionGestureDetectorBuilderDelegate {
  // Read on every use, like Flutter's TextField, so a parent can swap them.
  TextEditingController? _ownedController;
  FocusNode? _ownedFocus;
  TextEditingController get _controller =>
      widget.controller ?? (_ownedController ??= TextEditingController());
  FocusNode get _focus => widget.focusNode ?? (_ownedFocus ??= FocusNode());

  // Tap to place the caret, double tap to select a word, as in any text
  // field. shortcut: no copy/paste menu or selection handles (those are
  // Material/Cupertino); add a widgets-only toolbar if a screen needs it.
  late final TextSelectionGestureDetectorBuilder _gestures =
      TextSelectionGestureDetectorBuilder(delegate: this);

  @override
  final GlobalKey<EditableTextState> editableTextKey =
      GlobalKey<EditableTextState>();

  @override
  bool get forcePressEnabled => false;

  @override
  bool get selectionEnabled => widget.enabled;

  @override
  void didUpdateWidget(LpTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The parent stopped passing a controller: keep its text in ours.
    final TextEditingController? old = oldWidget.controller;
    if (old != null && widget.controller == null) {
      _ownedController?.dispose();
      _ownedController = TextEditingController.fromValue(old.value);
    }
  }

  @override
  void dispose() {
    _ownedController?.dispose();
    _ownedFocus?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_controller, _focus]),
      builder: _face,
    );
  }

  Widget _face(BuildContext context, Widget? child) {
    // Not in the initializer: check_guidelines misreads asserts there.
    assert(
      widget.clearIcon == null || widget.clearLabel != null,
      'a clear button needs clearLabel for screen readers',
    );
    final AppColorTokens colors = context.colors;
    return switch (widget._family) {
      _Family.box => _box(colors),
      _Family.line => _line(colors),
    };
  }

  bool get _empty => _controller.text.isEmpty;

  Widget _interactive(Widget child) {
    return IgnorePointer(
      ignoring: !widget.enabled,
      child: _gestures.buildGestureDetector(
        behavior: HitTestBehavior.translucent,
        child: child,
      ),
    );
  }

  Widget _editor(TextStyle style, Color color, [Color? cursor]) {
    return Semantics(
      label: widget.label ?? widget.placeholder,
      child: EditableText(
        key: editableTextKey,
        controller: _controller,
        focusNode: _focus,
        readOnly: !widget.enabled,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType ?? TextInputType.text,
        style: style.copyWith(
          color: color,
          fontFamily: AppTypeScale.familyFor(
            Localizations.maybeLocaleOf(context),
          ),
        ),
        cursorColor: cursor ?? color,
        backgroundCursorColor: context.colors.contentTertiary,
        selectionColor: _selectionColor(context.colors),
        onChanged: widget.onChanged,
        maxLines: 1,
        rendererIgnoresPointer: true, // taps come from _gestures
      ),
    );
  }

  Widget _box(AppColorTokens colors) {
    final _BoxLook look = _boxLook(colors);
    final Widget box = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: LpTextField.boxHeight),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: look.fill,
          border: Border.all(color: look.border),
          borderRadius: BorderRadius.circular(LpTextField.radius),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Expanded(child: _boxText(look)),
              if (widget.icon != null)
                ExcludeSemantics(
                  child: Icon(
                    widget.icon,
                    size: LpTextField.iconSize,
                    color: look.icon,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _interactive(box),
        if (widget.errorText != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(
              top: AppSpacing.sm,
              start: AppSpacing.lg,
            ),
            child: Semantics(
              liveRegion: true,
              child: Text(
                widget.errorText!,
                style: AppTextStyle.labelSmall,
                color: colors.statusDanger,
                textAlign: TextAlign.start,
              ),
            ),
          ),
      ],
    );
  }

  /// The label inside the box while idle, above the value once focused or
  /// filled. The editor never moves, so focus and the keyboard survive.
  Widget _boxText(_BoxLook look) {
    final bool floating = _focus.hasFocus || !_empty;
    return Stack(
      alignment: AlignmentDirectional.centerStart,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ExcludeSemantics(
              child: floating
                  ? Text(
                      widget.label!,
                      style: AppTextStyle.labelSmall,
                      color: look.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  : const SizedBox.shrink(),
            ),
            _editor(AppTypeScale.captionBase, look.value, look.cursor),
          ],
        ),
        if (!floating)
          ExcludeSemantics(
            child: Text(
              widget.label!,
              style: AppTextStyle.figmaBodyLarge,
              color: look.idleLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  Widget _line(AppColorTokens colors) {
    final bool m = widget.size == LpTextFieldSize.m;
    final bool showClear =
        widget.clearIcon != null && _focus.hasFocus && !_empty;
    final Widget row = ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: m ? LpTextField.lineHeight : LpTextField.subLineHeight,
      ),
      child: Row(
        children: [
          Expanded(
            child: Stack(
              alignment: AlignmentDirectional.centerStart,
              children: [
                _editor(
                  // Cursor: content/primary, agreed with design (2026-11).
                  m ? AppTypeScale.bodyBase : AppTypeScale.bodyXSmall,
                  widget.enabled
                      ? colors.contentPrimary
                      : colors.contentTertiary,
                ),
                if (_empty)
                  ExcludeSemantics(
                    child: Text(
                      widget.placeholder!,
                      style: m
                          ? AppTextStyle.bodyLarge
                          : AppTextStyle.bodySmall,
                      color: colors.contentTertiary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          if (showClear) ...[
            const SizedBox(width: AppSpacing.lg),
            _clearButton(colors),
          ],
        ],
      ),
    );
    if (!m) {
      return _interactive(row);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: AppSpacing.hairline,
          child: ColoredBox(color: colors.effectHairline),
        ),
        const SizedBox(height: AppSpacing.xs),
        _interactive(row),
      ],
    );
  }

  /// Figma's own size, 24, with no extra tap area, like LpCheckbox (WCAG
  /// 2.2 AA's 24px minimum).
  Widget _clearButton(AppColorTokens colors) {
    return Semantics(
      button: true,
      // Release builds skip the assert; never crash on it.
      label: widget.clearLabel ?? widget.placeholder,
      onTap: _clear,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _clear,
        child: Icon(
          widget.clearIcon,
          size: LpTextField.iconSize,
          color: colors.contentTertiary,
        ),
      ),
    );
  }

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
  }
}
