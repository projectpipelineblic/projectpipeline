import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_pipeline/core/theme/app_pallete.dart';

class PrimaryText extends StatelessWidget {
  final TextDecoration? decoration;
  final String text;
  final Color? color;
  final bool? softWrap;
  final double? size;
  final FontWeight? fontWeight;
  final TextOverflow? overflow;
  final int? maxLines;
  final TextAlign? textAlign;
  const PrimaryText({
    super.key,
    this.decoration,
    required this.text,
    this.color,
    this.softWrap,
    this.size,
    this.fontWeight,
    this.overflow,
    this.maxLines,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      overflow: overflow,
      softWrap: softWrap,
      maxLines: maxLines,
      textAlign: textAlign,
      style: GoogleFonts.roboto(
        color: color ?? AppPallete.black,
        fontSize: size,
        fontWeight: fontWeight,
        decoration: decoration,
      ),
    );
  }
}
