import 'package:flutter/material.dart';

IconData iconForService(String type) {
  final t = type.toLowerCase();
  if (t.contains('plumb')) return Icons.plumbing;
  if (t.contains('electric')) return Icons.electrical_services;
  if (t.contains('clean')) return Icons.cleaning_services;
  if (t.contains('carpent') || t.contains('handy')) return Icons.handyman;
  if (t.contains('paint')) return Icons.format_paint;
  if (t.contains('mechan') || t.contains('car')) return Icons.car_repair;
  if (t.contains('ac') || t.contains('hvac') || t.contains('air')) {
    return Icons.ac_unit;
  }
  if (t.contains('garden') || t.contains('landscap') || t.contains('lawn')) {
    return Icons.yard;
  }
  if (t.contains('pest')) return Icons.pest_control;
  if (t.contains('lock')) return Icons.lock_outline;
  if (t.contains('move') || t.contains('moving')) return Icons.local_shipping;
  if (t.contains('salon') || t.contains('beauty')) return Icons.content_cut;
  if (t.contains('tutor') || t.contains('teach')) return Icons.school;
  return Icons.home_repair_service;
}

const _tints = <Color>[
  Color(0xFFE8F0FF),
  Color(0xFFFFF1E5),
  Color(0xFFE7F8EF),
  Color(0xFFFFE9F0),
  Color(0xFFF1E9FF),
  Color(0xFFE8F7FA),
];

Color tintForService(String type) {
  if (type.isEmpty) return _tints.first;
  return _tints[type.hashCode.abs() % _tints.length];
}

const _iconColors = <Color>[
  Color(0xFF1A4FCC),
  Color(0xFFC45E00),
  Color(0xFF1F7A3D),
  Color(0xFFC41E5E),
  Color(0xFF6B2BC4),
  Color(0xFF0A7A8F),
];

Color iconColorForService(String type) {
  if (type.isEmpty) return _iconColors.first;
  return _iconColors[type.hashCode.abs() % _iconColors.length];
}
