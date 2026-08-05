import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/cashier_provider.dart';

class CreateCashierSheet extends ConsumerStatefulWidget {
  const CreateCashierSheet({super.key});

  @override
  ConsumerState<CreateCashierSheet> createState() =>
      _CreateCashierSheetState();
}

class _CreateCashierSheetState extends ConsumerState<CreateCashierSheet> {
  final _formKey         = GlobalKey<FormState>();
  final _nameCtr         = TextEditingController();
  final _phoneCtr        = TextEditingController();
  final _passwordCtr     = TextEditingController();
  final _confirmCtr      = TextEditingController();
  bool  _showPassword    = false;
  bool  _showConfirm     = false;

  @override
  void dispose() {
    _nameCtr.dispose();
    _phoneCtr.dispose();
    _passwordCtr.dispose();
    _confirmCtr.dispose();
    super.dispose();
  }

  // ── Phone formatter — allow only digits, strip leading 0, max 9 digits ──
  void _onPhoneChanged(String val) {
    String raw = val.replaceAll(RegExp(r'\D'), '');
    if (raw.startsWith('0')) raw = raw.substring(1);
    if (raw.length > 9) raw = raw.substring(0, 9);
    if (raw != val) {
      _phoneCtr.value = TextEditingValue(
        text: raw,
        selection: TextSelection.collapsed(offset: raw.length),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(createCashierProvider.notifier).create(
          name:     _nameCtr.text.trim(),
          phone:    '0${_phoneCtr.text.trim()}',
          password: _passwordCtr.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final createState = ref.watch(createCashierProvider);

    // Close sheet automatically on success
    ref.listen(createCashierProvider, (_, next) {
      if (next.success && context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cashier created successfully'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    });

    final viewInsets = MediaQuery.of(context).viewInsets;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 0, 20, viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Handle ──────────────────────────────────────────────────────
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ── Title ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_add_alt_1_rounded,
                      color: Color(0xFF10B981),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Add New Cashier',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Fill in the details below',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Error banner ─────────────────────────────────────────────────
            if (createState.error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
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
                        createState.error!,
                        style: TextStyle(
                            color: Colors.red.shade700, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Form ─────────────────────────────────────────────────────────
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Name
                  _buildField(
                    controller: _nameCtr,
                    label:       'Full Name',
                    hint:        'e.g. Abebe Kebede',
                    icon:        Icons.person_outline,
                    validator:   (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Name is required';
                      }
                      if (v.trim().length < 2) {
                        return 'Name must be at least 2 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Phone
                  TextFormField(
                    controller:  _phoneCtr,
                    keyboardType: TextInputType.phone,
                    onChanged:   _onPhoneChanged,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      hintText:  '9xxxxxxxx or 7xxxxxxxx',
                      prefixIcon: const Icon(Icons.phone_outlined,
                          color: Color(0xFF10B981)),
                      prefixText: '0',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFF10B981), width: 2),
                      ),
                      filled:    true,
                      fillColor: Colors.grey.shade50,
                    ),
                    validator: (v) {
                      final raw = v?.replaceAll(RegExp(r'\D'), '') ?? '';
                      if (raw.length != 9) {
                        return 'Enter a 9-digit number (after the 0)';
                      }
                      if (raw[0] != '9' && raw[0] != '7') {
                        return 'Phone must start with 9 or 7';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Password
                  _buildPasswordField(
                    controller:  _passwordCtr,
                    label:       'Password',
                    show:        _showPassword,
                    onToggle:    () =>
                        setState(() => _showPassword = !_showPassword),
                    validator:   (v) {
                      if (v == null || v.isEmpty) return 'Password is required';
                      if (v.length < 6) return 'Minimum 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Confirm password
                  _buildPasswordField(
                    controller:  _confirmCtr,
                    label:       'Confirm Password',
                    show:        _showConfirm,
                    onToggle:    () =>
                        setState(() => _showConfirm = !_showConfirm),
                    validator:   (v) {
                      if (v != _passwordCtr.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Buttons ──────────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: createState.isLoading
                        ? null
                        : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: createState.isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: createState.isLoading
                        ? const SizedBox(
                            height: 20,
                            width:  20,
                            child:  CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Create Cashier',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Field builders ────────────────────────────────────────────────────────

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText:  hint,
        prefixIcon: Icon(icon, color: const Color(0xFF10B981)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF10B981), width: 2),
        ),
        filled:    true,
        fillColor: Colors.grey.shade50,
      ),
      validator: validator,
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool show,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller:     controller,
      obscureText:    !show,
      decoration: InputDecoration(
        labelText: label,
        hintText:  '••••••••',
        prefixIcon:
            const Icon(Icons.lock_outline, color: Color(0xFF10B981)),
        suffixIcon: IconButton(
          icon: Icon(
            show ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey.shade500,
            size: 20,
          ),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF10B981), width: 2),
        ),
        filled:    true,
        fillColor: Colors.grey.shade50,
      ),
      validator: validator,
    );
  }
}
