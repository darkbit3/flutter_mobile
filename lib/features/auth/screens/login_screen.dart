import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

// ── Language options ───────────────────────────────────────────────────────
enum _Lang { en, am }

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

  // ── Strings ──────────────────────────────────────────────────────────────
  String get _title       => _lang == _Lang.en ? 'Shmeta'                      : 'ሽሜታ';
  String get _subtitle    => _lang == _Lang.en ? 'Sign in to your account'     : 'ወደ መለያዎ ይግቡ';
  String get _phoneLabel  => _lang == _Lang.en ? 'Phone Number'                : 'ስልክ ቁጥር';
  String get _phoneHint   => _lang == _Lang.en ? '09xxxxxxxx or 07xxxxxxxx'    : '09xxxxxxxx ወይም 07xxxxxxxx';
  String get _passLabel   => _lang == _Lang.en ? 'Password'                    : 'የሚስጥር ቃል';
  String get _forgotText  => _lang == _Lang.en ? 'Forgot Password?'            : 'የሚስጥር ቃሉን ረሱ?';
  String get _signInText  => _lang == _Lang.en ? 'Sign In'                     : 'ግባ';
  String get _phoneReq    => _lang == _Lang.en ? 'Phone number is required'    : 'ስልክ ቁጥር ያስፈልጋል';
  String get _phone10     => _lang == _Lang.en ? 'Phone must be exactly 10 digits' : 'ስልክ ቁጥር 10 አሃዝ መሆን አለበት';
  String get _phone09     => _lang == _Lang.en ? 'Must start with 09 or 07'   : '09 ወይም 07 መጀመር አለበት';
  String get _passReq     => _lang == _Lang.en ? 'Password is required'        : 'የሚስጥር ቃል ያስፈልጋል';
  String get _passMin     => _lang == _Lang.en ? 'Minimum 6 characters'        : 'ቢያንስ 6 ፊደሎች';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (_, next) {
      // Navigation is handled by GoRouter's refreshListenable redirect.
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Language switcher bar ─────────────────────────────────────
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
                    label: 'አማ',
                    selected: _lang == _Lang.am,
                    onTap: () => setState(() => _lang = _Lang.am),
                  ),
                ],
              ),
            ),

            // ── Rest of screen ────────────────────────────────────────────
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 16),

                          // ── Logo ─────────────────────────────────────────
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
                          const SizedBox(height: 40),

                          // ── Card ──────────────────────────────────────────
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: const Border.fromBorderSide(
                                  BorderSide(color: AppColors.border)),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.dark.withValues(alpha: 0.06),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Phone
                                TextFormField(
                                  controller:   _phoneCtr,
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(10),
                                  ],
                                  decoration: InputDecoration(
                                    labelText:   _phoneLabel,
                                    hintText:    _phoneHint,
                                    prefixIcon:  const Icon(Icons.phone_outlined),
                                    counterText: '',
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return _phoneReq;
                                    if (v.length != 10)         return _phone10;
                                    if (!RegExp(r'^0[97]\d{8}$').hasMatch(v)) return _phone09;
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Password
                                TextFormField(
                                  controller:  _passCtr,
                                  obscureText: _obscure,
                                  decoration: InputDecoration(
                                    labelText:  _passLabel,
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscure
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: AppColors.textMid,
                                        size: 20,
                                      ),
                                      onPressed: () =>
                                          setState(() => _obscure = !_obscure),
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return _passReq;
                                    if (v.length < 6)           return _passMin;
                                    return null;
                                  },
                                ),

                                // Forgot
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () => context.push('/forgot-password'),
                                    style: TextButton.styleFrom(
                                        foregroundColor: AppColors.gold),
                                    child: Text(_forgotText,
                                        style: const TextStyle(fontSize: 13)),
                                  ),
                                ),

                                // Error
                                if (state.error != null) ...[
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.red.shade200),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.error_outline,
                                            color: Colors.red.shade400, size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            state.error!,
                                            style: TextStyle(
                                                color: Colors.red.shade700,
                                                fontSize: 13),
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
                                    onPressed: state.isLoading ? null : _submit,
                                    child: state.isLoading
                                        ? Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const SizedBox(
                                                height: 18, width: 18,
                                                child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: AppColors.cream),
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                _lang == _Lang.en ? 'Signing in...' : 'እየገባ ነው...',
                                                style: const TextStyle(fontSize: 14),
                                              ),
                                            ],
                                          )
                                        : Text(_signInText,
                                            style: const TextStyle(fontSize: 15)),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 56),
                        ],
                      ),
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

// ── Language chip widget ──────────────────────────────────────────────────
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
