import 'dart:async';
import 'dart:io';

import 'package:beaconapp/Services/FirestoreService.dart';
import 'package:beaconapp/Services/LocationService.dart';
import 'package:beaconapp/common_widgets/Button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_duration_picker/flutter_duration_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:provider/provider.dart';

double _lat = 0, _long = 0;
ProgressDialog pr;

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
  int noOfHikers, _valInMinutes;
  List<dynamic> hikers = [];
  final Set<Marker> _markers = Set();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Completer<GoogleMapController> _controller = Completer();

  CameraPosition _initialPos =
      CameraPosition(target: LatLng(19.07283, 72.88261), zoom: 12.0);

  beaconExpire(BuildContext context) async {
    Fluttertoast.showToast(
        msg: "Beacon Expired , Exiting ",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.TOP);
    Firestore.instance.collection('hikes').document(widget.passkey).delete();
    Navigator.popUntil(
      context,
      ModalRoute.withName(Navigator.defaultRouteName),
    );
    setState(() {
      beacon_exp = true;
    });
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
          if (hikeExists == true) {
            return Column(
              children: <Widget>[
                Center(
                    child: Container(
                        margin: EdgeInsets.only(top: 10.0, bottom: 10.0),
                        child: Column(
                          children: <Widget>[
                            Text(
                              'Your fellow hikers',
                              style: TextStyle(fontSize: 25.0),
                            ),
                            Button(
                              onTap: () {
                                if (widget.isReferal == false) {
                                  _hikerName = widget.hikeCreator;
                                } else {
                                  _hikerName = _hikerName;
                                }

                                print("Hikername " + _hikerName.toString());
                                print("Holder " + beaconHolder.toString());
                                if (_hikerName == beaconHolder) {
                                  showDialog(
                                      context: context,
                                      builder: (context) => Dialog(
                                            shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(20.0))),
                                            child: Container(
                                              height: 380,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 32,
                                                        vertical: 16),
                                                child: Column(
                                                  children: <Widget>[
                                                    Text(
                                                      'Update time duration',
                                                      style: TextStyle(
                                                          color: Colors
                                                              .purple[900],
                                                          fontSize: 20.0),
                                                    ),
                                                    SizedBox(
                                                      height: 25.0,
                                                    ),
                                                    Center(
                                                      child: Container(
                                                        height: 200.0,
                                                        child: DurationPicker(
                                                          onChange:
                                                              (Duration value) {
                                                            setState(() {
                                                              _valInMinutes =
                                                                  value
                                                                      .inMinutes;
                                                            });
                                                          },
                                                          snapToMins: 2.0,
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      height: 30.0,
                                                    ),
                                                    Button(
                                                      onTap: () async {
                                                        if (_hikerName ==
                                                            beaconHolder) {
                                                          final String
                                                              old_time =
                                                              await _store
                                                                  .getExpTime(widget
                                                                      .passkey);
                                                          final exp_time = DateTime
                                                                  .parse(
                                                                      old_time)
                                                              .toLocal()
                                                              .add(Duration(
                                                                  minutes:
                                                                      _valInMinutes));
                                                          await _store
                                                              .updateHikeDuration(
                                                                  widget
                                                                      .passkey,
                                                                  beaconHolder,
                                                                  exp_time
                                                                      .toString())
                                                              .then((res) {
                                                            if (res == true) {
                                                              Fluttertoast
                                                                  .showToast(
                                                                      msg:
                                                                          "Updated");
                                                            } else {
                                                              Fluttertoast
                                                                  .showToast(
                                                                      msg:
                                                                          "Only the beacon holder can update");
                                                            }
                                                            Navigator.pop(
                                                                context);
                                                          });
                                                        } else {
                                                          Fluttertoast.showToast(
                                                              msg:
                                                                  "Only the beacon holder can update");
                                                        }
                                                      },
                                                      text: 'Update',
                                                      borderColor: Colors.black,
                                                      buttonHeight: 20.0,
                                                      buttonColor:
                                                          Colors.purple[900],
                                                    )
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ));
                                } else {
                                  Fluttertoast.showToast(
                                      msg: 'You aren\'t the beacon holder !');
                                }
                              },
                              text: 'Change duration',
                              borderColor: Colors.black,
                              buttonColor: Colors.purple[900],
                              buttonHeight: 10.0,
                              buttonWidth: 5.0,
                            )
                          ],
                        ))),
                hikeExists == true
                    ? Container(
                        height: 200.0,
                        child: StreamBuilder(
                          stream: Firestore.instance
                              .collection('hikes')
                              .document(widget.passkey)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.data != null) {
                              if (snapshot.data['hikers'].length != 0) {
                                hikers = snapshot.data['hikers'];
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
                                          print(
                                              "Hikern" + _hikerName.toString());
                                          print("Beacon h" + beaconHolder);
                                          if (beaconHolder == hikers[index]) {
                                            print("You already own the beaker");
                                          } else {
                                            if (beaconHolder == _hikerName) {
                                              final new_head =
                                                  await _beaconRelayCallback(
                                                      hikers[index]);
                                              setState(() {
                                                beaconHolder = new_head;
                                              });
                                            } else {
                                              Fluttertoast.showToast(
                                                  msg:
                                                      "First you should own the beacon");
                                            }
                                          }
                                        },
                                        onLongPress: () {
                                          if (widget.isReferal == true) {
                                            if (hikers[index] ==
                                                widget.hikeCreator) {
                                              Fluttertoast.showToast(
                                                  msg: "That is you");
                                            }
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
                        ))
                    : Center(
                        child: Text('Beacon expired'),
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
    if (widget.isReferal == false) {
      _hikerName = widget.hikeCreator;
    }
    prepare();
  }

  @override
  Widget build(BuildContext context) {
    pr = new ProgressDialog(context, type: ProgressDialogType.Normal);

    pr.style(
      message: 'Generating invite hike ...',
      borderRadius: 10.0,
      progressWidget: Container(
          padding: EdgeInsets.all(8.0),
          child: CircularProgressIndicator(
            strokeWidth: 3.0,
          )),
      backgroundColor: Colors.white,
      elevation: 90.0,
      //insetAnimCurve: Curves.elasticInOut,
      progress: 0.0,
      maxProgress: 100.0,
      progressTextStyle: TextStyle(
          color: Colors.black, fontSize: 13.0, fontWeight: FontWeight.w400),
      messageTextStyle: TextStyle(
          color: Colors.black, fontSize: 19.0, fontWeight: FontWeight.w600),
    );

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
                      margin: EdgeInsets.only(left: 100.0, bottom: 10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          GestureDetector(
                            onTap: () {
                              pr.show();
                              createUrl();
                            },
                            child: Icon(
                              Icons.share,
                              color: Colors.white,
                              size: 28.0,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(
                                  ClipboardData(text: widget.passkey));
                              Fluttertoast.showToast(msg: 'share passkey now ');
                            },
                            child: Container(
                              margin: EdgeInsets.only(left: 15.0),
                              child: Icon(
                                Icons.vpn_key,
                                color: Colors.white,
                                size: 30.0,
                              ),
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                )),
          ),
          Stack(
            children: <Widget>[
              widget.isReferal == false
                  ? Container(
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
                    )
                  : Container(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            height: 175.0,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: <Widget>[
                                Container(
                                  padding: EdgeInsets.all(15.0),
                                  child: TextFormField(
                                    style: TextStyle(fontSize: 20.0),
                                    onChanged: (val) {
                                      _hikerName = val;
                                    },
                                    decoration: InputDecoration(
                                        enabledBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Colors.purple[900]),
                                        ),
                                        focusedBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Colors.purple[900]),
                                        ),
                                        hintText: 'Name',
                                        hintStyle: TextStyle(
                                            fontSize: 20.0,
                                            color: Colors.black)),
                                  ),
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(30.0))),
                                ),
                                Button(
                                  text: 'Join hike',
                                  buttonHeight: 25,
                                  buttonWidth: 25,
                                  borderColor: Colors.black,
                                  buttonColor: Colors.purple[900],
                                  onTap: () async {
                                    final _store =
                                        Provider.of<FirestoreService>(context,
                                            listen: false);
                                    await _store
                                        .addUserToHike(
                                            _hikerName, widget.passkey)
                                        .then((res) {
                                      if (res == true) {
                                        Fluttertoast.showToast(
                                            msg:
                                                "Already a user exists with that name");

                                        Navigator.pop(context);
                                      } else {
                                        Fluttertoast.showToast(
                                            msg: "Added you to hike ");
                                        setState(() {
                                          widget.isReferal = false;
                                        });
                                      }
                                    });
                                  },
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
            ],
          ),
        ],
      ),
      floatingActionButton: widget.isReferal == false
          ? FloatingActionButton.extended(
              label:
                  beacon_exp == true ? Text(' Beacon Expired') : Text('Hikers'),
              icon: beacon_exp == true
                  ? Icon(Icons.remove)
                  : Icon(Icons.people_outline),
              onPressed: beacon_exp == false ? _showBottomSheetCallback : null)
          : null,
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
      await _generateDynamicLink(true).whenComplete(() {
        pr.dismiss();
      });
      Clipboard.setData(ClipboardData(text: _linkMsg));
      Fluttertoast.showToast(msg: 'You can share the link now !');
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

// showDialog(
//                           context: context,
//                           builder: (context) => Dialog(
//                                 shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.all(
//                                         Radius.circular(20.0))),
//                                 child: Container(
//                                   height: 250,
//                                   child: Padding(
//                                     padding: const EdgeInsets.symmetric(
//                                         horizontal: 32, vertical: 16),
//                                     child: Column(
//                                       children: <Widget>[
//                                         Container(
//                                           child: Padding(
//                                             padding: const EdgeInsets.all(4.0),
//                                             child: TextFormField(
//                                               cursorColor: Colors.purple[900],
//                                               onChanged: (key) {
//                                                 _enteredPassKey = key;
//                                               },
//                                               decoration: InputDecoration(
//                                                 enabledBorder:
//                                                     UnderlineInputBorder(
//                                                   borderSide: BorderSide(
//                                                       color: Colors.black),
//                                                 ),
//                                                 focusedBorder:
//                                                     UnderlineInputBorder(
//                                                   borderSide: BorderSide(
//                                                       color: Colors.deepPurple),
//                                                 ),
//                                                 labelText: 'Passkey',
//                                                 labelStyle: TextStyle(
//                                                     color: Colors.purple[900]),
//                                               ),
//                                             ),
//                                           ),
//                                         ),
//                                         SizedBox(
//                                           height: 30,
//                                         ),
//                                         Flexible(
//                                           child: Button(
//                                               buttonWidth: 48,
//                                               buttonHeight: 30,
//                                               text: 'Validate',
//                                               textColor: Colors.white,
//                                               buttonColor: Colors.purple[900],
//                                               onTap: () {
//                                                 Navigator.pop(context);
//                                                 checkPasskey(_enteredPassKey);
//                                               }),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ),
//                               ));
