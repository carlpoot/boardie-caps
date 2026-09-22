class StudentProfile {
  final String studentId;
  final String userId;
  final String campusId;

  /// Free-form preference blob (e.g. budget range, room type, amenities).
  /// Structure is not yet defined by the ERD, so it is kept as a flexible map.
  final Map<String, dynamic> preferences;

  const StudentProfile({
    required this.studentId,
    required this.userId,
    required this.campusId,
    this.preferences = const {},
  });

  factory StudentProfile.fromMap(Map<String, dynamic> map) => StudentProfile(
        studentId: map['student_id'] as String,
        userId: map['user_id'] as String,
        campusId: map['campus_id'] as String,
        preferences: Map<String, dynamic>.from(
          map['preferences'] as Map? ?? const {},
        ),
      );

  Map<String, dynamic> toMap() => {
        'student_id': studentId,
        'user_id': userId,
        'campus_id': campusId,
        'preferences': preferences,
      };

  StudentProfile copyWith({
    String? studentId,
    String? userId,
    String? campusId,
    Map<String, dynamic>? preferences,
  }) =>
      StudentProfile(
        studentId: studentId ?? this.studentId,
        userId: userId ?? this.userId,
        campusId: campusId ?? this.campusId,
        preferences: preferences ?? this.preferences,
      );
}
