import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

class EventDateSelector extends StatelessWidget {
  final DateTime selectedEventDate;
  final ValueChanged<DateTime> onDateChanged;
  final bool Function(DateTime)? isDateAvailable;
  final int extensionDays;
  final ValueChanged<int>? onExtensionDaysChanged;
  final double? rentalPrice;

  const EventDateSelector({
    super.key,
    required this.selectedEventDate,
    required this.onDateChanged,
    this.isDateAvailable,
    this.extensionDays = 0,
    this.onExtensionDaysChanged,
    this.rentalPrice,
  });

  DateTime get deliveryDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final evDate = DateTime(selectedEventDate.year, selectedEventDate.month, selectedEventDate.day);
    final daysUntilEvent = evDate.difference(today).inDays;
    if (daysUntilEvent >= 5) {
      return evDate.subtract(const Duration(days: 2));
    } else {
      // Compressed 4-day case: exactly 1-day pre-event buffer (today + 3 days processing)
      return today.add(const Duration(days: 3));
    }
  }

  DateTime get returnDate => selectedEventDate.add(Duration(days: 2 + extensionDays));

  int get daysUntilEvent {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final evDate = DateTime(selectedEventDate.year, selectedEventDate.month, selectedEventDate.day);
    return evDate.difference(today).inDays;
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    // Backend strictly enforces MIN_PROCESSING_DAYS (3) + MIN_PRE_EVENT_BUFFER (1) = 4 days minimum
    final firstAllowed = DateTime(now.year, now.month, now.day).add(const Duration(days: 4));
    final lastAllowed = DateTime(now.year, now.month, now.day).add(const Duration(days: 120));

    DateTime initialDate = selectedEventDate;
    if (initialDate.isBefore(firstAllowed)) {
      initialDate = firstAllowed;
    }
    if (isDateAvailable != null && !isDateAvailable!(initialDate)) {
      // If current initial date is disabled, pick first available date
      for (int i = 0; i < 90; i++) {
        final cand = firstAllowed.add(Duration(days: i));
        if (isDateAvailable!(cand)) {
          initialDate = cand;
          break;
        }
      }
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstAllowed,
      lastDate: lastAllowed,
      selectableDayPredicate: isDateAvailable,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.accentRose,
              onPrimary: Colors.white,
              onSurface: AppColors.ink,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onDateChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE, d MMM yyyy');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgCream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('FLAT EVENT PACKAGE', style: AppTypography.subtitleTag.copyWith(fontSize: 8, letterSpacing: 1.2)),
                    const SizedBox(height: 3),
                    Text(
                      'Select Your Event Date',
                      style: AppTypography.titleLarge.copyWith(fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _pickDate(context),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accentRose.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.accentRose.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_month_outlined, size: 14, color: AppColors.accentRose),
                      const SizedBox(width: 4),
                      Text(
                        'Change Date',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.accentRose,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Active Event Date Highlight
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.accentRose,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.celebration_outlined, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('YOUR OCCASION / EVENT', style: AppTypography.subtitleTag.copyWith(fontSize: 8, letterSpacing: 1.0)),
                      Text(
                        dateFormat.format(selectedEventDate),
                        style: AppTypography.titleLarge.copyWith(fontSize: 15, color: AppColors.ink),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isDateAvailable != null && !isDateAvailable!(selectedEventDate)) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_busy, color: Color(0xFFDC2626), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LISTING NOT FOUND FOR THIS DATE',
                          style: AppTypography.subtitleTag.copyWith(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFB91C1C),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Listing not available for this date. Please tap "Change Date" to select an available date.',
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 11,
                            color: const Color(0xFF991B1B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Auto-Calculated Timeline Indicators (Read-Only)
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.local_shipping_outlined, size: 13, color: AppColors.inkSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              daysUntilEvent >= 5 ? 'DELIVERY (-2 DAYS)' : 'DELIVERY (-1 DAY RUSH)',
                              style: AppTypography.subtitleTag.copyWith(
                                fontSize: 7,
                                letterSpacing: 0.5,
                                color: AppColors.inkSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('d MMM').format(deliveryDate),
                        style: AppTypography.titleLarge.copyWith(fontSize: 13),
                      ),
                      Text(
                        DateFormat('EEEE').format(deliveryDate),
                        style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppColors.inkSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.assignment_return_outlined, size: 13, color: AppColors.inkSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              extensionDays > 0 ? 'RETURN (+${2 + extensionDays} DAYS)' : 'RETURN (+2 DAYS)',
                              style: AppTypography.subtitleTag.copyWith(
                                fontSize: 7,
                                letterSpacing: 0.5,
                                color: AppColors.inkSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('d MMM').format(returnDate),
                        style: AppTypography.titleLarge.copyWith(fontSize: 13),
                      ),
                      Text(
                        DateFormat('EEEE').format(returnDate),
                        style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppColors.inkSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 4-Day Package + Extension Days Selector
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NEED MORE TIME?',
                        style: AppTypography.subtitleTag.copyWith(fontSize: 8, letterSpacing: 1.0),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        rentalPrice != null
                            ? '+25% (₹${(rentalPrice! * 0.25).toInt()}) per additional day'
                            : '+25% per additional day',
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.inkSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.bgCream,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: extensionDays > 0 && onExtensionDaysChanged != null
                            ? () => onExtensionDaysChanged!(extensionDays - 1)
                            : null,
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: extensionDays > 0 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: extensionDays > 0 ? Border.all(color: AppColors.border) : null,
                          ),
                          child: Icon(
                            Icons.remove,
                            size: 16,
                            color: extensionDays > 0 ? AppColors.ink : AppColors.inkMuted,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 28,
                        child: Text(
                          '$extensionDays',
                          style: AppTypography.titleLarge.copyWith(fontSize: 14, fontWeight: FontWeight.w700),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      InkWell(
                        onTap: onExtensionDaysChanged != null
                            ? () => onExtensionDaysChanged!(extensionDays + 1)
                            : null,
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Icon(
                            Icons.add,
                            size: 16,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Total Rental Value Summary
          if (rentalPrice != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Rental Value:',
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '₹${(rentalPrice! + (extensionDays * rentalPrice! * 0.25)).toInt()}',
                    style: AppTypography.titleLarge.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.accentRose,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
