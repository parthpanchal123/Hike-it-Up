import 'dart:async';

import 'package:beaconapp/Services/FirestoreService.dart';
import 'package:beaconapp/Services/LocationService.dart';
import 'package:beaconapp/common_widgets/Button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

double _lat = 0, _long = 0;

class HikeMainScreen extends StatefulWidget {
  bool isReferal;
  String hikeCreator, passkey;
  HikeMainScreen(this.passkey, {this.isReferal, this.hikeCreator});
  @override
  _HikeMainScreenState createState() => _HikeMainScreenState();
}

class _HikeMainScreenState extends State<HikeMainScreen> {
  String expiringAt, final_exp, _hikerName, _linkMsg;
  bool isGenLink = false, beacon_exp = false;
  int noOfHikers;
  List<dynamic> hikers = [];
  final Set<Marker> _markers = Set();
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
    bool hikeExists = await _store.checkIfHikeExists(widget.passkey);
    String beaconHolder = await _store.getbeaconHolder(widget.passkey);

    Future<String> _beaconRelayCallback(String new_head) async {
      beaconHolder = await _store.relayBeacon(widget.passkey, new_head);
      Fluttertoast.showToast(msg: "Beaker handed over to $new_head");
      return new_head;
    }

    showModalBottomSheet(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15.0),
                topRight: Radius.circular(15.0))),
        context: context,
        builder: (context) {
          if (hikeExists) {
            return Column(
              children: <Widget>[
                Center(
                    child: Container(
                        margin: EdgeInsets.only(top: 10.0, bottom: 10.0),
                        child: Text(
                          'Your fellow hikers',
                          style: TextStyle(fontSize: 25.0),
                        ))),
                Container(
                  height: 200.0,
                  child: StreamBuilder(
                    stream: Firestore.instance
                        .collection('hikes')
                        .document(widget.passkey)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        hikers = snapshot.data['hikers'];

                        if (hikers.length != 0) {
                          return ListView.separated(
                              separatorBuilder: (_, index) => Divider(
                                    color: Colors.purple[900],
                                  ),
                              itemCount: hikers.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  title: Text(hikers[index]),
                                  trailing: hikers[index] == beaconHolder
                                      ? Icon(
                                          Icons.adjust,
                                          color: Colors.purple[900],
                                        )
                                      : Container(
                                          width: 2.0,
                                          height: 2.0,
                                        ),
                                  onTap: () async {
                                    print("Hiker name : " +
                                        _hikerName.toString());
                                    print("Beacon holder : " + beaconHolder);
                                    if (widget.isReferal == false) {
                                      _hikerName = widget.hikeCreator;
                                    }
                                    if (beaconHolder == _hikerName) {
                                      print("zzzzzzzzHiker name : " +
                                          _hikerName.toString());
                                      print("zzzzzzzzzzzBeacon holder : " +
                                          beaconHolder);
                                      final new_head =
                                          await _beaconRelayCallback(
                                              hikers[index]);
                                      setState(() {
                                        beaconHolder = new_head;
                                      });
                                      Fluttertoast.showToast(msg: 'Updated');
                                      // Navigator.pop(context);
                                    } else {
                                      Fluttertoast.showToast(
                                          msg:
                                              "First you should own the beacon");
                                    }
                                  },
                                  onLongPress: () {
                                    if (hikers[index] == widget.hikeCreator) {
                                      Fluttertoast.showToast(
                                          msg:
                                              "That is you , the hike Creator");
                                    }
                                    if (hikers[index] == _hikerName) {
                                      print("Yes youuuu");
                                      Fluttertoast.showToast(
                                          msg: "That is you");
                                    }
                                  },
                                );
                              });
                        } else {
                          return Center(
                            child: Text('The hike has ended'),
                          );
                        }
                        ;
                      } else {
                        return Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                    },
                  ),
                ),
              ],
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

  getHikersList(BuildContext context) async {
    final _store = Provider.of<FirestoreService>(context, listen: false);
    final_exp = await _store.getExpTime(widget.passkey);
    await _store.getHikers(widget.passkey).then((data) {
      setState(() {
        hikers = List<String>.from(data);
        noOfHikers = hikers.length;
      });
    });
  }

  Future<void> _goToHikeLocation(double lat, double long) async {
    GoogleMapController controller = await _controller.future;
    controller
        .animateCamera(CameraUpdate.newLatLngZoom(LatLng(lat, long), 12.0));
    setState(() {
      _markers.add(
        Marker(
            markerId: MarkerId('Hikes Location'),
            position: LatLng(lat, long),
            infoWindow: InfoWindow(
                title: 'Yo Hikers',
                snippet: 'This is our hike location . Tap to copy'),
            onTap: () {}),
      );
    });

    Fluttertoast.showToast(
        msg: "Sharing Location Latitude $lat , Longitude $long",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIos: 4);
  }

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
    _goToHikeLocation(_loc.lat, _loc.long);
  }

  void prepare() {
    print("Get hikers list");
    //getHikersList(context);
    print("get location");
    getLocation(context);
    countDownTime();
  }

  void init() => initState();

  @override
  void initState() {
    super.initState();
    prepare();
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
                      child: GestureDetector(
                        onTap: () {
                          createUrl();
                        },
                        child: Icon(
                          Icons.share,
                          color: Colors.white,
                          size: 35.0,
                        ),
                      ),
                    )
                  ],
                )),
          ),
          Stack(
            children: <Widget>[
              Container(
                height: MediaQuery.of(context).size.height - 150,
                child: GoogleMap(
                  mapType: MapType.normal,
                  initialCameraPosition: _initialPos,
                  onMapCreated: (GoogleMapController controller) {
                    _controller.complete(controller);
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  markers: _markers,
                ),
              ),
              widget.isReferal == true
                  ? Container(
                      child: Align(
                        alignment: Alignment.center,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Button(
                            buttonHeight: 25,
                            buttonColor: Colors.purple[900],
                            buttonWidth: 64,
                            text: 'Add Me',
                            onTap: () {
                              showDialog(
                                  context: (context),
                                  builder: (context) => Dialog(
                                        child: Container(
                                          height: 200,
                                          child: Scaffold(
                                            body: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Column(
                                                children: <Widget>[
                                                  Flexible(
                                                    child: TextFormField(
                                                      onChanged: (key) {
                                                        setState(() {
                                                          _hikerName = key;
                                                        });
                                                      },
                                                      decoration:
                                                          InputDecoration(
                                                        hintText:
                                                            'Username Here',
                                                        hintStyle: TextStyle(
                                                            fontSize: 20,
                                                            color:
                                                                Colors.black),
                                                        labelText: 'Username',
                                                        labelStyle: TextStyle(
                                                            fontSize: 14,
                                                            color: Colors
                                                                .purple[900]),
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    height: 10,
                                                  ),
                                                  Button(
                                                    text: 'Done',
                                                    buttonWidth: 40,
                                                    onTap: () async {
                                                      final _store = Provider
                                                          .of<FirestoreService>(
                                                              context,
                                                              listen: false);
                                                      bool res = await _store
                                                          .addUserToHike(
                                                              _hikerName,
                                                              widget.passkey);

                                                      Navigator.pop(context);

                                                      if (res == true) {
                                                        print("User added");
                                                        Fluttertoast.showToast(
                                                            msg:
                                                                "Added you to the nike");
                                                      } else {
                                                        Fluttertoast.showToast(
                                                            msg:
                                                                "Already a user exists with that name");
                                                      }

                                                      setState(() {
                                                        widget.isReferal =
                                                            false;
                                                      });
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ));
                            },
                          ),
                        ),
                      ),
                    )
                  : Container()
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        label: Text('Others'),
        icon: Icon(Icons.people_outline),
        onPressed: _showBottomSheetCallback,
      ),
    );
  }

  // void _askNameAndAdd() {
  //   showDialog(
  //       context: context,
  //       builder: (context) => Dialog(
  //             shape: RoundedRectangleBorder(
  //                 borderRadius: BorderRadius.all(Radius.circular(20.0))),
  //             child: Container(
  //               height: 250,
  //               child: Padding(
  //                 padding:
  //                     const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
  //                 child: Column(
  //                   children: <Widget>[
  //                     Container(
  //                       child: Padding(
  //                         padding: const EdgeInsets.all(4.0),
  //                         child: TextFormField(
  //                           cursorColor: Colors.purple[900],
  //                           onChanged: (key) {
  //                             _hikerName = key;
  //                           },
  //                           decoration: InputDecoration(
  //                             enabledBorder: UnderlineInputBorder(
  //                               borderSide: BorderSide(color: Colors.black),
  //                             ),
  //                             focusedBorder: UnderlineInputBorder(
  //                               borderSide:
  //                                   BorderSide(color: Colors.deepPurple),
  //                             ),
  //                             labelText: 'Your Name',
  //                             labelStyle: TextStyle(color: Colors.purple[900]),
  //                           ),
  //                         ),
  //                       ),
  //                     ),
  //                     SizedBox(
  //                       height: 30,
  //                     ),
  //                     Flexible(
  //                       child: Button(
  //                           buttonWidth: 48,
  //                           buttonHeight: 30,
  //                           text: 'Join in',
  //                           textColor: Colors.white,
  //                           buttonColor: Colors.purple[900],
  //                           onTap: () async {
  //                             final _store = Provider.of<FirestoreService>(
  //                                 context,
  //                                 listen: false);
  //                             bool res = await _store.addUserToHike(
  //                                 _hikerName, widget.passkey);
  //                             SchedulerBinding.instance
  //                                 .addPostFrameCallback((_) {
  //                               setState(() {
  //                                 widget.isReferal = false;
  //                               });
  //                               Navigator.pop(context);
  //                             });

  //                             if (res) {
  //                               Fluttertoast.showToast(
  //                                   msg: "Added you to the nike");
  //                             } else {
  //                               Fluttertoast.showToast(
  //                                   msg:
  //                                       "Already a user exists with that name");
  //                             }
  //                             Navigator.pop(context);
  //                           }),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ),
  //           ));
  // }

  void createUrl() async {
    if (!isGenLink) {
      await _generateDynamicLink(true);
      Clipboard.setData(ClipboardData(text: _linkMsg));
      Fluttertoast.showToast(msg: 'Url is copied');
    }
  }

  Future<void> _generateDynamicLink(bool short) async {
    setState(() {
      isGenLink = true;
    });
    final DynamicLinkParameters parameters = DynamicLinkParameters(
      uriPrefix: 'https://getuserbeacon.page.link',
      link: Uri.parse(
          'https://dynamic.link.example/hikeScreen?${widget.passkey}'),
      androidParameters: AndroidParameters(
        packageName: 'com.parthpanchal.beaconapp',
        minimumVersion: 0,
      ),
      dynamicLinkParametersOptions: DynamicLinkParametersOptions(
        shortDynamicLinkPathLength: ShortDynamicLinkPathLength.short,
      ),
      iosParameters: IosParameters(
        bundleId: 'com.google.FirebaseCppDynamicLinksTestApp.dev',
        minimumVersion: '0',
      ),
    );

    Uri url;
    if (short) {
      final ShortDynamicLink shortLink = await parameters.buildShortLink();
      url = shortLink.shortUrl;
      print("The url is " + url.toString());
    } else {
      url = await parameters.buildUrl();
      print("The created url is " + url.toString());
    }
    setState(() {
      _linkMsg = url.toString();
      isGenLink = false;
    });
  }
}
