// Register form widget for user registration
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/register_provider.dart';
import '../providers/auth_provider.dart';
import '../data/auth_repository.dart';
import '../models/registration_plan.dart';
import '../../../core/theme/app_theme.dart';
import '../constants/lang_constants.dart';
import '../utils/phone_utils.dart';

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
  String _role = 'Manufacturer';
  List<RegistrationPlan> _plans = const [];
  String? _selectedPlanKey;
  String? _planError;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    try {
      final plans = await ref.read(authRepositoryProvider).getRegisterPlans();
      if (!mounted) return;
      setState(() {
        _plans = plans;
        _selectedPlanKey = plans.isEmpty ? null : plans.first.key;
      });
    } catch (_) {
      if (mounted)
        setState(() => _planError = 'Unable to load registration plans');
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(registerProvider.notifier);
    await notifier.register(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: normalizeEthiopianPhone(_phoneCtrl.text),
      password: _passCtrl.text,
      role: _role,
      planKey: _selectedPlanKey!,
    );
    final state = ref.read(registerProvider);
    if (state.success && state.user != null) {
      ref.read(authProvider.notifier).setAuthenticated(state.user!);
      if (mounted) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: Text(state.registrationFree
                ? 'Register Free'
                : 'Registration Complete'),
            content: Text(
              state.registrationFree
                  ? 'Your ${state.plan?.label.toLowerCase() ?? 'registration'} is free.'
                  : 'Your account was registered with a fee of ETB ${state.plan?.fee.toStringAsFixed(2) ?? '0.00'}.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Continue'),
              ),
            ],
          ),
        );
        if (mounted) context.go('/dashboard');
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
        border:
            const Border.fromBorderSide(BorderSide(color: AppColors.border)),
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
              validator: (v) => v == null || v.isEmpty
                  ? (isEn ? 'Name required' : 'ስም ያስፈልጋል')
                  : null,
            ),
            const SizedBox(height: 12),
            // Email
            TextFormField(
              controller: _emailCtrl,
              decoration: InputDecoration(
                labelText: isEn ? 'Email' : 'ኢሜይል',
                prefixIcon: const Icon(Icons.email_outlined),
              ),
              validator: (v) => v == null || v.isEmpty
                  ? (isEn ? 'Email required' : 'ኢሜይል ያስፈልጋል')
                  : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: InputDecoration(
                labelText: isEn ? 'Role' : 'ሚና',
                prefixIcon: const Icon(Icons.badge_outlined),
              ),
              items: const [
                DropdownMenuItem(
                    value: 'Manufacturer', child: Text('Manufacturer')),
                DropdownMenuItem(value: 'Reseller', child: Text('Reseller')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _role = value);
              },
              validator: (value) => value == null || value.isEmpty
                  ? (isEn ? 'Role required' : 'ሚና ያስፈልጋል')
                  : null,
            ),
            const SizedBox(height: 12),
            if (_plans.isNotEmpty)
              DropdownButtonFormField<String>(
                initialValue: _selectedPlanKey,
                decoration: InputDecoration(
                  labelText: isEn ? 'Registration Plan' : 'የምዝገባ እቅድ',
                  prefixIcon: const Icon(Icons.calendar_month_outlined),
                ),
                items: _plans.map((plan) {
                  final price = plan.isFree
                      ? (isEn ? 'Free' : 'ነፃ')
                      : 'ETB ${plan.fee.toStringAsFixed(2)}';
                  return DropdownMenuItem(
                      value: plan.key, child: Text('${plan.label} - $price'));
                }).toList(),
                onChanged: registerState.isLoading
                    ? null
                    : (value) => setState(() => _selectedPlanKey = value),
              ),
            if (_plans.isEmpty && _planError != null) ...[
              Text(_planError!,
                  style: const TextStyle(color: Colors.red, fontSize: 13)),
              const SizedBox(height: 8),
            ],
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
                hintText:
                    isEn ? '9xxxxxxxx or 7xxxxxxxx' : '9xxxxxxxx ወይም 7xxxxxxxx',
                counterText: '',
              ),
              validator: (v) {
                if (v == null || v.isEmpty)
                  return isEn ? 'Phone required' : 'ስልክ ያስፈልጋል';
                final normalized = normalizeEthiopianPhone(v);
                if (normalized.length != 12)
                  return isEn
                      ? 'Phone must be 12 digits starting with 251'
                      : 'ስልክ 12 ቁጥር መሆን አለበት እና 251 ከጀመረ';
                if (!isValidEthiopianPhone(normalized))
                  return isEn
                      ? 'Must start with 251 and then 9 digits starting with 9 or 7'
                      : '251 እና 9 ቁጥሮች መሆን አለበት እና 9 ወይም 7 ከጀመረ';
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
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.textMid,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty)
                  return isEn ? 'Password required' : 'ሚስጥር ያስፈልጋል';
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
              validator: (v) => v != _passCtrl.text
                  ? (isEn ? 'Passwords do not match' : 'ሚስጥሮች አይዛመዱም')
                  : null,
            ),
            const SizedBox(height: 24),
            // Submit button
            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: registerState.isLoading || _selectedPlanKey == null
                    ? null
                    : _submit,
                child: registerState.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.cream),
                      )
                    : Text(isEn ? 'Register' : 'ተመዝግብ',
                        style: const TextStyle(fontSize: 15)),
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
