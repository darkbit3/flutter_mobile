import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _phoneCtr = TextEditingController();
  bool  _submitted = false;

  @override
  void dispose() {
    _phoneCtr.dispose();
    super.dispose();
  }

  void _submit() {
    // Force validation on every field before proceeding
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitted = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
        leading: BackButton(onPressed: () => context.go('/login')),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: _submitted
                  ? _SuccessView(phone: _phoneCtr.text)
                  : _FormView(
                      formKey: _formKey,
                      phoneCtr: _phoneCtr,
                      onSubmit: _submit,
                      onBack: () => context.go('/login'),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Phone input form ──────────────────────────────────────────────────────────

class _FormView extends StatefulWidget {
  const _FormView({
    required this.formKey,
    required this.phoneCtr,
    required this.onSubmit,
    required this.onBack,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController phoneCtr;
  final VoidCallback onSubmit;
  final VoidCallback onBack;

  @override
  State<_FormView> createState() => _FormViewState();
}

class _FormViewState extends State<_FormView> {
  // Track whether user has touched the field (to show live errors only after first interaction)
  bool _dirty = false;

  String get _phone => widget.phoneCtr.text;

  // ── Individual rule checks ────────────────────────────────────────────────

  bool get _notEmpty   => _phone.isNotEmpty;
  bool get _startsRight => RegExp(r'^0[97]').hasMatch(_phone);
  bool get _fullLength  => _phone.length == 10;
  bool get _allDigits   => RegExp(r'^\d+$').hasMatch(_phone);
  bool get _allPassed   => _notEmpty && _allDigits && _startsRight && _fullLength;

  @override
  void initState() {
    super.initState();
    widget.phoneCtr.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.phoneCtr.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (!_dirty && _phone.isNotEmpty) setState(() => _dirty = true);
    if (_dirty) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      autovalidateMode: _dirty
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 48),

          // Icon
          const Icon(Icons.lock_reset_rounded, size: 72, color: AppColors.gold),
          const SizedBox(height: 20),

          // Title
          Text(
            'Forgot Password',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          // Subtitle
          Text(
            'Enter your registered phone number.\nAn admin will reset your password.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 36),

          // ── Phone field ──────────────────────────────────────────────────
          TextFormField(
            controller: widget.phoneCtr,
            keyboardType: TextInputType.phone,
            autofocus: true,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            decoration: InputDecoration(
              labelText: 'Phone Number',
              hintText: '09xxxxxxxx or 07xxxxxxxx',
              prefixIcon: const Icon(Icons.phone),
              border: const OutlineInputBorder(),
              counterText: '',
              // Live digit counter suffix
              suffixText: '${_phone.length}/10',
              suffixStyle: TextStyle(
                fontSize: 12,
                color: _phone.length == 10
                    ? Colors.green.shade700
                    : Colors.grey,
              ),
            ),
            validator: (v) {
              final val = v ?? '';
              if (val.isEmpty)    return 'Phone number is required';
              if (val.length < 10) return 'Phone must be exactly 10 digits';
              if (!RegExp(r'^0[97]\d{8}$').hasMatch(val)) {
                return 'Must start with 09 or 07  (e.g. 0912345678)';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // ── Live rule checklist (shown once user starts typing) ──────────
          if (_dirty) ...[
            _RuleRow(passed: _notEmpty,    label: 'Phone number is not empty'),
            _RuleRow(passed: _allDigits,   label: 'Digits only (no letters or spaces)'),
            _RuleRow(passed: _startsRight, label: 'Starts with 09 or 07'),
            _RuleRow(passed: _fullLength,  label: 'Exactly 10 digits'),
            const SizedBox(height: 12),
          ],

          const SizedBox(height: 12),

          // ── Submit ───────────────────────────────────────────────────────
          FilledButton(
            onPressed: widget.onSubmit,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              // Dim button when rules not passed yet
              backgroundColor: _dirty && !_allPassed
                  ? Colors.grey.shade400
                  : null,
            ),
            child: const Text('Submit', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 12),

          // ── Back to login ─────────────────────────────────────────────────
          OutlinedButton(
            onPressed: widget.onBack,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Back to Login'),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

// ── Single validation rule row ────────────────────────────────────────────────

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.passed, required this.label});

  final bool   passed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            passed ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: passed ? Colors.green.shade600 : Colors.red.shade400,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: passed ? Colors.green.shade700 : Colors.red.shade400,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Success confirmation ──────────────────────────────────────────────────────

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.phone});

  final String phone;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 64),

        const Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
        const SizedBox(height: 24),

        Text(
          'Request Sent',
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        Text(
          'Your reset request for\n$phone\nhas been submitted.\nPlease contact an admin to complete the reset.',
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Colors.grey.shade600, height: 1.6),
        ),
        const SizedBox(height: 40),

        FilledButton(
          onPressed: () => context.go('/login'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('Back to Login', style: TextStyle(fontSize: 16)),
        ),
        const SizedBox(height: 48),
      ],
    );
  }
}
