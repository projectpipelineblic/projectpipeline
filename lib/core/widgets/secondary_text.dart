import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:task_app/core/theme/app_pallete.dart';

class SecondaryText extends StatelessWidget {
  final TextDecoration? decoration;
  final String text;
  final Color? color;
  final bool? softWrap;
  final double? size;
  final FontWeight? fontWeight;
  final TextOverflow? overflow;
  final int? maxLines;
  const SecondaryText({super.key, this.decoration, required this.text, this.color, this.softWrap, this.size, this.fontWeight, this.overflow, this.maxLines});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      overflow: overflow,
      softWrap: softWrap,
      maxLines: maxLines,
      style: GoogleFonts.robotoMono(
        color: color ?? AppPallete.black,
        fontSize: size,
        fontWeight: fontWeight,
        decoration: decoration,
      ),
    );
  }
}
