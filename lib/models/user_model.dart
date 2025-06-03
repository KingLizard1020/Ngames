class UserModel {
  final String uid;
  final String? email;
  final String? displayName; // Add displayName

  UserModel({
    required this.uid,
    this.email,
    this.displayName,
  }); // Update constructor

  // Optional: Add a factory constructor from Firestore if needed elsewhere, though MessagingService handles it directly for now
  // factory UserModel.fromFirestore(DocumentSnapshot doc) {
  //   Map<String, dynamic> data = doc.data()! as Map<String, dynamic>;
  //   return UserModel(
  //     uid: doc.id,
  //     email: data['email'] as String?,
  //     displayName: data['displayName'] as String?,
  //   );
  // }
}
