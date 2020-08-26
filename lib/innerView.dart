import 'package:flutter/material.dart';
import 'package:aliPlayer/controller.dart';

import 'UIPanel.dart';

AnimatedWidget defaultRoutePageBuilder(BuildContext context,
    Animation<double> animation, APController controller) {
  return AnimatedBuilder(
    animation: animation,
    builder: (BuildContext context, Widget child) {
      double width = MediaQuery.of(context).size.height /
          controller.height *
          controller.width;
      double height = MediaQuery.of(context).size.height;
      double aspectRatio = controller.width / controller.height;
      return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              new AspectRatio(
                  aspectRatio: aspectRatio,
                  child: Container(
                      alignment: Alignment(0, 0),
                      child: Container(
                          width: width,
                          height: height,
                          color: Colors.blue,
                          child: Texture(
                            textureId: controller.textureId,
                          )))),
              UIPanel(
                player: controller,
                viewSize: Size(width, height),
              )
            ],
          ));
    },
  );
}
