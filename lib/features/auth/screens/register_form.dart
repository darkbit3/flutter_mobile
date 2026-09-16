// Register form widget for user registration with SaaS pricing plan selector & payment approval flow
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/register_provider.dart';
import '../providers/auth_provider.dart';
import '../data/auth_repository.dart';
import '../models/registration_plan.dart';
import '../models/payment_info.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/notifications/local_notification_service.dart';
import '../constants/lang_constants.dart';
import '../utils/phone_utils.dart';
import '../widgets/pricing_card.dart';

class RegisterForm extends ConsumerStatefulWidget {
  const RegisterForm({super.key, required this.lang});

  final Lang lang;

  @override
  ConsumerState<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends ConsumerState<RegisterForm> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  int _step = 0; // 0 = Account Info, 1 = Choose Plan, 2 = Payment & Approval
  bool _obscure = true;
  String _role = 'Manufacturer';
  List<RegistrationPlan> _plans = const [];
  String? _selectedPlanKey;
  String _selectedFilter = 'all'; // 'all', 'monthly', 'extended'
  late PageController _pageController;
  int _currentPage = 0;

  // Step 2 state
  PaymentInfo? _paymentInfo;
  bool _loadingPaymentInfo = false;
  Timer? _statusPollTimer;
  RegistrationStatusData? _currentStatus;
  bool _approvedHandled = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  static const List<RegistrationPlan> _defaultFallbackPlans = [
    RegistrationPlan(
      key: 'oneMonth',
      months: 1,
      label: '1 Month Free Trial',
      fee: 0,
      enabled: true,
    ),
    RegistrationPlan(
      key: 'twoMonths',
      months: 2,
      label: '2 Months Plan',
      fee: 350,
      enabled: true,
    ),
    RegistrationPlan(
      key: 'threeMonths',
      months: 3,
      label: '3 Months Plan',
      fee: 500,
      enabled: true,
    ),
    RegistrationPlan(
      key: 'sixMonths',
      months: 6,
      label: '6 Months Plan',
      fee: 950,
      enabled: true,
    ),
    RegistrationPlan(
      key: 'oneYear',
      months: 12,
      label: '1 Year Annual Plan',
      fee: 1800,
      enabled: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
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
    _statusPollTimer?.cancel();
    _pulseController.dispose();
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

  RegistrationPlan? get _selectedPlan {
    final list = _plans.isNotEmpty ? _plans : _defaultFallbackPlans;
    try {
      return list.firstWhere((p) => p.key == _selectedPlanKey);
    } catch (_) {
      return list.isNotEmpty ? list.first : null;
    }
  }

  void _proceedToPlanSelection() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _step = 1);
  }

  Future<void> _loadPaymentInfo() async {
    setState(() => _loadingPaymentInfo = true);
    try {
      final info = await ref.read(authRepositoryProvider).getPaymentInfo();
      if (mounted) {
        setState(() {
          _paymentInfo = info;
          _loadingPaymentInfo = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingPaymentInfo = false);
      }
    }
  }

  void _startStatusPolling(String phone) {
    _statusPollTimer?.cancel();
    _statusPollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        final statusData = await ref.read(authRepositoryProvider).getRegistrationStatus(phone);
        if (!mounted) return;
        setState(() {
          _currentStatus = statusData;
        });

        if (statusData.isApproved && !_approvedHandled) {
          _approvedHandled = true;
          timer.cancel();
          _onApproved();
        } else if (statusData.isRejected) {
          timer.cancel();
          _onRejected(statusData.rejectionReason);
        }
      } catch (_) {}
    });
  }

  void _onApproved() {
    final isEn = widget.lang == Lang.en;
    LocalNotificationService.instance.showRegistrationNotification(
      title: isEn ? '🎉 Registration Approved!' : '🎉 ምዝገባዎ ጸድቋል!',
      message: isEn
          ? 'Your payment has been verified. Your account is now active.'
          : 'ክፍያዎ ተረጋግጧል። መለያዎ አሁን ነቅቷል።',
    );

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 28),
            const SizedBox(width: 8),
            Text(isEn ? 'Approved!' : 'ተፈቅዷል!', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          isEn
              ? 'Congratulations! Super Admin has reviewed and approved your registration. You can now log into your account.'
              : 'እንኳን ደስ አለዎት! ሱፐር አድሚኑ ምዝገባዎን አይቶ አጽድቆታል። አሁን ወደ መለያዎ መግባት ይችላሉ።',
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go('/login');
            },
            child: Text(isEn ? 'Proceed to Login' : 'ወደ መግቢያ ይሂዱ'),
          ),
        ],
      ),
    );
  }

  void _onRejected(String? reason) {
    final isEn = widget.lang == Lang.en;
    LocalNotificationService.instance.showRegistrationNotification(
      title: isEn ? 'Registration Rejected' : 'ምዝገባው ውድቅ ተደርጓል',
      message: reason ?? (isEn ? 'Please check your payment receipt.' : 'እባክዎ ደረሰኝዎን ያረጋግጡ።'),
    );
  }

  Future<void> _submit() async {
    final selectedKey = _selectedPlanKey ??
        (_plans.isNotEmpty ? _plans.first.key : 'oneMonth');
    final normalizedPhone = normalizeEthiopianPhone(_phoneCtrl.text);
    final plan = _selectedPlan;
    final bool isPaidTier = selectedKey != 'oneMonth' || (plan != null && !plan.isFree);

    final notifier = ref.read(registerProvider.notifier);
    await notifier.register(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: normalizedPhone,
      password: _passCtrl.text,
      role: _role,
      planKey: selectedKey,
    );
    final state = ref.read(registerProvider);
    if (state.success && state.user != null) {
      if (isPaidTier || state.pendingApproval) {
        // Paid plan: Awaiting Super Admin review and approval
        // Discard any tokens received so user is NOT auto-authenticated
        await ref.read(authRepositoryProvider).logout();
        if (mounted) {
          setState(() => _step = 2);
          _loadPaymentInfo();
          _startStatusPolling(normalizedPhone);
        }
      } else {
        // Only 1 Month Free plan allows immediate activation
        ref.read(authProvider.notifier).setAuthenticated(state.user!);
        if (mounted) {
          await showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(widget.lang == Lang.en ? 'Welcome to Shmeta' : 'እንኳን ወደ ሽመታ በደህና መጡ'),
              content: Text(
                widget.lang == Lang.en
                    ? 'Your account has been activated with ${state.plan?.label ?? 'your free plan'}.'
                    : 'መለያዎ በ${state.plan?.label ?? 'እቅድዎ'} በተሳካ ሁኔታ ነቅቷል።',
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
  }

  Future<void> _openTelegram(String username) async {
    final clean = username.replaceAll('@', '').trim();
    final uri = Uri.parse('https://t.me/$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open Telegram: t.me/$clean')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final registerState = ref.watch(registerProvider);
    final isEn = widget.lang == Lang.en;

    Widget currentWidget;
    if (_step == 0) {
      currentWidget = _buildAccountInfoStep(isEn);
    } else if (_step == 1) {
      currentWidget = _buildPricingPlansStep(isEn, registerState);
    } else {
      currentWidget = _buildPaymentWaitingStep(isEn);
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: child,
      ),
      child: currentWidget,
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
            _StepProgressBar(currentStep: 0, isEn: isEn),
            const SizedBox(height: 20),

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
    final plan = _selectedPlan;
    final bool isPaid = _selectedPlanKey != 'oneMonth' || (plan != null && !plan.isFree);

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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: _StepProgressBar(currentStep: 1, isEn: isEn),
          ),
          const SizedBox(height: 18),

          PricingSelectorHeader(
            isEn: isEn,
            selectedFilter: _selectedFilter,
            onFilterChanged: (filter) {
              setState(() {
                _selectedFilter = filter;
                _currentPage = 0;
                final filtered = _filteredPlans;
                if (filtered.isNotEmpty) {
                  _selectedPlanKey = filtered.first.key;
                }
              });
              if (_pageController.hasClients) {
                _pageController.jumpToPage(0);
              }
            },
          ),
          const SizedBox(height: 16),

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
                final p = displayPlans[index];
                final isSelected = p.key == _selectedPlanKey;
                return PricingCard(
                  plan: p,
                  isSelected: isSelected,
                  isEn: isEn,
                  onSelect: () {
                    setState(() => _selectedPlanKey = p.key);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),

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
                      gradient: LinearGradient(
                        colors: isPaid
                            ? const [Color(0xFF6366F1), Color(0xFF4F46E5)]
                            : const [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: (isPaid ? const Color(0xFF4F46E5) : const Color(0xFF7C3AED))
                              .withValues(alpha: 0.35),
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
                                Icon(
                                  isPaid ? Icons.payment_rounded : Icons.check_circle_outline,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isPaid
                                      ? (isEn ? 'Pay & Register' : 'ክፈል እና ተመዝገብ')
                                      : (isEn ? 'Register Now' : 'አሁን ተመዝገብ'),
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

  // ── Step 2: Payment Details & Awaiting Super Admin Review ─────────────────
  Widget _buildPaymentWaitingStep(bool isEn) {
    final plan = _selectedPlan;
    final feeText = 'ETB ${plan?.fee.toStringAsFixed(2) ?? '0.00'}';
    final telegram = _paymentInfo?.telegramUsername ?? '@shmeta_admin';
    final accounts = _paymentInfo?.accounts ?? [];
    final status = _currentStatus;

    return Container(
      key: const ValueKey('step_2_payment'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StepProgressBar(currentStep: 2, isEn: isEn),
          const SizedBox(height: 20),

          // Plan & Amount Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      plan?.label ?? 'Paid Subscription',
                      style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFF59E0B)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ScaleTransition(
                            scale: _pulseAnimation,
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF59E0B),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isEn ? 'Awaiting Review' : 'ግምገማ ይጠብቃል',
                            style: const TextStyle(color: Color(0xFFFBBF24), fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  feeText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isEn
                      ? 'Please transfer the exact fee to any of the bank accounts below:'
                      : 'እባክዎ ትክክለኛውን ክፍያ ከታች ወዳሉት የባንክ ሂሳቦች ይላኩ፡',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Bank Accounts Section
          Row(
            children: [
              const Icon(Icons.account_balance_rounded, size: 18, color: Color(0xFF4F46E5)),
              const SizedBox(width: 8),
              Text(
                isEn ? 'Bank Account Details' : 'የባንክ ሂሳብ ዝርዝር',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (_loadingPaymentInfo) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
          ] else if (accounts.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                isEn ? 'Default CBE Account: 1000234567890' : 'መደበኛ CBE ሂሳብ፡ 1000234567890',
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
            ),
          ] else ...[
            ...accounts.map((acc) => _buildAccountTile(acc, isEn)),
          ],
          const SizedBox(height: 20),

          // Telegram Action Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF0284C7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEn ? 'Send Payment Screenshot' : 'የክፍያ ደረሰኝ በቴሌግራም ይላኩ',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                          ),
                          Text(
                            isEn
                                ? 'Send receipt screenshot to $telegram for fast verification'
                                : 'ፈጣን ማረጋገጫ ለማግኘት ደረሰኙን ወደ $telegram ይላኩ',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    elevation: 1,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _openTelegram(telegram),
                  icon: const Icon(Icons.telegram, size: 20),
                  label: Text(
                    isEn ? 'Send Screenshot on Telegram ($telegram)' : 'በቴሌግራም ደረሰኝ ላክ ($telegram)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Real-time Status Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: status?.isRejected == true
                    ? const Color(0xFFFCA5A5)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              children: [
                if (status?.isRejected == true) ...[
                  const Icon(Icons.cancel_outlined, color: Colors.red, size: 36),
                  const SizedBox(height: 8),
                  Text(
                    isEn ? 'Registration Rejected' : 'ምዝገባው ተቀባይነት አላገኘም',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status?.rejectionReason ?? (isEn ? 'Payment could not be verified.' : 'ክፍያው አልተረጋገጠም።'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                  ),
                ] else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6366F1)),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isEn ? 'Waiting for Super Admin review…' : 'ሱፐር አድሚኑ እስኪያረጋግጥ በመጠበቅ ላይ…',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isEn
                        ? 'This page automatically updates the instant your request is approved.'
                        : 'ጥያቄዎ እንደጸደቀ ይህ ገጽ ወዲያውኑ በራሱ ይዘምናል እና ያሳውቆታል።',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          TextButton(
            onPressed: () => context.go('/login'),
            child: Text(
              isEn ? 'Return to Login' : 'ወደ መግቢያ ተመለስ',
              style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountTile(PaymentAccount acc, bool isEn) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEDE9FE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.account_balance, color: Color(0xFF7C3AED), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  acc.bank,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                Text(
                  acc.accountName,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
                Text(
                  acc.accountNumber,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: isEn ? 'Copy Account Number' : 'የሂሳብ ቁጥሩን ቅዳ',
            icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF6366F1)),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: acc.accountNumber));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isEn ? 'Account number copied!' : 'የሂሳብ ቁጥሩ ተቀድቷል!'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// A compact three-step breadcrumb bar.
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
          label: isEn ? 'Account' : 'መረጃ',
          isActive: currentStep == 0,
          isCompleted: currentStep > 0,
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            height: 2,
            color: currentStep > 0
                ? const Color(0xFF7C3AED)
                : const Color(0xFFE2E8F0),
          ),
        ),
        _buildStepBadge(
          stepNumber: 2,
          label: isEn ? 'Plan' : 'እቅድ',
          isActive: currentStep == 1,
          isCompleted: currentStep > 1,
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            height: 2,
            color: currentStep > 1
                ? const Color(0xFF7C3AED)
                : const Color(0xFFE2E8F0),
          ),
        ),
        _buildStepBadge(
          stepNumber: 3,
          label: isEn ? 'Payment' : 'ክፍያ',
          isActive: currentStep == 2,
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
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, size: 13, color: Colors.white)
                : Text(
                    '$stepNumber',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: fg,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? const Color(0xFF0F172A) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}
