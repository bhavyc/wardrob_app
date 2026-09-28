enum PayoutStatus {
  pending,
  completed,
}

extension PayoutStatusExtension on PayoutStatus {
  String toPrismaString() {
    switch (this) {
      case PayoutStatus.pending:
        return 'PENDING';
      case PayoutStatus.completed:
        return 'COMPLETED';
    }
  }

  static PayoutStatus fromString(String? status) {
    switch (status?.toUpperCase()) {
      case 'COMPLETED':
        return PayoutStatus.completed;
      case 'PENDING':
      default:
        return PayoutStatus.pending;
    }
  }
}

class PayoutModel {
  final String id;
  final String bookingId;
  final double amount;
  final double commissionPaid;
  final PayoutStatus status;
  final String? batchRef;
  final bool hasDisputeHold;
  final String? listingTitle;
  final DateTime createdAt;

  PayoutModel({
    required this.id,
    required this.bookingId,
    required this.amount,
    required this.commissionPaid,
    required this.status,
    this.batchRef,
    this.hasDisputeHold = false,
    this.listingTitle,
    required this.createdAt,
  });

  factory PayoutModel.fromJson(Map<String, dynamic> json) {
    bool onHold = false;
    String? title;

    if (json['booking'] is Map<String, dynamic>) {
      final b = json['booking'] as Map<String, dynamic>;
      if (b['listing'] is Map<String, dynamic>) {
        title = b['listing']['title']?.toString();
      }
      if (b['damageReports'] is List) {
        final reports = b['damageReports'] as List;
        onHold = reports.any((r) =>
            r is Map &&
            r['dispute'] is Map &&
            r['dispute']['status']?.toString().toUpperCase() == 'OPEN');
      }
    }

    return PayoutModel(
      id: json['id']?.toString() ?? '',
      bookingId: json['bookingId']?.toString() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      commissionPaid: double.tryParse(json['commissionPaid']?.toString() ?? '0') ?? 0.0,
      status: PayoutStatusExtension.fromString(json['status']?.toString()),
      batchRef: json['batchRef']?.toString(),
      hasDisputeHold: onHold,
      listingTitle: title,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
