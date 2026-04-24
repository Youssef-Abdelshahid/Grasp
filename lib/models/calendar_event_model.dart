import 'package:flutter/material.dart';

class CalendarEventModel {
  const CalendarEventModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.date,
    required this.color,
  });

  final String id;
  final String title;
  final String subtitle;
  final String type;
  final DateTime date;
  final Color color;
}
