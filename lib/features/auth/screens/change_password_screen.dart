import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState
    extends ConsumerState<ChangePasswordScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _currentCtr = TextEditingController();
  final _newCtr     = TextEditingController();
  final _confirmCtr = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew     = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(changePasswordProvider.notifier).reset());
  }

  @override
  void dispose() {
    _currentCtr.dispose();
    _newCtr.dispose();
    _confirmCtr.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(changePasswordProvider.notifier).changePassword(
          currentPassword: _currentCtr.text,
          newPassword:     _newCtr.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(changePasswordProvider);

    ref.listen<ChangePasswordState>(changePasswordProvider, (_, next) {
      if (next.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password changed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Future.delayed(const Duration(seconds: 1), () {
          if (context.mounted) context.pop();
        });
      }
    });

    return Scaffold(
      body: SafeArea(
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
                    const SizedBox(height: 32),
                    const Icon(Icons.lock_reset_rounded,
                        size: 64, color: AppColors.gold),
                    const SizedBox(height: 16),
                    Text('Change Password',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      'Enter your current password and choose a new one.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.grey),
                    ),
                    const SizedBox(height: 36),

                    // Current
                    _PasswordField(
                      controller: _currentCtr,
                      label:      'Current Password',
                      obscure:    _obscureCurrent,
                      onToggle:   () => setState(
                          () => _obscureCurrent = !_obscureCurrent),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Current password is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // New
                    _PasswordField(
                      controller: _newCtr,
                      label:      'New Password',
                      obscure:    _obscureNew,
                      onToggle:   () =>
                          setState(() => _obscureNew = !_obscureNew),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'New password is required';
                        }
                        if (v.length < 6) return 'Minimum 6 characters';
                        if (v == _currentCtr.text) {
                          return 'New password must differ from current';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Confirm
                    _PasswordField(
                      controller: _confirmCtr,
                      label:      'Confirm New Password',
                      obscure:    _obscureConfirm,
                      onToggle:   () => setState(
                          () => _obscureConfirm = !_obscureConfirm),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Please confirm your new password';
                        }
                        if (v != _newCtr.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),

                    // Error
                    if (state.error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.red, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(state.error!,
                                  style: const TextStyle(
                                      color: Colors.red)),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),

                    FilledButton(
                      onPressed: state.isLoading ? null : _submit,
                      style: FilledButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: state.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white),
                            )
                          : const Text('Change Password',
                              style: TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggle,
    required this.validator,
  });

  final TextEditingController            controller;
  final String                           label;
  final bool                             obscure;
  final VoidCallback                     onToggle;
  final String? Function(String?)        validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller:  controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText:   label,
        prefixIcon:  const Icon(Icons.lock),
        border:      const OutlineInputBorder(),
        suffixIcon:  IconButton(
          icon: Icon(
              obscure ? Icons.visibility : Icons.visibility_off),
          onPressed: onToggle,
        ),
      ),
      validator: validator,
    );
  }
}
