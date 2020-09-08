import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aliPlayer/event.dart';

import 'UIPanel.dart';
import 'controller.dart';

class FAliPlayerView extends StatefulWidget {
  final APController controller;

  const FAliPlayerView(
      {Key key,
      this.controller})
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
    super.initState();
    widget.controller.onPlayEvent.listen((event) {
      if (widget.controller.firstRenderedStart) {
        setState(() {});
        widget.controller.firstRenderedStart = false;
      }
    });

    _stateEvent = widget.controller.onPlayEvent.listen((event) {
      if (event == AVPEventType.AVPEventPrepareDone) {
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
    super.dispose();
    _stateEvent?.cancel();
    _fullScreenEvent?.cancel();
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
                                "loop": widget.controller.loop
                              },
                            )
                          : UiKitView(
                              viewType:
                                  "plugin.honghu.com/ali_video_play_single_",
                              creationParamsCodec: const StandardMessageCodec(),
                              onPlatformViewCreated:
                                  widget.controller.onViewCreate,
                              creationParams: <String, dynamic>{
                                "loop": widget.controller.loop,
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
