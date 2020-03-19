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
        'expiryAt': expiringAt,
        'hikers': FieldValue.arrayUnion([hikerName]),
        'lat': 0.0,
        'long': 0.0
      });
      return ref.documentID.toString();
    } catch (e) {
      return e.toString();
    }
  }

  Future<List<dynamic>> getHikers(String passkey) async {
    try {
      DocumentReference ref = _store.collection('hikes').document(passkey);
      final hike_data = await ref.get();
      return hike_data.data['hikers'];
    } catch (e) {
      print(e);
    }
  }

  Future<String> getExpTime(String passkey) async {
    try {
      DocumentReference ref = _store.collection('hikes').document(passkey);
      final hike_data = await ref.get();
      return hike_data.data['expiryAt'];
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> updateLocation(String passkey, dynamic lat, dynamic long) async {
    _store.collection('hikes').document(passkey).updateData({
      'lat': lat,
      'long': long,
    });
  }

  Future<bool> checkIfHikeExists(String passkey) async {
    final snapShot = await _store.collection('hikes').document(passkey).get();
    if (snapShot == null || !snapShot.exists) {
      return false;
    } else {
      return true;
    }
  }
}
