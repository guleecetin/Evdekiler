import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme.dart';
import '../../core/api/api_exception.dart';
import '../../core/widgets/app_logo.dart';
import 'auth_controller.dart';

const _forest = Color(0xFF1D3A2A);
const _forestDeep = Color(0xFF122A1C);
const _gold = Color(0xFFD8BD82);
const _danger = Color(0xFFB42318);

const _herbSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 300 260" fill="none" stroke="#D8BD82" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">
<path d="M30 250C80 200 120 140 150 40"/>
<path d="M140 72c-30-6-48-24-52-50 28 4 46 22 52 50Z"/>
<path d="M150 64c26-14 50-14 70 0-22 16-46 16-70 0Z"/>
<path d="M118 128c-32 0-54-14-66-40 30-2 52 12 66 40Z"/>
<path d="M128 118c22-22 46-28 72-20-16 24-40 30-72 20Z"/>
<path d="M90 180c-30 6-56-2-74-24 28-8 54 0 74 24Z"/>
<path d="M100 168c16-26 38-38 66-36-12 28-34 40-66 36Z"/>
</svg>''';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _error;

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );
  late final _cardIn = CurvedAnimation(
    parent: _intro,
    curve: Curves.easeOutCubic,
  );

  @override
  void initState() {
    super.initState();
    // Şifre gücü ve eşleşme yazarken anında güncellensin
    _passwordController.addListener(_refresh);
    _confirmController.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_intro.status == AnimationStatus.dismissed) {
      if (MediaQuery.of(context).disableAnimations) {
        _intro.value = 1;
      } else {
        _intro.forward();
      }
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .register(
            displayName: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      // Başarılı olursa router otomatik olarak ana sayfaya geçer
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _forestDeep,
        body: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    const _CompactHero(),
                    Expanded(
                      child: FadeTransition(
                        opacity: _cardIn,
                        child: SlideTransition(
                          position: Tween(
                            begin: const Offset(0, 0.08),
                            end: Offset.zero,
                          ).animate(_cardIn),
                          child: _formCard(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _formCard(BuildContext context) {
    final password = _passwordController.text;
    final confirm = _confirmController.text;
    final matches = confirm.isNotEmpty && confirm == password;
    final mismatch = confirm.isNotEmpty && confirm != password;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        28,
        24,
        20 + MediaQuery.of(context).padding.bottom,
      ),
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Hesabını oluştur',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: _forest,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Bir dakikada kaydol, buzdolabın hep cebinde olsun.',
                style: TextStyle(
                  color: AppColors.muted,
                  height: 1.45,
                  fontSize: 14.5,
                ),
              ),
              const SizedBox(height: 24),

              const _FieldLabel('Adın'),
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                decoration: _inputDecoration(
                  hint: 'Ör. Gülendam',
                  icon: Icons.person_outline_rounded,
                ),
                validator: (value) {
                  final name = value?.trim() ?? '';
                  if (name.isEmpty) return 'Adını gir';
                  if (name.length > 100) return 'En fazla 100 karakter';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              const _FieldLabel('E-posta'),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: _inputDecoration(
                  hint: 'ornek@mail.com',
                  icon: Icons.mail_outline_rounded,
                ),
                validator: (value) => (value == null || !value.contains('@'))
                    ? 'Geçerli bir e-posta gir'
                    : null,
              ),
              const SizedBox(height: 16),

              const _FieldLabel('Şifre'),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                decoration: _inputDecoration(
                  hint: 'En az 8 karakter',
                  icon: Icons.lock_outline_rounded,
                  suffix: IconButton(
                    tooltip: _obscurePassword
                        ? 'Şifreyi göster'
                        : 'Şifreyi gizle',
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.muted,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (value) => (value == null || value.length < 8)
                    ? 'Şifre en az 8 karakter olmalı'
                    : null,
              ),
              if (password.isNotEmpty) _PasswordStrength(password: password),
              const SizedBox(height: 16),

              const _FieldLabel('Şifre tekrar'),
              TextFormField(
                controller: _confirmController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                onFieldSubmitted: (_) => _submit(),
                decoration: _inputDecoration(
                  hint: 'Şifreni tekrar yaz',
                  icon: Icons.lock_reset_rounded,
                  suffix: matches
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.basil,
                        )
                      : null,
                ),
                validator: (value) => value != _passwordController.text
                    ? 'Şifreler eşleşmiyor'
                    : null,
              ),
              if (mismatch)
                const Padding(
                  padding: EdgeInsets.only(left: 4, top: 6),
                  child: Text(
                    'Şifreler henüz eşleşmiyor',
                    style: TextStyle(
                      color: Color(0xFFB45309),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: _error == null
                    ? const SizedBox(height: 24)
                    : Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDECEA),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFF5C2BC)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: _danger,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: const TextStyle(
                                    color: _danger,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),

              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: _isLoading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: _forest,
                    disabledBackgroundColor: _forest.withValues(alpha: 0.7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: _gold,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Hesabımı oluştur',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: _gold,
                              size: 20,
                            ),
                          ],
                        ),
                ),
              ),

              const Spacer(),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Zaten hesabın var mı?',
                    style: TextStyle(color: AppColors.muted),
                  ),
                  TextButton(
                    onPressed: () => context.pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.basil,
                    ),
                    child: const Text(
                      'Giriş yap',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color, width: width),
        );

    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFB0B0B0)),
      prefixIcon: Icon(icon, color: AppColors.muted),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 18),
      border: border(AppColors.line),
      enabledBorder: border(const Color(0xFFE6E1D8)),
      focusedBorder: border(AppColors.basil, 1.6),
      errorBorder: border(const Color(0xFFE5948B)),
      focusedErrorBorder: border(_danger, 1.6),
    );
  }
}

// ─── Üst kısım: kısa yeşil şerit, geri butonu, logo + başlık ──

class _CompactHero extends StatelessWidget {
  const _CompactHero();

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A5A40), _forest, _forestDeep],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            right: -40,
            bottom: -50,
            width: 190,
            child: Transform.flip(
              flipX: true,
              child: Opacity(opacity: 0.14, child: SvgPicture.string(_herbSvg)),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(8, top + 4, 24, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  tooltip: 'Geri',
                  onPressed: () => context.pop(),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Row(
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: _gold.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const AppLogo(size: 56),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Evdekiler',
                              style: GoogleFonts.bricolageGrotesque(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.6,
                              ),
                            ),
                            Text(
                              'Aramıza hoş geldin',
                              style: TextStyle(
                                color: _gold.withValues(alpha: 0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Şifre gücü: 4 parçalı çubuk ─────────────────────────────

class _PasswordStrength extends StatelessWidget {
  const _PasswordStrength({required this.password});

  final String password;

  // Her kural bir puan: uzunluk, büyük harf, rakam, sembol ya da 12+ karakter
  int get _score {
    var s = 0;
    if (password.length >= 8) s++;
    if (RegExp(r'[A-ZÇĞİÖŞÜ]').hasMatch(password)) s++;
    if (RegExp(r'\d').hasMatch(password)) s++;
    if (RegExp(r'[^A-Za-z0-9ÇĞİÖŞÜçğıöşü]').hasMatch(password) ||
        password.length >= 12)
      s++;
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final score = _score;
    const labels = ['Çok zayıf', 'Zayıf', 'Orta', 'İyi', 'Güçlü'];
    const colors = [
      _danger,
      _danger,
      Color(0xFFD97706),
      Color(0xFF65A30D),
      AppColors.basil,
    ];
    final color = colors[score];

    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 2, right: 2),
      child: Row(
        children: [
          for (var i = 0; i < 4; i++) ...[
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                height: 5,
                decoration: BoxDecoration(
                  color: i < score ? color : const Color(0xFFE6E1D8),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            if (i < 3) const SizedBox(width: 6),
          ],
          const SizedBox(width: 10),
          SizedBox(
            width: 64,
            child: Text(
              labels[score],
              textAlign: TextAlign.right,
              style: TextStyle(
                color: color,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: _forest,
          fontSize: 14,
        ),
      ),
    );
  }
}
