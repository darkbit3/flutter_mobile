import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../constants/lang_constants.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({Key? key, required this.lang}) : super(key: key);

  final Lang lang;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpCtrl = TextEditingController();

  @override
  void dispose() {
    _otpCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    // TODO: implement OTP verification logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(widget.lang == Lang.en ? 'OTP submitted' : 'OTP ተልኳል')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEn = widget.lang == Lang.en;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEn ? 'Enter OTP' : 'OTP ያስገቡ'),
        backgroundColor: AppColors.dark,
      ),
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
                    TextFormField(
                      controller: _otpCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: isEn ? 'OTP Code' : 'OTP ኮድ',
                        prefixIcon: const Icon(Icons.security),
                      ),
                      validator: (v) => v == null || v.isEmpty ? (isEn ? 'Enter OTP' : 'OTP ያስገቡ') : null,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 50,
                      child: FilledButton(
                        onPressed: _submit,
                        child: Text(isEn ? 'Verify' : 'ያረጋግጡ'),
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
}
