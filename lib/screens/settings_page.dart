import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/settings_controller.dart';

/// A dedicated settings page replacing the previous alert dialog.
class SettingsPage extends StatelessWidget {
  final SettingsController settings;

  const SettingsPage({super.key, required this.settings});

  static const String whatsappNumber = '0633977491';
  static const String emailAddress = 'a.bouramdane.se24@lydex-se.ma';
  static const String whatsappGroupUrl =
      'https://chat.whatsapp.com/Kp1wrLGgmxd6G0U2W8kGYQ';

  Future<void> _launchWhatsApp(BuildContext context) async {
    final uri = Uri.parse('https://wa.me/212633977491');
    await _launch(uri, context, 'WhatsApp');
  }

  Future<void> _launchEmail(BuildContext context) async {
    final uri = Uri.parse('mailto:a.bouramdane.se24@lydex-se.ma');
    await _launch(uri, context, 'Email');
  }

  Future<void> _launchWhatsAppGroup(BuildContext context) async {
    final uri = Uri.parse(whatsappGroupUrl);
    await _launch(uri, context, 'WhatsApp group');
  }

  Future<void> _launch(Uri uri, BuildContext context, String label) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        _showError(context, 'Could not open $label.');
      }
    } catch (_) {
      if (context.mounted) _showError(context, 'Could not open $label.');
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Back',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          const _SectionTitle(label: 'Appearance'),
          ListenableBuilder(
            listenable: settings,
            builder: (context, _) {
              return RadioGroup<AppThemeMode>(
                groupValue: settings.themeMode,
                onChanged: (value) {
                  if (value != null) settings.setThemeMode(value);
                },
                child: const Column(
                  children: [
                    RadioListTile<AppThemeMode>(
                      title: Text('System'),
                      subtitle: Text('Follow your device setting'),
                      secondary: Icon(Icons.brightness_auto_rounded),
                      value: AppThemeMode.system,
                    ),
                    RadioListTile<AppThemeMode>(
                      title: Text('Light'),
                      subtitle: Text('Always use the light theme'),
                      secondary: Icon(Icons.light_mode_rounded),
                      value: AppThemeMode.light,
                    ),
                    RadioListTile<AppThemeMode>(
                      title: Text('Dark'),
                      subtitle: Text('Always use the dark theme'),
                      secondary: Icon(Icons.dark_mode_rounded),
                      value: AppThemeMode.dark,
                    ),
                  ],
                ),
              );
            },
          ),

          const _SectionTitle(label: 'About'),
          const _AboutCard(),
          const _SectionTitle(label: 'Information'),
          const ListTile(
            leading: Icon(Icons.info_outline_rounded),
            title: Text('Version'),
            trailing: Text('2.3'),
          ),
          const ListTile(
            leading: Icon(Icons.school_rounded),
            title: Text('School'),
            trailing: Text('Lydex de Rabat'),
          ),
          const ListTile(
            leading: Icon(Icons.person_rounded),
            title: Text('Developer'),
            trailing: Text('Ahmed BOURAMDANE'),
          ),

          const _SectionTitle(label: 'Contact'),
          _WhatsAppGroupTile(onTap: () => _launchWhatsAppGroup(context)),
          const SizedBox(height: 4),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFF25D366),
              child: Icon(Icons.chat_rounded, color: Colors.white, size: 20),
            ),
            title: const Text('WhatsApp'),
            subtitle: const Text(whatsappNumber),
            trailing: const Icon(Icons.open_in_new_rounded, size: 18),
            onTap: () => _launchWhatsApp(context),
          ),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFD93025),
              child: Icon(Icons.email_rounded, color: Colors.white, size: 20),
            ),
            title: const Text('Email'),
            subtitle: const Text(emailAddress),
            trailing: const Icon(Icons.open_in_new_rounded, size: 18),
            onTap: () => _launchEmail(context),
          ),

          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Text(
              'My Study Archive — Cours, séries d\'exercices et livres pour la '
              '2ème année bac sciences mathématiques.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;

  const _SectionTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}

/// Prominent call-to-action card to join the official WhatsApp group.
class _WhatsAppGroupTile extends StatelessWidget {
  final VoidCallback onTap;

  const _WhatsAppGroupTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: const Color(0xFF25D366),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.groups_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Join our WhatsApp group',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Follow the new versions & updates',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      color: scheme.primaryContainer.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: scheme.primary,
              child: const Icon(
                Icons.menu_book_rounded,
                size: 28,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'My Study Archive',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Developed by Ahmed BOURAMDANE',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}