import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/settings_controller.dart';
import 'home_page.dart';

/// Private-access gate shown before the app loads. Students must enter the
/// verification code to unlock the archive; the granted access is cached on
/// the device so it is only asked once (until the global expiry date).
class VerificationPage extends StatefulWidget {
  final SettingsController settings;

  const VerificationPage({super.key, required this.settings});

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage>
    with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final AnimationController _shake;
  late final AnimationController _successPulse;
  late final Animation<double> _shakeAnim;
  late final Animation<double> _successScale;

  final TextEditingController _codeController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _obscured = true;
  bool _loading = false;
  bool _success = false;
  String? _error;

  bool get _expired => widget.settings.isExpired;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 460),
    );

    _successPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -7.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -7.0, end: 7.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 7.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shake, curve: Curves.easeInOut));

    _successScale = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _successPulse, curve: Curves.elasticOut));
  }

  @override
  void dispose() {
    _entrance.dispose();
    _shake.dispose();
    _successPulse.dispose();
    _codeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Wraps [child] in a staggered fade + slide-up entrance animation.
  Widget _enter(Widget child, {required double start, required double end}) {
    final anim = CurvedAnimation(
      parent: _entrance,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: anim,
      child: child,
      builder: (context, child) {
        final t = anim.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 28 * (1 - t)),
            child: child,
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    if (_loading) return;
    FocusScope.of(context).unfocus();

    final code = _codeController.text.trim().toLowerCase();
    if (code != SettingsController.accessCode) {
      if (mounted) {
        setState(() => _error = 'Code de vérification incorrect.');
        _shake.forward(from: 0);
      }
      return;
    }

    setState(() {
      _error = null;
      _loading = true;
    });

    await widget.settings.markVerified();
    if (!mounted) return;

    setState(() {
      _loading = false;
      _success = true;
    });
    _successPulse.forward();

    await Future<void>.delayed(const Duration(milliseconds: 750));
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => HomePage(settings: widget.settings)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final content = _expired ? _ExpiredAccessCard() : _buildAccessForm();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF16181D)
            : const Color(0xFFF7F8FA),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 56,
                  ),
                  child: IntrinsicHeight(child: content),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAccessForm() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _enter(_buildLogo(), start: 0.0, end: 0.45),
        const SizedBox(height: 24),
        _enter(
          Text(
            'Accès Privé',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF202124),
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          start: 0.2,
          end: 0.5,
        ),
        const SizedBox(height: 10),
        _enter(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Cette application est privée et réservée aux élèves du '
              'Lydex-Rabat (2ème BAC Sciences Mathématiques) uniquement.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white70 : const Color(0xFF5F6368),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
          start: 0.3,
          end: 0.6,
        ),
        const SizedBox(height: 28),
        _enter(_buildCard(), start: 0.4, end: 0.75),
        const SizedBox(height: 20),
        _enter(
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.hourglass_bottom_rounded,
                size: 15,
                color: isDark ? Colors.white54 : const Color(0xFF9AA0A6),
              ),
              const SizedBox(width: 6),
              Text(
                'Accès valable jusqu\'au 1 janvier 2027',
                style: TextStyle(
                  color: isDark ? Colors.white54 : const Color(0xFF9AA0A6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          start: 0.65,
          end: 0.95,
        ),
      ],
    );
  }

  Widget _buildLogo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 56),
      child: Image.asset('assets/lydex.png', height: 60, fit: BoxFit.contain),
    );
  }

  Widget _buildCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? const Color(0xFF22252C) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF2E323A)
        : const Color(0xFFE4E4E7);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Transform.translate(
        offset: Offset(0, _shakeAnim.value),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Code de vérification',
                style: TextStyle(
                  color: isDark ? Colors.white70 : const Color(0xFF5F6368),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              _buildTextField(isDark),
              const SizedBox(height: 18),
              SizedBox(height: 52, child: _buildSubmitArea(isDark)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(bool isDark) {
    return TextField(
      controller: _codeController,
      focusNode: _focusNode,
      obscureText: _obscured,
      autocorrect: false,
      enableSuggestions: false,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _submit(),
      onChanged: (_) {
        if (_error != null) setState(() => _error = null);
      },
      style: TextStyle(
        fontSize: 15,
        color: isDark ? Colors.white : const Color(0xFF202124),
      ),
      decoration: InputDecoration(
        hintText: 'Entrez le code secret',
        hintStyle: TextStyle(
          color: isDark ? Colors.white38 : const Color(0xFF9AA0A6),
        ),
        errorText: _error,
        errorMaxLines: 2,
        prefixIcon: Icon(
          Icons.lock_outline_rounded,
          size: 20,
          color: isDark ? Colors.white54 : const Color(0xFF5F6368),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscured
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            size: 20,
          ),
          onPressed: () => setState(() => _obscured = !_obscured),
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF2A2E36) : const Color(0xFFF1F3F4),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF3A3F48) : Colors.transparent,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? Colors.white70 : const Color(0xFF202124),
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD93025)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD93025), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildSubmitArea(bool isDark) {
    final success = _success;
    return AnimatedBuilder(
      animation: _successPulse,
      builder: (context, _) {
        if (!success) {
          return _SubmitButton(
            loading: _loading,
            isDark: isDark,
            onPressed: _submit,
          );
        }
        return Transform.scale(
          scale: _successScale.value,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF25D366),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_rounded, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Accès accordé !',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Simple monochrome submit button with a built-in loading spinner.
class _SubmitButton extends StatelessWidget {
  final bool loading;
  final bool isDark;
  final VoidCallback onPressed;

  const _SubmitButton({
    required this.loading,
    required this.isDark,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? Colors.white : const Color(0xFF202124);
    final fg = isDark ? Colors.black : Colors.white;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: loading ? null : onPressed,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: loading
              ? Row(
                  key: const ValueKey('loading'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Vérification...',
                      style: TextStyle(
                        color: fg,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                )
              : Row(
                  key: const ValueKey('idle'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_forward_rounded, color: fg, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Entrer dans l\'archive',
                      style: TextStyle(
                        color: fg,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Shown when the global access period is over.
class _ExpiredAccessCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2E36) : const Color(0xFFF1F3F4),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.lock_clock_rounded,
            size: 40,
            color: isDark ? Colors.white70 : const Color(0xFF5F6368),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Accès expiré',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF202124),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'La période d\'accès gratuit à cette application s\'est terminée '
            'le 1 janvier 2027.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white70 : const Color(0xFF5F6368),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
