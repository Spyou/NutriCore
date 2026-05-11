import 'package:flutter/material.dart';

class AnimatedAuthField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData leadingIcon;
  final bool obscure;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool showEyeToggle;
  final String? autofillHint;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;
  final bool autofocus;

  const AnimatedAuthField({
    super.key,
    required this.controller,
    required this.hint,
    required this.leadingIcon,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.showEyeToggle = false,
    this.autofillHint,
    this.textInputAction,
    this.onSubmitted,
    this.autofocus = false,
  });

  @override
  State<AnimatedAuthField> createState() => AnimatedAuthFieldState();
}

class AnimatedAuthFieldState extends State<AnimatedAuthField>
    with SingleTickerProviderStateMixin {
  final FocusNode _focusNode = FocusNode();
  late final AnimationController _shake;
  bool _obscure = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscure;
    _focusNode.addListener(() => setState(() {}));
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _shake.dispose();
    super.dispose();
  }

  void focus() => _focusNode.requestFocus();

  void clearError() {
    if (_errorText != null) setState(() => _errorText = null);
  }

  bool validateAndShake() {
    final err = widget.validator?.call(widget.controller.text);
    setState(() => _errorText = err);
    if (err != null) {
      _shake.forward(from: 0);
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isFocused = _focusNode.hasFocus;
    final hasError = _errorText != null;

    final fill = hasError
        ? scheme.errorContainer.withValues(alpha: 0.25)
        : isFocused
            ? scheme.primaryContainer.withValues(alpha: 0.22)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.55);

    final iconColor = hasError
        ? scheme.error
        : isFocused
            ? scheme.primary
            : scheme.primary.withValues(alpha: 0.7);

    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) {
        final t = _shake.value;
        final dx = t == 0
            ? 0.0
            : 8 *
                (1 - t) *
                (t < 0.2
                    ? -1
                    : t < 0.4
                        ? 1
                        : t < 0.6
                            ? -1
                            : t < 0.8
                                ? 1
                                : 0);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            height: 58,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasError
                    ? scheme.error
                    : isFocused
                        ? scheme.primary
                        : Colors.transparent,
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(widget.leadingIcon, size: 20, color: iconColor),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    obscureText: _obscure,
                    keyboardType: widget.keyboardType,
                    textInputAction: widget.textInputAction,
                    onFieldSubmitted: widget.onSubmitted,
                    autofocus: widget.autofocus,
                    autofillHints: widget.autofillHint != null
                        ? [widget.autofillHint!]
                        : null,
                    onChanged: (v) {
                      if (_errorText != null) setState(() => _errorText = null);
                      widget.onChanged?.call(v);
                    },
                    cursorColor: scheme.primary,
                    cursorWidth: 2,
                    style: TextStyle(
                      fontSize: 15,
                      color: scheme.onSurface,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      filled: false,
                      fillColor: Colors.transparent,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      hintText: widget.hint,
                      hintStyle: TextStyle(
                        color: scheme.onSurface.withValues(alpha: 0.45),
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
                if (widget.showEyeToggle)
                  GestureDetector(
                    onTap: () => setState(() => _obscure = !_obscure),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 19,
                        color: _obscure
                            ? scheme.onSurface.withValues(alpha: 0.45)
                            : scheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (hasError)
            Padding(
              padding: const EdgeInsets.only(left: 6, top: 6),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded,
                      size: 13, color: scheme.error),
                  const SizedBox(width: 4),
                  Text(
                    _errorText!,
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.error,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
