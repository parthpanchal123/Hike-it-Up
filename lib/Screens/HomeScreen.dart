import 'dart:io';

import 'package:beaconapp/Screens/HikeMainScreen.dart';
import 'package:beaconapp/Services/FirestoreService.dart';
import 'package:beaconapp/common_widgets/Button.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_duration_picker/flutter_duration_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool createHikeRoom = false;
  int _valInMinutes = 0;
  String _hikerName = "", _enteredPassKey;

  void setUpLinks() async {
    final PendingDynamicLinkData data =
        await FirebaseDynamicLinks.instance.getInitialLink();
    final Uri deepLink = data?.link;
    print(deepLink);
    if (deepLink != null) {
      print('Deep Link: $deepLink');
      String receivedPasskey = deepLink
          .toString()
          .substring(
              deepLink.toString().indexOf('?') + 1, deepLink.toString().length)
          .toString();
      print("The received pass key is $receivedPasskey");
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => HikeMainScreen(
                    receivedPasskey,
                    isReferal: true,
                  )));
    }
    FirebaseDynamicLinks.instance.onLink(
        onSuccess: (PendingDynamicLinkData dynamicLink) async {
      final Uri deepLink = dynamicLink?.link;
      if (deepLink != null) {
        print('Deep Link: $deepLink');
        String receivedPasskey = deepLink
            .toString()
            .substring(deepLink.toString().indexOf('?') + 1,
                deepLink.toString().length)
            .toString();
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HikeMainScreen(
                receivedPasskey,
                isReferal: true,
              ),
            ));
      }
    }, onError: (OnLinkErrorException e) async {
      print('onLinkError');
      print(e.message);
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _checkNetConnecton();
    setUpLinks();
  }

  checkPasskey(String enteredPasskey) async {
    try {
      final _store = Provider.of<FirestoreService>(context, listen: false);
      bool hikeExist = await _store.checkIfHikeExists(enteredPasskey);
      if (hikeExist) {
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HikeMainScreen(
                enteredPasskey,
                isReferal: true,
              ),
            ));
      } else {
        Fluttertoast.showToast(msg: 'Incorrect Passkey');
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final _store = Provider.of<FirestoreService>(context, listen: false);
    ProgressDialog pr;
    pr = new ProgressDialog(context, type: ProgressDialogType.Normal);

    pr.style(
      message: 'Creating a hike ...',
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
        body: Stack(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.all(0.0),
          child: Container(
            height: MediaQuery.of(context).size.height,
            decoration: BoxDecoration(
                image: DecorationImage(
              alignment: Alignment.topRight,
              image: AssetImage('assets/images/hiker.png'),
              fit: BoxFit.fitHeight,
            )),
          ),
        ),
        Positioned(
          //  height: 500.0,
          bottom: 0,
          child: Container(
            height: 210.0,
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(50.0),
                    topRight: Radius.circular(50.0))),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  SizedBox(
                    height: 5.0,
                  ),
                  Button(
                    text: 'Create a Hike',
                    borderColor: Colors.black,
                    buttonColor: Colors.purple[900],
                    onTap: () {
                      showDialog(
                          context: context,
                          builder: (context) => Dialog(
                                elevation: 2.0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20.0)),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: SingleChildScrollView(
                                    child: Container(
                                      width: 500,
                                      height: 475,
                                      decoration: BoxDecoration(),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text('Hiker Name',
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 23.0,
                                                  letterSpacing: 0.5)),
                                          Container(
                                            margin: EdgeInsets.only(top: 10.0),
                                            height: 60.0,
                                            child: TextFormField(
                                              cursorColor: Colors.purple[900],
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 20.0),
                                              decoration: InputDecoration(
                                                  border: InputBorder.none,
                                                  contentPadding:
                                                      EdgeInsets.only(
                                                          top: 15.0,
                                                          bottom: 15.0,
                                                          left: 15.0),
                                                  prefixIcon: Icon(
                                                    Icons.person,
                                                    color: Colors.black,
                                                    size: 28.0,
                                                  )),
                                              onChanged: (val) {
                                                _hikerName = val;
                                              },
                                            ),
                                            decoration: BoxDecoration(
                                                color: Colors.grey[400],
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(25.0))),
                                          ),
                                          SizedBox(
                                            height: 20.0,
                                          ),
                                          Text('Time Duration',
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 23.0,
                                                  letterSpacing: 0.5)),
                                          SizedBox(
                                            height: 20.0,
                                          ),
                                          Center(
                                            child: Container(
                                              height: 200.0,
                                              child: DurationPicker(
                                                onChange: (Duration value) {
                                                  setState(() {
                                                    _valInMinutes =
                                                        value.inMinutes;
                                                  });
                                                },
                                                snapToMins: 1.0,
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            height: 10.0,
                                          ),
                                          Center(
                                            child: Button(
                                              text: 'Create Hike',
                                              buttonHeight: 17.0,
                                              onTap: () async {
                                                if (_hikerName == "") {
                                                  Fluttertoast.showToast(
                                                      msg: 'Enter your name !');
                                                } else {
                                                  pr.show();
                                                  // print(DateTime.now().toLocal());
                                                  final exp_time = DateTime
                                                          .now()
                                                      .toLocal()
                                                      .add(Duration(
                                                          minutes:
                                                              _valInMinutes));
                                                  print(exp_time);
                                                  final passkey = await _store
                                                      .addHike(
                                                          hikerName: _hikerName,
                                                          expiringAt: exp_time
                                                              .toLocal()
                                                              .toString())
                                                      .whenComplete(() {
                                                    print("Done adding");
                                                    pr.dismiss();
                                                  });

                                                  Fluttertoast.showToast(
                                                      msg: 'Hike setup done !');

                                                  Navigator.pop(context);
                                                  Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (context) =>
                                                              HikeMainScreen(
                                                                passkey,
                                                                isReferal:
                                                                    false,
                                                                hikeCreator:
                                                                    _hikerName,
                                                              )));
                                                }
                                              },
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ));
                    },
                  ),
                  SizedBox(
                    height: 10.0,
                  ),
                  Button(
                    onTap: () {
                      showDialog(
                          context: context,
                          builder: (context) => Dialog(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(
                                        Radius.circular(20.0))),
                                child: Container(
                                  height: 250,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 32, vertical: 16),
                                    child: Column(
                                      children: <Widget>[
                                        Container(
                                          child: Padding(
                                            padding: const EdgeInsets.all(4.0),
                                            child: TextFormField(
                                              cursorColor: Colors.purple[900],
                                              onChanged: (key) {
                                                _enteredPassKey = key;
                                              },
                                              decoration: InputDecoration(
                                                enabledBorder:
                                                    UnderlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Colors.black),
                                                ),
                                                focusedBorder:
                                                    UnderlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Colors.deepPurple),
                                                ),
                                                labelText: 'Passkey',
                                                labelStyle: TextStyle(
                                                    color: Colors.purple[900]),
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          height: 30,
                                        ),
                                        Flexible(
                                          child: Button(
                                              buttonWidth: 48,
                                              buttonHeight: 30,
                                              text: 'Validate',
                                              textColor: Colors.white,
                                              buttonColor: Colors.purple[900],
                                              onTap: () {
                                                Navigator.pop(context);
                                                checkPasskey(_enteredPassKey);
                                              }),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ));
                    },
                    text: 'Join a Hike',
                    borderColor: Colors.black,
                    buttonColor: Colors.purple[900],
                  )
                ],
              ),
            ),
          ),
        )
      ],
    ));
  }

  void _checkNetConnecton() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        print('connected');
      }
    } on SocketException catch (_) {
      print("ayayayay");
      showDialog(
          barrierDismissible: false,
          context: context,
          builder: (context) => Dialog(
                elevation: 2.0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0)),
                child: Container(
                  decoration: BoxDecoration(),
                  width: 500.0,
                  height: 200.0,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      Text(
                        'You need an active internet connection !',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20.0,
                        ),
                      ),
                      Button(
                        text: 'Done',
                        onTap: () {
                          Navigator.pop(context);
                        },
                        buttonHeight: 20.0,
                      ),
                    ],
                  ),
                ),
              ));
    }
  }
}
