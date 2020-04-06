import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:groupchat/chat.dart';

void main() async {
  // modify with your true address/port
  // ignore: close_sinks
  Socket socket = await Socket.connect('178.153.25.7', 5353);
  runApp(MyApp(socket));
}

class MyApp extends StatelessWidget {
  Socket socket;
  MyApp(Socket socket){
    this.socket = socket;
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Chat Application',socket: socket,),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title,this.socket}) : super(key: key);
  final String title;
  final Socket socket;

  @override
  _MyHomePageState createState() => _MyHomePageState(socket);
}

class _MyHomePageState extends State<MyHomePage> {
  Socket socket;
  _MyHomePageState(Socket socket){
    this.socket = socket;
  }

  final TextEditingController _textController = new TextEditingController();

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
              Text("Enter your name"),
              TextField(
                textAlign: TextAlign.center,
                controller: _textController,
              )
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
            child: Icon(Icons.exit_to_app),
            onPressed: (){
              socket.writeln(_textController.text);
              Navigator.push(context, MaterialPageRoute(
                  builder: (context) => ChatApp(socket,_textController.text)),
              );
            }
        )
    ); // This trailing comma makes auto-formatting nicer for build methods.
  }
}
