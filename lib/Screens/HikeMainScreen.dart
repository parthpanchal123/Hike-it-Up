import 'package:beaconapp/Services/FirestoreService.dart';
import 'package:beaconapp/Services/LocationService.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
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
  bool _isReferred = false,beacon_exp = false;
  String _hikerName;
  int noOfHikers;
  List<String> _hikers,hikers = [];

  beaconExpire(BuildContext context) {
    Firestore.instance.collection('hikes').document(widget.passkey).delete();
    beacon_exp = true ;
    print("Beacon expired");
  }

  countDownTime() async {

    final _store = Provider.of<FirestoreService>(context, listen: false);
    final_exp = await _store.getExpTime(widget.passkey) ;

    final minutes =
        DateTime.parse(final_exp).difference(DateTime.now()).inMinutes;
    print(minutes);
    Future.delayed(Duration(minutes: minutes), () {
      beaconExpire(context);
      print("Done with shit");
    });
  }

//  getHikersList(BuildContext context) async {
//    //countDownTime();
//     final _store = Provider.of<FirestoreService>(context, listen: false);
//    _isReferred = widget.isReferal;
//    _hikerName = widget.hikeCreator;
//    _store.
//
//
//    String curr_dur = expiringAt;
//  }

  getHikersList(BuildContext context) async {
    final _store = Provider.of<FirestoreService>(context, listen: false);
    final_exp = await _store.getExpTime(widget.passkey) ;
     await _store.getHikers(widget.passkey).then((data){
       setState(() {
         hikers = List<String>.from(data) ;
         noOfHikers = hikers.length ;

       });
     });

      //print(hikers);
  }

  getLocation(BuildContext context)async {
    final _loc = Provider.of<Location>(context, listen: false);
    final _store = Provider.of<FirestoreService>(context, listen: false);

    await _loc.getCurrentLocation();
    print(_loc.lat);
   _store.updateLocation(widget.passkey,_loc.lat,_loc.long);


  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getHikersList(context);
    getLocation(context);
    countDownTime();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Container(
            width: MediaQuery.of(context).size.width,
            height: 150.0,
            decoration: BoxDecoration(
                color: Colors.purple[900],
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30.0),bottomRight: Radius.circular(30.0))
            ),
            child: Align(
                alignment: Alignment.bottomLeft,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    Container(
                        margin: EdgeInsets.only(bottom: 10.0),
                        child: Text("Your Hike" , style: TextStyle(color: Colors.white , fontSize: 30.0 , fontWeight: FontWeight.bold),)),
                    Container(
                      margin: EdgeInsets.only(left: 30.0,bottom: 10.0),
                      child: Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 40.0,
                      ),
                    )
                  ],
                ) ),
          ),

        ],
      ),
    );
  }
}
