import 'dart:io';

import 'package:flutter/material.dart';
import 'package:aliPlayer/controller.dart';

import 'UIPanel.dart';

AnimatedWidget defaultRoutePageBuilder(
    BuildContext context, Animation<double> animation, Controller controller) {
  return AnimatedBuilder(
    animation: animation,
    builder: (BuildContext context, Widget child) {
      return Scaffold(
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: <Widget>[
              new AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    child:Platform.isAndroid?Texture(textureId: controller.textureId,):UiKitView(
                viewType: "plugin.honghu.com/ali_video_play_single_",))
              ),
              UIPanel(
                player: controller,
                viewSize: Size(
                    MediaQuery.of(context).size.width / 16 * 9,MediaQuery.of(context).size.width,),
              )
            ],
          ));
    },
  );
}
