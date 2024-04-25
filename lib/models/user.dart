import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  String name;
  String email;
  String uid;
  String guestId;

  User({
    required this.name,
    required this.email,
    required this.uid,
    required this.guestId,
  });

  Map<String, dynamic> toJson() =>
      {"name": name, "email": email, "uid": uid, "guestId": guestId};

  static User fromSnap(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;
    return User(
      email: snapshot['email'],
      uid: snapshot['uid'],
      name: snapshot['name'],
      guestId: snapshot['guestId'],
    );
  }
}
