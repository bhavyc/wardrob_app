import 'listing_model.dart';

enum BookingStatus {
  pending,
  confirmed,
  atHubPre,
  outForDelivery,
  inUse,
  returnedToHub,
  completed,
  cancelled,
  lostNotReturned,
}

extension BookingStatusExtension on BookingStatus {
  String toPrismaString() {
    switch (this) {
      case BookingStatus.pending:
        return 'PENDING';
      case BookingStatus.confirmed:
        return 'CONFIRMED';
      case BookingStatus.atHubPre:
        return 'AT_HUB_PRE';
      case BookingStatus.outForDelivery:
        return 'OUT_FOR_DELIVERY';
      case BookingStatus.inUse:
        return 'IN_USE';
      case BookingStatus.returnedToHub:
        return 'RETURNED_TO_HUB';
      case BookingStatus.completed:
        return 'COMPLETED';
      case BookingStatus.cancelled:
        return 'CANCELLED';
      case BookingStatus.lostNotReturned:
        return 'LOST_NOT_RETURNED';
    }
  }

  String toDisplayString() {
    switch (this) {
      case BookingStatus.pending:
        return 'Pending Verification';
      case BookingStatus.confirmed:
        return 'Confirmed & Reserved';
      case BookingStatus.atHubPre:
        return 'At Hub (Pre-Dispatch)';
      case BookingStatus.outForDelivery:
        return 'Out For Delivery';
      case BookingStatus.inUse:
        return 'In Use';
      case BookingStatus.returnedToHub:
        return 'Returned To Hub';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.lostNotReturned:
        return 'Item Lost / Overdue';
    }
  }

  static BookingStatus fromString(String? status) {
    switch (status?.toUpperCase()) {
      case 'CONFIRMED':
        return BookingStatus.confirmed;
      case 'AT_HUB_PRE':
        return BookingStatus.atHubPre;
      case 'OUT_FOR_DELIVERY':
        return BookingStatus.outForDelivery;
      case 'IN_USE':
        return BookingStatus.inUse;
      case 'RETURNED_TO_HUB':
        return BookingStatus.returnedToHub;
      case 'COMPLETED':
        return BookingStatus.completed;
      case 'CANCELLED':
        return BookingStatus.cancelled;
      case 'LOST_NOT_RETURNED':
        return BookingStatus.lostNotReturned;
      case 'PENDING':
      default:
        return BookingStatus.pending;
    }
  }
}

class BookingModel {
  final String id;
  final String listingId;
  final String renterId;
  final DateTime startDate;
  final DateTime endDate;
  final double rentAmount;
  final double securityDeposit;
  final double extensionFee;
  final double totalAmount;
  final BookingStatus status;
  final ListingModel? listing;
  final String? renterName;
  final String? renterPhone;
  final double? refundAmount;
  final String? refundStatus;
  final String? shipmentStatus;
  final String? shipmentTracking;
  final String? shipmentCourier;
  final String? shipmentLeg;

  BookingModel({
    required this.id,
    required this.listingId,
    required this.renterId,
    required this.startDate,
    required this.endDate,
    required this.rentAmount,
    required this.securityDeposit,
    this.extensionFee = 0.0,
    required this.totalAmount,
    required this.status,
    this.listing,
    this.renterName,
    this.renterPhone,
    this.refundAmount,
    this.refundStatus,
    this.shipmentStatus,
    this.shipmentTracking,
    this.shipmentCourier,
    this.shipmentLeg,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    ListingModel? listM;
    if (json['listing'] is Map<String, dynamic>) {
      listM = ListingModel.fromJson(json['listing'] as Map<String, dynamic>);
    }

    String? rName;
    String? rPhone;
    if (json['renter'] is Map<String, dynamic>) {
      rName = json['renter']['name']?.toString();
      rPhone = json['renter']['phone']?.toString();
    }

    double? rAmount;
    String? rStatus;
    if (json['refund'] is Map<String, dynamic>) {
      rAmount = double.tryParse(json['refund']['amount']?.toString() ?? '0');
      rStatus = json['refund']['status']?.toString();
    }

    String? sStatus;
    String? sTracking;
    String? sCourier;
    String? sLeg;
    if (json['shipments'] is List && (json['shipments'] as List).isNotEmpty) {
      final s = (json['shipments'] as List).last;
      if (s is Map<String, dynamic>) {
        sStatus = s['status']?.toString();
        sTracking = s['trackingNumber']?.toString();
        sCourier = s['courierName']?.toString();
        sLeg = s['leg']?.toString();
      }
    }

    return BookingModel(
      id: json['id']?.toString() ?? '',
      listingId: json['listingId']?.toString() ?? '',
      renterId: json['renterId']?.toString() ?? '',
      startDate: DateTime.tryParse(json['startDate']?.toString() ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(json['endDate']?.toString() ?? '') ?? DateTime.now().add(const Duration(days: 4)),
      rentAmount: double.tryParse(json['rentAmount']?.toString() ?? '0') ?? 0.0,
      securityDeposit: double.tryParse(json['securityDeposit']?.toString() ?? '0') ?? 0.0,
      extensionFee: double.tryParse(json['extensionFee']?.toString() ?? '0') ?? 0.0,
      totalAmount: double.tryParse(json['totalAmount']?.toString() ?? '0') ?? 0.0,
      status: BookingStatusExtension.fromString(json['status']?.toString()),
      listing: listM,
      renterName: rName,
      renterPhone: rPhone,
      refundAmount: rAmount,
      refundStatus: rStatus,
      shipmentStatus: sStatus,
      shipmentTracking: sTracking,
      shipmentCourier: sCourier,
      shipmentLeg: sLeg,
    );
  }
}
