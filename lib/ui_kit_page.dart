import 'dart:ui';
import 'package:flutter/material.dart';

// ── Design tokens (matches dashboard / login palette) ─────────────────────────
const _kBg = Color(0xFF131313);
const _kPrimary = Color(0xFF00FF41);
const _kAccent = Color(0xFFFDD329);
const _kSurface = Color(0xFF1C1B1C);
const _kOnSurface = Color(0xFFE5E2E3);
const _kOnSurfaceVariant = Color(0xFFB9CCB2);
const _kOutline = Color(0xFF84967E);
const _kOutlineVariant = Color(0xFF3B4B37);
const _kError = Color(0xFFFF3333);

class UiKitPage extends StatelessWidget {
  const UiKitPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          _TopBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(48, 32, 48, 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Section('Colors', child: _ColorsSection()),
                  _Section('Typography', child: _TypographySection()),
                  _Section('Buttons', child: _ButtonsSection()),
                  _Section('Inputs', child: _InputsSection()),
                  _Section('Badges & Status', child: _BadgesSection()),
                  _Section('Error Banner', child: _ErrorBannerSection()),
                  _Section('Spacing & Radius', child: _SpacingRadiusSection()),
                  _Section('Player Token', child: _PlayerTokenSection()),
                  _Section('Toolbar', child: _ToolbarSection()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            color: _kBg.withValues(alpha: 0.9),
            border: Border(
              bottom: BorderSide(color: _kOutlineVariant.withValues(alpha: 0.2)),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back, color: _kOnSurfaceVariant, size: 20),
                tooltip: 'Back',
              ),
              const SizedBox(width: 12),
              const Text(
                'UI KIT',
                style: TextStyle(
                  color: _kPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: _kPrimary.withValues(alpha: 0.3)),
                ),
                child: const Text(
                  'Foundations & Components',
                  style: TextStyle(color: _kPrimary, fontSize: 10, letterSpacing: 1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section wrapper ───────────────────────────────────────────────────────────
class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section(this.title, {required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        Row(
          children: [
            Container(width: 3, height: 24, color: _kPrimary),
            const SizedBox(width: 12),
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                color: _kOnSurface,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        child,
        const SizedBox(height: 8),
        Divider(color: _kOutlineVariant.withValues(alpha: 0.15)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. COLORS
// ─────────────────────────────────────────────────────────────────────────────
class _ColorsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ColorGroupLabel('Brand & Accent'),
        const SizedBox(height: 10),
        _ColorRow(const [
          _ColorSwatch('Primary', Color(0xFF00FF41), dark: true),
          _ColorSwatch('Accent', Color(0xFFFDD329), dark: true),
          _ColorSwatch('Selection', Color(0xFF00FF94), dark: true),
          _ColorSwatch('On Primary', Color(0xFF007117)),
          _ColorSwatch('On Brand Dark', Color(0xFF003907)),
        ]),
        const SizedBox(height: 20),
        _ColorGroupLabel('Surfaces'),
        const SizedBox(height: 10),
        _ColorRow(const [
          _ColorSwatch('Lowest', Color(0xFF0E0E0F), outlined: true),
          _ColorSwatch('Surface', Color(0xFF131314), outlined: true),
          _ColorSwatch('Surface Low', Color(0xFF1C1B1C), outlined: true),
          _ColorSwatch('Background', Color(0xFF171717), outlined: true),
          _ColorSwatch('Card', Color(0xFF222222), outlined: true),
          _ColorSwatch('Dropdown', Color(0xFF2A2A2A), outlined: true),
          _ColorSwatch('Surface High', Color(0xFF353436), outlined: true),
        ]),
        const SizedBox(height: 20),
        _ColorGroupLabel('Text'),
        const SizedBox(height: 10),
        _ColorRow(const [
          _ColorSwatch('Primary', Color(0xFFE5E2E3)),
          _ColorSwatch('Secondary', Color(0xFFB9CCB2)),
          _ColorSwatch('Muted', Color(0xFF84967E)),
          _ColorSwatch('Brand', Color(0xFF00FF41), dark: true),
          _ColorSwatch('Accent', Color(0xFFFDD329), dark: true),
          _ColorSwatch('Error', Color(0xFFFF6666)),
        ]),
        const SizedBox(height: 20),
        _ColorGroupLabel('Status'),
        const SizedBox(height: 10),
        _ColorRow(const [
          _ColorSwatch('Error', Color(0xFFFF3333)),
          _ColorSwatch('Error Light', Color(0xFFFF6666)),
          _ColorSwatch('Success', Color(0xFF00FF41), dark: true),
          _ColorSwatch('Online', Color(0xFF00FF94), dark: true),
        ]),
      ],
    );
  }
}

class _ColorGroupLabel extends StatelessWidget {
  final String text;
  const _ColorGroupLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(color: _kOutline, fontSize: 9, letterSpacing: 3, fontWeight: FontWeight.w600),
    );
  }
}

class _ColorRow extends StatelessWidget {
  final List<_ColorSwatch> swatches;
  const _ColorRow(this.swatches);

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 12, runSpacing: 12, children: swatches);
  }
}

class _ColorSwatch extends StatelessWidget {
  final String name;
  final Color color;
  final bool dark;
  final bool outlined;
  const _ColorSwatch(this.name, this.color, {this.dark = false, this.outlined = false});

  @override
  Widget build(BuildContext context) {
    final labelColor = dark ? Colors.black.withValues(alpha: 0.75) : Colors.white.withValues(alpha: 0.75);
    return Container(
      width: 104,
      height: 72,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        border: outlined ? Border.all(color: Colors.white.withValues(alpha: 0.12)) : null,
      ),
      padding: const EdgeInsets.all(8),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Text(
          name,
          style: TextStyle(color: labelColor, fontSize: 10, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. TYPOGRAPHY
// ─────────────────────────────────────────────────────────────────────────────
class _TypographySection extends StatelessWidget {
  static const _specs = [
    _TypeSpec('Hero', 'ARCHITECT THE PERFECT PLAY.', 40, FontWeight.w900, letterSpacing: -0.5),
    _TypeSpec('Heading H1', 'Access Hub', 28, FontWeight.bold),
    _TypeSpec('Heading H2', 'TactBoard', 22, FontWeight.bold),
    _TypeSpec('Heading H3', 'Tactics Board', 18, FontWeight.w600),
    _TypeSpec('Body Large', 'Advanced real-time tactical analysis platform', 15, FontWeight.w300),
    _TypeSpec('Body Default', 'Enter your email address', 14, FontWeight.normal),
    _TypeSpec('Body Medium', 'E. Haaland — Forward', 13, FontWeight.w500),
    _TypeSpec('Body Small', 'Already have an account?', 12, FontWeight.normal),
    _TypeSpec('Label', 'EMAIL ADDRESS', 12, FontWeight.w300, letterSpacing: 1.5),
    _TypeSpec('Label Bold', 'V4.2 ANALYSIS ENGINE ONLINE', 9, FontWeight.bold, letterSpacing: 3),
    _TypeSpec('Button', 'INITIALIZE SESSION', 14, FontWeight.w600, letterSpacing: 1),
    _TypeSpec('Formation', '4-4-2', 13, FontWeight.w500, letterSpacing: 2),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _specs.map((spec) => _TypeRow(spec)).toList(),
    );
  }
}

class _TypeSpec {
  final String label;
  final String sample;
  final double size;
  final FontWeight weight;
  final double letterSpacing;
  const _TypeSpec(this.label, this.sample, this.size, this.weight, {this.letterSpacing = 0});
}

class _TypeRow extends StatelessWidget {
  final _TypeSpec spec;
  const _TypeRow(this.spec);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '${spec.label}\n${spec.size.toInt()}px',
              style: const TextStyle(color: _kOutline, fontSize: 11, height: 1.5),
            ),
          ),
          Expanded(
            child: Text(
              spec.sample,
              style: TextStyle(
                color: _kOnSurface,
                fontSize: spec.size,
                fontWeight: spec.weight,
                letterSpacing: spec.letterSpacing,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. BUTTONS
// ─────────────────────────────────────────────────────────────────────────────
class _ButtonsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 20,
      runSpacing: 20,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Primary
        _KitCard(
          label: 'Button / Primary',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PrimaryBtn('INITIALIZE SESSION', enabled: true),
              const SizedBox(height: 8),
              _PrimaryBtn('PROCESSING...', enabled: true, loading: true),
              const SizedBox(height: 8),
              _PrimaryBtn('DISABLED', enabled: false),
            ],
          ),
        ),
        // OAuth
        _KitCard(
          label: 'Button / OAuth',
          child: Column(
            children: [
              _OAuthBtn('Continue with Google'),
              const SizedBox(height: 8),
              _OAuthBtn('Continue with Apple'),
            ],
          ),
        ),
        // Text link
        _KitCard(
          label: 'Button / TextLink',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('No account? ', style: TextStyle(color: _kOnSurface.withValues(alpha: 0.5), fontSize: 12)),
              const SizedBox(height: 4),
              Text(
                'Create one',
                style: const TextStyle(
                  color: _kPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  decorationColor: _kPrimary,
                ),
              ),
            ],
          ),
        ),
        // Toolbar
        _KitCard(
          label: 'Button / Toolbar (32×32)',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ToolbarBtn(selected: false),
              const SizedBox(width: 8),
              _ToolbarBtn(selected: true),
              const SizedBox(width: 8),
              _ToolbarBtn(disabled: true),
            ],
          ),
        ),
        // Toggle / Settings
        _KitCard(
          label: 'Button / FieldToggle (48×48)',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ToggleBtn(),
              const SizedBox(width: 12),
              _ToggleBtn(hovered: true),
            ],
          ),
        ),
        // Back
        _KitCard(
          label: 'Button / Back (40×40)',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _BackBtn(),
              const SizedBox(width: 8),
              _BackBtn(hovered: true),
            ],
          ),
        ),
        // Formation
        _KitCard(
          label: 'Button / Formation',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FormationBtn('4-4-2', selected: false),
              const SizedBox(width: 6),
              _FormationBtn('4-3-3', selected: true),
              const SizedBox(width: 6),
              _FormationBtn('3-5-2', selected: false),
            ],
          ),
        ),
      ],
    );
  }
}

class _PrimaryBtn extends StatelessWidget {
  final String label;
  final bool enabled;
  final bool loading;
  const _PrimaryBtn(this.label, {required this.enabled, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      height: 48,
      decoration: BoxDecoration(
        color: _kPrimary.withValues(alpha: enabled ? 1 : 0.4),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (loading) ...[
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF003907)),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: TextStyle(
              color: const Color(0xFF003907).withValues(alpha: enabled ? 1 : 0.5),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _OAuthBtn extends StatelessWidget {
  final String label;
  const _OAuthBtn(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kOutlineVariant.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

class _ToolbarBtn extends StatelessWidget {
  final bool selected;
  final bool disabled;
  const _ToolbarBtn({this.selected = false, this.disabled = false});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.4 : 1,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: selected ? _kAccent.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.crop_square_rounded,
          size: 18,
          color: selected ? _kAccent : Colors.white.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final bool hovered;
  const _ToggleBtn({this.hovered = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: hovered ? 0.7 : 0.5),
        borderRadius: BorderRadius.circular(12),
        border: hovered ? Border.all(color: Colors.white.withValues(alpha: 0.1)) : null,
      ),
      child: Icon(Icons.settings_outlined, color: Colors.white.withValues(alpha: 0.9), size: 22),
    );
  }
}

class _BackBtn extends StatelessWidget {
  final bool hovered;
  const _BackBtn({this.hovered = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: hovered ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.arrow_back, color: Colors.white.withValues(alpha: 0.8), size: 20),
    );
  }
}

class _FormationBtn extends StatelessWidget {
  final String label;
  final bool selected;
  const _FormationBtn(this.label, {required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 75,
      height: 32,
      decoration: BoxDecoration(
        color: selected ? _kAccent.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: selected ? _kAccent : Colors.white,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. INPUTS
// ─────────────────────────────────────────────────────────────────────────────
class _InputsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 20,
      runSpacing: 20,
      children: [
        _KitCard(
          label: 'Input / Default',
          child: _KitInput(hint: 'email@tactboard.pro', icon: Icons.mail_outline),
        ),
        _KitCard(
          label: 'Input / Password',
          child: _KitInput(hint: '••••••••••••', icon: Icons.lock_outline, obscure: true),
        ),
        _KitCard(
          label: 'Dropdown',
          child: _KitDropdown(),
        ),
      ],
    );
  }
}

class _KitInput extends StatefulWidget {
  final String hint;
  final IconData icon;
  final bool obscure;
  const _KitInput({required this.hint, required this.icon, this.obscure = false});

  @override
  State<_KitInput> createState() => _KitInputState();
}

class _KitInputState extends State<_KitInput> {
  bool _hideText = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: TextField(
          obscureText: widget.obscure && _hideText,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 14),
            border: InputBorder.none,
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 16, right: 12),
              child: Icon(widget.icon, color: Colors.white.withValues(alpha: 0.4), size: 18),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 46),
            suffixIcon: widget.obscure
                ? GestureDetector(
                    onTap: () => setState(() => _hideText = !_hideText),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: Icon(
                        _hideText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: Colors.white.withValues(alpha: 0.35),
                        size: 18,
                      ),
                    ),
                  )
                : null,
            suffixIconConstraints: const BoxConstraints(minWidth: 46),
            contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
            isCollapsed: true,
          ),
        ),
      ),
    );
  }
}

class _KitDropdown extends StatefulWidget {
  @override
  State<_KitDropdown> createState() => _KitDropdownState();
}

class _KitDropdownState extends State<_KitDropdown> {
  String _value = 'Premier League';
  final _options = ['Premier League', 'La Liga', 'Bundesliga', 'Serie A', 'Ligue 1'];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kOutlineVariant.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _value,
          dropdownColor: const Color(0xFF2A2A2A),
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.white.withValues(alpha: 0.5), size: 18),
          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
          onChanged: (v) => setState(() => _value = v!),
          items: _options
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. BADGES & STATUS
// ─────────────────────────────────────────────────────────────────────────────
class _BadgesSection extends StatelessWidget {
  static const _competitions = [
    ('Premier League', Color(0xFF38003C)),
    ('La Liga', Color(0xFFFF4B44)),
    ('Bundesliga', Color(0xFFD3010C)),
    ('Serie A', Color(0xFF008FD7)),
    ('Ligue 1', Color(0xFF085FFF)),
    ('Champions League', Color(0xFF3562A6)),
    ('Europa League', Color(0xFFF68E21)),
    ('Conference League', Color(0xFF00B140)),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        // Version badge
        _KitCard(
          label: 'Badge / Version',
          child: _VersionBadge(),
        ),
        // Status dots
        _KitCard(
          label: 'Badge / StatusDot',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StatusDot(const Color(0xFF00FF41), label: 'Online'),
              const SizedBox(width: 16),
              _StatusDot(const Color(0xFFFF3333), label: 'Offline'),
              const SizedBox(width: 16),
              _StatusDot(const Color(0xFFFDD329), label: 'Away'),
            ],
          ),
        ),
        // Competition badges
        _KitCard(
          label: 'Badge / Competition',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _competitions
                .map((e) => _CompetitionBadge(e.$1, e.$2))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _VersionBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF353436).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: _kOutlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _kPrimary,
              boxShadow: [BoxShadow(color: _kPrimary.withValues(alpha: 0.5), blurRadius: 6)],
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'V4.2 ANALYSIS ENGINE ONLINE',
            style: TextStyle(
              color: Color(0xFFEBFFE2),
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final Color color;
  final String label;
  const _StatusDot(this.color, {required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: label == 'Online'
                ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6)]
                : null,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: _kOutline, fontSize: 10)),
      ],
    );
  }
}

class _CompetitionBadge extends StatelessWidget {
  final String name;
  final Color color;
  const _CompetitionBadge(this.name, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 6),
          Text(name, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 6. ERROR BANNER
// ─────────────────────────────────────────────────────────────────────────────
class _ErrorBannerSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _KitCard(
      label: 'ErrorBanner',
      child: Container(
        width: 360,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _kError.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _kError.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: _kError, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Invalid credentials. Please try again.',
                style: const TextStyle(color: Color(0xFFFF6666), fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 7. SPACING & RADIUS
// ─────────────────────────────────────────────────────────────────────────────
class _SpacingRadiusSection extends StatelessWidget {
  static const _spacing = [
    ('2xs', 2.0), ('xs', 4.0), ('sm', 8.0), ('md', 12.0), ('lg', 16.0),
    ('xl', 24.0), ('2xl', 28.0), ('3xl', 32.0), ('4xl', 40.0), ('5xl', 48.0),
  ];
  static const _radius = [
    ('none', 0.0), ('xs', 4.0), ('sm', 8.0), ('md', 12.0),
    ('lg', 20.0), ('xl', 24.0), ('2xl', 32.0), ('full', 100.0),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _KitCard(
          label: 'Spacing Scale',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _spacing.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  SizedBox(
                    width: 48,
                    child: Text('${e.$1}  ${e.$2.toInt()}px', style: const TextStyle(color: _kOutline, fontSize: 10)),
                  ),
                  Container(
                    width: e.$2 * 3,
                    height: e.$2.clamp(4, 20).toDouble(),
                    decoration: BoxDecoration(
                      color: _kAccent.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ),
        const SizedBox(width: 20),
        _KitCard(
          label: 'Border Radius',
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _radius.map((e) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _kAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(e.$2.clamp(0, 28)),
                    border: Border.all(color: _kAccent.withValues(alpha: 0.5)),
                  ),
                ),
                const SizedBox(height: 4),
                Text('${e.$1}\n${e.$2.toInt()}px',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _kOutline, fontSize: 9, height: 1.4)),
              ],
            )).toList(),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 8. PLAYER TOKEN
// ─────────────────────────────────────────────────────────────────────────────
class _PlayerTokenSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 20,
      runSpacing: 20,
      children: [
        _KitCard(
          label: 'Player Token / Outfield',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PlayerToken(number: 10, color: const Color(0xFF3B82F6), name: 'Messi', selected: false),
              const SizedBox(width: 16),
              _PlayerToken(number: 10, color: const Color(0xFF3B82F6), name: 'Messi', selected: true),
            ],
          ),
        ),
        _KitCard(
          label: 'Player Token / Goalkeeper',
          child: _PlayerToken(number: 1, color: const Color(0xFFEAB308), name: 'Alisson', selected: false),
        ),
        _KitCard(
          label: 'Player Token / Opponent',
          child: _PlayerToken(number: 9, color: const Color(0xFFEF4444), name: 'Haaland', selected: false),
        ),
      ],
    );
  }
}

class _PlayerToken extends StatelessWidget {
  final int number;
  final Color color;
  final String name;
  final bool selected;
  const _PlayerToken({required this.number, required this.color, required this.name, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(
              color: selected ? Colors.white : color.withValues(alpha: 0.5),
              width: selected ? 2.5 : 1.5,
            ),
            boxShadow: selected
                ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 10)]
                : [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 6)],
          ),
          child: Center(
            child: Text(
              '$number',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(name, style: const TextStyle(color: _kOnSurfaceVariant, fontSize: 11)),
        if (selected)
          Container(
            width: 6, height: 6,
            margin: const EdgeInsets.only(top: 3),
            decoration: const BoxDecoration(shape: BoxShape.circle, color: _kPrimary),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 9. TOOLBAR
// ─────────────────────────────────────────────────────────────────────────────
class _ToolbarSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 20,
      runSpacing: 20,
      children: [
        _KitCard(
          label: 'Toolbar / Container',
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ToolbarBtn(),
                const SizedBox(width: 4),
                _ToolbarBtn(selected: true),
                const SizedBox(width: 4),
                Container(width: 1, height: 24, color: Colors.white.withValues(alpha: 0.2)),
                const SizedBox(width: 4),
                _ToolbarBtn(),
                const SizedBox(width: 4),
                _ToolbarBtn(),
              ],
            ),
          ),
        ),
        _KitCard(
          label: 'Drawing / Color Dots',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Color(0xFFFF0000),
              Color(0xFF0000FF),
              Color(0xFFFFFF00),
              Color(0xFFFFFFFF),
              Color(0xFF000000),
              Color(0xFF00FF94),
            ].asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                width: 24, height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: e.value,
                  border: Border.all(
                    color: e.key == 0 ? Colors.white : Colors.white.withValues(alpha: 0.3),
                    width: e.key == 0 ? 2 : 1,
                  ),
                  boxShadow: e.key == 0
                      ? [BoxShadow(color: e.value.withValues(alpha: 0.5), blurRadius: 4)]
                      : null,
                ),
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared: KitCard wrapper
// ─────────────────────────────────────────────────────────────────────────────
class _KitCard extends StatelessWidget {
  final String label;
  final Widget child;
  const _KitCard({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kOutlineVariant.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(color: _kOutline, fontSize: 9, letterSpacing: 2, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
