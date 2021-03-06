
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:image_picker/image_picker.dart';

final ThemeData iOSTheme = new ThemeData(
  primarySwatch: Colors.red,
  primaryColor: Colors.grey[400],
  primaryColorBrightness: Brightness.dark,
);

final ThemeData androidTheme = new ThemeData(
  primarySwatch: Colors.blue,
  accentColor: Colors.green,
);

String dataServer;


// ignore: must_be_immutable
class ChatApp extends StatelessWidget {
  Socket socket;
  String name;
  ChatApp(Socket s,String name) {
    this.socket = s;
    this.name = name;
  }
  @override
  Widget build(BuildContext ctx) {
    return new MaterialApp(
      title: "Chat Application",
      theme: defaultTargetPlatform == TargetPlatform.iOS
          ? iOSTheme
          : androidTheme,
      home: new Chat(channel: socket,name: name,),
    );
  }
}

class Chat extends StatefulWidget {
  final Socket channel;
  String title;
  String name;
  Chat({Key key, @required this.title, @required this.channel, this.name})
      : super(key: key);
  @override
  State createState() => new ChatWindow(channel,name);
}

class ChatWindow extends State<Chat> with TickerProviderStateMixin {
  Socket channel;
  String name;
  ChatWindow(Socket c, String name){
    this.name = name;
    this.channel = c;
    channel.listen(datahandler);
  }
  final List<Msg> _messages = <Msg>[];
  final TextEditingController _textController = new TextEditingController();
  bool _isWriting = false;

  void initState() {
    super.initState();
    BackButtonInterceptor.add(myInterceptor);
  }

  @override
  void dispose() {
    BackButtonInterceptor.remove(myInterceptor);
    super.dispose();
  }

  bool myInterceptor(bool stopDefaultButtonEvent) {
    return true;
  }

  @override
  Widget build(BuildContext ctx) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Chat Application"),
        elevation:
        Theme.of(ctx).platform == TargetPlatform.iOS ? 0.0 : 6.0,
      ),
      body: new Column(children: <Widget>[
        new Flexible(
            child: new ListView.builder(
              itemBuilder: (_, int index) => _messages[index],
              itemCount: _messages.length,
              reverse: true,
              padding: new EdgeInsets.all(6.0),
            )),
        new Divider(height: 1.0),
        new Container(
          child: _buildComposer(),
          decoration: new BoxDecoration(color: Theme.of(ctx).cardColor),
        ),
      ]),
    );
  }


  Widget _buildComposer() {
    return new IconTheme(
      data: new IconThemeData(color: Theme.of(context).accentColor),
      child: new Container(
          margin: const EdgeInsets.symmetric(horizontal: 9.0),
          child: new Row(
            children: <Widget>[
              new Flexible(
                child: new TextField(
                  controller: _textController,
                  onChanged: (String txt) {
                    setState(() {
                      _isWriting = txt.length > 0;
                    });
                  },
                  onSubmitted: _submitMsg,
                  decoration:
                  new InputDecoration.collapsed(hintText: "Enter some text to send a message"),
                ),
              ),
              new Container(
                margin: new EdgeInsets.symmetric(horizontal: 3.0),
                child: new IconButton(
                    icon: new Icon(Icons.add_a_photo),
                    onPressed: _submitImg,
                ),
              ),
              new Container(
                  margin: new EdgeInsets.symmetric(horizontal: 3.0),
                  child: Theme.of(context).platform == TargetPlatform.iOS
                      ? new CupertinoButton(
                      child: new Text("Submit"),
                      onPressed: _isWriting ? () => _submitMsg(_textController.text)
                          : null
                  )
                      : new IconButton(
                    icon: new Icon(Icons.message),
                    onPressed: _isWriting
                        ? () => _submitMsg(_textController.text)
                        : null,
                  )
              ),
            ],
          ),
          decoration: Theme.of(context).platform == TargetPlatform.iOS
              ? new BoxDecoration(
              border:
              new Border(top: new BorderSide(color: Colors.brown))) :
          null
      ),
    );
  }

  void datahandler(data){
    var serr = new String.fromCharCodes(data).trim();
    print(serr);
    var splited = serr.split(">");
    if(splited[1].startsWith("/9j/")){
      List<int> bytes = base64Decode(splited[1]);
      var image = MemoryImage(bytes);
      Msg msg = new Msg(
        name: splited[0],
        img: image,
        animationController: new AnimationController(
          vsync: this,
          duration: new Duration(milliseconds: 800),
        ),
      );
      setState(() {
        _messages.insert(0, msg);
      });
      msg.animationController.forward();
    }else {
      List<int> bytes = base64Decode(splited[1]);
      String s = utf8.decode(bytes);
      Msg msg = new Msg(
        name: splited[0],
        txt: s,
        animationController: new AnimationController(
          vsync: this,
          duration: new Duration(milliseconds: 800),
        ),
      );
      setState(() {
        _messages.insert(0, msg);
      });
      msg.animationController.forward();
    }
  }

  void _submitImg() async{
    File _image;
    var image = await ImagePicker.pickImage(
        source: ImageSource.gallery,
    );
    setState(() {
      _image = image;
    });

    List<int> bytes = image.readAsBytesSync();
    String s = base64Encode(bytes);
    widget.channel.writeln(s);
    Msg msg = new Msg(
      name: name,
      image: _image,
      animationController: new AnimationController(
          vsync: this,
          duration: new Duration(milliseconds: 800)
      ),
    );
    setState(() {
      _messages.insert(0, msg);
    });
    msg.animationController.forward();
  }

  void _submitMsg(String txt) {
    List<int> byte = utf8.encode(txt);
    String s = base64Encode(byte);
    widget.channel.writeln(s);
    _textController.clear();
    setState(() {
      _isWriting = false;
    });
    Msg msg = new Msg(
      name: name,
      txt: txt,
      animationController: new AnimationController(
          vsync: this,
          duration: new Duration(milliseconds: 800)
      ),
    );
    setState(() {
      _messages.insert(0, msg);
    });
    msg.animationController.forward();
  }


}

class Msg extends StatelessWidget {
  Msg({this.txt, this.animationController,this.name,this.image,this.img});
  final String name;
  final String txt;
  final File image;
  final MemoryImage img;
  final AnimationController animationController;

  @override
  Widget build(BuildContext ctx) {
    if(image == null && img == null) {
      return new SizeTransition(
        sizeFactor: new CurvedAnimation(
            parent: animationController, curve: Curves.easeOut),
        axisAlignment: 0.0,
        child: new Container(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: new Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              new Container(
                margin: const EdgeInsets.only(right: 18.0),
                child: new CircleAvatar(child: new Text(name[0])),
              ),
              new Expanded(
                child: new Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    new Text(name, style: Theme
                        .of(ctx)
                        .textTheme
                        .subhead),
                    new Container(
                      margin: const EdgeInsets.only(top: 6.0),
                      child: new Text(txt)
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }else if (txt == null && img == null){
      return new SizeTransition(
        sizeFactor: new CurvedAnimation(
            parent: animationController, curve: Curves.easeOut),
        axisAlignment: 0.0,
        child: new Container(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: new Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              new Container(
                margin: const EdgeInsets.only(right: 18.0),
                child: new CircleAvatar(child: new Text(name[0])),
              ),
              new Expanded(
                child: new Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    new Text(name, style: Theme
                        .of(ctx)
                        .textTheme
                        .subhead),
                    new Container(
                        margin: const EdgeInsets.only(top: 6.0),
                        child: new Image.file(image)
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }else{
      return new SizeTransition(
        sizeFactor: new CurvedAnimation(
            parent: animationController, curve: Curves.easeOut),
        axisAlignment: 0.0,
        child: new Container(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: new Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              new Container(
                margin: const EdgeInsets.only(right: 18.0),
                child: new CircleAvatar(child: new Text(name[0])),
              ),
              new Expanded(
                child: new Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    new Text(name, style: Theme
                        .of(ctx)
                        .textTheme
                        .subhead),
                    new Container(
                        margin: const EdgeInsets.only(top: 6.0),
                        child: new Image(image: img)
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}