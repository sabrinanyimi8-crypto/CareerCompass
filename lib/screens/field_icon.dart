import 'package:flutter/material.dart';

// Picks an icon for a career field, like Software Development or Security.
// It matches on keywords, so a field the admin adds later, such as
// "Data Science", still gets a sensible icon. Anything it does not
// recognise gets a general work icon.
IconData fieldIcon(String field) {
  final f = field.toLowerCase();

  if (f.contains('software') || f.contains('develop') || f.contains('program')) {
    return Icons.code;
  }
  if (f.contains('data') || f.contains('analytic')) {
    return Icons.insights;
  }
  if (f.contains('security') || f.contains('cyber')) {
    return Icons.shield_outlined;
  }
  if (f.contains('infrastructure') || f.contains('network') || f.contains('cloud')) {
    return Icons.dns_outlined;
  }
  if (f.contains('design') || f.contains('ux') || f.contains('ui')) {
    return Icons.brush_outlined;
  }
  if (f.contains('business') || f.contains('project') || f.contains('management')) {
    return Icons.business_center_outlined;
  }
  if (f.contains('education') || f.contains('teach') || f.contains('lectur')) {
    return Icons.school_outlined;
  }
  return Icons.work_outline;
}