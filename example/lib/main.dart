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
    controller = APController(isAutoPlay: false, loop: false);
    controller.onStatusEvent.listen((status) {
      print(status);
      
    });
    controller.onPlayEvent.listen((event) {
      if(event==AVPEventType.AVPEventCreated){
        print('inited');
        controller.setSource(vid:'30664f2aab914d1ebac16e8fe8b119b6',playAuth:'eyJTZWN1cml0eVRva2VuIjoiQ0FJUzF3SjFxNkZ0NUIyeWZTaklyNWJ4TFlQWm42MFQ5cXFQUnhIYW9sWTBRc2wwcTRuQTFUejJJSGxQZTNGaEFPb2V2L2svbVc5VTdmb2NscnNvRXNRZEZSQ1ZObzVvNnAxR3pRU2lib3laVkN3M0NCTkMydk9mQW1HMkowUFJMNmF3Q3J5THNicS9GOTZwYjFmYjdDd1JwWkx4YVRTbFdYRzhMSlNOa3VRSlI5OExYdzYrSHdFa1k4bFJLbGxOcGRNaU1YTEFGUENqTlh5UW5HM2NYbVZscGpSOWhXNTR3cU81ek15VGlIemJrRWFvOHVzY3RvbnJDNFc0YjZzSU9ZdGtBZSt4MWYxWGNLVEdza2hWOXdNWTJLcDlscjFjNVJUS3I2dnFZVDlyN2c2Qkx2RGYvL0IyTVFaOWZkSmFJYU5mcStYbW52QUswWTY2MWFhUGtrZ2RiTEFORG42QUh0djRtSldhUTluRWJJaHBLZXpKWEYzV3ljMktPNVhQdEFjcFhHa1dMZ3NpZWFCNmN5UXZVVTExRUdtTGQvLzZwd3lSUGxtNU40R0IwYkFyMTZSeXcyN2g5TUd4TzBPMVJMR1V3Ym00aEN5UG1hdERHb0FCbTk4YWtaTUFEYWVHVStXWERtdEpzTkNKcFRTWDhGeTU0VGVOSXM2WEI5eEUydzhJZCs5Z3l0M2tHK3NkSkZZWDN4c3B3bVhSWGZZbDQvZFpQSkVmRUNIWFVHNFVMcWo4Z2lOL3lJbTMrL2FIQTVRWkZ6c3Nma0h6N1RMVmcvRDA3LzBVWW5xQWNUakJ3OFhPSUpOU3RUOVJINThCSlhaVGZKaUI4WEIyUE9BPSIsIkF1dGhJbmZvIjoie1wiQ0lcIjpcIkM5bjZIMnVTak5hSVdBZDJJQWFMTUdJTlAxT0pRcEdEcmRoK2F1L0ZDdVhHTm1sd0VWbkpsZHpPendPNzJ4dXRzL2p1SEg1ZlYzakYxWmVFcTQ2a0tRPT1cIixcIkNhbGxlclwiOlwiQlpybGRTQlRyMnpSUTRnR1NFMHZGUT09XCIsXCJFeHBpcmVUaW1lXCI6XCIyMDIwLTA5LTA5VDA2OjUyOjA3WlwiLFwiTWVkaWFJZFwiOlwiMzA2NjRmMmFhYjkxNGQxZWJhYzE2ZThmZThiMTE5YjZcIixcIlBsYXlEb21haW5cIjpcIm1lZGlhMDAxLmdlZWtiYW5nLm9yZ1wiLFwiU2lnbmF0dXJlXCI6XCJIVVJSZ1VBV3B5VTN6T0Y1TW9sdVRScVdFQlU9XCJ9IiwiVmlkZW9NZXRhIjp7IlN0YXR1cyI6Ik5vcm1hbCIsIlZpZGVvSWQiOiIzMDY2NGYyYWFiOTE0ZDFlYmFjMTZlOGZlOGIxMTliNiIsIlRpdGxlIjoiMyBXZWIg5a6J5YWo5YmN56uv5Z+656GA77yaSFRNTCIsIkNvdmVyVVJMIjoiaHR0cHM6Ly9tZWRpYTAwMS5nZWVrYmFuZy5vcmcvMzA2NjRmMmFhYjkxNGQxZWJhYzE2ZThmZThiMTE5YjYvc25hcHNob3RzL2JhNWE5YmQ4NjFhNzRiMmE4YjE4MzQ1NWJiODNjZTI2LTAwMDA1LmpwZyIsIkR1cmF0aW9uIjo0MjQuOTg2fSwiQWNjZXNzS2V5SWQiOiJTVFMuTlVEZjltcnIyQWhkRTdrRlZhTkZYRExrNyIsIlBsYXlEb21haW4iOiJtZWRpYTAwMS5nZWVrYmFuZy5vcmciLCJBY2Nlc3NLZXlTZWNyZXQiOiI2dlo5YTN2SnM5aXFWV3B3a2hqQ1lrdDlQRm9udmRxYUVmRVg1b25qODRyMiIsIlJlZ2lvbiI6ImNuLXNoYW5naGFpIiwiQ3VzdG9tZXJJZCI6MzEzMDg0OTN9');
        // controller.setSource(url:'https://vod.apuscn.com/hundun/89b4542bcd5d491d9660f1d0616dbb39/89b4542bcd5d491d9660f1d0616dbb39.m3u8');
        print('set source');
      }
      if(event==AVPEventType.AVPEventPrepareDone){
        controller.getTrack().then((value){
          print(value);
        });
      }
    });
    // controller.onBufferPositionUpdate.listen((event) {
    //   print('BufferPosition:$event');
    // });
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
            return Column(
                children: <Widget>[
                  FAliPlayerView(controller: controller),
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
              );
            }))
    );
  }
}