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
      setState(() {});
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
    double width = widget.controller.fullScreen? MediaQuery.of(context).size.height / widget.controller.height*widget.controller.width :MediaQuery.of(context).size.width;
    double height;
    if(widget.controller.fullScreen){
      height = MediaQuery.of(context).size.height;
    }else{
      if(widget.controller.height==null){
        height=width/16*9;
      }else{
        height=width/widget.controller.width*widget.controller.height;
      }
    }
    double aspectRatio=widget.controller.height!=null?widget.controller.width/widget.controller.height: 16 / 9;
    return LayoutBuilder(
      builder: (context, contraints) {
        return Container(
          width: width,
          height: height,
          color: Colors.black,
          child: Stack(
                children: <Widget>[
                  new AspectRatio(
                      aspectRatio: aspectRatio,
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
                          viewSize: Size(width, height),
                        )
                ],
              ),
        );
      },
    );
  }
}
