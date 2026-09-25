import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

class TripGoTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? initialValue;
  final TextInputType? keyboardType;
  final bool obscure;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final IconData? prefixIcon;
  final AutovalidateMode autovalidateMode;
  final bool enabled;
  final TextInputAction? textInputAction;

  const TripGoTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.initialValue,
    this.keyboardType,
    this.obscure = false,
    this.validator,
    this.onChanged,
    this.prefixIcon,
    this.autovalidateMode = AutovalidateMode.disabled,
    this.enabled = true,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textStyle = AppTypography.bodyStyle.copyWith(
      color: isDark ? const Color(0xFFF1F5F9) : AppColors.textPrimary,
    );
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      keyboardType: keyboardType,
      obscureText: obscure,
      validator: validator,
      onChanged: onChanged,
      enabled: enabled,
      textInputAction: textInputAction,
      autovalidateMode: autovalidateMode,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 20, color: AppColors.textSecondary),
      ),
      style: textStyle,
    );
  }
}

class TripGoSearchField extends StatelessWidget {
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final String hint;

  const TripGoSearchField({super.key, this.initialValue, this.onChanged, this.onTap, this.hint = 'Search city or station'});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: initialValue == null ? null : TextEditingController(text: initialValue),
      onChanged: onChanged,
      onTap: onTap,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
        suffixIcon: initialValue == null
            ? null
            : IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => onChanged?.call('')),
      ),
    );
  }
}

class TripGoSelectField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;
  final String? hint;

  const TripGoSelectField({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: AppColors.lightBlue, shape: BoxShape.circle),
              child: Icon(icon, size: 20, color: AppColors.royalBlue),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTypography.smallStyle),
                  const SizedBox(height: 2),
                  Text(
                    value.isEmpty ? (hint ?? 'Select') : value,
                    style: value.isEmpty ? AppTypography.bodyStyle.copyWith(color: AppColors.textSecondary) : AppTypography.bodyMedium,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}