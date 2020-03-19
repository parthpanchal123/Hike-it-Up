import 'package:beaconapp/Services/FirestoreService.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

double _lat = 0, _long = 0;

class HikeMainScreen extends StatefulWidget {
  bool isReferal;
  String hikeCreator, passkey;
  @override
  _HikeMainScreenState createState() => _HikeMainScreenState();
  HikeMainScreen(this.passkey, {this.isReferal, this.hikeCreator});
}

class _HikeMainScreenState extends State<HikeMainScreen> {
  String expiringAt, final_exp;
  bool _isReferred = false;
  String _hikerName;
  int noOfHikers;

  beaconExpire(BuildContext context) {
    Firestore.instance.collection('hikes').document(widget.passkey).delete();
    print("Beacon expired");
  }

  countDownTime() {
    final minutes =
        DateTime.parse(final_exp).difference(DateTime.now()).inMinutes;
    Future.delayed(Duration(minutes: minutes), () {
      beaconExpire(context);
      print("Done with shit");
    });
  }

  getHikersList(BuildContext context) async {
    countDownTime();
    // final _store = Provider.of<FirestoreService>(context, listen: false);
    List<String> hikers = [];
    _isReferred = widget.isReferal;
    _hikerName = widget.hikeCreator;
    print(widget.passkey);

    Firestore.instance
        .collection('hikes')
        .document('Dsnm2Taok0U9QhDP0Lz0')
        .get()
        .then((snapshot) {
      final_exp = snapshot.data['expiryAt'];
      for (String name in snapshot.data['hikers']) {
        hikers.add(name);
      }
    });

    noOfHikers = hikers.length;
    String curr_dur = expiringAt;
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getHikersList(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}
