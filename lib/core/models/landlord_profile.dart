import 'enums.dart';

class LandlordProfile {
  final String landlordId;
  final String userId;
  final String contactNo;
  final VerificationStatus verificationStatus;

  const LandlordProfile({
    required this.landlordId,
    required this.userId,
    required this.contactNo,
    required this.verificationStatus,
  });

  factory LandlordProfile.fromMap(Map<String, dynamic> map) => LandlordProfile(
        landlordId: map['landlord_id'] as String,
        userId: map['user_id'] as String,
        contactNo: map['contact_no'] as String,
        verificationStatus:
            VerificationStatus.fromValue(map['verification_status'] as String),
      );

  Map<String, dynamic> toMap() => {
        'landlord_id': landlordId,
        'user_id': userId,
        'contact_no': contactNo,
        'verification_status': verificationStatus.value,
      };

  LandlordProfile copyWith({
    String? landlordId,
    String? userId,
    String? contactNo,
    VerificationStatus? verificationStatus,
  }) =>
      LandlordProfile(
        landlordId: landlordId ?? this.landlordId,
        userId: userId ?? this.userId,
        contactNo: contactNo ?? this.contactNo,
        verificationStatus: verificationStatus ?? this.verificationStatus,
      );
}
