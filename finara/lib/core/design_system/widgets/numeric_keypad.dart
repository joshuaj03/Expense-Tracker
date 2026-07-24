/// NumericKeypad â€” custom calculator-style keypad with +/âˆ’/×/÷ operations.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_colors.dart';
import '../app_typography.dart';

class NumericKeypad extends StatelessWidget {
  final String value;
  final ValueChanged<String> onValueChanged;
  final VoidCallback? onDone;

  const NumericKeypad({
    super.key,
    required this.value,
    required this.onValueChanged,
    this.onDone,
  });

  void _onKey(String key) {
    HapticFeedback.lightImpact();

    if (key == '⌫') {
      if (value.isNotEmpty) {
        onValueChanged(value.substring(0, value.length - 1));
      }
      return;
    }

    if (key == 'C') {
      onValueChanged('');
      return;
    }

    if (key == '=') {
      _evaluate();
      return;
    }

    // Prevent multiple dots in the same number segment
    if (key == '.') {
      final parts = value.split(RegExp(r'[+\-×÷]'));
      if (parts.last.contains('.')) return;
    }

    // Prevent multiple operators in a row
    if ('+-×÷'.contains(key) && value.isNotEmpty) {
      final lastChar = value[value.length - 1];
      if ('+-×÷'.contains(lastChar)) {
        onValueChanged(value.substring(0, value.length - 1) + key);
        return;
      }
    }

    onValueChanged(value + key);
  }

  void _evaluate() {
    if (value.isEmpty) return;

    try {
      var expr = value.replaceAll('×', '*').replaceAll('÷', '/');

      // Simple expression evaluator
      final result = _parseExpression(expr);
      if (result != null) {
        // Format to remove unnecessary decimals
        final formatted = result == result.truncateToDouble()
            ? result.truncate().toString()
            : result.toStringAsFixed(2);
        onValueChanged(formatted);
      }
    } catch (_) {
      // Keep current value on parse error
    }
  }

  double? _parseExpression(String expr) {
    try {
      // Tokenize
      final tokens = <String>[];
      var current = '';
      for (int i = 0; i < expr.length; i++) {
        final ch = expr[i];
        if ('+-*/'.contains(ch) && current.isNotEmpty) {
          tokens.add(current);
          tokens.add(ch);
          current = '';
        } else {
          current += ch;
        }
      }
      if (current.isNotEmpty) tokens.add(current);

      if (tokens.isEmpty) return null;

      // Evaluate left-to-right with precedence
      // First pass: * and /
      var i = 0;
      while (i < tokens.length) {
        if (i > 0 && (tokens[i] == '*' || tokens[i] == '/')) {
          final left = double.parse(tokens[i - 1]);
          final right = double.parse(tokens[i + 1]);
          final result = tokens[i] == '*' ? left * right : left / right;
          tokens.replaceRange(i - 1, i + 2, [result.toString()]);
          i--;
        }
        i++;
      }

      // Second pass: + and -
      var result = double.parse(tokens[0]);
      i = 1;
      while (i < tokens.length - 1) {
        final op = tokens[i];
        final right = double.parse(tokens[i + 1]);
        if (op == '+') {
          result += right;
        } else if (op == '-') {
          result -= right;
        }
        i += 2;
      }

      return result;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    const keys = [
      ['7', '8', '9', '÷'],
      ['4', '5', '6', '×'],
      ['1', '2', '3', '-'],
      ['.', '0', '=', '+'],
    ];

    return Column(
      children: [
        // Clear and backspace row
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Expanded(
                child: _KeyButton(
                  label: 'C',
                  onTap: () => _onKey('C'),
                  isOperator: true,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: _KeyButton(
                  label: '⌫',
                  onTap: () => _onKey('⌫'),
                  isOperator: true,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ),
        // Number pad
        ...keys.map(
          (row) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: row
                  .map(
                    (key) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: key != row.last ? 8 : 0,
                        ),
                        child: _KeyButton(
                          label: key,
                          onTap: () => _onKey(key),
                          isOperator: '÷×-+='.contains(key),
                          isDark: isDark,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _KeyButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isOperator;
  final bool isDark;

  const _KeyButton({
    required this.label,
    required this.onTap,
    this.isOperator = false,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isOperator
          ? AppColors.accentViolet.withValues(alpha: isDark ? 0.15 : 0.1)
          : isDark
          ? AppColors.darkCard
          : AppColors.lightCard,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 52,
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTypography.headlineMedium.copyWith(
              color: isOperator
                  ? AppColors.accentViolet
                  : Theme.of(context).textTheme.bodyLarge?.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
