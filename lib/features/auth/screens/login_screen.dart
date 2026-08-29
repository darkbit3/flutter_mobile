import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

// â”€â”€ Language options â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
enum _Lang { en, am }
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
  _Lang _lang     = _Lang.en;
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
        .login(_phoneCtr.text.trim(), _passCtr.text);
  }

  // â”€â”€ Strings â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  String get _title       => _lang == _Lang.en ? 'Shmeta'                      : 'áˆ½áˆœá‰³';
  String get _subtitle    => _lang == _Lang.en ? 'Sign in to your account'     : 'á‹ˆá‹° áˆ˜áˆˆá‹«á‹Ž á‹­áŒá‰¡';
  String get _phoneLabel  => _lang == _Lang.en ? 'Phone Number'                : 'áˆµáˆáŠ­ á‰áŒ¥áˆ­';
  String get _phoneHint   => _lang == _Lang.en ? '09xxxxxxxx or 07xxxxxxxx'    : '09xxxxxxxx á‹ˆá‹­áˆ 07xxxxxxxx';
  String get _passLabel   => _lang == _Lang.en ? 'Password'                    : 'á‹¨áˆšáˆµáŒ¥áˆ­ á‰ƒáˆ';
  String get _forgotText  => _lang == _Lang.en ? 'Forgot Password?'            : 'á‹¨áˆšáˆµáŒ¥áˆ­ á‰ƒáˆ‰áŠ• áˆ¨áˆ±?';
  String get _signInText  => _lang == _Lang.en ? 'Sign In'                     : 'áŒá‰£';
  String get _phoneReq    => _lang == _Lang.en ? 'Phone number is required'    : 'áˆµáˆáŠ­ á‰áŒ¥áˆ­ á‹«áˆµáˆáˆáŒ‹áˆ';
  String get _phone10     => _lang == _Lang.en ? 'Phone must be exactly 10 digits' : 'áˆµáˆáŠ­ á‰áŒ¥áˆ­ 10 áŠ áˆƒá‹ áˆ˜áˆ†áŠ• áŠ áˆˆá‰ á‰µ';
  String get _phone09     => _lang == _Lang.en ? 'Must start with 09 or 07'   : '09 á‹ˆá‹­áˆ 07 áˆ˜áŒ€áˆ˜áˆ­ áŠ áˆˆá‰ á‰µ';
  String get _passReq     => _lang == _Lang.en ? 'Password is required'        : 'á‹¨áˆšáˆµáŒ¥áˆ­ á‰ƒáˆ á‹«áˆµáˆáˆáŒ‹áˆ';
  String get _passMin     => _lang == _Lang.en ? 'Minimum 6 characters'        : 'á‰¢á‹«áŠ•áˆµ 6 áŠá‹°áˆŽá‰½';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // â”€â”€ Language switcher bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _LangChip(
                    label: 'EN',
                    selected: _lang == _Lang.en,
                    onTap: () => setState(() => _lang = _Lang.en),
                  ),
                  const SizedBox(width: 8),
                  _LangChip(
                    label: 'áŠ áˆ›',
                    selected: _lang == _Lang.am,
                    onTap: () => setState(() => _lang = _Lang.am),
                  ),
                ],
              ),
            ),

            // â”€â”€ Rest of screen â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

                        // â”€â”€ Logo â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

                        // â”€â”€ Tab switcher: Login / Register â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
                                label: _lang == _Lang.en ? 'Sign In' : 'áŒá‰£',
                                selected: _tab == _Tab.login,
                                onTap: () => setState(() => _tab = _Tab.login),
                              ),
                              _TabButton(
                                label: _lang == _Lang.en ? 'Register' : 'á‰°áˆ˜á‹áŒˆá‰¥',
                                selected: _tab == _Tab.register,
                                onTap: () => setState(() => _tab = _Tab.register),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // â”€â”€ Tab content â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
                              : _RegisterCard(
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

// â”€â”€ Tab button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

// â”€â”€ Login card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
  final _Lang lang;
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
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: InputDecoration(
                labelText:   phoneLabel,
                hintText:    phoneHint,
                prefixIcon:  const Icon(Icons.phone_outlined),
                counterText: '',
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return phoneReq;
                if (v.length != 10)         return phone10;
                if (!RegExp(r'^0[97]\d{8}$').hasMatch(v)) return phone09;
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
                            lang == _Lang.en ? 'Signing in...' : 'áŠ¥á‹¨áŒˆá‰£ áŠá‹...',
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

// â”€â”€ Register card (info) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _RegisterCard extends StatelessWidget {
  const _RegisterCard({super.key, required this.lang});
  final _Lang lang;

  @override
  Widget build(BuildContext context) {
    final isEn = lang == _Lang.en;
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
            isEn ? 'New Account' : 'áŠ á‹²áˆµ áˆ˜áˆˆá‹«',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.dark),
          ),
          const SizedBox(height: 10),
          Text(
            isEn
                ? 'Accounts are created by your admin.\nContact your Shmeta administrator to get registered.'
                : 'áˆ˜áˆˆá‹«á‹Ž á‰ áŠ áˆµá‰°á‹³á‹³áˆªá‹Ž á‹­áˆáŒ áˆ«áˆá¢\náˆŠáˆ˜á‹˜áŒˆá‰¡ áˆˆáˆšáˆáˆáŒ‰ Shmeta áŠ áˆµá‰°á‹³á‹³áˆªá‹ŽáŠ• á‹«áŠáŒ‹áŒáˆ©á¢',
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
                        : 'áŠ áˆµá‰°á‹³á‹³áˆªá‹Ž Shmeta áŠ áˆµá‰°á‹³á‹³áˆª á“áŠ“áˆ‰ áˆ‹á‹­ áˆµáˆáŠ­ á‰áŒ¥áˆ­á‹ŽáŠ• áŠ¥áŠ“ áˆšáŠ“á‹ŽáŠ• áŠ¥áŠ•á‹²áŒ¨áˆáˆ­ á‹­áŒ á‹­á‰á¢',
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

// â”€â”€ Language chip widget â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _LangChip extends StatelessWidget {
  const _LangChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool   selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color:        selected ? AppColors.dark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border:       Border.all(
            color: selected ? AppColors.dark : AppColors.border,
            width: 1.5,
          ),
          boxShadow: selected
              ? [BoxShadow(
                  color: AppColors.dark.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize:   13,
            fontWeight: FontWeight.w600,
            color:      selected ? AppColors.cream : AppColors.textMid,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

// â”€â”€ Language options â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
