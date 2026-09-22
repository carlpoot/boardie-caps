import 'enums.dart';

/// "Place a temporary hold on one specific room." Kept separate from
/// [VisitRequest] (which asks to visit a property in person) by design.
class RoomRequest {
  final String requestId;
  final String studentId;
  final String roomId;
  final String propertyId;
  final String landlordId;
  final RoomRequestStatus status;
  final DateTime? heldUntil;
  final DateTime? approvedAt;
  final DateTime? confirmedAt;
  final DateTime createdAt;

  const RoomRequest({
    required this.requestId,
    required this.studentId,
    required this.roomId,
    required this.propertyId,
    required this.landlordId,
    required this.status,
    this.heldUntil,
    this.approvedAt,
    this.confirmedAt,
    required this.createdAt,
  });

  factory RoomRequest.fromMap(Map<String, dynamic> map) => RoomRequest(
        requestId: map['request_id'] as String,
        studentId: map['student_id'] as String,
        roomId: map['room_id'] as String,
        propertyId: map['property_id'] as String,
        landlordId: map['landlord_id'] as String,
        status: RoomRequestStatus.fromValue(map['status'] as String),
        heldUntil: map['held_until'] == null
            ? null
            : DateTime.parse(map['held_until'] as String),
        approvedAt: map['approved_at'] == null
            ? null
            : DateTime.parse(map['approved_at'] as String),
        confirmedAt: map['confirmed_at'] == null
            ? null
            : DateTime.parse(map['confirmed_at'] as String),
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'request_id': requestId,
        'student_id': studentId,
        'room_id': roomId,
        'property_id': propertyId,
        'landlord_id': landlordId,
        'status': status.value,
        'held_until': heldUntil?.toIso8601String(),
        'approved_at': approvedAt?.toIso8601String(),
        'confirmed_at': confirmedAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  RoomRequest copyWith({
    String? requestId,
    String? studentId,
    String? roomId,
    String? propertyId,
    String? landlordId,
    RoomRequestStatus? status,
    DateTime? heldUntil,
    DateTime? approvedAt,
    DateTime? confirmedAt,
    DateTime? createdAt,
  }) =>
      RoomRequest(
        requestId: requestId ?? this.requestId,
        studentId: studentId ?? this.studentId,
        roomId: roomId ?? this.roomId,
        propertyId: propertyId ?? this.propertyId,
        landlordId: landlordId ?? this.landlordId,
        status: status ?? this.status,
        heldUntil: heldUntil ?? this.heldUntil,
        approvedAt: approvedAt ?? this.approvedAt,
        confirmedAt: confirmedAt ?? this.confirmedAt,
        createdAt: createdAt ?? this.createdAt,
      );
}
