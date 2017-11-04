import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';                        //new
import 'package:flutter/cupertino.dart';                      //new
import 'package:google_sign_in/google_sign_in.dart';                   // new
import 'dart:async';                                               // new
import 'package:firebase_analytics/firebase_analytics.dart';      // new
import 'package:firebase_auth/firebase_auth.dart';                // new
import 'package:firebase_database/firebase_database.dart';         //new
import 'package:firebase_database/ui/firebase_animated_list.dart'; //new
import 'package:firebase_storage/firebase_storage.dart';          // new
import 'package:image_picker/image_picker.dart';     // new

import 'dart:math';                                  // new
import 'dart:io';                                    // new


const String _name = "Niamh";

final ThemeData kIOSTheme = new ThemeData(
  primarySwatch: Colors.orange,
  primaryColor: Colors.grey[100],
  primaryColorBrightness: Brightness.light,
);

final ThemeData kDefaultTheme = new ThemeData(
  primarySwatch: Colors.purple,
  accentColor: Colors.orangeAccent[400],
);

final googleSignIn = new GoogleSignIn();

final analytics = new FirebaseAnalytics();
final auth = FirebaseAuth.instance;
final reference = FirebaseDatabase.instance.reference().child('messages');

void main() {
  runApp(new FriendlychatApp());
}

class FriendlychatApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: "Friendlychat",
      theme: defaultTargetPlatform == TargetPlatform.iOS
        ? kIOSTheme
      : kDefaultTheme,
      home: new ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  @override
  State createState() => new ChatScreenState();
}


class ChatScreenState extends State<ChatScreen> {             // modified
  final TextEditingController _textController = new TextEditingController();
  bool _isComposing = false;

  Widget _buildTextComposer() {
    return new IconTheme(
      data: new IconThemeData(color: Theme.of(context).accentColor),
      child: new Container(
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          child: new Row( children: <Widget>[
            new Container(                                           //new
              margin: new EdgeInsets.symmetric(horizontal: 4.0),     //new
              child: new IconButton(                                 //new
                  icon: new Icon(Icons.photo_camera),                //new
                  onPressed: () async {
                    await _ensureLoggedIn();
                    File imageFile = await ImagePicker.pickImage();
                    int random = new Random().nextInt(100000);                         //new
                    StorageReference ref =                                             //new
                    FirebaseStorage.instance.ref().child("image_$random.jpg");         //new
                    StorageUploadTask uploadTask = ref.put(imageFile);                 //new
                    Uri downloadUrl = (await uploadTask.future).downloadUrl;           //new
                    _sendMessage(imageUrl: downloadUrl.toString());                // new
                  }
              ),                                                     //new
            ),                                                       //new
            new Flexible(
                  child:  new TextField(
                    controller: _textController,
                    onChanged: (String text) {
                      setState(() {
                        _isComposing = text.length > 0;
                      });
                    },
                    onSubmitted: _handleSubmitted,
                    decoration: new InputDecoration.collapsed(
                        hintText: "Send a message"),
                  ),
                ),
            new Container(
                  margin: new EdgeInsets.symmetric(horizontal: 4.0),
                  child: Theme.of(context).platform == TargetPlatform.iOS ?
                    new CupertinoButton(
                      child: new Text("Send"),
                      onPressed: _isComposing
                        ? () => _handleSubmitted(_textController.text) : null,) :
                      new IconButton(
                        icon: new Icon(Icons.send),
                        onPressed: _isComposing ? () => _handleSubmitted(_textController.text) : null,
                    )
            ),
              ]
          )
      )
    );
  }

  Future<Null> _handleSubmitted(String text) async {
    _textController.clear();

    setState(() {
      _isComposing = false;
    });
    await _ensureLoggedIn();
    _sendMessage(text: text);
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Friendlychat"),
        elevation: Theme.of(context).platform == TargetPlatform.iOS ? 0.0 : 4.0,
      ),
      body: new Container(                                      //modified
          child: new Column(                                      //modified
            children: <Widget>[
              new Flexible(
                child: new FirebaseAnimatedList(                            //new
                  query: reference,                                       //new
                  sort: (a, b) => b.key.compareTo(a.key),                 //new
                  padding: new EdgeInsets.all(8.0),                       //new
                  reverse: true,                                          //new
                  itemBuilder: (_, DataSnapshot snapshot, Animation<double> animation) { //new
                    return new ChatMessage(                               //new
                        snapshot: snapshot,                                 //new
                        animation: animation                                //new
                    );                                                    //new
                  },                                                      //new
                ),                                                        //new
              ),
              new Divider(height: 1.0),
              new Container(
                decoration: new BoxDecoration(
                    color: Theme.of(context).cardColor),
                child: _buildTextComposer(),
              ),
            ],
          ),
          decoration: Theme.of(context).platform == TargetPlatform.iOS          //new
              ? new BoxDecoration(                                              //new
              border:                                                       //new
              new Border(top: new BorderSide(color: Colors.grey[200]))) //new
              : null),                                                          //new
    );
  }

  Future<Null> _ensureLoggedIn() async {
    GoogleSignInAccount user = googleSignIn.currentUser;
    if (user == null)
      user = await googleSignIn.signInSilently();
    if (user == null) {
      await googleSignIn.signIn();
      analytics.logLogin();
    }
    if (await auth.currentUser() == null) {
      GoogleSignInAuthentication credentials = await googleSignIn.currentUser.authentication;
      await auth.signInWithGoogle(idToken: credentials.idToken, accessToken: credentials.accessToken);
    }
  }

  void _sendMessage({ String text, String imageUrl }) {
    reference.push().set({                                         //new
      'text': text,
      'photoUrl': imageUrl,                                         //new//new
      'senderName': googleSignIn.currentUser.displayName,          //new
      'senderPhotoUrl': googleSignIn.currentUser.photoUrl,         //new
    });                                                            //new
    analytics.logEvent(name: 'send_message');
  }
}

class ChatMessage extends StatelessWidget {
  ChatMessage({this.snapshot, this.animation});              // modified
  final DataSnapshot snapshot;                               // modified
  final Animation animation;                                 // modified

  @override
  Widget build(BuildContext context) {
    return new SizeTransition(
        sizeFactor: new CurvedAnimation(
            parent: animation, curve: Curves.easeOut),            // modified
      axisAlignment: 0.0,
      child: new Container(
          margin: const EdgeInsets.symmetric(vertical: 10.0),
          child: new Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              new Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  new Text(snapshot.value['senderName'],                      //modified
                      style: Theme.of(context).textTheme.subhead),
                  new Container(
                    margin: const EdgeInsets.only(top: 5.0),
                    child: snapshot.value['photoUrl'] != null ? new Image.network(
                      snapshot.value['photoUrl'],
                      width: 250.0,
                    ) : new Text(snapshot.value['text']),
                  ),
                ],
              ),
            ],
          ),

      )
    );
  }
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or press Run > Flutter Hot Reload in IntelliJ). Notice that the
        // counter didn't reset back to zero; the application is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return new Scaffold(
      appBar: new AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: new Text(widget.title),
      ),
      body: new Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: new Column(
          // Column is also layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug paint" (press "p" in the console where you ran
          // "flutter run", or select "Toggle Debug Paint" from the Flutter tool
          // window in IntelliJ) to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            new Text(
              'You have pushed the button this many times:',
            ),
            new Text(
              '$_counter',
              style: Theme.of(context).textTheme.display1,
            ),
          ],
        ),
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: new Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
