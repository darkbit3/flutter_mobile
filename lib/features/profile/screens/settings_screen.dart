import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/toast/toast_service.dart';
import '../../auth/providers/auth_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late double _threshold;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _threshold = user?.alertThresholdPercentage ?? 20.0;
  }

  Future<void> _saveThreshold() async {
    await ref.read(alertThresholdProvider.notifier).updateThreshold(_threshold);
    
    final state = ref.read(alertThresholdProvider);
    if (state.success) {
      ref.read(toastServiceProvider).success(
        'Alert threshold updated to ${_threshold.toStringAsFixed(0)}%',
      );
      if (mounted) Navigator.pop(context);
    } else if (state.error != null) {
      ref.read(toastServiceProvider).error(state.error ?? 'Failed to update');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isLoading = ref.watch(alertThresholdProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.dark,
        foregroundColor: AppColors.cream,
        elevation: 0,
        title: const Text('Alert Settings', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: user == null
          ? const Center(child: Text('User not found'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  
                  // ── Description ────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.1),
                      border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '⚠️ Low Stock Alert Threshold',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.gold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Set the percentage at which you want to receive notifications when a material is running low on stock.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textMid,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Current Threshold Display ──────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Threshold',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMid,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_threshold.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.gold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'You will be notified when material quantity drops to this percentage of the initial quantity.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMid,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Slider ──────────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Adjust Threshold',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMid,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Text(
                              '5%',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textMid,
                              ),
                            ),
                            Expanded(
                              child: Slider(
                                value: _threshold,
                                min: 5,
                                max: 100,
                                divisions: 19,
                                label: '${_threshold.toStringAsFixed(0)}%',
                                activeColor: AppColors.gold,
                                inactiveColor: AppColors.border,
                                onChanged: (value) {
                                  setState(() => _threshold = value);
                                },
                              ),
                            ),
                            const Text(
                              '100%',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textMid,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.warning.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            'Preview: Materials with quantity ≤ ${_threshold.toStringAsFixed(0)}% will trigger alerts',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.warning,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Save Button ────────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isLoading ? null : _saveThreshold,
                      icon: const Icon(Icons.check_rounded),
                      label: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save Settings'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.dark,
                        disabledBackgroundColor: AppColors.gold.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Cancel Button ──────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: isLoading ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.border),
                        disabledForegroundColor:
                            AppColors.textMid.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Info Box ───────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.1),
                      border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ℹ️ How It Works',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.info,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          '• Notifications are triggered when material quantity drops below your threshold\n'
                          '• Example: 20% threshold = notify when quantity ≤ 20% of initial quantity\n'
                          '• Notifications appear when adding materials or making sales',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMid,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
