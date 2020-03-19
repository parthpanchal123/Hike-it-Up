import 'package:beaconapp/Services/FirestoreService.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'Screens/HomeScreen.dart';
import 'Services/LocationService.dart';

void main() => runApp(MultiProvider(
      providers: [
        Provider<FirestoreService>(
          create: (_) => FirestoreService(),
        ),
        Provider<Location>(
          create: (_) => Location(),
        )
      ],
      child: MaterialApp(
        theme: ThemeData(accentColor: Colors.purple[900]),
        debugShowCheckedModeBanner: false,
        title: 'Lets Beacon',
        home: HomeScreen(),
      ),
    ));
