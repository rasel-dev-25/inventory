import 'package:flutter/material.dart';

Widget shopLogo({double size = 24, Color? color}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: Image.asset(
      'assets/shop_logo.jpeg',
      width: size * 2.2,
      height: size * 2.2,
      fit: BoxFit.contain,
    ),
  );
}
