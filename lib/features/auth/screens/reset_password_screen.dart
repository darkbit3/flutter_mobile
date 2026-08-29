import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../data/auth_repository.dart';

// ── Steps ─────────────────────────────────────────────────────────────────────
enum _Step { phone, otp, done }

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  _Step _step = _Step.phone;

  // Phone step
  final _phoneCtr = TextEditingController();
  bool _phoneLoading = false;
  String? _phoneError;
  String? _otpFromServer; // shown in dev so user can see the code

  // OTP step
  final _otpCtr     = TextEditingController();
  final _newPassCtr = TextEditingController();
  final _confirmPassCtr = TextEditingController();
  bool _otpLoading  = false;
  String? _otpError;
  bool _obscureNew  = true;
  bool _obscureConf = true;

  @override
  void dispose() {
    _phoneCtr.dispose();
    _otpCtr.dispose();
    _newPassCtr.dispose();
    _confirmPassCtr.dispose();
    super.dispose();
  }

  // ── Step 1: Check phone ───────────────────────────────────────────────────
  Future<void> _submitPhone() async {
    final phone = _phoneCtr.text.trim();
    if (phone.isEmpty) { setState(() => _phoneError = 'Phone number is required'); return; }
    if (phone.length != 10) { setState(() => _phoneError = 'Phone must be exactly 10 digits'); return; }
    if (!RegExp(r'^0[97]\d{8}$').hasMatch(phone)) { setState(() => _phoneError = 'Must start with 09 or 07'); return; }

    setState(() { _phoneLoading = true; _phoneError = null; });
    try {
      final repo   = ref.read(authRepositoryProvider);
      final result = await repo.forgotPasswordCheckPhone(phone);
      setState(() {
        _phoneLoading  = false;
        _otpFromServer = result['otp'] as String?; // dev only
        _step          = _Step.otp;
      });
    } catch (e) {
      setState(() { _phoneLoading = false; _phoneError = e.toString(); });
    }
  }

  // ── Step 2: Verify OTP + set new password ─────────────────────────────────
  Future<void> _submitOtp() async {
    final otp     = _otpCtr.text.trim();
    final newPass = _newPassCtr.text;
    final conf    = _confirmPassCtr.text;

    if (otp.length != 6)          { setState(() => _otpError = 'OTP must be 6 digits'); return; }
    if (newPass.length < 6)       { setState(() => _otpError = 'Password must be at least 6 characters'); return; }
    if (newPass != conf)          { setState(() => _otpError = 'Passwords do not match'); return; }

    setState(() { _otpLoading = true; _otpError = null; });
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.forgotPasswordVerifyOtp(
        phone:       _phoneCtr.text.trim(),
        otp:         otp,
        newPassword: newPass,
      );
      setState(() { _otpLoading = false; _step = _Step.done; });
    } catch (e) {
      setState(() { _otpLoading = false; _otpError = e.toString(); });
    }
  }

  // ── UI ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.dark,
        foregroundColor: AppColors.cream,
        title: const Text('Forgot Password'),
        leading: BackButton(onPressed: () {
          if (_step == _Step.otp) {
            setState(() { _step = _Step.phone; _otpError = null; _otpCtr.clear(); _newPassCtr.clear(); _confirmPassCtr.clear(); });
          } else {
            context.go('/login');
          }
        }),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: switch (_step) {
                  _Step.phone => _PhoneStep(
                      key: const ValueKey('phone'),
                      phoneCtr:    _phoneCtr,
                      loading:     _phoneLoading,
                      error:       _phoneError,
                      onSubmit:    _submitPhone,
                      onBack:      () => context.go('/login'),
                    ),
                  _Step.otp => _OtpStep(
                      key: const ValueKey('otp'),
                      phone:        _phoneCtr.text.trim(),
                      devOtp:       _otpFromServer,
                      otpCtr:       _otpCtr,
                      newPassCtr:   _newPassCtr,
                      confirmCtr:   _confirmPassCtr,
                      loading:      _otpLoading,
                      error:        _otpError,
                      obscureNew:   _obscureNew,
                      obscureConf:  _obscureConf,
                      onToggleNew:  () => setState(() => _obscureNew = !_obscureNew),
                      onToggleConf: () => setState(() => _obscureConf = !_obscureConf),
                      onSubmit:     _submitOtp,
                      onResend:     () { setState(() { _step = _Step.phone; _otpCtr.clear(); _newPassCtr.clear(); _confirmPassCtr.clear(); }); },
                    ),
                  _Step.done => _DoneStep(
                      key: const ValueKey('done'),
                      onLogin: () => context.go('/login'),
                    ),
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══ Step 1: Phone input ══════════════════════════════════════════════════════

class _PhoneStep extends StatelessWidget {
  const _PhoneStep({
    super.key,
    required this.phoneCtr,
    required this.loading,
    required this.error,
    required this.onSubmit,
    required this.onBack,
  });

  final TextEditingController phoneCtr;
  final bool loading;
  final String? error;
  final VoidCallback onSubmit;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        // Icon
        Center(
          child: Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_reset_rounded, size: 40, color: AppColors.gold),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Forgot Password',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.dark),
        ),
        const SizedBox(height: 8),
        const Text(
          'Enter your registered phone number.\nWe\'ll send you a verification code.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13.5, color: AppColors.textMid, height: 1.5),
        ),
        const SizedBox(height: 32),

        // Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: const Border.fromBorderSide(BorderSide(color: AppColors.border)),
            boxShadow: [BoxShadow(color: AppColors.dark.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: phoneCtr,
                keyboardType: TextInputType.phone,
                autofocus: true,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '09xxxxxxxx or 07xxxxxxxx',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  counterText: '',
                  errorText: error,
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                height: 50,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.dark,
                    foregroundColor: AppColors.cream,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: loading ? null : onSubmit,
                  child: loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Send OTP', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: onBack,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.dark,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Back to Login'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

// ═══ Step 2: OTP + new password ═══════════════════════════════════════════════

class _OtpStep extends StatelessWidget {
  const _OtpStep({
    super.key,
    required this.phone,
    required this.devOtp,
    required this.otpCtr,
    required this.newPassCtr,
    required this.confirmCtr,
    required this.loading,
    required this.error,
    required this.obscureNew,
    required this.obscureConf,
    required this.onToggleNew,
    required this.onToggleConf,
    required this.onSubmit,
    required this.onResend,
  });

  final String phone;
  final String? devOtp;
  final TextEditingController otpCtr;
  final TextEditingController newPassCtr;
  final TextEditingController confirmCtr;
  final bool loading;
  final String? error;
  final bool obscureNew;
  final bool obscureConf;
  final VoidCallback onToggleNew;
  final VoidCallback onToggleConf;
  final VoidCallback onSubmit;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Center(
          child: Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.sms_outlined, size: 40, color: Colors.blue),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Enter Verification Code',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.dark),
        ),
        const SizedBox(height: 8),
        Text(
          'Code sent to $phone\nEnter it below and set your new password.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: AppColors.textMid, height: 1.5),
        ),
        // Dev banner — shows the OTP code
        if (devOtp != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: Colors.amber.shade700),
                const SizedBox(width: 8),
                Text(
                  'Dev mode — OTP: $devOtp',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.amber.shade800),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),

        // Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: const Border.fromBorderSide(BorderSide(color: AppColors.border)),
            boxShadow: [BoxShadow(color: AppColors.dark.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // OTP field
              TextFormField(
                controller: otpCtr,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                autofocus: true,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 10),
                decoration: const InputDecoration(
                  labelText: 'Verification Code',
                  hintText: '• • • • • •',
                  counterText: '',
                  prefixIcon: Icon(Icons.pin_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // New password
              TextFormField(
                controller: newPassCtr,
                obscureText: obscureNew,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(obscureNew ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                    onPressed: onToggleNew,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Confirm password
              TextFormField(
                controller: confirmCtr,
                obscureText: obscureConf,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(obscureConf ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                    onPressed: onToggleConf,
                  ),
                ),
              ),

              // Error
              if (error != null) ...[
                const SizedBox(height: 12),
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
                      Expanded(child: Text(error!, style: TextStyle(color: Colors.red.shade700, fontSize: 13))),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),
              SizedBox(
                height: 50,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.dark,
                    foregroundColor: AppColors.cream,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: loading ? null : onSubmit,
                  child: loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Reset Password', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: onResend,
                child: const Text('Resend Code', style: TextStyle(color: AppColors.gold)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

// ═══ Step 3: Success ══════════════════════════════════════════════════════════

class _DoneStep extends StatelessWidget {
  const _DoneStep({super.key, required this.onLogin});
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 48),
        Center(
          child: Container(
            width: 90, height: 90,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded, size: 52, color: Colors.green),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Password Reset!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.dark),
        ),
        const SizedBox(height: 10),
        const Text(
          'Your password has been reset successfully.\nYou can now sign in with your new password.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13.5, color: AppColors.textMid, height: 1.5),
        ),
        const SizedBox(height: 36),
        SizedBox(
          height: 50,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.dark,
              foregroundColor: AppColors.cream,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: onLogin,
            child: const Text('Back to Login', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 48),
      ],
    );
  }
}
