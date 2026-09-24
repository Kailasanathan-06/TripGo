String _s(dynamic v) => v?.toString() ?? '';
int _i(dynamic v) => int.tryParse(v?.toString() ?? '') ?? 0;
double _d(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0;
bool _b(dynamic v) => v == true || v == 1 || v?.toString() == 'true';
DateTime? _dt(dynamic v) {
  if (v == null || v.toString().isEmpty) return null;
  return DateTime.tryParse(v.toString())?.toLocal();
}

class UserModel {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String phone;
  final String profileImage;

  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.firstName = '',
    this.lastName = '',
    this.phone = '',
    this.profileImage = '',
  });

  String get displayName => '$firstName $lastName'.trim().isEmpty ? username : '$firstName $lastName'.trim();
  String get initials {
    final parts = displayName.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return displayName.isEmpty ? 'U' : displayName[0].toUpperCase();
  }

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: _i(json['id']),
        username: _s(json['username']),
        email: _s(json['email']),
        firstName: _s(json['first_name']),
        lastName: _s(json['last_name']),
        phone: _s(json['phone']),
        profileImage: _s(json['profile_image']),
      );
}

class PassengerModel {
  final int? id;
  final String fullName;
  final int age;
  final String gender;
  final String mobile;
  final String email;
  final String idType;
  final String idNumber;

  const PassengerModel({
    this.id,
    required this.fullName,
    required this.age,
    this.gender = 'M',
    this.mobile = '',
    this.email = '',
    this.idType = '',
    this.idNumber = '',
  });

  factory PassengerModel.fromJson(Map<String, dynamic> json) => PassengerModel(
        id: _i(json['id']) != 0 ? _i(json['id']) : null,
        fullName: _s(json['full_name']),
        age: _i(json['age']),
        gender: _s(json['gender']),
        mobile: _s(json['mobile']),
        email: _s(json['email']),
        idType: _s(json['id_type']),
        idNumber: _s(json['id_number']),
      );

  Map<String, dynamic> toJson() => {
        'full_name': fullName,
        'age': age,
        'gender': gender,
        'mobile': mobile,
        'email': email,
        'id_type': idType,
        'id_number': idNumber,
      };
}

class CityModel {
  final int id;
  final String name;
  final String state;
  final bool isPopular;

  const CityModel({required this.id, required this.name, this.state = '', this.isPopular = false});

  factory CityModel.fromJson(Map<String, dynamic> json) => CityModel(
        id: _i(json['id']),
        name: _s(json['name']),
        state: _s(json['state']),
        isPopular: _b(json['is_popular']),
      );
}

class SearchQuery {
  final String source;
  final String sourceCode;
  final String destination;
  final String destinationCode;
  final DateTime date;
  final int passengers;

  const SearchQuery({
    required this.source,
    this.sourceCode = '',
    required this.destination,
    this.destinationCode = '',
    required this.date,
    this.passengers = 1,
  });

  String get dateIso => '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  SearchQuery copyWith({
    String? source,
    String? sourceCode,
    String? destination,
    String? destinationCode,
    DateTime? date,
    int? passengers,
  }) =>
      SearchQuery(
        source: source ?? this.source,
        sourceCode: sourceCode ?? this.sourceCode,
        destination: destination ?? this.destination,
        destinationCode: destinationCode ?? this.destinationCode,
        date: date ?? this.date,
        passengers: passengers ?? this.passengers,
      );
}

class BusModel {
  final int id;
  final String name;
  final String operator;
  final String busType;
  final int totalSeats;
  final double rating;
  final List<String> amenities;
  final bool isAc;
  final bool isSleeper;

  const BusModel({
    required this.id,
    required this.name,
    required this.operator,
    required this.busType,
    required this.totalSeats,
    required this.rating,
    required this.amenities,
    required this.isAc,
    required this.isSleeper,
  });

  factory BusModel.fromJson(Map<String, dynamic> json) => BusModel(
        id: _i(json['id']),
        name: _s(json['name']),
        operator: _s(json['operator']),
        busType: _s(json['bus_type']),
        totalSeats: _i(json['total_seats']),
        rating: _d(json['rating']),
        amenities: (json['amenities'] as List?)?.map((e) => _s(e)).toList() ?? const [],
        isAc: _b(json['is_ac']),
        isSleeper: _b(json['is_sleeper']),
      );
}

class BusScheduleModel {
  final int id;
  final BusModel bus;
  final String sourceCity;
  final String destinationCity;
  final int sourceId;
  final int destinationId;
  final String boardingPoint;
  final String droppingPoint;
  final DateTime boardingTime;
  final DateTime droppingTime;
  final int durationMinutes;
  final double baseFare;
  final double discountAmount;
  final double rating;
  final int reviewsCount;
  final int availableSeats;

  const BusScheduleModel({
    required this.id,
    required this.bus,
    required this.sourceCity,
    required this.destinationCity,
    required this.sourceId,
    required this.destinationId,
    required this.boardingPoint,
    required this.droppingPoint,
    required this.boardingTime,
    required this.droppingTime,
    required this.durationMinutes,
    required this.baseFare,
    required this.discountAmount,
    required this.rating,
    required this.reviewsCount,
    required this.availableSeats,
  });

  String get durationText => '${durationMinutes ~/ 60}h${durationMinutes % 60 == 0 ? '' : ' ${durationMinutes % 60}m'}';

  factory BusScheduleModel.fromJson(Map<String, dynamic> json) => BusScheduleModel(
        id: _i(json['id']),
        bus: BusModel.fromJson((json['bus'] as Map?) ?? const {}),
        sourceCity: _s(json['source_city']),
        destinationCity: _s(json['destination_city']),
        sourceId: _i(json['source_id']),
        destinationId: _i(json['destination_id']),
        boardingPoint: _s(json['boarding_point']),
        droppingPoint: _s(json['dropping_point']),
        boardingTime: _dt(json['boarding_time']) ?? DateTime.now(),
        droppingTime: _dt(json['dropping_time']) ?? DateTime.now(),
        durationMinutes: _i(json['duration_minutes']),
        baseFare: _d(json['base_fare']),
        discountAmount: _d(json['discount_amount']),
        rating: _d(json['rating']),
        reviewsCount: _i(json['reviews_count']),
        availableSeats: _i(json['available_seats']),
      );
}

class BusSeatModel {
  final int id;
  final String label;
  final int row;
  final int floor;
  final String status;
  final String gender;

  const BusSeatModel({
    required this.id,
    required this.label,
    required this.row,
    required this.floor,
    required this.status,
    this.gender = '',
  });

  bool get isAvailable => status == 'AVAILABLE';
  bool get isBooked => status == 'BOOKED';
  bool get isHeld => status == 'HELD';

  factory BusSeatModel.fromJson(Map<String, dynamic> json) => BusSeatModel(
        id: _i(json['id']),
        label: _s(json['label']),
        row: _i(json['row']),
        floor: _i(json['floor']),
        status: _s(json['status']),
        gender: _s(json['gender']),
      );
}

class TrainModel {
  final int id;
  final String number;
  final String name;
  final String trainType;
  final double rating;

  const TrainModel({
    required this.id,
    required this.number,
    required this.name,
    required this.trainType,
    required this.rating,
  });

  factory TrainModel.fromJson(Map<String, dynamic> json) => TrainModel(
        id: _i(json['id']),
        number: _s(json['number']),
        name: _s(json['name']),
        trainType: _s(json['train_type']),
        rating: _d(json['rating']),
      );
}

class TrainCoachModel {
  final int id;
  final String name;
  final String coachClass;
  final double classFare;
  final int available;

  const TrainCoachModel({
    required this.id,
    required this.name,
    required this.coachClass,
    required this.classFare,
    required this.available,
  });

  factory TrainCoachModel.fromJson(Map<String, dynamic> json) => TrainCoachModel(
        id: _i(json['id']),
        name: _s(json['name']),
        coachClass: _s(json['coach_class']),
        classFare: _d(json['class_fare']),
        available: _i(json['available']),
      );
}

class TrainScheduleModel {
  final int id;
  final TrainModel train;
  final String sourceStationName;
  final String sourceStationCode;
  final String destinationStationName;
  final String destinationStationCode;
  final DateTime travelDate;
  final int durationMinutes;
  final double distanceKm;
  final List<TrainCoachModel> coaches;
  final int totalAvailable;

  const TrainScheduleModel({
    required this.id,
    required this.train,
    required this.sourceStationName,
    required this.sourceStationCode,
    required this.destinationStationName,
    required this.destinationStationCode,
    required this.travelDate,
    required this.durationMinutes,
    required this.distanceKm,
    required this.coaches,
    required this.totalAvailable,
  });

  String get durationText => '${durationMinutes ~/ 60}h${durationMinutes % 60 == 0 ? '' : ' ${durationMinutes % 60}m'}';

  factory TrainScheduleModel.fromJson(Map<String, dynamic> json) => TrainScheduleModel(
        id: _i(json['id']),
        train: TrainModel.fromJson((json['train'] as Map?) ?? const {}),
        sourceStationName: _s(json['source_station_name']),
        sourceStationCode: _s(json['source_station_code']),
        destinationStationName: _s(json['destination_station_name']),
        destinationStationCode: _s(json['destination_station_code']),
        travelDate: _dt(json['travel_date']) ?? DateTime.now(),
        durationMinutes: _i(json['duration_minutes']),
        distanceKm: _d(json['distance_km']),
        coaches: (json['coaches'] as List?)
                ?.map((e) => TrainCoachModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        totalAvailable: _i(json['total_available']),
      );
}

class TrainBerthModel {
  final int id;
  final String label;
  final String type;
  final int coach;
  final String status;
  final String gender;

  const TrainBerthModel({
    required this.id,
    required this.label,
    required this.type,
    required this.coach,
    required this.status,
    this.gender = '',
  });

  bool get isAvailable => status == 'AVAILABLE';

  factory TrainBerthModel.fromJson(Map<String, dynamic> json) => TrainBerthModel(
        id: _i(json['id']),
        label: _s(json['label']),
        type: _s(json['type']),
        coach: _i(json['coach']),
        status: _s(json['status']),
        gender: _s(json['gender']),
      );
}

class BookingSeatModel {
  final String label;
  final String coach;
  final String state;

  const BookingSeatModel({required this.label, this.coach = '', this.state = 'HELD'});

  factory BookingSeatModel.fromJson(Map<String, dynamic> json) => BookingSeatModel(
        label: _s(json['label']),
        coach: _s(json['coach']),
        state: _s(json['state']),
      );
}

class BookingModel {
  final int id;
  final String transportType;
  final DateTime travelDate;
  final String state;
  final String source;
  final String destination;
  final String boardingPoint;
  final String droppingPoint;
  final String departureTime;
  final String arrivalTime;
  final String vehicleName;
  final String vehicleNumber;
  final String vehicleType;
  final double passengerFare;
  final double serviceFee;
  final double tax;
  final double discount;
  final double totalAmount;
  final String offerCode;
  final String? pnr;
  final String? ticketStatus;
  final List<PassengerModel> passengers;
  final List<BookingSeatModel> seats;

  const BookingModel({
    required this.id,
    required this.transportType,
    required this.travelDate,
    required this.state,
    required this.source,
    required this.destination,
    this.boardingPoint = '',
    this.droppingPoint = '',
    this.departureTime = '',
    this.arrivalTime = '',
    this.vehicleName = '',
    this.vehicleNumber = '',
    this.vehicleType = '',
    required this.passengerFare,
    required this.serviceFee,
    required this.tax,
    required this.discount,
    required this.totalAmount,
    this.offerCode = '',
    this.pnr,
    this.ticketStatus,
    required this.passengers,
    required this.seats,
  });

  bool get isConfirmed => state == 'CONFIRMED';
  bool get isCancelled => state == 'CANCELLED';
  String get seatSummary => seats.map((s) => s.label).join(', ');

  factory BookingModel.fromJson(Map<String, dynamic> json) => BookingModel(
        id: _i(json['id']),
        transportType: _s(json['transport_type']),
        travelDate: _dt(json['travel_date']) ?? DateTime.now(),
        state: _s(json['state']),
        source: _s(json['source']),
        destination: _s(json['destination']),
        boardingPoint: _s(json['boarding_point']),
        droppingPoint: _s(json['dropping_point']),
        departureTime: _s(json['departure_time']),
        arrivalTime: _s(json['arrival_time']),
        vehicleName: _s(json['vehicle_name']),
        vehicleNumber: _s(json['vehicle_number']),
        vehicleType: _s(json['vehicle_type']),
        passengerFare: _d(json['passenger_fare']),
        serviceFee: _d(json['service_fee']),
        tax: _d(json['tax']),
        discount: _d(json['discount']),
        totalAmount: _d(json['total_amount']),
        offerCode: _s(json['offer_code']),
        pnr: json['pnr']?.toString(),
        ticketStatus: json['ticket_status']?.toString(),
        passengers: (json['passengers'] as List?)
                ?.map((e) => PassengerModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        seats: (json['seats'] as List?)
                ?.map((e) => BookingSeatModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}

class PaymentModel {
  final int id;
  final String reference;
  final String method;
  final String status;
  final double amount;
  final BookingModel? booking;

  const PaymentModel({
    required this.id,
    required this.reference,
    this.method = 'app',
    this.status = 'INITIATED',
    required this.amount,
    this.booking,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) => PaymentModel(
        id: _i(json['id']),
        reference: _s(json['reference']),
        method: _s(json['method']),
        status: _s(json['status']),
        amount: _d(json['amount']),
        booking: json['booking'] is Map<String, dynamic>
            ? BookingModel.fromJson(json['booking'] as Map<String, dynamic>)
            : null,
      );
}

class TicketModel {
  final int id;
  final String pnr;
  final String ticketNumber;
  final String status;
  final String qrData;
  final String pdfUrl;
  final DateTime issuedAt;
  final Map<String, dynamic> payload;
  final BookingModel? booking;

  const TicketModel({
    required this.id,
    required this.pnr,
    required this.ticketNumber,
    required this.status,
    required this.qrData,
    this.pdfUrl = '',
    required this.issuedAt,
    this.payload = const {},
    this.booking,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) => TicketModel(
        id: _i(json['id']),
        pnr: _s(json['pnr']),
        ticketNumber: _s(json['ticket_number']),
        status: _s(json['status']),
        qrData: _s(json['qr_data']),
        pdfUrl: _s(json['pdf_url']),
        issuedAt: _dt(json['issued_at']) ?? DateTime.now(),
        payload: (json['payload'] as Map?)?.cast<String, dynamic>() ?? const {},
        booking: json['booking'] is Map<String, dynamic>
            ? BookingModel.fromJson(json['booking'] as Map<String, dynamic>)
            : null,
      );
}

class PnrModel {
  final String pnr;
  final String status;
  final TicketModel ticket;

  const PnrModel({required this.pnr, required this.status, required this.ticket});

  factory PnrModel.fromJson(Map<String, dynamic> json) => PnrModel(
        pnr: _s(json['pnr']),
        status: _s(json['status']),
        ticket: TicketModel.fromJson(json),
      );
}

class OfferModel {
  final int id;
  final String code;
  final String title;
  final String description;
  final double discountAmount;
  final int discountPercent;
  final double minFare;
  final String transportTypes;

  const OfferModel({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.discountAmount,
    required this.discountPercent,
    required this.minFare,
    required this.transportTypes,
  });

  String get badgeText {
    if (discountPercent > 0) return '${discountPercent}% OFF';
    return '₹${discountAmount.toStringAsFixed(0)} OFF';
  }

  factory OfferModel.fromJson(Map<String, dynamic> json) => OfferModel(
        id: _i(json['id']),
        code: _s(json['code']),
        title: _s(json['title']),
        description: _s(json['description']),
        discountAmount: _d(json['discount_amount']),
        discountPercent: _i(json['discount_percent']),
        minFare: _d(json['min_fare']),
        transportTypes: _s(json['transport_types']),
      );
}

class NotificationModel {
  final int id;
  final String type;
  final String title;
  final String message;
  final bool read;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.read,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
        id: _i(json['id']),
        type: _s(json['type']),
        title: _s(json['title']),
        message: _s(json['message']),
        read: _b(json['read']),
        createdAt: _dt(json['created_at']) ?? DateTime.now(),
      );
}