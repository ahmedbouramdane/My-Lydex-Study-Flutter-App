import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../core/settings_controller.dart';
import '../models/app_section.dart';
import '../widgets/app_drawer.dart';
import '../widgets/loading_screen.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  final SettingsController settings;

  const HomePage({super.key, required this.settings});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const String baseUrl =
      'https://ahmedbouramdane.github.io/2BAC-Archive-Web';

  late final WebViewController _controller;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isLoaded = false;
  late int _currentSection;
  bool _didRestoreSection = false;

  @override
  void initState() {
    super.initState();

    _currentSection = widget.settings.lastSection.clamp(
      0,
      kSections.length - 1,
    );

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            _syncWebTheme();
            _restoreSection();
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) setState(() => _isLoaded = true);
            });
          },
          onWebResourceError: (error) {
            debugPrint('WebView error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(baseUrl));

    // Keep the website's theme in sync whenever it changes.
    widget.settings.addListener(_syncWebTheme);
  }

  @override
  void dispose() {
    widget.settings.removeListener(_syncWebTheme);
    super.dispose();
  }

  /// After the page loads, jump to the last visited section by updating the
  /// hash only (no reload). Runs at most once per WebView load.
  void _restoreSection() {
    if (_didRestoreSection) return;
    _didRestoreSection = true;

    final path = kSections[_currentSection].hashPath;
    if (path.isNotEmpty) {
      _controller.runJavaScript('''
        window.location.hash = '$path';
        true;
      ''');
    }
  }

  /// Pushes the active Flutter theme into the website (WebView).
  void _syncWebTheme() {
    final isDark = widget.settings.isDark(context);
    final theme = isDark ? 'dark' : 'light';
    _controller.runJavaScript('''
      (function() {
        document.documentElement.setAttribute('data-theme', '$theme');
        localStorage.setItem('theme', '$theme');
        var icon = document.querySelector('#themeToggle i');
        if (icon) icon.className = ${isDark ? "'fas fa-sun'" : "'fas fa-moon'"};
        return true;
      })();
    ''');
  }

  /// Switch SPA section via hash only — no page reload.
  void _navigateToSection(int index) {
    _scaffoldKey.currentState?.closeDrawer();
    setState(() => _currentSection = index);
    widget.settings.setLastSection(index);

    final path = kSections[index].hashPath;

    // Fermer le lecteur PDF du site s'il est ouvert, puis naviguer.
    // On appelle d'abord la fonction exposée du site (si présente) puis on
    // force la fermeture du modal via le DOM, pour rester robuste même si le
    // site déployé n'a pas encore la fonction globale.
    _controller.runJavaScript('''
      (function() {
        try {
          if (typeof window.closePdfViewer === 'function') window.closePdfViewer();
        } catch (e) {}
        var ov = document.getElementById('pdfOverlay');
        if (ov && !ov.hidden) {
          ov.hidden = true;
          document.body.style.overflow = '';
          var wrap = document.getElementById('pdfFrameWrap');
          if (wrap) wrap.innerHTML = '';
        }
        window.location.hash = '$path';
        return true;
      })();
    ''');
  }

  void _openSettings() {
    _scaffoldKey.currentState?.closeDrawer();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsPage(settings: widget.settings),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.settings.isDark(context);
    final appBarColor = isDark
        ? const Color(0xFF121212)
        : const Color(0xFF0D47A1);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF0D47A1),
      appBar: AppBar(
        backgroundColor: appBarColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const _AppBarTitle(),
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          tooltip: 'Menu',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _controller.reload(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      drawer: AppDrawer(
        currentSection: _currentSection,
        onSectionSelected: _navigateToSection,
        onSettingsTapped: _openSettings,
        settings: widget.settings,
      ),
      body: ListenableBuilder(
        listenable: widget.settings,
        builder: (context, _) {
          return Stack(
            children: [
              WebViewWidget(controller: _controller),
              AnimatedOpacity(
                opacity: _isLoaded ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 400),
                child: IgnorePointer(
                  ignoring: _isLoaded,
                  child: _isLoaded
                      ? const SizedBox.shrink()
                      : const LoadingScreen(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AppBarTitle extends StatelessWidget {
  const _AppBarTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.menu_book_rounded, size: 20),
        const SizedBox(width: 8),
        Text(
          'My Study Archive',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.95),
          ),
        ),
      ],
    );
  }
}
