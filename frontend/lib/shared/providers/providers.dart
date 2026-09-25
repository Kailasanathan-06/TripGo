import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_failure.dart';
import '../../core/storage/token_storage.dart';
import '../models/models.dart';
import '../services/services.dart';

/// ───────────────────────── SETTINGS ─────────────────────────
enum AppThemeMode { light, dark, system }

class SettingsController extends Notifier<AppThemeMode> {
  @override
  AppThemeMode build() => AppThemeMode.system;

  void set(AppThemeMode mode) => state = mode;
}

final settingsProvider = NotifierProvider<SettingsController, AppThemeMode>(SettingsController.new);

/// ───────────────────────── AUTH ─────────────────────────
class AuthState {
  final UserModel? user;
  final bool loading;
  final bool initialized;
  final String? error;

  const AuthState({this.user, this.loading = false, this.initialized = false, this.error});

  AuthState copyWith({UserModel? user, bool? loading, bool? initialized, String? error, bool clearError = false}) =>
      AuthState(
        user: user ?? this.user,
        loading: loading ?? this.loading,
        initialized: initialized ?? this.initialized,
        error: clearError ? null : (error ?? this.error),
      );

  bool get authenticated => user != null;
}

class AuthController extends AsyncNotifier<AuthState> {
  final _auth = AuthRepository();

  @override
  Future<AuthState> build() async {
    if (!await TokenStorage.hasTokens()) {
      return const AuthState(initialized: true);
    }
    try {
      final user = await _auth.me();
      return AuthState(user: user, initialized: true);
    } catch (_) {
      return const AuthState(initialized: true);
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncLoading();
    try {
      final user = await _auth.login(email: email, password: password);
      state = AsyncData(AuthState(user: user, initialized: true));
    } catch (e) {
      state = AsyncData(AuthState(initialized: true, error: e is ApiException ? e.message : 'Login failed.'));
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      final user = await _auth.register(
        username: email.split('@').first,
        email: email,
        firstName: name,
        phone: phone,
        password: password,
      );
      state = AsyncData(AuthState(user: user, initialized: true));
    } catch (e) {
      state = AsyncData(AuthState(initialized: true, error: e is ApiException ? e.message : 'Registration failed.'));
    }
  }

  Future<void> logout() async {
    await _auth.logout();
    state = const AsyncData(AuthState(initialized: true));
  }
}

final authProvider = AsyncNotifierProvider<AuthController, AuthState>(AuthController.new);

/// ───────────────────────── SEARCH STATE ─────────────────────────
class SearchController extends Notifier<SearchQuery> {
  @override
  SearchQuery build() => SearchQuery(
        source: 'Chennai',
        destination: 'Bengaluru',
        date: DateTime.now().add(const Duration(days: 1)),
        passengers: 1,
      );

  void update(SearchQuery query) => state = query;
  void swap() => state = state.copyWith(
        source: state.destination,
        sourceCode: state.destinationCode,
        destination: state.source,
        destinationCode: state.sourceCode,
      );
}

final searchProvider = NotifierProvider<SearchController, SearchQuery>(SearchController.new);

/// Selected transport results (populated by search).
class SearchResultHolder {
  final List<BusScheduleModel> buses;
  final List<TrainScheduleModel> trains;
  final String transport; // 'bus' | 'train'

  const SearchResultHolder({this.buses = const [], this.trains = const [], this.transport = 'bus'});

  SearchResultHolder copyWith({
    List<BusScheduleModel>? buses,
    List<TrainScheduleModel>? trains,
    String? transport,
  }) =>
      SearchResultHolder(
        buses: buses ?? this.buses,
        trains: trains ?? this.trains,
        transport: transport ?? this.transport,
      );
}

class SearchResultController extends Notifier<SearchResultHolder> {
  @override
  SearchResultHolder build() => const SearchResultHolder();
  void set(SearchResultHolder holder) => state = holder;
}

final searchResultProvider = NotifierProvider<SearchResultController, SearchResultHolder>(SearchResultController.new);

/// ───────────────────────── BOOKING FLOW ─────────────────────────
class BookingFlowState {
  final String transport; // 'bus' | 'train'
  final int scheduleId;
  final int? coachId;
  final String vehicleName;
  final String vehicleNumber;
  final String route;
  final String travelDateLabel;
  final String departure;
  final String arrival;
  final String boardingPoint;
  final String droppingPoint;
  final double unitFare;
  final double discount;
  final int available;
  final List<String> selectedSeats;

  const BookingFlowState({
    required this.transport,
    required this.scheduleId,
    this.coachId,
    required this.vehicleName,
    required this.vehicleNumber,
    required this.route,
    required this.travelDateLabel,
    required this.departure,
    required this.arrival,
    required this.boardingPoint,
    required this.droppingPoint,
    required this.unitFare,
    this.discount = 0,
    required this.available,
    this.selectedSeats = const [],
  });

  BookingFlowState copyWith({List<String>? selectedSeats, double? discount}) => BookingFlowState(
        transport: transport,
        scheduleId: scheduleId,
        coachId: coachId,
        vehicleName: vehicleName,
        vehicleNumber: vehicleNumber,
        route: route,
        travelDateLabel: travelDateLabel,
        departure: departure,
        arrival: arrival,
        boardingPoint: boardingPoint,
        droppingPoint: droppingPoint,
        unitFare: unitFare,
        discount: discount ?? this.discount,
        available: available,
        selectedSeats: selectedSeats ?? this.selectedSeats,
      );
}

class BookingFlowController extends Notifier<BookingFlowState?> {
  @override
  BookingFlowState? build() => null;

  void start(BookingFlowState flow) => state = flow;
  void toggleSeat(String label) {
    final current = state;
    if (current == null) return;
    final seats = List<String>.from(current.selectedSeats);
    if (seats.contains(label)) {
      seats.remove(label);
    } else {
      seats.add(label);
    }
    state = current.copyWith(selectedSeats: seats);
  }

  void clear() => state = null;
}

final bookingFlowProvider = NotifierProvider<BookingFlowController, BookingFlowState?>(BookingFlowController.new);

/// Passengers entered during the flow.
final passengersProvider = StateProvider<List<PassengerModel>>((ref) => const []);
final offerDiscountProvider = StateProvider<double>((ref) => 0);
final offerCodeProvider = StateProvider<String>((ref) => '');

/// The confirmed Booking returned by the backend after payment success.
final confirmedBookingProvider = StateProvider<BookingModel?>((ref) => null);
final paymentReferenceProvider = StateProvider<String>((ref) => '');
final paymentAmountProvider = StateProvider<double>((ref) => 0);
final paymentMethodProvider = StateProvider<String>((ref) => '');

/// ───────────────────────── ASYNC LISTS ─────────────────────────
final myBookingsProvider = FutureProvider<List<BookingModel>>((ref) => BookingRepository().myBookings());

final myTicketsProvider = FutureProvider<List<TicketModel>>((ref) async {
  final bookings = await BookingRepository().myBookings();
  final tickets = <TicketModel>[];
  for (final b in bookings) {
    if (b.pnr != null) {
      try {
        tickets.add(await TicketRepository().byPnr(b.pnr!));
      } catch (_) {
        // skip missing
      }
    }
  }
  return tickets;
});

final offersProvider = FutureProvider<List<OfferModel>>((ref) => OfferRepository().offers());

final notificationsProvider = FutureProvider<List<NotificationModel>>((ref) => NotificationRepository().all());

final unreadNotificationsProvider = Provider<int>((ref) {
  final list = ref.watch(notificationsProvider).valueOrNull;
  if (list == null) return 0;
  return list.where((n) => !n.read).length;
});

/// Fault injection for demo (used by mock payment screens).
final demoFailChoiceProvider = StateProvider<String>((ref) => '');

Future<void> invalidateUserData(WidgetRef ref) async {
  ref.invalidate(myBookingsProvider);
  ref.invalidate(myTicketsProvider);
  ref.invalidate(notificationsProvider);
  ref.invalidate(offersProvider);
  await Future<void>.delayed(Duration.zero);
}