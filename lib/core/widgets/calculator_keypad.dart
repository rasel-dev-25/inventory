import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../design/tokens.dart';
import '../utils/calculator_evaluator.dart';

/// Applies a calculator key press (e.g. `'7'`, `'+'`, `'AC'`, `'='`, `'⌫'`) directly to a [TextEditingController].
void applyCalculatorKeyToController(TextEditingController controller, String key) {
  HapticFeedback.lightImpact();
  var text = controller.text;

  if (key == 'AC') {
    controller.text = '';
  } else if (key == '⌫') {
    if (text.isNotEmpty) {
      controller.text = text.substring(0, text.length - 1);
    }
  } else if (key == '=') {
    if (text.isNotEmpty) {
      final res = CalculatorEvaluator.evaluate(text);
      if (res != null) {
        controller.text = CalculatorEvaluator.formatResult(res);
      }
    }
  } else if (key == '+' || key == '-' || key == '×' || key == '÷' || key == '%') {
    if (text.isEmpty) {
      if (key == '-') controller.text = '-';
    } else {
      final lastChar = text[text.length - 1];
      if (lastChar == '+' || lastChar == '-' || lastChar == '×' || lastChar == '÷' || lastChar == '%') {
        controller.text = '${text.substring(0, text.length - 1)}$key';
      } else {
        controller.text = '$text$key';
      }
    }
  } else if (key == '.') {
    final parts = text.split(RegExp(r'[+\-×÷%]'));
    final currentPart = parts.isNotEmpty ? parts.last : '';
    if (!currentPart.contains('.')) {
      controller.text = text.isEmpty ? '0.' : '$text.';
    }
  } else {
    // Digits 0-9 or 00
    if (text == '0' && key != '0' && key != '00') {
      controller.text = key;
    } else {
      controller.text = '$text$key';
    }
  }
}

/// Evaluates any expression inside the controller before form submit.
void finalizeCalculatorController(TextEditingController controller) {
  final text = controller.text.trim();
  if (text.isEmpty) return;
  final res = CalculatorEvaluator.evaluate(text) ?? CalculatorEvaluator.evaluatePreview(text);
  if (res != null) {
    controller.text = CalculatorEvaluator.formatResult(res);
  }
}

/// A compact bar shown directly above the inline calculator keypad.
class InPlaceCalculatorBar extends StatelessWidget {
  final String label;
  final String currentText;
  final String? unitLabel;
  final String prefixText;
  final VoidCallback? onDone;

  const InPlaceCalculatorBar({
    required this.label,
    required this.currentText,
    super.key,
    this.unitLabel,
    this.prefixText = '৳ ',
    this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final previewVal = CalculatorEvaluator.evaluatePreview(currentText);
    final hasMath = currentText.contains(RegExp(r'[+\-×÷%]'));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest : const Color(0xFFF9FAFB),
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
          bottom: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                if (hasMath && previewVal != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '= $prefixText${CalculatorEvaluator.formatResult(previewVal)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onDone != null)
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              child: InkWell(
                onTap: onDone,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.keyboard_hide_outlined, size: 18, color: colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        'confirmAmount'.tr,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// An interactive, styled container representing an in-place calculator amount field.
class CalculatorFieldCard extends StatelessWidget {
  final String label;
  final String value;
  final bool isSelected;
  final VoidCallback onTap;
  final String prefixText;
  final String? helperText;
  final String? errorText;

  const CalculatorFieldCard({
    required this.label,
    required this.value,
    required this.isSelected,
    required this.onTap,
    super.key,
    this.prefixText = '৳ ',
    this.helperText,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final borderColor = isSelected
        ? colorScheme.primary
        : (errorText != null ? colorScheme.error : colorScheme.outlineVariant);
    final bgColor = isSelected
        ? colorScheme.primary.withValues(alpha: isDark ? 0.12 : 0.04)
        : Colors.transparent;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? colorScheme.primary
                    : (errorText != null ? colorScheme.error : theme.hintColor),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                Expanded(
                  // Combine prefix + value into one Text so Bengali ৳ renders correctly
                  child: Text(
                    value.isEmpty
                        ? (prefixText.isNotEmpty ? '$prefixText-' : '-')
                        : '$prefixText$value',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: value.isEmpty
                          ? theme.hintColor
                          : (isSelected ? colorScheme.primary : colorScheme.onSurface),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 2,
                    height: 16,
                    color: colorScheme.primary,
                  ),
              ],
            ),
            if (errorText != null) ...[
              const SizedBox(height: 2),
              Text(
                errorText!,
                style: TextStyle(fontSize: 10, color: colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
}

/// The 5-row custom number pad matching the TallyKhata / POS standard layout.
class CalculatorKeypad extends StatelessWidget {
  final ValueChanged<String> onKeyPress;

  const CalculatorKeypad({required this.onKeyPress, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final numBg = isDark ? colorScheme.surfaceContainerHigh : Colors.white;
    final opBg = isDark
        ? colorScheme.surfaceContainerHighest
        : const Color(0xFFF3F4F6);
    final accentBg = colorScheme.primary.withValues(alpha: isDark ? 0.25 : 0.12);
    final borderColor = colorScheme.outlineVariant.withValues(alpha: 0.4);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainer : const Color(0xFFE5E7EB),
        border: Border(top: BorderSide(color: borderColor, width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: AC, %, ÷, ×
          _buildRow([
            _KeyConfig('AC', bg: opBg, textColor: Colors.red.shade700, isBold: true),
            _KeyConfig('%', bg: opBg, isOp: true),
            _KeyConfig('÷', bg: opBg, isOp: true),
            _KeyConfig('×', bg: opBg, isOp: true),
          ], borderColor),

          // Row 2: 7, 8, 9, -
          _buildRow([
            _KeyConfig('7', bg: numBg),
            _KeyConfig('8', bg: numBg),
            _KeyConfig('9', bg: numBg),
            _KeyConfig('-', bg: opBg, isOp: true),
          ], borderColor),

          // Row 3: 4, 5, 6, +
          _buildRow([
            _KeyConfig('4', bg: numBg),
            _KeyConfig('5', bg: numBg),
            _KeyConfig('6', bg: numBg),
            _KeyConfig('+', bg: accentBg, textColor: colorScheme.primary, isBold: true),
          ], borderColor),

          // Row 4: 1, 2, 3, =
          _buildRow([
            _KeyConfig('1', bg: numBg),
            _KeyConfig('2', bg: numBg),
            _KeyConfig('3', bg: numBg),
            _KeyConfig('=', bg: accentBg, textColor: colorScheme.primary, isBold: true),
          ], borderColor),

          // Row 5: ⌫, 0, . , 00
          _buildRow([
            _KeyConfig('⌫', bg: opBg, isIcon: true, icon: Icons.backspace_outlined),
            _KeyConfig('0', bg: numBg),
            _KeyConfig('.', bg: numBg, isBold: true),
            _KeyConfig('00', bg: numBg),
          ], borderColor),
        ],
      ),
    );
  }

  Widget _buildRow(List<_KeyConfig> keys, Color borderColor) {
    return Row(
      children: [
        for (var i = 0; i < keys.length; i++) ...[
          if (i > 0)
            Container(width: 0.5, height: 48, color: borderColor),
          Expanded(
            child: _CalculatorKeyButton(
              config: keys[i],
              onTap: () => onKeyPress(keys[i].label),
            ),
          ),
        ],
      ],
    );
  }
}

class _KeyConfig {
  final String label;
  final Color bg;
  final Color? textColor;
  final bool isBold;
  final bool isOp;
  final bool isIcon;
  final IconData? icon;

  const _KeyConfig(
    this.label, {
    required this.bg,
    this.textColor,
    this.isBold = false,
    this.isOp = false,
    this.isIcon = false,
    this.icon,
  });
}

class _CalculatorKeyButton extends StatelessWidget {
  final _KeyConfig config;
  final VoidCallback onTap;

  const _CalculatorKeyButton({
    required this.config,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultTextColor = theme.colorScheme.onSurface;

    return Material(
      color: config.bg,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          child: config.isIcon
              ? Icon(
                  config.icon ?? Icons.backspace_outlined,
                  size: 20,
                  color: config.textColor ?? defaultTextColor,
                )
              : Text(
                  config.label,
                  style: TextStyle(
                    fontSize: config.isOp ? 20 : 19,
                    fontWeight: config.isBold || config.isOp
                        ? FontWeight.bold
                        : FontWeight.w500,
                    color: config.textColor ?? defaultTextColor,
                  ),
                ),
        ),
      ),
    );
  }
}

/// Standalone modal bottom sheet fallback if needed.
Future<String?> showCalculatorModal(
  BuildContext context, {
  required String initialValue,
  String? title,
  String? unitLabel,
  String currencySymbol = '৳ ',
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _CalculatorModalSheet(
      initialValue: initialValue,
      title: title,
      unitLabel: unitLabel,
      currencySymbol: currencySymbol,
    ),
  );
}

class _CalculatorModalSheet extends StatefulWidget {
  final String initialValue;
  final String? title;
  final String? unitLabel;
  final String currencySymbol;

  const _CalculatorModalSheet({
    required this.initialValue,
    this.title,
    this.unitLabel,
    this.currencySymbol = '৳ ',
  });

  @override
  State<_CalculatorModalSheet> createState() => _CalculatorModalSheetState();
}

class _CalculatorModalSheetState extends State<_CalculatorModalSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InPlaceCalculatorBar(
              label: widget.title ?? 'calculator'.tr,
              currentText: _controller.text,
              unitLabel: widget.unitLabel,
              prefixText: widget.currencySymbol,
              onDone: () {
                finalizeCalculatorController(_controller);
                Navigator.of(context).pop(_controller.text);
              },
            ),
            CalculatorKeypad(
              onKeyPress: (key) {
                setState(() {
                  applyCalculatorKeyToController(_controller, key);
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
