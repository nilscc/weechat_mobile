import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

void main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  void _incrementCounter() async {
    final s = await SecureSocket.connect('nils.cc', 9009,
        onBadCertificate: (cert) => true);

    s.write('(handshake) handshake password_hash_algo=sha512\n');

    s.listen((event) {
      try {
        print(event);
        final view = ByteData.sublistView(event);
        print(view.getUint32(0));
        print(view.getUint8(4));
        final comp = zlib.decode(event.sublist(5)) as Uint8List;
        print(comp);
        final compview = ByteData.sublistView(comp);
        final idlen = compview.getUint32(0);
        print(idlen);
        var offset = 4;
        print(String.fromCharCodes(comp.sublist(offset, offset+idlen)));
        offset += idlen;
        print(String.fromCharCodes(comp.sublist(offset, offset+3)));
        offset += 3;
        print(String.fromCharCodes(comp.sublist(offset, offset+3)));
        print(String.fromCharCodes(comp.sublist(offset+3, offset+6)));
        offset += 6;
        print(compview.getUint32(offset));
      }
      catch (e) {
        print(e);
      }
      finally {
        s.close();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ),
    );
  }
}
