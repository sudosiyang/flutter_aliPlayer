import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'event.dart';
import 'innerView.dart';

typedef FirstRenderedStartListener = void Function();


///当前缓存进度更新
typedef OnBufferedPositionUpdateListener = void Function(int position);

///当前缓存进度更新
typedef OnPlayEventListener = void Function(AVPEventType eventType);

///大小改变回调
typedef OnVideoSizeChanged = void Function();


enum AVPEventType {
  ///准备完成事件*/
  AVPEventPrepareDone,

  ///自动启播事件*/
  AVPEventAutoPlayStart,

  ///首帧显示事件*/
  AVPEventFirstRenderedStart,

  ///播放完成事件*/
  AVPEventCompletion,

  ///缓冲开始事件*/
  AVPEventLoadingStart,

  ///缓冲完成事件*/
  AVPEventLoadingEnd,

  ///跳转完成事件*/
  AVPEventSeekEnd,

  ///循环播放开始事件*/
  AVPEventLoopingStart,
}
enum AVPStatus {
  ///空转，闲时，静态
  AVPStatusIdle,

  /// 初始化完成
  AVPStatusInitialzed,

  /// 准备完成
  AVPStatusPrepared,

  /// 正在播放
  AVPStatusStarted,

  /// 播放暂停
  AVPStatusPaused,

  /// 播放停止
  AVPStatusStopped,

  /// 播放完成
  AVPStatusCompletion,

  /// 播放错误
  AVPStatusError
}
enum AVPScalingMode {
  SCALETOFILL,
  SCALEASPECTFIT,
  SCALEASPECTFILL,
}

/// Event 播放器状态监听
class StateChangeEvent {
  int state;
  StateChangeEvent(this.state);
}

/// 当前播放进度更新
class CurrentPositionUpdate{
  int position;
  CurrentPositionUpdate(this.position);
}

/// 全屏时间
class FullScreenChange{
  bool isFs;
  FullScreenChange(this.isFs);
}


class APController {

  /// 创建EventBus
  EventBus eventBus = EventBus();


  MethodChannel _channel;
  StreamSubscription _streamSubscription;

  /// 全屏
  bool fullScreen = false;

  ///自动播放
  bool isAutoPlay;

  ///循环播放
  bool loop;

  ///标记第一帧渲染成功,每次都切换新的视频都会标记为true
  ///用到的地方需要手动标记为false，否则会一直为true
  bool firstRenderedStart = false;

  /// 视频时长
  Duration duration;

  ///缓存配置
  // AVPCacheConfig cacheConfig;

  ///当前视频的高
  int height;

  ///当前视频的宽
  int width;

  int currentStatus;

  int textureId;

  ///第一帧渲染成功的监听器，每次切换新的视频都会调用
  FirstRenderedStartListener _firstRenderedStartListener;

  OnBufferedPositionUpdateListener _bufferedPositionUpdateListener;

  OnVideoSizeChanged _onVideoSizeChanged;

  OnPlayEventListener _onPlayEventListener;

  APController({this.isAutoPlay = true, this.loop = false});

  /// 当前是否正在播放
  bool get isPlaying => currentStatus == AVPStatus.AVPStatusStarted.index;

  void setBufferedPositionUpdateListener(
      OnBufferedPositionUpdateListener value) {
    _bufferedPositionUpdateListener = value;
  }

  /// 设置首帧渲染完成的监听器
  setFirstRenderedStartListener(FirstRenderedStartListener listener) {
    this._firstRenderedStartListener = listener;
  }

  /// 设置视频宽高变化监听
  setOnVideoSizeChanged(OnVideoSizeChanged listener) {
    this._onVideoSizeChanged = listener;
  }

  ///播放器事件监听
  setOnPlayEventListener(OnPlayEventListener listener) {
    this._onPlayEventListener = listener;
  }

  ///开始播放
  Future<void> start() {
    return _channel?.invokeMethod("start");
  }

  ///暂停
  Future<void> pause() {
    return _channel?.invokeMethod("pause");
  }

  ///暂停
  Future<void> release() {
    return _channel?.invokeMethod("release");
  }

  /// 更换视频源
  Future<void> setSource({String vid, String playAuth, String url}) {
    print(url);
    return _channel?.invokeMethod("setSource",
        {"vid": vid ?? null, "playAuth": playAuth ?? null, "url": url ?? null});
  }

  Future<void> setScalingMode(AVPScalingMode mode) {
    return _channel?.invokeMethod("setScalingMode", {
      "mode": mode.index,
    });
  }

  Future<void> seekTo(int position) {
    return _channel?.invokeMethod("seekTo", {"position": position});
  }

  Future<void> setSpeed(double speed) {
    return _channel?.invokeMethod("setSpeed", {"speed": speed});
  }

  void _onEvent(event) {
    String type = event['eventType'];
    switch (type) {
      case "onPlayerEvent":
        if (_onPlayEventListener != null) {
          _onPlayEventListener(event["values"]);
        }
        break;
      case "onPlayerStatusChanged":
        currentStatus = event["values"];
        if (event["values"] == AVPStatus.AVPStatusStarted.index) {
          firstRenderedStart = true;
          this._firstRenderedStartListener();
        }
        eventBus.fire(StateChangeEvent(event["values"]));
        break;
      case "onPrepared":
        duration = new Duration(milliseconds: event['duration']);
        break;
      case "onCurrentPositionUpdate":
        eventBus.fire(CurrentPositionUpdate(event["values"]));
        break;
      case "onBufferedPositionUpdate":
        if (this._bufferedPositionUpdateListener != null) {
          this._bufferedPositionUpdateListener(event["values"]);
        }
        break;
      case "onVideoSizeChanged":
        this.height = event["height"];
        this.width = event["width"];
        if (this._onVideoSizeChanged != null) {
          this._onVideoSizeChanged();
        }
        break;
    }
  }

  void dispose() {
    release();
    _streamSubscription?.cancel();
  }

  void onViewCreate(int i) {
    textureId = i;
    if (_channel == null && _streamSubscription == null) {
      _channel = MethodChannel("plugin.honghu.com/ali_video_play_single_$i");

      _streamSubscription = EventChannel(
              "plugin.honghu.com/eventChannel/ali_video_play_single_$i")
          .receiveBroadcastStream()
          .listen(_onEvent);
      if (isAutoPlay) {
        this.start();
      }
    }
  }

  void enterFullScreen(context) {
    fullScreen = true;
    _pushFullScreenWidget(context);
    eventBus.fire(FullScreenChange(fullScreen));
  }

  void exitFullScreen(context) async{
    if(Platform.isIOS){
      if (MediaQuery.of(context).orientation == Orientation.portrait) {
        await setOrientationLandscape();
      } else if (MediaQuery.of(context).orientation == Orientation.landscape){
        await setOrientationPortrait();
      }
    } else {
      print('退出全屏');
      Navigator.of(context).pop();
    }
    fullScreen = false;
    eventBus.fire(FullScreenChange(fullScreen));
  }

  Future<dynamic> _pushFullScreenWidget(BuildContext context) async {
    final TransitionRoute<Null> route = PageRouteBuilder<Null>(
      settings: RouteSettings(),
      pageBuilder: _fullScreenRoutePageBuilder,
    );

    await SystemChrome.setEnabledSystemUIOverlays([]);
    var orientation = MediaQuery.of(context).orientation;
    if (width >= height) {
      if (orientation == Orientation.portrait) {
        await setOrientationLandscape();
      } else if (orientation == Orientation.landscape){
        await setOrientationPortrait();
      }
    }
    if(Platform.isAndroid){
      await Navigator.of(context).push(route);
      fullScreen = false;
      // widget.player.exitFullScreen();
      await SystemChrome.setEnabledSystemUIOverlays(
          [SystemUiOverlay.top, SystemUiOverlay.bottom]);
      await setOrientationPortrait();
    }
  }

  static Future<bool> setOrientationPortrait() async {
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    return Future.value(true);
  }

  static Future<bool> setOrientationLandscape() async {
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeRight, DeviceOrientation.landscapeLeft]);
    return Future.value(true);
  }

  Widget _fullScreenRoutePageBuilder(BuildContext context,
      Animation<double> animation, Animation<double> secondaryAnimation) {
    return defaultRoutePageBuilder(context, animation, this);
  }
}
