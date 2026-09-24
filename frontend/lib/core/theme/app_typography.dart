import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  static const double display = 28;
  static const double title = 20;
  static const double heading = 17;
  static const double body = 14;
  static const double caption = 12;
  static const double small = 11;

  static TextStyle get displayStyle => GoogleFonts.poppins(
        fontSize: display,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle get titleStyle => GoogleFonts.poppins(
        fontSize: title,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get headingStyle => GoogleFonts.poppins(
        fontSize: heading,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyStyle => GoogleFonts.poppins(
        fontSize: body,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyMedium => GoogleFonts.poppins(
        fontSize: body,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );

  static TextStyle get captionStyle => GoogleFonts.poppins(
        fontSize: caption,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  static TextStyle get smallStyle => GoogleFonts.poppins(
        fontSize: small,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );

  static TextStyle get labelStyle => GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );
}