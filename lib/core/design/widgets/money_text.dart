import 'package:flutter/material.dart';

import '../../money/money.dart';

/// Renders a [Money] value with consistent styling and an optional colour
/// convention: positive amounts in the theme's default text colour,
/// negative amounts in the error colour (e.g. an outstanding due, a
/// negative cash reconciliation delta). This is the only place `Money`
/// formatting-for-display logic should live — screens must not call
/// `.format()` and then hand-roll their own colour/weight decisions
/// inconsistently.
class MoneyText extends StatelessWidget {
  final Money amount;
  final TextStyle? style;
  final bool colorCodeSign;
  final bool showSymbol;

  const MoneyText(
    this.amount, {
    super.key,
    this.style,
    this.colorCodeSign = false,
    this.showSymbol = true,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? Theme.of(context).textTheme.bodyLarge;
    final color = colorCodeSign
        ? (amount.isNegative
              ? Theme.of(context).colorScheme.error
              : baseStyle?.color)
        : baseStyle?.color;
    return Text(
      amount.format(showSymbol: showSymbol),
      style: baseStyle?.copyWith(color: color),
    );
  }
}
