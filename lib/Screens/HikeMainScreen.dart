import 'dart:async';

import 'package:beaconapp/Services/FirestoreService.dart';
import 'package:beaconapp/Services/LocationService.dart';
import 'package:beaconapp/common_widgets/Button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  bool _isReferred = false, beacon_exp = false;
  String _hikerName;
  int noOfHikers;
  List<String> _hikers, hikers = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Completer<GoogleMapController> _controller = Completer();
  CameraPosition _initialPos =
      CameraPosition(target: LatLng(19.07283, 72.88261), zoom: 12.0);

  beaconExpire(BuildContext context) {
    Firestore.instance.collection('hikes').document(widget.passkey).delete();
    beacon_exp = true;
    print("Beacon expired");
  }

  void _showBottomSheetCallback() async {
    final _store = Provider.of<FirestoreService>(context, listen: false);
    bool userExists = await _store.checkIfHikeExists(widget.passkey);

    showModalBottomSheet(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15.0),
                topRight: Radius.circular(15.0))),
        context: context,
        builder: (context) {
          if (userExists) {
            return Container(
              decoration: BoxDecoration(),
              child: FutureBuilder(
                future: _store.getHikers(widget.passkey),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return ListView.separated(
                        separatorBuilder: (context, index) => Divider(
                              color: Colors.purple[900],
                              thickness: 1.0,
                            ),
                        padding: EdgeInsets.all(8.0),
                        itemCount: snapshot.data.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            onTap: () {},
                            title: Text(snapshot.data[index]),
                          );
                        });
                  } else {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                },
              ),
            );
          } else {
            return Center(child: Text("The hike already ended !"));
          }
        });
  }

  countDownTime() async {
    final _store = Provider.of<FirestoreService>(context, listen: false);
    final_exp = await _store.getExpTime(widget.passkey);

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
    final_exp = await _store.getExpTime(widget.passkey);
    await _store.getHikers(widget.passkey).then((data) {
      setState(() {
        hikers = List<String>.from(data);
        noOfHikers = hikers.length;
      });
    });

    //print(hikers);
  }
  // Future<bool> _onWillPop() async {
  //   return (await showDialog(
  //     context: context,
  //     builder: (context) => showExitDialog(context),
  //   )) ?? false;
  // }

  getLocation(BuildContext context) async {
    final _loc = Provider.of<Location>(context, listen: false);
    final _store = Provider.of<FirestoreService>(context, listen: false);

    await _loc.getCurrentLocation();
    print(_loc.lat);
    _store.updateLocation(widget.passkey, _loc.lat, _loc.long);
    setState(() {
      _initialPos =
          CameraPosition(target: LatLng(_loc.lat, _loc.lat), zoom: 12.0);
    });
  }

  // _showBottomSheet(BuildContext context) {
  //   showBottomSheet(
  //       context: context,
  //       builder: (builder) {
  //         return Container(
  //           height: 200.0,
  //           color: Colors.black,
  //         );
  //       });
  // }

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
      key: _scaffoldKey,
      body: Column(
        children: <Widget>[
          Container(
            width: MediaQuery.of(context).size.width,
            height: 150.0,
            decoration: BoxDecoration(
                color: Colors.purple[900],
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30.0),
                    bottomRight: Radius.circular(30.0))),
            child: Align(
                alignment: Alignment.bottomLeft,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    Container(
                        margin: EdgeInsets.only(bottom: 10.0),
                        child: Text(
                          "Your Hike",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 30.0,
                              fontWeight: FontWeight.bold),
                        )),
                    Container(
                      margin: EdgeInsets.only(left: 30.0, bottom: 10.0),
                      child: Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 40.0,
                      ),
                    )
                  ],
                )),
          ),
          Container(
            height: MediaQuery.of(context).size.height - 150,
            child: GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: _initialPos,
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        child: Text("Hello"),
      ),
      floatingActionButton: FloatingActionButton.extended(
        label: Text('Others'),
        icon: Icon(Icons.people_outline),
        onPressed: _showBottomSheetCallback,
      ),
    );
  }
}
