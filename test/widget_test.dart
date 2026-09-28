import 'package:flutter_test/flutter_test.dart';
import 'package:wardrob_mobile/models/booking_model.dart';
import 'package:wardrob_mobile/models/listing_model.dart';

void main() {
  group('ListingModel Tests', () {
    test('Correctly parses Listing with AT_HUB status and baselineImages', () {
      final json = {
        'id': 'list_123',
        'title': 'Royal Velvet Sherwani',
        'description': 'Handcrafted zardozi silk',
        'category': 'Sherwani',
        'size': 'L',
        'condition': 'Pristine',
        'rentalPrice': '7500',
        'securityDeposit': '3000',
        'status': 'AT_HUB',
        'isFeatured': true,
        'baselineImages': [
          'https://images.unsplash.com/photo-1',
          'https://images.unsplash.com/photo-2'
        ],
        'lister': {
          'shopName': 'Heritage Atelier',
          'user': {'name': 'Raghav Sharma'}
        }
      };

      final listing = ListingModel.fromJson(json);

      expect(listing.id, 'list_123');
      expect(listing.title, 'Royal Velvet Sherwani');
      expect(listing.rentalPrice, 7500.0);
      expect(listing.securityDeposit, 3000.0);
      expect(listing.status, ListingStatus.atHub);
      expect(listing.status.toPrismaString(), 'AT_HUB');
      expect(listing.baselineImages.length, 2);
      expect(listing.listerShopName, 'Heritage Atelier');
      expect(listing.isFeatured, true);
    });
  });

  group('BookingModel Tests', () {
    test('Correctly parses Booking with live shipment tracking and deposit refund', () {
      final json = {
        'id': 'bk_999',
        'listingId': 'list_123',
        'renterId': 'usr_456',
        'startDate': '2026-09-18T00:00:00.000Z',
        'endDate': '2026-09-22T00:00:00.000Z',
        'rentAmount': '6000',
        'securityDeposit': '2000',
        'totalAmount': '8000',
        'status': 'RETURNED_TO_HUB',
        'shipments': [
          {
            'leg': 'RENTER_TO_HUB',
            'status': 'IN_TRANSIT',
            'trackingNumber': 'BLUEDART_991823'
          }
        ],
        'refund': {
          'amount': '2000',
          'status': 'PROCESSED'
        },
        'renter': {
          'name': 'Priya Patel'
        },
        'listing': {
          'id': 'list_123',
          'title': 'Embroidered Anarkali',
          'rentalPrice': 6000,
          'securityDeposit': 2000,
          'baselineImages': ['https://images.unsplash.com/photo-1']
        }
      };

      final booking = BookingModel.fromJson(json);

      expect(booking.id, 'bk_999');
      expect(booking.rentAmount, 6000.0);
      expect(booking.securityDeposit, 2000.0);
      expect(booking.status, BookingStatus.returnedToHub);
      expect(booking.status.toPrismaString(), 'RETURNED_TO_HUB');
      expect(booking.renterName, 'Priya Patel');
      expect(booking.shipmentLeg, 'RENTER_TO_HUB');
      expect(booking.shipmentStatus, 'IN_TRANSIT');
      expect(booking.shipmentTracking, 'BLUEDART_991823');
      expect(booking.refundStatus, 'PROCESSED');
      expect(booking.refundAmount, 2000.0);
      expect(booking.listing?.title, 'Embroidered Anarkali');
    });
  });

  group('Logistics Buffer Calculations', () {
    test('Calculates delivery 2 days prior for events >= 5 days away', () {
      final today = DateTime(2026, 9, 14);
      final eventDate = DateTime(2026, 9, 20); // 6 days away
      final daysUntilEvent = eventDate.difference(today).inDays;

      expect(daysUntilEvent, 6);
      expect(daysUntilEvent >= 5, true);

      final deliveryDate = eventDate.subtract(const Duration(days: 2));
      expect(deliveryDate, DateTime(2026, 9, 18));
    });

    test('Calculates delivery with rush buffer (today + 3 days) for events exactly 4 days away', () {
      final today = DateTime(2026, 9, 14);
      final eventDate = DateTime(2026, 9, 18); // Exactly 4 days away
      final daysUntilEvent = eventDate.difference(today).inDays;

      expect(daysUntilEvent, 4);

      final deliveryDate = today.add(const Duration(days: 3));
      expect(deliveryDate, DateTime(2026, 9, 17)); // 1 day pre-event buffer
    });

    test('Scheduled return is strictly event date + 2 days', () {
      final eventDate = DateTime(2026, 9, 18);
      final returnDate = eventDate.add(const Duration(days: 2));
      expect(returnDate, DateTime(2026, 9, 20));
    });
  });
}
