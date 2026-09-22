class SavedProperty {
  final String saveId;
  final String studentId;
  final String propertyId;
  final DateTime savedAt;

  const SavedProperty({
    required this.saveId,
    required this.studentId,
    required this.propertyId,
    required this.savedAt,
  });

  factory SavedProperty.fromMap(Map<String, dynamic> map) => SavedProperty(
        saveId: map['save_id'] as String,
        studentId: map['student_id'] as String,
        propertyId: map['property_id'] as String,
        savedAt: DateTime.parse(map['saved_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'save_id': saveId,
        'student_id': studentId,
        'property_id': propertyId,
        'saved_at': savedAt.toIso8601String(),
      };

  SavedProperty copyWith({
    String? saveId,
    String? studentId,
    String? propertyId,
    DateTime? savedAt,
  }) =>
      SavedProperty(
        saveId: saveId ?? this.saveId,
        studentId: studentId ?? this.studentId,
        propertyId: propertyId ?? this.propertyId,
        savedAt: savedAt ?? this.savedAt,
      );
}
