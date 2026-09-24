import '../../core/errors/app_failure.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/token_storage.dart';
import '../models/models.dart';

/// ─────────────────────────── AUTH ───────────────────────────
class AuthRepository {
  final _api = ApiClient.instance;

  Future<UserModel> login({required String email, required String password}) async {
    final resp = await _api.post('/auth/login/', data: {'email': email, 'password': password});
    final tokens = resp['data'] as Map<String, dynamic>;
    await TokenStorage.saveTokens(
      access: tokens['access'] as String,
      refresh: tokens['refresh'] as String,
    );
    return UserModel.fromJson(tokens['user'] as Map<String, dynamic>);
  }

  Future<UserModel> register({
    required String username,
    required String email,
    required String firstName,
    required String phone,
    required String password,
  }) async {
    final resp = await _api.post('/auth/register/', data: {
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': '',
      'phone': phone,
      'password': password,
      'password2': password,
    });
    final tokens = resp['data'] as Map<String, dynamic>;
    await TokenStorage.saveTokens(
      access: tokens['access'] as String,
      refresh: tokens['refresh'] as String,
    );
    return UserModel.fromJson(tokens['user'] as Map<String, dynamic>);
  }

  Future<UserModel> me() async {
    final resp = await _api.get('/auth/me/');
    return UserModel.fromJson(resp['data'] as Map<String, dynamic>);
  }

  Future<void> logout() async {
    try {
      final refresh = await TokenStorage.readRefresh();
      if (refresh != null) {
        await _api.post('/auth/logout/', data: {'refresh': refresh});
      }
    } catch (_) {
      // ignore: token invalidation best-effort
    }
    await TokenStorage.clear();
  }

  Future<void> forgotPassword(String email) async {
    await _api.post('/auth/forgot-password/', data: {'email': email});
  }

  Future<void> verifyOtp({required String email, required String otp, required String newPassword}) async {
    await _api.post('/auth/verify-otp/', data: {'email': email, 'otp': otp, 'new_password': newPassword});
  }
}

/// ─────────────────────────── CATALOG ───────────────────────────
class CityRepository {
  final _api = ApiClient.instance;

  Future<List<CityModel>> searchCities(String query) async {
    final resp = await _api.get('/cities/', query: {'q': query});
    final list = (resp['data'] as List?) ?? const [];
    return list.map((e) => CityModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}

class BusRepository {
  final _api = ApiClient.instance;

  Future<List<BusScheduleModel>> search(SearchQuery query) async {
    final resp = await _api.get('/buses/', query: {
      'source': query.source,
      'destination': query.destination,
      'date': query.dateIso,
    });
    final list = (resp['data'] as List?) ?? const [];
    return list.map((e) => BusScheduleModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<BusSeatModel>> seats(int scheduleId) async {
    final resp = await _api.get('/buses/$scheduleId/seats/');
    final list = (resp['data'] as List?) ?? const [];
    return list.map((e) => BusSeatModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}

class TrainRepository {
  final _api = ApiClient.instance;

  Future<List<TrainScheduleModel>> search(SearchQuery query) async {
    final resp = await _api.get('/trains/', query: {
      'source': query.source,
      'destination': query.destination,
      'date': query.dateIso,
    });
    final list = (resp['data'] as List?) ?? const [];
    return list.map((e) => TrainScheduleModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<TrainBerthModel>> berths(int coachId) async {
    final resp = await _api.get('/trains/coaches/$coachId/berths/');
    final list = (resp['data'] as List?) ?? const [];
    return list.map((e) => TrainBerthModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}

/// ─────────────────────────── BOOKING ───────────────────────────
class BookingRepository {
  final _api = ApiClient.instance;

  Future<BookingModel> create({
    required String transportType,
    required int scheduleId,
    required List<String> seatLabels,
    int? coachId,
    required List<PassengerModel> passengers,
    String offerCode = '',
  }) async {
    final resp = await _api.post('/bookings/', data: {
      'transport_type': transportType,
      'schedule_id': scheduleId,
      if (coachId != null) 'coach_id': coachId,
      'seat_labels': seatLabels,
      'passengers': passengers.map((p) => p.toJson()).toList(),
      'offer_code': offerCode,
    });
    return BookingModel.fromJson(resp['data'] as Map<String, dynamic>);
  }

  Future<List<BookingModel>> myBookings() async {
    final resp = await _api.get('/bookings/list/');
    final list = (resp['data'] as List?) ?? const [];
    return list.map((e) => BookingModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<BookingModel> detail(int id) async {
    final resp = await _api.get('/bookings/$id/');
    return BookingModel.fromJson(resp['data'] as Map<String, dynamic>);
  }

  Future<BookingModel> cancel(int id) async {
    final resp = await _api.post('/bookings/$id/cancel/');
    return BookingModel.fromJson(resp['data'] as Map<String, dynamic>);
  }
}

/// ─────────────────────────── PAYMENT (MOCK) ───────────────────────────
class PaymentRepository {
  final _api = ApiClient.instance;

  Future<PaymentModel> pay({
    required int bookingId,
    required String method,
    required String action,
    double? amount,
  }) async {
    final resp = await _api.post('/payments/mock/', data: {
      'booking_id': bookingId,
      'method': method,
      'action': action,
      if (amount != null) 'amount': amount,
    });
    final data = resp['data'] as Map<String, dynamic>;
    return PaymentModel(
      id: (data['payment'] as Map<String, dynamic>)['id'] as int,
      reference: (data['payment'] as Map<String, dynamic>)['reference'] as String,
      method: (data['payment'] as Map<String, dynamic>)['method'] as String? ?? 'app',
      status: (data['payment'] as Map<String, dynamic>)['status'] as String,
      amount: double.tryParse((data['payment'] as Map<String, dynamic>)['amount']?.toString() ?? '0') ?? 0,
      booking: data['booking'] is Map<String, dynamic>
          ? BookingModel.fromJson(data['booking'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// ─────────────────────────── TICKET / PNR ───────────────────────────
class TicketRepository {
  final _api = ApiClient.instance;

  Future<TicketModel> byBooking(int bookingId) async {
    final bookings = await BookingRepository().myBookings();
    final booking = bookings.where((b) => b.id == bookingId).firstWhere((b) => b.pnr != null, orElse: () => bookings.firstWhere((b) => b.id == bookingId));
    if (booking.pnr == null) {
      throw const ApiException('No ticket generated yet for this booking.');
    }
    return await byPnr(booking.pnr!);
  }

  Future<TicketModel> byPnr(String pnr) async {
    final resp = await _api.get('/pnr/$pnr/');
    return TicketModel.fromJson(resp['data'] as Map<String, dynamic>);
  }
}

/// ─────────────────────────── OFFERS ───────────────────────────
class OfferRepository {
  final _api = ApiClient.instance;

  Future<List<OfferModel>> offers() async {
    final resp = await _api.get('/offers/');
    final list = (resp['data'] as List?) ?? const [];
    return list.map((e) => OfferModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<double> validateCoupon({required String code, required String transportType, required double fare}) async {
    final resp = await _api.post('/offers/validate/', data: {
      'code': code,
      'transport_type': transportType,
      'fare': fare,
    });
    final data = resp['data'] as Map<String, dynamic>;
    return double.tryParse((data['discount'] ?? '0').toString()) ?? 0;
  }
}

/// ─────────────────────────── NOTIFICATIONS ───────────────────────────
class NotificationRepository {
  final _api = ApiClient.instance;

  Future<List<NotificationModel>> all() async {
    final resp = await _api.get('/notifications/');
    final list = (resp['data'] as List?) ?? const [];
    return list.map((e) => NotificationModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> markRead(int id) async {
    await _api.post('/notifications/$id/read/');
  }

  Future<void> markAllRead() async {
    await _api.post('/notifications/read-all/');
  }
}