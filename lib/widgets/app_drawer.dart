import 'package:flutter/material.dart';

import '../core/settings_controller.dart';
import '../models/app_section.dart';

class AppDrawer extends StatelessWidget {
  final int currentSection;
  final ValueChanged<int> onSectionSelected;
  final VoidCallback onSettingsTapped;
  final SettingsController settings;

  const AppDrawer({
    super.key,
    required this.currentSection,
    required this.onSectionSelected,
    required this.onSettingsTapped,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = settings.isDark(context);

    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor =
        isDark ? Colors.white.withValues(alpha: 0.65) : Colors.grey.shade600;
    final iconColor = isDark ? Colors.grey.shade300 : Colors.grey.shade700;

    return Drawer(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(isDark),
            const SizedBox(height: 12),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _drawerSectionLabel(
                    'Sections',
                    color: subtextColor,
                  ),
                  for (int i = 0; i < kSections.length; i++)
                    _buildDrawerItem(
                      index: i,
                      section: kSections[i],
                      isSelected: currentSection == i,
                      textColor: textColor,
                      subtextColor: subtextColor,
                      iconColor: iconColor,
                    ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Divider(),
                  ),
                  _drawerSectionLabel('More', color: subtextColor),
                  ListTile(
                    leading: Icon(Icons.settings_rounded, color: iconColor),
                    title: Text(
                      'Settings',
                      style: TextStyle(fontSize: 14, color: textColor),
                    ),
                    onTap: onSettingsTapped,
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.palette_rounded,
                      color: Color(0xFF1A73E8),
                    ),
                    title: Text(
                      isDark ? 'Light mode' : 'Dark mode',
                      style: TextStyle(fontSize: 14, color: textColor),
                    ),
                    trailing: Switch(
                      value: isDark,
                      activeTrackColor: const Color(0xFF1A73E8),
                      onChanged: (_) => settings.toggleLightDark(),
                    ),
                    onTap: () => settings.toggleLightDark(),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Version 2.3 • © 2026 • Ahmed',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: subtextColor.withValues(alpha: 0.8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF1A73E8), Color(0xFF003366)]
              : const [Color(0xFF1A73E8), Color(0xFF0D47A1)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'My Study Archive',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'جميع دروس الثانوي',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerSectionLabel(String label, {required Color color}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          color: color,
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required int index,
    required AppSection section,
    required bool isSelected,
    required Color textColor,
    required Color subtextColor,
    required Color iconColor,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isSelected ? const Color(0xFF1A73E8) : Colors.transparent,
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(
          section.icon,
          color: isSelected ? Colors.white : iconColor,
        ),
        title: Text(
          section.title,
          style: TextStyle(
            color: isSelected ? Colors.white : textColor,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        subtitle: section.subtitle != null
            ? Text(
                section.subtitle!,
                style: TextStyle(
                  color: isSelected ? Colors.white.withValues(alpha: 0.8) : subtextColor,
                  fontSize: 12,
                ),
              )
            : null,
        trailing: isSelected
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
            : null,
        onTap: () => onSectionSelected(index),
      ),
    );
  }
}