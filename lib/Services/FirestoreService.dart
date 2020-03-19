import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  final _store = Firestore.instance;
  DocumentReference ref;

  Future<String> addHike(
      {@required String hikerName, @required String expiringAt}) async {
    try {
      ref = await _store.collection('hikes').add({
        'hikeCreatorName': hikerName ?? "Parth",
        'noOfHikers': 1,
        'expiryAt': expiringAt
      });
      return ref.documentID.toString();
    } catch (e) {
      return e.toString();
    }
  }
}
