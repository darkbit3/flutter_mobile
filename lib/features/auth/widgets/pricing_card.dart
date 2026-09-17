import 'package:flutter/material.dart';
import '../models/registration_plan.dart';

/// Features and metadata descriptor for each registration plan tier.
class PlanTierInfo {
  final String tag;
  final String amharicTag;
  final String subtitle;
  final String amharicSubtitle;
  final bool isPopular;
  final List<String> features;
  final List<String> amharicFeatures;

  const PlanTierInfo({
    required this.tag,
    required this.amharicTag,
    required this.subtitle,
    required this.amharicSubtitle,
    this.isPopular = false,
    required this.features,
    required this.amharicFeatures,
  });
}

PlanTierInfo getTierInfoForPlan(RegistrationPlan plan) {
  if (plan.months == 1) {
    return const PlanTierInfo(
      tag: 'Free Starter',
      amharicTag: 'ነፃ ጀማሪ',
      subtitle: 'Best for individuals and getting started',
      amharicSubtitle: 'ለጀማሪዎች እና ለግል ስራ ተመራጭ',
      isPopular: false,
      features: [
        'Complete Material & Fabric Inventory',
        'Sales Management & Digital Invoices',
        'Cashier & Staff Account Support',
        'Real-time Stock Tracking',
        'Phone Support',
      ],
      amharicFeatures: [
        'ሙሉ የጨርቅ እና የእቃዎች ቁጥጥር',
        'የሽያጭ አስተዳደር እና ደረሰኝ',
        'የካሸር እና ሰራተኛ አካውንት',
        'ቅጽበታዊ የስቶክ ክትትል',
        'የስልክ ድጋፍ',
      ],
    );
  } else if (plan.months <= 3) {
    return const PlanTierInfo(
      tag: 'Professional',
      amharicTag: 'ፕሮፌሽናል',
      subtitle: 'Best for growing workshops and stores',
      amharicSubtitle: 'ለሚያድጉ ሱቆች እና ወርክሾፖች ተመራጭ',
      isPopular: true,
      features: [
        'Everything in Free Starter',
        'Unlimited Cutters & Cashiers',
        'Production Order Workflow & Wastage Logs',
        'Profit & Loss Financial Analytics',
        'Multi-device Real-time Sync',
        'Priority Technical Support',
      ],
      amharicFeatures: [
        'በነፃ ጀማሪ ውስጥ ያሉ ሁሉ',
        'ያልተገደበ ቆራጮች እና ካሸሮች',
        'የስራ ትዕዛዝ እና የብክነት ክትትል',
        'የትርፍ እና ኪሳራ ትንታኔ',
        'በበርካታ ስልኮች በአንድ ጊዜ መጠቀም',
        'ፈጣን የቴክኒክ ድጋፍ',
      ],
    );
  } else if (plan.months <= 6) {
    return const PlanTierInfo(
      tag: 'Business Pro',
      amharicTag: 'ቢዝነስ ፕሮ',
      subtitle: 'For established manufacturing businesses',
      amharicSubtitle: 'ለተቋቋሙ አምራቾች እና ነጋዴዎች',
      isPopular: true,
      features: [
        'Everything in Professional',
        'Multi-branch Inventory Coordination',
        'Automated Low-Stock Reorder Alerts',
        'Export Data to PDF & Excel Reports',
        'Advanced Permission Controls',
        '24/7 Priority Support',
      ],
      amharicFeatures: [
        'በፕሮፌሽናል ውስጥ ያሉ ሁሉ',
        'የተለያዩ ቅርንጫፎች ክትትል',
        'እቃ ሊያልቅ ሲል አውቶማቲክ ማስጠንቀቂያ',
        'ሪፖርቶችን ወደ PDF እና Excel ማውጣት',
        'የላቁ የተጠቃሚ ፈቃድ ቁጥጥሮች',
        'የ24/7 ቅድሚያ ድጋፍ',
      ],
    );
  } else {
    return const PlanTierInfo(
      tag: 'Enterprise',
      amharicTag: 'ኢንተርፕራይዝ',
      subtitle: 'Best for large teams and high volume factories',
      amharicSubtitle: 'ለትላልቅ ፋብሪካዎች እና ድርጅቶች',
      isPopular: false,
      features: [
        'Everything in Business Pro',
        'Unlimited Projects & Cutting Operations',
        'Custom Roles & Audit Logs',
        'Dedicated Account Manager',
        'Automated Cloud Backups & Zero Downtime',
        'Custom Staff Training & Onboarding',
      ],
      amharicFeatures: [
        'በቢዝነስ ፕሮ ውስጥ ያሉ ሁሉ',
        'ያልተገደበ ፕሮጀክቶች እና ስራዎች',
        'ዝርዝር የደህንነት እና የኦዲት መዝገብ',
        'ልዩ የደንበኞች ተቆጣጣሪ',
        'አውቶማቲክ የክላውድ ባክአፕ',
        'የሰራተኞች የስልጠና ድጋፍ',
      ],
    );
  }
}

/// A modern, SaaS-style pricing card modeled after the reference design.
class PricingCard extends StatelessWidget {
  const PricingCard({
    super.key,
    required this.plan,
    required this.isSelected,
    required this.isEn,
    required this.onSelect,
  });

  final RegistrationPlan plan;
  final bool isSelected;
  final bool isEn;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final tier = getTierInfoForPlan(plan);
    final isHighlighted = isSelected || tier.isPopular;

    final formattedPrice = plan.isFree
        ? (isEn ? 'ETB 0' : '0 ብር')
        : (isEn
            ? 'ETB ${plan.fee.toStringAsFixed(0)}'
            : '${plan.fee.toStringAsFixed(0)} ብር');

    final periodSuffix = isEn
        ? (plan.months == 1 ? '/month' : '/${plan.months} mo')
        : (plan.months == 1 ? '/ወር' : '/${plan.months} ወራት');

    final displayTag = isEn ? tier.tag : tier.amharicTag;
    final displaySubtitle = isEn ? tier.subtitle : tier.amharicSubtitle;
    final features = isEn ? tier.features : tier.amharicFeatures;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        gradient: isHighlighted
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF3E8FF),
                  Color(0xFFFAFAFA),
                  Colors.white,
                ],
                stops: [0.0, 0.22, 1.0],
              )
            : null,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF7C3AED)
              : (tier.isPopular
                  ? const Color(0xFFC4B5FD)
                  : const Color(0xFFE2E8F0)),
          width: isSelected ? 2.2 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? const Color(0xFF7C3AED).withValues(alpha: 0.18)
                : const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: isSelected ? 20 : 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onSelect,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top row: Tier tag badge & Popular pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isHighlighted
                            ? const Color(0xFFEDE9FE)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        displayTag,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isHighlighted
                              ? const Color(0xFF6D28D9)
                              : const Color(0xFF475569),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    if (tier.isPopular)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isEn ? 'MOST POPULAR' : 'ተወዳጅ',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      )
                    else if (plan.isFree)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: Text(
                          isEn ? '100% FREE' : 'ነፃ',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF047857),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // Subtitle
                Text(
                  displaySubtitle,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF64748B),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),

                // Price display ($0 /month style)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      formattedPrice,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      periodSuffix,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // CTA Button: "Choose Plan"
                SizedBox(
                  height: 44,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                            )
                          : null,
                      color: isSelected ? null : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? null
                          : Border.all(
                              color: isHighlighted
                                  ? const Color(0xFFC4B5FD)
                                  : const Color(0xFFCBD5E1),
                              width: 1.2,
                            ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color:
                                    const Color(0xFF7C3AED).withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isSelected) ...[
                            const Icon(Icons.check_circle,
                                size: 16, color: Colors.white),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            isSelected
                                ? (isEn ? 'Selected' : 'ተመርጧል')
                                : (isEn ? 'Choose Plan' : 'እቅድ ይምረጡ'),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : (isHighlighted
                                      ? const Color(0xFF6D28D9)
                                      : const Color(0xFF1E293B)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),
                const Divider(color: Color(0xFFF1F5F9), height: 1),
                const SizedBox(height: 14),

                // "What You Get" section
                Text(
                  isEn ? 'What You Get' : 'የሚያገኙት ጥቅሞች',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 10),

                // Feature items with checkmark
                ...features.map(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEDE9FE),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 13,
                            color: Color(0xFF7C3AED),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            feature,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF334155),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Header and Plan Selector Container matching the reference image.
class PricingSelectorHeader extends StatelessWidget {
  const PricingSelectorHeader({
    super.key,
    required this.isEn,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  final bool isEn;
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Small pill badge: "• Pricing"
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFF3E8FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDDD6FE)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF7C3AED),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                isEn ? 'Pricing' : 'ዋጋዎች',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6D28D9),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Headline: "Clear & Simple Pricing"
        Text(
          isEn ? 'Clear & Simple Pricing' : 'ግልጽ እና ቀላል ዋጋዎች',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 6),

        // Subtitle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            isEn
                ? 'Choose the plan that fits your business. Upgrade anytime as your operations grow.'
                : 'ለንግድዎ የሚስማማውን እቅድ ይምረጡ። ስራዎ ሲያድግ በማንኛውም ጊዜ ያሻሽሉ።',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Period filter toggle: [All Plans] [Monthly] [Extended]
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FilterButton(
                label: isEn ? 'All Plans' : 'ሁሉም',
                active: selectedFilter == 'all',
                onTap: () => onFilterChanged('all'),
              ),
              _FilterButton(
                label: isEn ? 'Monthly' : 'ወርሃዊ',
                active: selectedFilter == 'monthly',
                onTap: () => onFilterChanged('monthly'),
              ),
              _FilterButton(
                label: isEn ? 'Yearly (Save 15%)' : 'አመታዊ (ቅናሽ 15%)',
                active: selectedFilter == 'extended',
                onTap: () => onFilterChanged('extended'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF2E1065) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: const Color(0xFF2E1065).withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: active ? FontWeight.w700 : FontWeight.w600,
            color: active ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}
