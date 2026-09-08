import 'package:flutter/material.dart';

/// A section of the website navigable from the drawer (SPA hash routes).
class AppSection {
  final String title;
  final String route;
  final IconData icon;
  final String? subtitle;

  const AppSection(this.title, this.route, this.icon, {this.subtitle});

  /// The part of the route after '#', e.g. `'math'` for `'#/math'`,
  /// or an empty string for the home route.
  String get hashPath {
    final path = route.startsWith('#') ? route.substring(1) : route;
    return path == '/' ? '' : path.substring(1);
  }
}

const AppSection kHomeSection = AppSection(
  'Accueil',
  '#/',
  Icons.home_rounded,
  subtitle: 'الرئيسية',
);

const List<AppSection> kSections = [
  AppSection(
    'Accueil',
    '#/',
    Icons.home_rounded,
    subtitle: 'الرئيسية',
  ),
  AppSection(
    'Mathématiques',
    '#/math',
    Icons.functions_rounded,
    subtitle: 'الرياضيات',
  ),
  AppSection(
    'Physique & Chimie',
    '#/physics',
    Icons.science_rounded,
    subtitle: 'الفيزياء والكيمياء',
  ),
  AppSection(
    'Livres',
    '#/books',
    Icons.menu_book_rounded,
    subtitle: 'الكتب',
  ),
];