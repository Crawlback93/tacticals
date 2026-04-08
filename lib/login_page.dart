import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'elements/custom_input.dart';
import 'services/auth_service.dart';

const _surface = Color(0xFF131314);
const _primaryContainer = Color(0xFF00FF41);
const _onPrimary = Color(0xFF003907);
const _onPrimaryContainer = Color(0xFF007117);
const _surfaceContainerLow = Color(0xFF1C1B1C);
const _surfaceContainerLowest = Color(0xFF0E0E0F);
const _outline = Color(0xFF84967E);
const _outlineVariant = Color(0xFF3B4B37);
const _onSurfaceVariant = Color(0xFFB9CCB2);
const _onBackground = Color(0xFFE5E2E3);
const _surfaceContainerHighest = Color(0xFF353436);
const _primary = Color(0xFFEBFFE2);

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _loading = false;
  String? _errorMessage;
  bool _isRegister = false;
  bool _emailConfirmationSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _switchMode(bool toRegister) {
    setState(() {
      _isRegister = toRegister;
      _errorMessage = null;
      _emailController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
    });
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final error = await AuthService.signInWithEmail(email, password);

    if (!mounted) return;

    if (error != null) {
      setState(() {
        _errorMessage = error;
        _loading = false;
      });
    } else {
      context.go('/dashboard');
    }
  }

  Future<void> _handleRegister() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (email.isEmpty || password.isEmpty || confirm.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields.');
      return;
    }
    if (password != confirm) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final error = await AuthService.signUpWithEmail(email, password);

    if (!mounted) return;

    if (error != null) {
      setState(() {
        _errorMessage = error;
        _loading = false;
      });
    } else if (AuthService.currentSession != null) {
      context.go('/dashboard');
    } else {
      setState(() {
        _emailConfirmationSent = true;
        _loading = false;
      });
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    final error = await AuthService.signInWithGoogle();
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _errorMessage = error;
        _loading = false;
      });
    }
    // On success the auth state change will redirect via main.dart listener
  }

  Future<void> _handleAppleSignIn() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    final error = await AuthService.signInWithApple();
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _errorMessage = error;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: Stack(
        children: [
          Row(
            children: [
              // Left column: Auth (40%)
              SizedBox(
                width: MediaQuery.sizeOf(context).width * 0.4,
                height: double.infinity,
                child: _buildAuthColumn(),
              ),
              // Right column: Hero (60%)
              Expanded(child: _buildHeroColumn()),
            ],
          ),
          // Footer overlay
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildAuthColumn() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: _surfaceContainerLow.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _outline.withValues(alpha: 0.1)),
                ),
                padding: const EdgeInsets.all(40),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.04),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: _emailConfirmationSent
                      ? _buildConfirmationNotice()
                      : _isRegister
                      ? _buildRegisterForm()
                      : _buildLoginForm(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      key: const ValueKey('login'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBranding(),
        const SizedBox(height: 40),
        _buildLoginHeader(),
        const SizedBox(height: 28),
        _buildLoginFields(),
        const SizedBox(height: 24),
        if (_errorMessage != null) ...[
          _buildErrorBanner(_errorMessage!),
          const SizedBox(height: 12),
        ],
        _buildSubmitButton('INITIALIZE SESSION', _handleLogin),
        const SizedBox(height: 12),
        _buildModeToggleLink(
          prompt: 'No account? ',
          action: 'Create one',
          onTap: () => _switchMode(true),
        ),
        const SizedBox(height: 16),
        _buildOAuthDivider(),
        const SizedBox(height: 16),
        _buildOAuthRow(),
        const SizedBox(height: 32),
        Divider(color: _outlineVariant.withValues(alpha: 0.15)),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'Authorized Personnel Only. © 2024 TactBoard Labs.',
            style: TextStyle(color: _outline, fontSize: 10, letterSpacing: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Column(
      key: const ValueKey('register'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBranding(),
        const SizedBox(height: 40),
        _buildRegisterHeader(),
        const SizedBox(height: 28),
        _buildRegisterFields(),
        const SizedBox(height: 24),
        if (_errorMessage != null) ...[
          _buildErrorBanner(_errorMessage!),
          const SizedBox(height: 12),
        ],
        _buildSubmitButton('CREATE ACCOUNT', _handleRegister),
        const SizedBox(height: 12),
        _buildModeToggleLink(
          prompt: 'Already have an account? ',
          action: 'Sign in',
          onTap: () => _switchMode(false),
        ),
        const SizedBox(height: 32),
        Divider(color: _outlineVariant.withValues(alpha: 0.15)),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'Authorized Personnel Only. © 2024 TactBoard Labs.',
            style: TextStyle(color: _outline, fontSize: 10, letterSpacing: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmationNotice() {
    return Column(
      key: const ValueKey('confirm'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildBranding(),
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _primaryContainer.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _primaryContainer.withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.mark_email_read_outlined,
                color: _primaryContainer,
                size: 40,
              ),
              const SizedBox(height: 16),
              const Text(
                'CHECK YOUR INBOX',
                style: TextStyle(
                  color: _onBackground,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'A confirmation link was sent to\n${_emailController.text.trim()}',
                style: const TextStyle(
                  color: _onSurfaceVariant,
                  fontSize: 13,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildModeToggleLink(
          prompt: 'Back to ',
          action: 'Sign in',
          onTap: () => setState(() {
            _emailConfirmationSent = false;
            _isRegister = false;
          }),
        ),
      ],
    );
  }

  Widget _buildBranding() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _primaryContainer,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: _primaryContainer.withValues(alpha: 0.3),
                blurRadius: 20,
              ),
            ],
          ),
          child: const Icon(
            Icons.grid_view,
            color: _onPrimaryContainer,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'TactBoard',
              style: TextStyle(
                color: _onBackground,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'ELITE ANALYTICS SYSTEM',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 3,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoginHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Access Hub',
          style: TextStyle(
            color: _onBackground,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Secure gateway for certified tactical coordinators.',
          style: TextStyle(
            color: _onSurfaceVariant,
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Create Account',
          style: TextStyle(
            color: _onBackground,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Register to access the tactical coordination platform.',
          style: TextStyle(
            color: _onSurfaceVariant,
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Email'),
        const SizedBox(height: 6),
        CustomInput(
          controller: _emailController,
          hint: 'email@tactboard.pro',
          leadingIcon: Icons.mail_outline,
          keyboardType: TextInputType.emailAddress,
          accentColor: _primaryContainer,
        ),
        const SizedBox(height: 16),
        _fieldLabel('Password'),
        const SizedBox(height: 6),
        CustomInput(
          controller: _passwordController,
          hint: '••••••••••••',
          leadingIcon: Icons.lock_outline,
          obscureText: true,
          accentColor: _primaryContainer,
          onSubmitted: (_) => _handleLogin(),
        ),
      ],
    );
  }

  Widget _buildRegisterFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Email'),
        const SizedBox(height: 6),
        CustomInput(
          controller: _emailController,
          hint: 'email@tactboard.pro',
          leadingIcon: Icons.mail_outline,
          keyboardType: TextInputType.emailAddress,
          accentColor: _primaryContainer,
        ),
        const SizedBox(height: 16),
        _fieldLabel('Password'),
        const SizedBox(height: 6),
        CustomInput(
          controller: _passwordController,
          hint: '••••••••••••',
          leadingIcon: Icons.lock_outline,
          obscureText: true,
          accentColor: _primaryContainer,
        ),
        const SizedBox(height: 16),
        _fieldLabel('Confirm Password'),
        const SizedBox(height: 6),
        CustomInput(
          controller: _confirmPasswordController,
          hint: '••••••••••••',
          leadingIcon: Icons.lock_outline,
          obscureText: true,
          accentColor: _primaryContainer,
          onSubmitted: (_) => _handleRegister(),
        ),
      ],
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: _outline,
          fontSize: 9,
          fontWeight: FontWeight.w600,
          letterSpacing: 3,
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFF3333).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFFF3333).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFFF6666), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFFF6666),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggleLink({
    required String prompt,
    required String action,
    required VoidCallback onTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          prompt,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
        ),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: onTap,
            child: Text(
              action,
              style: const TextStyle(
                color: _primaryContainer,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: _primaryContainer,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(String label, VoidCallback handler) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _loading ? null : handler,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 48,
          decoration: BoxDecoration(
            color: _loading
                ? _primaryContainer.withValues(alpha: 0.5)
                : _primaryContainer,
            borderRadius: BorderRadius.circular(24),
            boxShadow: _loading
                ? []
                : [
                    BoxShadow(
                      color: _primaryContainer.withValues(alpha: 0.2),
                      blurRadius: 32,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Center(
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _onPrimary,
                    ),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      color: _onPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildOAuthDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: _outlineVariant.withValues(alpha: 0.3))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR CONTINUE WITH',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
          ),
        ),
        Expanded(child: Divider(color: _outlineVariant.withValues(alpha: 0.3))),
      ],
    );
  }

  Widget _buildOAuthRow() {
    return Row(
      children: [
        Expanded(
          child: _oauthButton(
            Icons.g_mobiledata,
            'Google',
            onTap: _loading ? null : _handleGoogleSignIn,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _oauthButton(
            Icons.apple,
            'Apple ID',
            onTap: _loading ? null : _handleAppleSignIn,
          ),
        ),
      ],
    );
  }

  Widget _oauthButton(IconData icon, String label, {VoidCallback? onTap}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            border: Border.all(color: _outlineVariant.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: _onSurfaceVariant, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Hero column ────────────────────────────────────────────────────────────

  Widget _buildHeroColumn() {
    return Container(
      color: _surfaceContainerLow,
      child: Stack(
        children: [
          // Dot-grid background
          Positioned.fill(child: CustomPaint(painter: _PitchGridPainter())),
          // Green radial glow (top-left)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-1, -1),
                  radius: 1.4,
                  colors: [Color(0x0D00FF41), Colors.transparent],
                ),
              ),
            ),
          ),
          // Central content
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(80, 80, 80, 140),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildVersionBadge(),
                  const SizedBox(height: 28),
                  const Text(
                    'ARCHITECT THE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _onBackground,
                      fontSize: 60,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -2,
                      height: 0.95,
                    ),
                  ),
                  const Text(
                    'PERFECT PLAY.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _primaryContainer,
                      fontSize: 60,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -2,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: const Text(
                      'Transform raw scouting data into executable match-winning '
                      'strategies with our professional-grade drawing engine.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _onSurfaceVariant,
                        fontSize: 15,
                        fontWeight: FontWeight.w300,
                        height: 1.7,
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  Flexible(child: _buildMiniPitch()),
                ],
              ),
            ),
          ),
          // Stats bar
          Positioned(bottom: 48, left: 80, right: 80, child: _buildStats()),
        ],
      ),
    );
  }

  Widget _buildVersionBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _surfaceContainerHighest.withValues(alpha: 0.8),
        border: Border.all(color: _outlineVariant.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _primaryContainer,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _primaryContainer.withValues(alpha: 0.8),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'V4.2 ANALYSIS ENGINE ONLINE',
            style: TextStyle(
              color: _primary,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniPitch() {
    return AspectRatio(aspectRatio: 16 / 9, child: _buildMiniPitchContent());
  }

  Widget _buildMiniPitchContent() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _outlineVariant.withValues(alpha: 0.4)),
        color: const Color(0xCC0A0A0A),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _MiniPitchPainter())),
          // Analytics card
          Positioned(top: 20, right: 20, child: _buildAnalyticsCard()),
          // Bottom fade
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 80,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xFF0A0A0A)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: 160,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _surfaceContainerLow.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _primaryContainer.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'EXPECTED CONTROL',
                style: TextStyle(
                  color: _outline,
                  fontSize: 8,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '78.4%',
                style: TextStyle(
                  color: _primaryContainer,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: 0.784,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _primaryContainer,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Column(
      children: [
        Divider(color: _outlineVariant.withValues(alpha: 0.2)),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _statTile('94%', 'Accuracy in Simulation'),
            Container(
              width: 1,
              height: 28,
              color: _outlineVariant.withValues(alpha: 0.3),
            ),
            _statTile('500+', 'Elite Clubs Enabled'),
            Container(
              width: 1,
              height: 28,
              color: _outlineVariant.withValues(alpha: 0.3),
            ),
            _statTile('24/7', 'Match Intelligence'),
          ],
        ),
      ],
    );
  }

  Widget _statTile(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: _primaryContainer,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: _outline,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  // ─── Footer ─────────────────────────────────────────────────────────────────

  Widget _buildFooter() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 24,
        color: _surfaceContainerLowest,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: _primaryContainer,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'LIVE SYNC ACTIVE  •  LAST SAVED: JUST NOW',
                  style: TextStyle(
                    color: _primaryContainer,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                _footerLink('SYSTEM STATUS'),
                const SizedBox(width: 24),
                _footerLink('CLOUD SYNC'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _footerLink(String text) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Text(
        text,
        style: const TextStyle(
          color: _outline,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

// ─── Painters ───────────────────────────────────────────────────────────────

/// Radial dot grid for the hero background (pitch-grid effect).
class _PitchGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00FF41).withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_PitchGridPainter _) => false;
}

/// Mini pitch with markings, tactical tokens, and a dashed movement arrow.
class _MiniPitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Outer pitch border (inset 5%)
    canvas.drawRect(
      Rect.fromLTWH(w * 0.05, h * 0.05, w * 0.9, h * 0.9),
      linePaint,
    );

    // Centre line
    canvas.drawLine(
      Offset(w / 2, h * 0.05),
      Offset(w / 2, h * 0.95),
      linePaint,
    );

    // Centre circle
    canvas.drawCircle(Offset(w / 2, h / 2), w * 0.11, linePaint);

    // Token positions (relative to full canvas)
    _drawToken(canvas, Offset(w * 0.23, h * 0.32), '09', size: size);
    _drawToken(
      canvas,
      Offset(w * 0.455, h * 0.50),
      '10',
      highlighted: true,
      size: size,
    );
    _drawToken(
      canvas,
      Offset(w * 0.275, h * 0.68),
      '04',
      enemy: true,
      size: size,
    );

    // Tactical dashed arrow from "09" toward goal area
    _drawDashedArrow(
      canvas,
      start: Offset(w * 0.23, h * 0.38),
      control: Offset(w * 0.34, h * 0.52),
      end: Offset(w * 0.455, h * 0.65),
    );
  }

  void _drawToken(
    Canvas canvas,
    Offset center,
    String number, {
    bool highlighted = false,
    bool enemy = false,
    required Size size,
  }) {
    final r = size.width * 0.025;
    final tokenColor = enemy ? Colors.white : const Color(0xFF00FF41);

    if (highlighted) {
      canvas.drawCircle(
        center,
        r + 5,
        Paint()
          ..color = const Color(0xFF00FF41).withValues(alpha: 0.18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = tokenColor.withValues(alpha: enemy ? 0.05 : 0.10)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = tokenColor.withValues(alpha: enemy ? 0.25 : 0.5)
        ..strokeWidth = highlighted ? 2 : 1.5
        ..style = PaintingStyle.stroke,
    );

    final tp = TextPainter(
      text: TextSpan(
        text: number,
        style: TextStyle(
          color: tokenColor.withValues(alpha: enemy ? 0.5 : 1),
          fontSize: size.width * 0.013,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  void _drawDashedArrow(
    Canvas canvas, {
    required Offset start,
    required Offset control,
    required Offset end,
  }) {
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);

    final paint = Paint()
      ..color = const Color(0xFF00FF41).withValues(alpha: 0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw dashed segments
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double dist = 0;
      bool draw = true;
      while (dist < metric.length) {
        final len = draw ? 8.0 : 4.0;
        if (draw) {
          canvas.drawPath(metric.extractPath(dist, dist + len), paint);
        }
        dist += len;
        draw = !draw;
      }
    }

    // Arrow dot at the end
    canvas.drawCircle(
      end,
      4,
      Paint()
        ..color = const Color(0xFF00FF41)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_MiniPitchPainter _) => false;
}
