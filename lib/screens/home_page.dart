import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../core/settings_controller.dart';
import '../models/app_section.dart';
import '../widgets/app_drawer.dart';
import '../widgets/loading_screen.dart';
import 'settings_page.dart';

/// How far along the loading of [baseUrl] is.
enum _LoadStatus { loading, ready, error }

/// The website loaded in the WebView.
///
/// Designed to stay robust on desktop (Windows): the page is never hidden
/// behind an animated overlay once loaded, a watchdog reports a stuck or blank
/// load instead of showing a white screen forever, and the user can always
/// fall back to the system browser.
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

  _LoadStatus _status = _LoadStatus.loading;
  late String _errorMessage;
  Timer? _watchdog;

  late int _currentSection;
  bool _didRestoreSection = false;

  bool get _isDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS);

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
          onPageStarted: (_) {
            if (mounted && _status != _LoadStatus.loading) {
              setState(() {
                _status = _LoadStatus.loading;
                _errorMessage = '';
                _didRestoreSection = false;
              });
            }
            _armWatchdog();
          },
          onPageFinished: (_) {
            _armWatchdog();
            _syncWebTheme();
            _restoreSection();
            _probeLoadedContent();
          },
          onWebResourceError: (error) {
            // A failing sub-resource is not fatal, but a failing main frame
            // means the page can never appear.
            if (error.isForMainFrame && _status != _LoadStatus.ready) {
              debugPrint('WebView error: ${error.description}');
              _failLoad(
                'Impossible de charger le site.\n'
                '${error.description}',
              );
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(baseUrl));

    // Keep the website's theme in sync whenever it changes.
    widget.settings.addListener(_syncWebTheme);
  }

  @override
  void dispose() {
    _watchdog?.cancel();
    widget.settings.removeListener(_syncWebTheme);
    super.dispose();
  }

  /// Cancels any pending watch and starts a fresh timeout for the current
  /// navigation. A stuck page switches to the rescue screen instead of
  /// leaving (or revealing) a blank view.
  void _armWatchdog() {
    _watchdog?.cancel();
    if (_status == _LoadStatus.error) return;
    _watchdog = Timer(
      Duration(seconds: _isDesktop ? 12 : 20),
      () {
        if (!mounted) return;
        if (_status != _LoadStatus.ready) {
          _failLoad(
            'Le site met trop de temps à répondre. '
            'Vérifiez votre connexion internet, puis réessayez.',
          );
        }
      },
    );
  }

  void _failLoad(String message) {
    if (!mounted) return;
    _watchdog?.cancel();
    setState(() {
      _status = _LoadStatus.error;
      _errorMessage = message;
    });
  }

  /// After a successful load, reads back a snippet of the rendered page. If
  /// the browser returned an empty body (blank/white page), we surface a
  /// rescue screen instead of staring at whiteness.
  Future<void> _probeLoadedContent() async {
    try {
      final snippet = await _controller
          .runJavaScriptReturningResult(
            'document.body && document.body.innerText'
                ' ? document.body.innerText.replace(/\\s+/g, " ").trim().slice(0, 60)'
                ' : "EMPTY_BODY"',
          )
          .timeout(const Duration(seconds: 3));
      if (!mounted) return;
      final text = snippet.toString();
      if (text == 'EMPTY_BODY') {
        _failLoad(
          'La page s\'est chargée mais ne contient aucun contenu. '
          'Ouvrez le site dans votre navigateur ou réessayez.',
        );
        return;
      }
      setState(() => _status = _LoadStatus.ready);
    } catch (_) {
      // Probe failed, but the page still finished. Trust onPageFinished.
      if (!mounted) return;
      setState(() => _status = _LoadStatus.ready);
    }
  }

  /// Hard reload of the site, re-arming the watchdog and section restore.
  Future<void> _reloadSite() async {
    setState(() {
      _status = _LoadStatus.loading;
      _errorMessage = '';
      _didRestoreSection = false;
    });
    _armWatchdog();
    _controller.loadRequest(Uri.parse(baseUrl));
  }

  /// Opens the site in the system's default browser (escape hatch used from
  /// the recovery screen and the app bar).
  Future<void> _openInBrowser() async {
    final ok = await launchUrl(
      Uri.parse(baseUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'ouvrir le navigateur.'),
        ),
      );
    }
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
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFF0D47A1),
      appBar: AppBar(
        backgroundColor: appBarColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: !_isDesktop,
        title: const _AppBarTitle(),
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          tooltip: 'Menu',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser_rounded),
            onPressed: _openInBrowser,
            tooltip: 'Ouvrir dans le navigateur',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _status == _LoadStatus.error ? _reloadSite : _controller.reload,
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
              // The WebView is always mounted and painted at the bottom of the
              // stack; once loaded, nothing renders above it (overlay widgets
              // rare on desktop) to avoid platform-view painting glitches.
              WebViewWidget(controller: _controller),
              if (_status == _LoadStatus.loading) _buildLoadingOverlay(),
              if (_status == _LoadStatus.error)
                _ErrorPanel(
                  message: _errorMessage,
                  onRetry: _reloadSite,
                  onOpenBrowser: _openInBrowser,
                ),
            ],
          );
        },
      ),
    );
  }

  /// Loading presentation. Desktop gets a slim progress bar so the user keeps
  /// seeing the (still empty) WebView; mobile keeps the immersive screen.
  Widget _buildLoadingOverlay() {
    if (_isDesktop) {
      return const Align(
        alignment: Alignment.topCenter,
        child: LinearProgressIndicator(minHeight: 3),
      );
    }
    return const Positioned.fill(child: LoadingScreen());
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<_LoadStatus>('status', _status));
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

/// Full-screen recovery card shown when the site cannot be loaded (stuck,
/// blank, or network error). Offers a retry and an escape to the browser so
/// desktop users never face an un-labelled white window.
class _ErrorPanel extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onOpenBrowser;

  const _ErrorPanel({
    required this.message,
    required this.onRetry,
    required this.onOpenBrowser,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned.fill(
      child: Container(
        color: isDark ? const Color(0xFF16181D) : const Color(0xFFF7F8FA),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF22252C) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? const Color(0xFF2E323A) : const Color(0xFFE4E4E7),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_off_rounded,
                  size: 44,
                  color: isDark ? Colors.white70 : const Color(0xFF5F6368),
                ),
                const SizedBox(height: 16),
                Text(
                  'Le site n\'a pas pu être chargé',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF202124),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: isDark ? Colors.white70 : const Color(0xFF5F6368),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onOpenBrowser,
                        icon: const Icon(Icons.open_in_new_rounded, size: 18),
                        label: const Text('Ouvrir dans le navigateur'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Réessayer'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1A73E8),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}