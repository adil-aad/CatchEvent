import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/constants.dart';

/// A user document from the `users` collection.
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role;
  final DateTime? createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.createdAt,
  });

  bool get isStudent => role == AppConstants.roleStudent;
  bool get isOrganizer => role == AppConstants.roleOrganizer;

  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    return UserModel(
      uid: uid,
      name: (map['name'] ?? '') as String,
      email: (map['email'] ?? '') as String,
      role: (map['role'] ?? AppConstants.roleStudent) as String,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  factory UserModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return UserModel.fromMap(doc.id, doc.data() ?? <String, dynamic>{});
  }

  /// Shape written to Firestore. `createdAt` is set by the service using a
  /// server timestamp, so it is not included here.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'email': email,
      'role': role,
    };
  }
}
