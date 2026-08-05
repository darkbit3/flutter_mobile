import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 12),

        // ── Avatar banner ──────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(vertical: 28),
          decoration: BoxDecoration(
            color: AppColors.dark,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              Container(
                width: 76, height: 76,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.5), width: 2),
                ),
                child: Center(
                  child: Text(
                    user?.name.isNotEmpty == true
                        ? user!.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                user?.name ?? '—',
                style: const TextStyle(
                  color: AppColors.cream,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.4)),
                ),
                child: Text(
                  user?.role ?? '',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── Account Details ────────────────────────────────────────────────
        const _SectionLabel('Account Details'),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: const Border.fromBorderSide(
                BorderSide(color: AppColors.border)),
          ),
          child: Column(
            children: [
              _DetailRow(icon: Icons.person_outline,  label: 'Full Name', value: user?.name  ?? '—'),
              const _Div(),
              _DetailRow(icon: Icons.phone_outlined,  label: 'Phone',     value: user?.phone ?? '—'),
              const _Div(),
              _DetailRow(
                icon: Icons.badge_outlined, label: 'Role',
                value: user?.role ?? '—', valueColor: AppColors.gold,
              ),
              const _Div(),
              _DetailRow(
                icon: user?.status == 'Active'
                    ? Icons.check_circle_outline
                    : Icons.block_rounded,
                label: 'Status',
                value: user?.status ?? '—',
                valueColor: user?.status == 'Active'
                    ? AppColors.success
                    : AppColors.warning,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── Settings ───────────────────────────────────────────────────────
        const _SectionLabel('Settings'),
        const SizedBox(height: 10),
        _ActionTile(
          icon:     Icons.lock_reset_rounded,
          color:    AppColors.gold,
          title:    'Change Password',
          subtitle: 'Update your login password',
          onTap:    () => context.push('/change-password'),
        ),
        const SizedBox(height: 24),

        // ── Logout ─────────────────────────────────────────────────────────
        OutlinedButton.icon(
          onPressed: () async {
            await ref.read(authProvider.notifier).logout();
            if (context.mounted) context.go('/login');
          },
          icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
          label: const Text('Logout',
              style: TextStyle(color: Colors.redAccent)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: const BorderSide(color: Colors.redAccent),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textMid,
        fontWeight: FontWeight.w600,
        fontSize: 12,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _Div extends StatelessWidget {
  const _Div();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, color: AppColors.border, indent: 16, endIndent: 16);
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String   label;
  final String   value;
  final Color?   valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.gold),
          const SizedBox(width: 12),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textMid, fontSize: 13)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: valueColor ?? AppColors.dark,
              )),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData     icon;
  final Color        color;
  final String       title;
  final String       subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: const Border.fromBorderSide(
            BorderSide(color: AppColors.border)),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: AppColors.dark)),
        subtitle: Text(subtitle,
            style: const TextStyle(
                color: AppColors.textMid, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right_rounded,
            color: AppColors.textLight),
        onTap: onTap,
      ),
    );
  }
}
