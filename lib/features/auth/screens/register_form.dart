// Register form widget for user registration with SaaS pricing plan selector
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
import '../widgets/pricing_card.dart';

class RegisterForm extends ConsumerStatefulWidget {
  const RegisterForm({super.key, required this.lang});

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

  int _step = 0; // 0 = Account Info, 1 = Choose Plan
  bool _obscure = true;
  String _role = 'Manufacturer';
  List<RegistrationPlan> _plans = const [];
  String? _selectedPlanKey;
  String _selectedFilter = 'all'; // 'all', 'monthly', 'extended'
  late PageController _pageController;
  int _currentPage = 0;

  static const List<RegistrationPlan> _defaultFallbackPlans = [
    RegistrationPlan(
      key: 'oneMonth',
      months: 1,
      label: 'Free for 1 month',
      fee: 0,
      enabled: true,
    ),
    RegistrationPlan(
      key: 'threeMonths',
      months: 3,
      label: 'Free for 3 months',
      fee: 0,
      enabled: true,
    ),
    RegistrationPlan(
      key: 'oneYear',
      months: 12,
      label: 'Free for 1 year',
      fee: 0,
      enabled: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    try {
      final plans = await ref.read(authRepositoryProvider).getRegisterPlans();
      if (!mounted) return;
      setState(() {
        if (plans.isNotEmpty) {
          _plans = plans;
          _selectedPlanKey ??= plans.first.key;
        } else {
          _plans = _defaultFallbackPlans;
          _selectedPlanKey ??= _defaultFallbackPlans.first.key;
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _plans = _defaultFallbackPlans;
          _selectedPlanKey ??= _defaultFallbackPlans.first.key;
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  List<RegistrationPlan> get _filteredPlans {
    final list = _plans.isNotEmpty ? _plans : _defaultFallbackPlans;
    if (_selectedFilter == 'monthly') {
      final monthly = list.where((p) => p.months <= 2).toList();
      return monthly.isNotEmpty ? monthly : list;
    } else if (_selectedFilter == 'extended') {
      final extended = list.where((p) => p.months >= 3).toList();
      return extended.isNotEmpty ? extended : list;
    }
    return list;
  }

  void _proceedToPlanSelection() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _step = 1);
  }

  Future<void> _submit() async {
    final selectedKey = _selectedPlanKey ??
        (_plans.isNotEmpty ? _plans.first.key : 'oneMonth');

    final notifier = ref.read(registerProvider.notifier);
    await notifier.register(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: normalizeEthiopianPhone(_phoneCtrl.text),
      password: _passCtrl.text,
      role: _role,
      planKey: selectedKey,
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
                ? (widget.lang == Lang.en ? 'Welcome to Shmeta' : 'እንኳን ወደ ሽመታ በደህና መጡ')
                : (widget.lang == Lang.en ? 'Registration Complete' : 'ምዝገባው ተጠናቋል')),
            content: Text(
              state.registrationFree
                  ? (widget.lang == Lang.en
                      ? 'Your account has been activated with ${state.plan?.label ?? 'your plan'}.'
                      : 'መለያዎ በ${state.plan?.label ?? 'እቅድዎ'} በተሳካ ሁኔታ ነቅቷል።')
                  : (widget.lang == Lang.en
                      ? 'Your account was registered with a fee of ETB ${state.plan?.fee.toStringAsFixed(2) ?? '0.00'}.'
                      : 'መለያዎ በ ETB ${state.plan?.fee.toStringAsFixed(2) ?? '0.00'} ክፍያ ተመዝግቧል።'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(widget.lang == Lang.en ? 'Get Started' : 'ጀምር'),
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

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: child,
      ),
      child: _step == 0
          ? _buildAccountInfoStep(isEn)
          : _buildPricingPlansStep(isEn, registerState),
    );
  }

  // ── Step 0: Account Details ───────────────────────────────────────────────
  Widget _buildAccountInfoStep(bool isEn) {
    return Container(
      key: const ValueKey('step_0_form'),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
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
            // Step header indicator
            _StepProgressBar(currentStep: 0, isEn: isEn),
            const SizedBox(height: 20),

            // Name
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: isEn ? 'Full Name' : 'ሙሉ ስም',
                prefixIcon: const Icon(Icons.person_outline),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return isEn ? 'Name required' : 'ስም ያስፈልጋል';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Email
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: isEn ? 'Email' : 'ኢሜይል',
                prefixIcon: const Icon(Icons.email_outlined),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return isEn ? 'Email required' : 'ኢሜይል ያስፈልጋል';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Role selection
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: InputDecoration(
                labelText: isEn ? 'Business Role' : 'የስራ ሚና',
                prefixIcon: const Icon(Icons.badge_outlined),
              ),
              items: [
                DropdownMenuItem(
                  value: 'Manufacturer',
                  child: Text(isEn ? 'Manufacturer (አምራች)' : 'አምራች (Manufacturer)'),
                ),
                DropdownMenuItem(
                  value: 'Reseller',
                  child: Text(isEn ? 'Reseller (ነጋዴ)' : 'ነጋዴ (Reseller)'),
                ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _role = value);
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return isEn ? 'Role required' : 'ሚና ያስፈልጋል';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Phone
            TextFormField(
              controller: _phoneCtrl,
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
                labelText: isEn ? 'Phone Number' : 'ስልክ ቁጥር',
                prefixIcon: const Icon(Icons.phone_outlined),
                hintText: isEn ? '9..., 09..., or 2519...' : '9..., 09..., ወይም 2519...',
                counterText: '',
              ),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return isEn ? 'Phone required' : 'ስልክ ያስፈልጋል';
                }
                final digits = v.replaceAll(RegExp(r'\D'), '');
                final expectedLength = digits.startsWith('251')
                  ? 12
                  : digits.startsWith('0')
                    ? 10
                    : 9;
                if (digits.length != expectedLength) {
                  return isEn
                    ? 'Use 9 digits (9...), 10 digits (09...), or 12 digits (251...)'
                    : '9, 10, ወይም 12 አሃዞች ያስገቡ';
                }
                if (!isValidEthiopianPhone(v)) {
                  return isEn
                      ? 'Must start with 9 or 7 (e.g. 09... or 07...)'
                      : 'በ 9 ወይም 7 መጀመር አለበት';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Password
            TextFormField(
              controller: _passCtrl,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: isEn ? 'Password' : 'ሚስጥር ቃል',
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
                if (v == null || v.isEmpty) {
                  return isEn ? 'Password required' : 'ሚስጥር ያስፈልጋል';
                }
                if (v.length < 6) {
                  return isEn ? 'Min 6 characters' : 'ቢያንስ 6 ፊደላት';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Confirm Password
            TextFormField(
              controller: _confirmCtrl,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: isEn ? 'Confirm Password' : 'ሚስጥር ቃል ያረጋግጡ',
                prefixIcon: const Icon(Icons.lock_reset_outlined),
              ),
              validator: (v) {
                if (v != _passCtrl.text) {
                  return isEn ? 'Passwords do not match' : 'ሚስጥሮች አይዛመዱም';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Next button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E1B4B),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _proceedToPlanSelection,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isEn ? 'Continue to Choose Plan' : 'እቅድ ለመምረጥ ቀጥል',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 1: Pricing Plans Selector ─────────────────────────────────────────
  Widget _buildPricingPlansStep(bool isEn, dynamic registerState) {
    final displayPlans = _filteredPlans;

    return Container(
      key: const ValueKey('step_1_pricing'),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Step header indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: _StepProgressBar(currentStep: 1, isEn: isEn),
          ),
          const SizedBox(height: 18),

          // Header matching the reference design
          PricingSelectorHeader(
            isEn: isEn,
            selectedFilter: _selectedFilter,
            onFilterChanged: (filter) {
              setState(() {
                _selectedFilter = filter;
                _currentPage = 0;
              });
              if (_pageController.hasClients) {
                _pageController.jumpToPage(0);
              }
            },
          ),
          const SizedBox(height: 16),

          // Plan Cards Carousel
          SizedBox(
            height: 480,
            child: PageView.builder(
              controller: _pageController,
              itemCount: displayPlans.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                  _selectedPlanKey = displayPlans[index].key;
                });
              },
              itemBuilder: (context, index) {
                final plan = displayPlans[index];
                final isSelected = plan.key == _selectedPlanKey;
                return PricingCard(
                  plan: plan,
                  isSelected: isSelected,
                  isEn: isEn,
                  onSelect: () {
                    setState(() => _selectedPlanKey = plan.key);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Page indicator dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              displayPlans.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == i ? 22 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: _currentPage == i
                      ? const Color(0xFF7C3AED)
                      : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Action buttons: [Back] and [Complete Registration]
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: registerState.isLoading
                      ? null
                      : () => setState(() => _step = 0),
                  icon: const Icon(Icons.arrow_back_rounded, size: 16),
                  label: Text(
                    isEn ? 'Back' : 'ተመለስ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: registerState.isLoading ? null : _submit,
                      child: registerState.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle_outline,
                                    size: 18, color: Colors.white),
                                const SizedBox(width: 8),
                                Text(
                                  isEn ? 'Register Now' : 'አሁን ተመዝገብ',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (registerState.error != null) ...[
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                registerState.error!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A compact two-step breadcrumb bar.
class _StepProgressBar extends StatelessWidget {
  const _StepProgressBar({
    required this.currentStep,
    required this.isEn,
  });

  final int currentStep;
  final bool isEn;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildStepBadge(
          stepNumber: 1,
          label: isEn ? 'Account Info' : 'መረጃ',
          isActive: currentStep == 0,
          isCompleted: currentStep > 0,
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            height: 2,
            color: currentStep > 0
                ? const Color(0xFF7C3AED)
                : const Color(0xFFE2E8F0),
          ),
        ),
        _buildStepBadge(
          stepNumber: 2,
          label: isEn ? 'Choose Plan' : 'እቅድ ይምረጡ',
          isActive: currentStep == 1,
          isCompleted: false,
        ),
      ],
    );
  }

  Widget _buildStepBadge({
    required int stepNumber,
    required String label,
    required bool isActive,
    required bool isCompleted,
  }) {
    final bg = isCompleted
        ? const Color(0xFF10B981)
        : (isActive ? const Color(0xFF7C3AED) : const Color(0xFFE2E8F0));
    final fg = (isActive || isCompleted) ? Colors.white : const Color(0xFF64748B);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : Text(
                    '$stepNumber',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: fg,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? const Color(0xFF0F172A) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}
