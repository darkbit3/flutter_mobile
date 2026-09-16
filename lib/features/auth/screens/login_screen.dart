import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import 'register_form.dart';
import '../utils/phone_utils.dart';
import '../providers/auth_provider.dart';
import '../constants/lang_constants.dart';
import '../../../core/localization/language_provider.dart';

// â”€â”€ Language options â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

enum _Tab  { login, register }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _phoneCtr = TextEditingController();
  final _passCtr  = TextEditingController();
  bool  _obscure  = true;
  Lang  _lang     = Lang.en;
  _Tab  _tab      = _Tab.login;

  @override
  void dispose() {
    _phoneCtr.dispose();
    _passCtr.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(authProvider.notifier)
      .login(normalizeEthiopianPhone(_phoneCtr.text), _passCtr.text);
  }

  // â”€â”€ Strings â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  String get _title       => _lang == Lang.en ? 'Shmeta'                      : '\u{123D}\u{121C}\u{1273}';
  String get _subtitle    => _lang == Lang.en ? 'Sign in to your account'     : '\u{12C8}\u{12F0} \u{1215}\u{1233}\u{1265}\u{1215} \u{130D}\u{1263}';
  String get _phoneLabel  => _lang == Lang.en ? 'Phone Number'                : '\u{1235}\u{120D}\u{12AD} \u{1241}\u{1305}\u{122D}';
  String get _phoneHint   => _lang == Lang.en ? '9xxxxxxxx, 09xxxxxxxxx, or 251xxxxxxxxx' : '9xxxxxxxx, 09xxxxxxxxx, \u{12C8}\u{12EE} 251xxxxxxxxx';
  String get _passLabel   => _lang == Lang.en ? 'Password'                    : '\u{12E8}\u{121A}\u{1235}\u{1325}\u{122D} \u{134D}\u{1208}\u{1303}';
  String get _forgotText  => _lang == Lang.en ? 'Forgot Password?'            : '\u{12E8}\u{121A}\u{1235}\u{1325}\u{122D} \u{134D}\u{1208}\u{1303} \u{1228}\u{1231}?';
  String get _signInText  => _lang == Lang.en ? 'Sign In'                     : '\u{130D}\u{1263}';
  String get _phoneReq    => _lang == Lang.en ? 'Phone number is required'    : '\u{1235}\u{120D}\u{12AD} \u{1241}\u{1305}\u{122D} \u{12EB}\u{1235}\u{1348}\u{120D}\u{130B}\u{120D}';
  String get _phone10     => _lang == Lang.en ? 'Use 9 digits (9...), 10 digits (09...), or 12 digits (251...)' : '\u{1235}\u{120D}\u{12AD} \u{1241}\u{1305}\u{122D} 9, 10, \u{12C9} 12 \u{12A0}\u{1203}\u{12DE}\u{127D} \u{12ED}\u{1301}\u{1235}\u{1260}\u{1229}';
  String get _phone09     => _lang == Lang.en ? 'Must start with 9 or 7'   : '9 \u{12C8}\u{12ED}\u{121D} 7 \u{121B}\u{1230}\u{1300}\u{1218}\u{122D} \u{12A0}\u{1208}\u{1260}\u{1275}';
  String get _passReq     => _lang == Lang.en ? 'Password is required'        : '\u{12E8}\u{121A}\u{1235}\u{1325}\u{122D} \u{134D}\u{1208}\u{1303} \u{12EB}\u{1235}\u{1348}\u{120D}\u{130B}\u{120D}';
  String get _passMin     => _lang == Lang.en ? 'Minimum 6 characters'        : '\u{1262}\u{12EB}\u{1295}\u{1235} 6 \u{1241}\u{121D}\u{134A}\u{12CE}\u{127D}';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);
    final lang = ref.watch(languageProvider);
    if (_lang != lang) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _lang = lang);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // â”€â”€ Language switcher bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _LangChip(
                    label: 'EN',
                    selected: lang == Lang.en,
                    onTap: () {
                      setState(() => _lang = Lang.en);
                      ref.read(languageProvider.notifier).setLanguage(Lang.en);
                    },
                  ),
                  const SizedBox(width: 8),
                  _LangChip(
                    label: '\u{12A0}\u{121B}',
                    selected: lang == Lang.am,
                    onTap: () {
                      setState(() => _lang = Lang.am);
                      ref.read(languageProvider.notifier).setLanguage(Lang.am);
                    },
                  ),
                ],
              ),
            ),

            // â”€â”€ Rest of screen â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 16),

                        // â”€â”€ Logo â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 90, height: 90,
                                decoration: BoxDecoration(
                                  color: AppColors.dark,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.dark.withValues(alpha: 0.25),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),   
                                  ],
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Image.asset(
                                  'assets/images/logo.jpg',
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _title,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.dark,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _subtitle,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textMid,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // â”€â”€ Tab switcher: Login / Register â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: const Border.fromBorderSide(BorderSide(color: AppColors.border)),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Row(
                            children: [
                              _TabButton(
                                label: _lang == Lang.en ? 'Sign In' : '\u{130D}\u{1263}',
                                selected: _tab == _Tab.login,
                                onTap: () => setState(() => _tab = _Tab.login),
                              ),
                              _TabButton(
                                label: _lang == Lang.en ? 'Register' : '\u{1270}\u{1218}\u{12DD}\u{130D}\u{1265}',
                                selected: _tab == _Tab.register,
                                onTap: () => setState(() => _tab = _Tab.register),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // â”€â”€ Tab content â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: _tab == _Tab.login
                              ? _LoginCard(
                                  key: const ValueKey('login'),
                                  formKey:    _formKey,
                                  phoneCtr:   _phoneCtr,
                                  passCtr:    _passCtr,
                                  obscure:    _obscure,
                                  loading:    state.isLoading,
                                  error:      state.error,
                                  lang:       _lang,
                                  phoneLabel: _phoneLabel,
                                  phoneHint:  _phoneHint,
                                  passLabel:  _passLabel,
                                  forgotText: _forgotText,
                                  signInText: _signInText,
                                  phoneReq:   _phoneReq,
                                  phone10:    _phone10,
                                  phone09:    _phone09,
                                  passReq:    _passReq,
                                  passMin:    _passMin,
                                  onToggleObscure: () => setState(() => _obscure = !_obscure),
                                  onForgot:   () => context.push('/forgot-password'),
                                  onSubmit:   _submit,
                                )
                              : RegisterForm(
                                  key: const ValueKey('register'),
                                  lang: _lang,
                                ),
                        ),

                        const SizedBox(height: 56),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€ Tab button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _TabButton extends StatelessWidget {
  const _TabButton({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool   selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? AppColors.dark : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: selected ? AppColors.cream : AppColors.textMid,
            ),
          ),
        ),
      ),
    );
  }
}

// â”€â”€ Language chip â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _LangChip extends StatelessWidget {
  const _LangChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool   selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.dark : Colors.white,
          border: Border.all(color: selected ? AppColors.dark : AppColors.border),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.cream : AppColors.dark,
          ),
        ),
      ),
    );
  }
}

// â”€â”€ Login card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _LoginCard extends StatelessWidget {
  const _LoginCard({
    super.key,
    required this.formKey,
    required this.phoneCtr,
    required this.passCtr,
    required this.obscure,
    required this.loading,
    required this.error,
    required this.lang,
    required this.phoneLabel,
    required this.phoneHint,
    required this.passLabel,
    required this.forgotText,
    required this.signInText,
    required this.phoneReq,
    required this.phone10,
    required this.phone09,
    required this.passReq,
    required this.passMin,
    required this.onToggleObscure,
    required this.onForgot,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController phoneCtr;
  final TextEditingController passCtr;
  final bool obscure;
  final bool loading;
  final String? error;
  final Lang lang;
  final String phoneLabel, phoneHint, passLabel, forgotText, signInText;
  final String phoneReq, phone10, phone09, passReq, passMin;
  final VoidCallback onToggleObscure;
  final VoidCallback onForgot;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: const Border.fromBorderSide(BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: AppColors.dark.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Phone
            TextFormField(
              controller:   phoneCtr,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                TextInputFormatter.withFunction((oldValue, newValue) {
                  final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
                  final maxDigits = digits.startsWith('251')
                      ? 12
                      : digits.startsWith('0')
                          ? 10
                          : 9;
                  final maxLength = newValue.text.startsWith('+') ? 13 : maxDigits;
                  return newValue.text.length <= maxLength ? newValue : oldValue;
                }),
              ],
              decoration: InputDecoration(
                labelText:   phoneLabel,
                hintText:    phoneHint,
                prefixIcon:  const Icon(Icons.phone_outlined),
                counterText: '',
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return phoneReq;
                final digits = v.replaceAll(RegExp(r'\D'), '');
                final expectedLength = digits.startsWith('251')
                    ? 12
                    : digits.startsWith('0')
                        ? 10
                        : 9;
                if (digits.length != expectedLength) return phone10;
                if (!isValidEthiopianPhone(v)) return phone09;
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Password
            TextFormField(
              controller:  passCtr,
              obscureText: obscure,
              decoration: InputDecoration(
                labelText:  passLabel,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.textMid,
                    size: 20,
                  ),
                  onPressed: onToggleObscure,
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return passReq;
                if (v.length < 6)           return passMin;
                return null;
              },
            ),

            // Forgot
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onForgot,
                style: TextButton.styleFrom(foregroundColor: AppColors.gold),
                child: Text(forgotText, style: const TextStyle(fontSize: 13)),
              ),
            ),

            // Error
            if (error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade400, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        error!,
                        style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            const SizedBox(height: 4),

            // Submit
            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: loading ? null : onSubmit,
                child: loading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            height: 18, width: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.cream),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            lang == Lang.en ? 'Signing in...' : '\u{1260}\u{1218}\u{130D}\u{1263}\u{1275}...',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      )
                    : Text(signInText, style: const TextStyle(fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€ Register card (info) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _RegisterCard extends StatelessWidget {
  const _RegisterCard({super.key, required this.lang});
  final Lang lang;

  @override
  Widget build(BuildContext context) {
    final isEn = lang == Lang.en;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: const Border.fromBorderSide(BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: AppColors.dark.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 68, height: 68,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_add_rounded, size: 34, color: AppColors.gold),
          ),
          const SizedBox(height: 16),
          Text(
            isEn ? 'New Account' : '\u{12A0}\u{12ED}\u{1235} \u{1273}\u{12D4}\u{1275}\u{1235}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.dark),
          ),
          const SizedBox(height: 10),
          Text(
            isEn
                ? 'Accounts are created by your admin.\nContact your Shmeta administrator to get registered.'
                : '\u{12A5}\u{12ED}\u{1275}\u{12A5}\u{1233}\u{1275} \u{12A0}\u{12A0}\u{12ED}\u{1235}\u{12A0}\u{12E8}\u{120D}\u{12AD}\u{1295}\u{1275} \u{12AD}\u{1275}\u{1265}\u{1275}\u{1295}\u{1275}\u{1295}\u{1275}\u{122D}\u{12A5}\u{1275}\u{120D}\u{1265}\u{1274}\u{121D}\u{12A5}\u{120D}\u{12D5}\u{1233}\u{1275}\u{120D}\u{1303}\u{120D}\u{1295}\u{12C8}\u{1235}\u{1293}\u{120D}\u{1265}\u{1235}\u{1275}\u{120D}\u{12A3}\u{1275}\u{120D} \u{12A0}\u{1235}\u{120D}\u{1260}\u{1275}\u{120D}\u{1295}\u{1275}\u{120D}\u{1235}\u{12C8}\u{1235} Shmeta \u{12A0}\u{12ED}\u{1235}\u{12A0}\u{12E8}\u{120D}\u{12AD}\u{1295}\u{1275}\u{120D}\u{1235}\u{12C8}\u{1235}\u{1275}\u{120D}\u{12A3}\u{1275}\u{120D}\u{120D}\u{12C8}\u{1260}\u{1275}\u{120D}\u{1273}\u{120D}\u{12A5}\u{1275}\u{120D}\u{122D}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13.5, color: AppColors.textMid, height: 1.6),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.gold, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isEn
                        ? 'Ask your admin to add your phone number and role in the Shmeta Admin Panel.'
                        : '\u{12A0}\u{12ED}\u{1235}\u{12A0}\u{12E8}\u{120D}\u{12AD}\u{1295}\u{1275}\u{120D}\u{1235}\u{12C8}\u{1235} Shmeta \u{12A0}\u{12ED}\u{1235}\u{12A0}\u{12E8}\u{120D}\u{12AD}\u{1295}\u{1275}\u{120D}\u{1235} \u{12C9}\u{12A5}\u{12AB}\u{12A5}\u{121D}\u{12AA} \u{12A5}\u{12AD}\u{12C8}\u{12F5} \u{1235}\u{120D}\u{12AD}\u{12A5}\u{1235}\u{120D} \u{12EB}\u{12CD}\u{12A3}\u{1295} \u{12A0}\u{1233}\u{12A5}\u{1275}\u{120D}\u{1275}\u{12A0}\u{1260}\u{1275}\u{120D}\u{1295}\u{1275}\u{120D} ',
                    style: const TextStyle(fontSize: 12.5, color: AppColors.dark, height: 1.4),
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
