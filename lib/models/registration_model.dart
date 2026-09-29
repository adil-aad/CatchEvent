import 'package:cloud_firestore/cloud_firestore.dart';

/// A row in the `registrations` collection linking a student to an event.
class RegistrationModel {
  final String id;
  final String eventId;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final DateTime? registeredAt;

  const RegistrationModel({
    required this.id,
    required this.eventId,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    this.registeredAt,
  });

  factory RegistrationModel.fromMap(String id, Map<String, dynamic> map) {
    return RegistrationModel(
      id: id,
      eventId: (map['eventId'] ?? '') as String,
      studentId: (map['studentId'] ?? '') as String,
      studentName: (map['studentName'] ?? '') as String,
      studentEmail: (map['studentEmail'] ?? '') as String,
      registeredAt: (map['registeredAt'] as Timestamp?)?.toDate(),
    );
  }

  factory RegistrationModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return RegistrationModel.fromMap(doc.id, doc.data() ?? <String, dynamic>{});
  }

  /// `registeredAt` is added by the service using a server timestamp.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'eventId': eventId,
      'studentId': studentId,
      'studentName': studentName,
      'studentEmail': studentEmail,
    };
  }
}
