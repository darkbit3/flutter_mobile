// Register form widget for user registration
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/register_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../constants/lang_constants.dart';

class RegisterForm extends ConsumerStatefulWidget {
  const RegisterForm({Key? key, required this.lang}) : super(key: key);

  final Lang lang;

  @override
  ConsumerState<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends ConsumerState<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String _normalizePhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D+'), '');
    if (digits.startsWith('251')) return digits;
    return '251$digits';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(registerProvider.notifier);
    await notifier.register(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _normalizePhone(_phoneCtrl.text),
      password: _passCtrl.text,
    );
    final state = ref.read(registerProvider);
    if (state.success) {
      // Navigate to OTP screen
      if (mounted) {
        context.go('/register-otp');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final registerState = ref.watch(registerProvider);
    final isEn = widget.lang == Lang.en;
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
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Name
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: isEn ? 'Name' : 'ስም',
                prefixIcon: const Icon(Icons.person),
              ),
              validator: (v) => v == null || v.isEmpty ? (isEn ? 'Name required' : 'ስም ያስፈልጋል') : null,
            ),
            const SizedBox(height: 12),
            // Email
            TextFormField(
              controller: _emailCtrl,
              decoration: InputDecoration(
                labelText: isEn ? 'Email' : 'ኢሜይል',
                prefixIcon: const Icon(Icons.email_outlined),
              ),
              validator: (v) => v == null || v.isEmpty ? (isEn ? 'Email required' : 'ኢሜይል ያስፈልጋል') : null,
            ),
            const SizedBox(height: 12),
            // Phone
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(9),
              ],
              decoration: InputDecoration(
                labelText: isEn ? 'Phone Number' : 'ስልክ ቁጥር',
                prefixText: '251 ',
                prefixIcon: const Icon(Icons.phone_outlined),
                hintText: isEn ? '9xxxxxxxx or 7xxxxxxxx' : '9xxxxxxxx ወይም 7xxxxxxxx',
                counterText: '',
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return isEn ? 'Phone required' : 'ስልክ ያስፈልጋል';
                final normalized = _normalizePhone(v);
                if (normalized.length != 12) return isEn ? 'Phone must be 12 digits starting with 251' : 'ስልክ 12 ቁጥር መሆን አለበት እና 251 ከጀመረ';
                if (!RegExp(r'^251[97]\d{8}$').hasMatch(normalized)) return isEn ? 'Must start with 251 and then 9 digits starting with 9 or 7' : '251 እና 9 ቁጥሮች መሆን አለበት እና 9 ወይም 7 ከጀመረ';
                return null;
              },
            ),
            const SizedBox(height: 12),
            // Password
            TextFormField(
              controller: _passCtrl,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: isEn ? 'Password' : 'ሚስጥር',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: AppColors.textMid,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return isEn ? 'Password required' : 'ሚስጥር ያስፈልጋል';
                if (v.length < 6) return isEn ? 'Min 6 chars' : 'ቢያንስ 6 ቁምፊ';
                return null;
              },
            ),
            const SizedBox(height: 12),
            // Confirm Password
            TextFormField(
              controller: _confirmCtrl,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: isEn ? 'Confirm Password' : 'ሚስጥር እናረጋግጣለን',
                prefixIcon: const Icon(Icons.lock),
              ),
              validator: (v) => v != _passCtrl.text ? (isEn ? 'Passwords do not match' : 'ሚስጥሮች አይዛመዱም') : null,
            ),
            const SizedBox(height: 24),
            // Submit button
            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: registerState.isLoading ? null : _submit,
                child: registerState.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.cream),
                      )
                    : Text(isEn ? 'Register' : 'ተመዝግብ', style: const TextStyle(fontSize: 15)),
              ),
            ),
            if (registerState.error != null) ...[
              const SizedBox(height: 12),
              Text(
                registerState.error!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
