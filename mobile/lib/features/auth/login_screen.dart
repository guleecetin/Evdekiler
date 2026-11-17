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

// Köşelerdeki silik ot dalı (web panelindeki menü çizimiyle aynı)
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

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _error;

  // Açılış: önce logo, sonra kart
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final _logoIn = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0, 0.6, curve: Curves.easeOutBack),
  );
  late final _cardIn = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.3, 1, curve: Curves.easeOutCubic),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_intro.status == AnimationStatus.dismissed) {
      // "Animasyonları kaldır" açıksa direkt son hal
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
    _emailController.dispose();
    _passwordController.dispose();
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
          .login(
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
      value: SystemUiOverlayStyle.light, // koyu zeminde açık renk durum çubuğu
      child: Scaffold(
        backgroundColor: _forestDeep,
        body: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    _Hero(animation: _logoIn),
                    Expanded(
                      child: FadeTransition(
                        opacity: _cardIn,
                        child: SlideTransition(
                          position: Tween(
                            begin: const Offset(0, 0.12),
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
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        30,
        24,
        24 + MediaQuery.of(context).padding.bottom,
      ),
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tekrar hoş geldin',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: _forest,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Giriş yap, buzdolabındakilerle bu akşam ne pişireceğine birlikte bakalım.',
                style: TextStyle(
                  color: AppColors.muted,
                  height: 1.45,
                  fontSize: 14.5,
                ),
              ),
              const SizedBox(height: 26),

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
              const SizedBox(height: 18),

              const _FieldLabel('Şifre'),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onFieldSubmitted: (_) => _submit(),
                decoration: _inputDecoration(
                  hint: '••••••••',
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
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Şifreni gir' : null,
              ),

              // Hata: kaybolmasın, butonun hemen üstünde dursun
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: _error == null
                    ? const SizedBox(height: 26)
                    : Padding(
                        padding: const EdgeInsets.only(top: 16, bottom: 16),
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
                                color: Color(0xFFB42318),
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: const TextStyle(
                                    color: Color(0xFFB42318),
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
                              'Giriş yap',
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
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Hesabın yok mu?',
                    style: TextStyle(color: AppColors.muted),
                  ),
                  TextButton(
                    onPressed: () => context.push('/register'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.basil,
                    ),
                    child: const Text(
                      'Kayıt ol',
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
      focusedErrorBorder: border(const Color(0xFFB42318), 1.6),
    );
  }
}

// ─── Üst kısım: yeşil zemin, altın ot dalları, logo ─────────

class _Hero extends StatelessWidget {
  const _Hero({required this.animation});

  final Animation<double> animation;

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
          // Silik ot dalları
          Positioned(
            left: -60,
            bottom: -40,
            width: 220,
            child: Opacity(opacity: 0.16, child: SvgPicture.string(_herbSvg)),
          ),
          Positioned(
            right: -50,
            top: top - 10,
            width: 170,
            child: Transform.flip(
              flipX: true,
              child: Opacity(opacity: 0.1, child: SvgPicture.string(_herbSvg)),
            ),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(24, top + 44, 24, 56),
            child: Center(
              child: FadeTransition(
                opacity: animation.drive(
                  Tween(
                    begin: 0.0,
                    end: 1.0,
                  ).chain(CurveTween(curve: Curves.easeOut)),
                ),
                child: ScaleTransition(
                  scale: Tween(begin: 0.85, end: 1.0).animate(animation),
                  child: Column(
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: _gold.withValues(alpha: 0.35),
                              blurRadius: 30,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: const AppLogo(size: 88),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Evdekiler',
                        style: GoogleFonts.bricolageGrotesque(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Buzdolabındakilerle bugün ne pişirsen?',
                        style: TextStyle(
                          color: _gold.withValues(alpha: 0.9),
                          fontSize: 14.5,
                        ),
                      ),
                    ],
                  ),
                ),
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
