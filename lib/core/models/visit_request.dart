import 'enums.dart';

/// "Ask to visit a property in person." Kept separate from [RoomRequest]
/// (which places a temporary hold on one specific room) by design.
class VisitRequest {
  final String visitId;
  final String studentId;
  final String propertyId;
  final String landlordId;
  final VisitRequestStatus status;
  final DateTime requestedDatetime;
  final DateTime? respondedDatetime;
  final DateTime createdAt;

  const VisitRequest({
    required this.visitId,
    required this.studentId,
    required this.propertyId,
    required this.landlordId,
    required this.status,
    required this.requestedDatetime,
    this.respondedDatetime,
    required this.createdAt,
  });

  factory VisitRequest.fromMap(Map<String, dynamic> map) => VisitRequest(
        visitId: map['visit_id'] as String,
        studentId: map['student_id'] as String,
        propertyId: map['property_id'] as String,
        landlordId: map['landlord_id'] as String,
        status: VisitRequestStatus.fromValue(map['status'] as String),
        requestedDatetime: DateTime.parse(map['requested_datetime'] as String),
        respondedDatetime: map['responded_datetime'] == null
            ? null
            : DateTime.parse(map['responded_datetime'] as String),
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'visit_id': visitId,
        'student_id': studentId,
        'property_id': propertyId,
        'landlord_id': landlordId,
        'status': status.value,
        'requested_datetime': requestedDatetime.toIso8601String(),
        'responded_datetime': respondedDatetime?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  VisitRequest copyWith({
    String? visitId,
    String? studentId,
    String? propertyId,
    String? landlordId,
    VisitRequestStatus? status,
    DateTime? requestedDatetime,
    DateTime? respondedDatetime,
    DateTime? createdAt,
  }) =>
      VisitRequest(
        visitId: visitId ?? this.visitId,
        studentId: studentId ?? this.studentId,
        propertyId: propertyId ?? this.propertyId,
        landlordId: landlordId ?? this.landlordId,
        status: status ?? this.status,
        requestedDatetime: requestedDatetime ?? this.requestedDatetime,
        respondedDatetime: respondedDatetime ?? this.respondedDatetime,
        createdAt: createdAt ?? this.createdAt,
      );
}
