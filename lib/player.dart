import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aliPlayer/event.dart';

import 'UIPanel.dart';
import 'controller.dart';

class FAliPlayerView extends StatefulWidget {
  // final String url;
  final String playAuth;
  final String vid;
  final APController controller;
  final bool isCurrentLocation;
  final String url;

  const FAliPlayerView(
      {Key key,
      this.controller,
      this.url,
      this.isCurrentLocation,
      this.playAuth,
      this.vid})
      : super(key: key);

  @override
  _FAliPlayerViewState createState() => _FAliPlayerViewState();
}

class _FAliPlayerViewState extends State<FAliPlayerView> {
  bool prepared = false;
  Widget platformView;
  StreamSubscription _stateEvent;
  StreamSubscription _fullScreenEvent;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    widget.controller.setFirstRenderedStartListener(() {
      if (widget.controller.firstRenderedStart) {
        setState(() {});
        widget.controller.firstRenderedStart = false;
      }
    });

    _stateEvent = widget.controller.eventBus.on<StateChangeEvent>().listen((event) {
      if (event.state == 2) {
        setState(() {
          prepared = true;
        });
      }
    });
    _fullScreenEvent = widget.controller.eventBus.on<FullScreenChange>().listen((event) {
      if(event.isFs == false){
        setState(() {
          platformView = new UiKitView(viewType:"plugin.honghu.com/ali_video_play_single_");
        });
      }
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _stateEvent.cancel();
    _fullScreenEvent.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, contraints) {
        return Container(
            color: Colors.black,
            child: Stack(
              children: <Widget>[
                new AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Platform.isAndroid
                        ? AndroidView(
                            viewType:
                                "plugin.honghu.com/ali_video_play_single_",
                            creationParamsCodec: const StandardMessageCodec(),
                            onPlatformViewCreated:
                                widget.controller.onViewCreate,
                            creationParams: <String, dynamic>{
                              "playAuth": widget.playAuth ?? null,
                              "vid": widget.vid ?? null,
                              "url": widget.url ?? null,
                              "loop": widget.controller.loop,
                              "auto": widget.controller.isAutoPlay
                            },
                          )
                        : UiKitView(
                            viewType:
                                "plugin.honghu.com/ali_video_play_single_",
                            creationParamsCodec: const StandardMessageCodec(),
                            onPlatformViewCreated:
                                widget.controller.onViewCreate,
                            creationParams: <String, dynamic>{
                              "playAuth": widget.playAuth ?? null,
                              "vid": widget.vid ?? null,
                              "url": widget.url ?? null,
                              "loop": widget.controller.loop,
                              "auto": widget.controller.isAutoPlay
                            },
                          )),
                !prepared
                    ? Container()
                    : UIPanel(
                        player: widget.controller,
                        viewSize: Size(MediaQuery.of(context).size.width,
                            MediaQuery.of(context).size.width / 16 * 9),
                      )
              ],
            ));
      },
    );
  }
}
