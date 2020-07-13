import 'package:flutter/material.dart';
import 'package:aliPlayer/controller.dart';

import 'UIPanel.dart';

AnimatedWidget defaultRoutePageBuilder(
    BuildContext context, Animation<double> animation, APController controller) {
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
                    child:Texture(textureId: controller.textureId,))
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
