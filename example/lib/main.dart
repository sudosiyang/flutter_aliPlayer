import 'dart:io';

import 'package:flutter/material.dart';
import 'package:aliPlayer/player.dart';
import 'package:aliPlayer/controller.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  APController controller;
  FAliPlayerView view;
  bool playing = true;
  bool fullScreen = false;
  @override
  void initState() {
    super.initState();
    controller = APController(isAutoPlay: false, loop: true);
    controller.eventBus.on<FullScreenChange>().listen((event) {
      if(Platform.isIOS){
        setState(() {
          fullScreen = event.isFs;
        });
      }
    });
    view = FAliPlayerView(
        url:
            'https://vod.apuscn.com/hundun/89b4542bcd5d491d9660f1d0616dbb39/89b4542bcd5d491d9660f1d0616dbb39.m3u8',
        controller: controller,
        isCurrentLocation: true);
  }

  changeState() {
    if (controller.isPlaying == true) {
      controller.pause();
    } else {
      controller.start();
    }
    setState(() {
      playing = !playing;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          body: LayoutBuilder(builder: (context,con){
            return _wrapper(Column(
                children: <Widget>[
                  view == null ? Container() : view,
                  FlatButton(
                    child: Text(
                      '下一个',
                      style: TextStyle(fontSize: 16),
                    ),
                    onPressed: () {
                      setState(() {
                        print(controller.textureId);
                        // controller.dispose();
                        // controller=new Controller(isAutoPlay: false, loop: true);
                        // view=FAliPlayerView(url: 'http://vod.apuscn.com/test/aaa.m3u8',controller: controller);
                        controller.setSource(
                            url: 'http://vod.apuscn.com/test/aaa.m3u8');
                      });
                    },
                  )
                ],
              ),context);
            }))
    );
  }

  Widget _wrapper(widget,context){
    double width= MediaQuery.of(context).size.width;
    return Platform.isIOS ? OverflowBox(
              alignment: Alignment.topLeft,
              maxHeight: fullScreen == true? width : double.infinity,
              child: widget) : widget;
  }
}
