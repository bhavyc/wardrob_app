enum ListingStatus {
  available,
  rented,
  atHub,
  maintenance,
  unlisted,
}

extension ListingStatusExtension on ListingStatus {
  String toPrismaString() {
    switch (this) {
      case ListingStatus.available:
        return 'AVAILABLE';
      case ListingStatus.rented:
        return 'RENTED';
      case ListingStatus.atHub:
        return 'AT_HUB';
      case ListingStatus.maintenance:
        return 'MAINTENANCE';
      case ListingStatus.unlisted:
        return 'UNLISTED';
    }
  }

  static ListingStatus fromString(String? status) {
    switch (status?.toUpperCase()) {
      case 'RENTED':
        return ListingStatus.rented;
      case 'AT_HUB':
        return ListingStatus.atHub;
      case 'MAINTENANCE':
        return ListingStatus.maintenance;
      case 'UNLISTED':
        return ListingStatus.unlisted;
      case 'AVAILABLE':
      default:
        return ListingStatus.available;
    }
  }
}

class BookedRange {
  final DateTime startDate;
  final DateTime endDate;
  final DateTime? eventDate;

  BookedRange({
    required this.startDate,
    required this.endDate,
    this.eventDate,
  });

  factory BookedRange.fromJson(Map<String, dynamic> json) {
    return BookedRange(
      startDate: DateTime.tryParse(json['startDate']?.toString() ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(json['endDate']?.toString() ?? '') ?? DateTime.now(),
      eventDate: json['eventDate'] != null ? DateTime.tryParse(json['eventDate'].toString()) : null,
    );
  }

  static const int postReturnTurnaroundDays = 2;

  /// ⚠️ CROSS-LANGUAGE SYNC NOTICE:
  /// This buffer calculation logic is mirrored in the Web Next.js engine at:
  /// `src/lib/availability.ts` (calculateRentalWindow, POST_RETURN_TURNAROUND_DAYS & isDateConflictingWithBookings).
  /// If any buffer rules change here (e.g. 2-day delivery buffer, 2-day return pickup buffer, post-return turnaround, or min 4-day advance notice),
  /// you MUST also update `src/lib/availability.ts` on the Web backend to prevent Web/Mobile inconsistency.
  bool conflictsWith(DateTime targetEventDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final evDate = DateTime(targetEventDate.year, targetEventDate.month, targetEventDate.day);
    final daysUntilEvent = evDate.difference(today).inDays;

    if (daysUntilEvent < 4) {
      return true; // Not bookable within 4 days
    }

    DateTime delivery;
    if (daysUntilEvent >= 5) {
      delivery = evDate.subtract(const Duration(days: 2));
    } else {
      delivery = today.add(const Duration(days: 3));
    }

    final returnPickup = evDate.add(const Duration(days: 2));
    final returnPickupWithTurnaround = returnPickup.add(const Duration(days: postReturnTurnaroundDays));

    final sDate = DateTime(startDate.year, startDate.month, startDate.day);
    final eDate = DateTime(endDate.year, endDate.month, endDate.day);
    final occupiedEnd = eDate.add(const Duration(days: postReturnTurnaroundDays));

    return !sDate.isAfter(returnPickupWithTurnaround) && !occupiedEnd.isBefore(delivery);
  }
}

class ListingModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String size;
  final String condition;
  final double rentalPrice;
  final double securityDeposit;
  final List<String> baselineImages;
  final ListingStatus status;
  final bool isFeatured;
  final int bookingsCount;
  final String? listerShopName;
  final String? listerName;
  final List<BookedRange> bookedRanges;
  final bool isAvailableNow;
  final String availabilityBadge;
  final DateTime nextAvailableDate;

  ListingModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.size,
    required this.condition,
    required this.rentalPrice,
    required this.securityDeposit,
    required this.baselineImages,
    this.status = ListingStatus.available,
    this.isFeatured = false,
    this.bookingsCount = 0,
    this.listerShopName,
    this.listerName,
    this.bookedRanges = const [],
    this.isAvailableNow = true,
    this.availabilityBadge = 'Available Now',
    DateTime? nextAvailableDate,
  }) : nextAvailableDate = nextAvailableDate ?? DateTime.now().add(const Duration(days: 4));

  bool isDateAvailable(DateTime eventDate) {
    for (final range in bookedRanges) {
      if (range.conflictsWith(eventDate)) {
        return false;
      }
    }
    return true;
  }

  DateTime getNextAvailableDate([DateTime? startFrom]) {
    final now = DateTime.now();
    final firstAllowed = DateTime(now.year, now.month, now.day).add(const Duration(days: 4));
    DateTime candidate = startFrom ?? firstAllowed;
    if (candidate.isBefore(firstAllowed)) candidate = firstAllowed;

    for (int i = 0; i < 90; i++) {
      final date = candidate.add(Duration(days: i));
      if (isDateAvailable(date)) {
        return date;
      }
    }
    return candidate;
  }

  static String computeBadgeText(DateTime nextDate, bool isAvailableNow) {
    if (isAvailableNow) return 'Available Now';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return 'Available from ${nextDate.day} ${months[nextDate.month - 1]}';
  }

  factory ListingModel.fromJson(Map<String, dynamic> json) {
    List<String> images = [];
    if (json['baselineImages'] is List && (json['baselineImages'] as List).isNotEmpty) {
      images = (json['baselineImages'] as List).map((e) => e.toString()).toList();
    } else if (json['images'] is List && (json['images'] as List).isNotEmpty) {
      images = (json['images'] as List).map((e) => e.toString()).toList();
    }

    String? shop;
    String? lName;
    if (json['lister'] is Map) {
      final lister = json['lister'] as Map<String, dynamic>;
      shop = lister['shopName']?.toString();
      if (lister['user'] is Map) {
        lName = (lister['user'] as Map<String, dynamic>)['name']?.toString();
      }
    } else if (json['Lister'] is Map) {
      final lister = json['Lister'] as Map<String, dynamic>;
      shop = lister['shopName']?.toString();
    }

    final priceRaw = json['rentalPrice'] ?? json['price'] ?? '0';

    int bCount = 0;
    if (json['_count'] is Map) {
      bCount = int.tryParse(json['_count']['bookings']?.toString() ?? '0') ?? 0;
    }

    List<BookedRange> bookedList = [];
    if (json['bookings'] is List) {
      bookedList = (json['bookings'] as List)
          .whereType<Map<String, dynamic>>()
          .map((b) => BookedRange.fromJson(b))
          .toList();
    }

    final now = DateTime.now();
    final firstAllowed = DateTime(now.year, now.month, now.day).add(const Duration(days: 4));

    DateTime calculatedNextDate = firstAllowed;
    for (int i = 0; i < 90; i++) {
      final cand = firstAllowed.add(Duration(days: i));
      bool hasConflict = false;
      for (final r in bookedList) {
        if (r.conflictsWith(cand)) {
          hasConflict = true;
          break;
        }
      }
      if (!hasConflict) {
        calculatedNextDate = cand;
        break;
      }
    }

    final bool isAvail = json['isAvailableNow'] ?? (calculatedNextDate.difference(firstAllowed).inDays <= 1);
    final String badge = json['availabilityBadge']?.toString() ?? computeBadgeText(calculatedNextDate, isAvail);

    return ListingModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Ethnic Wear',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Lehenga',
      size: json['size']?.toString() ?? 'M',
      condition: json['condition']?.toString() ?? 'Pristine',
      rentalPrice: double.tryParse(priceRaw.toString()) ?? 0.0,
      securityDeposit: double.tryParse(json['securityDeposit']?.toString() ?? '0') ?? 0.0,
      baselineImages: images,
      status: ListingStatusExtension.fromString(json['status']?.toString()),
      isFeatured: json['isFeatured'] == true,
      bookingsCount: bCount,
      listerShopName: shop,
      listerName: lName,
      bookedRanges: bookedList,
      isAvailableNow: isAvail,
      availabilityBadge: badge,
      nextAvailableDate: calculatedNextDate,
    );
  }
}
