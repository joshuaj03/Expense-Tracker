import sys

def modify_file():
    with open('finara/lib/features/transactions/presentation/screens/add_transaction_screen.dart', 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Remove bad injections
    bad_injection = '''  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSideBySide = ref.watch(sideBySideTransactionUINotifierProvider);'''

    good_injection_state = bad_injection
    good_injection_stateless = '''  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;'''

    parts = content.split(bad_injection)
    if len(parts) > 1:
        content = parts[0] + good_injection_state + good_injection_stateless.join(parts[1:])

    # 2. Fix AccountType equality
    content = content.replace('== AccountType.creditCard', '== AccountType.creditCard.name')
    content = content.replace('== AccountType.loan', '== AccountType.loan.name')

    # 3. Replace _PickerTile class
    old_picker = '''class _PickerTile extends StatelessWidget {
  final String label;
  final String icon;
  final String value;
  final VoidCallback onTap;

  const _PickerTile({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.onTap,
  });'''
  
    # Wait, in the file I viewed, it does not have `super.key`. It just has:
    old_picker2 = '''class _PickerTile extends StatelessWidget {
  final String label;
  final String icon;
  final String value;
  final VoidCallback onTap;

  const _PickerTile({
    required this.label,
    required this.icon,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTypography.labelSmall),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.keyboard_arrow_down, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}'''

    new_picker = '''class _PickerTile extends StatelessWidget {
  final String label;
  final String icon;
  final String value;
  final VoidCallback onTap;
  final bool isCompact;

  const _PickerTile({
    required this.label,
    required this.icon,
    required this.value,
    required this.onTap,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(14),
        border: isCompact ? Border.all(color: AppColors.outline.withValues(alpha: 0.5)) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 16, vertical: isCompact ? 10 : 14),
            child: Row(
              children: [
                Text(icon, style: TextStyle(fontSize: isCompact ? 24 : 20)),
                SizedBox(width: isCompact ? 8 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: AppTypography.labelSmall),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (!isCompact)
                  const Icon(Icons.keyboard_arrow_down, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}'''

    if old_picker2 in content:
        content = content.replace(old_picker2, new_picker)

    with open('finara/lib/features/transactions/presentation/screens/add_transaction_screen.dart', 'w', encoding='utf-8') as f:
        f.write(content)

modify_file()
