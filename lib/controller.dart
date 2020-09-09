import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'event.dart';
import 'innerView.dart';

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

  ///轨道切换成功*/
  AVPEventTrackChangeSuccess,

  ///循环播放开始事件*/
  AVPEventLoopingStart,

  ///轨道切换失败*/
  AVPEventTrackChangeFail,

  ///Player Created*/
  AVPEventCreated,
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

enum AVPScreenStatus{
  FULLSCREEN,
  NORMAL
}

enum AVPScalingMode {
  SCALETOFILL,
  SCALEASPECTFIT,
  SCALEASPECTFILL,
}



class LoadProcess{
  final int percent;
  final double kbps;
  LoadProcess(this.percent,this.kbps);
}
/// 当前播放进度更新
class PlayerPosition{
  int position;
  PlayerPosition(this.position);
}
class BufferPosition{
  int position;
  BufferPosition(this.position);
}

class AVPError{
  int errorCode;
  String msg;
  AVPError({this.errorCode,this.msg});
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

  /// 视频时长
  Duration duration = Duration();

  ///缓存配置
  // AVPCacheConfig cacheConfig;

  ///当前视频的高
  int height;
  List tracks = [];
  ///当前视频的宽
  int width;

  AVPStatus currentStatus;

  int textureId;

  OnVideoSizeChanged _onVideoSizeChanged;


  APController({this.isAutoPlay = true, this.loop = false});

  /// 当前是否正在播放
  bool get isPlaying => currentStatus == AVPStatus.AVPStatusStarted;

  Stream<AVPEventType> get onPlayEvent => eventBus.on<AVPEventType>();
  Stream<AVPStatus> get onStatusEvent => eventBus.on<AVPStatus>();
  Stream<int> get onPositionUpdate => eventBus.on<PlayerPosition>().transform(StreamTransformer.fromHandlers(handleData:(value, sink){
    sink.add(value.position);
  }));
  Stream<int> get onBufferPositionUpdate => eventBus.on<BufferPosition>().transform(StreamTransformer.fromHandlers(handleData:(value, sink){
    sink.add(value.position);
  }));
  Stream<AVPError> get onError => eventBus.on<AVPError>();
  Stream<AVPScreenStatus> get onFullScreenChange => eventBus.on<AVPScreenStatus>();
  /// 设置视频宽高变化监听
  setOnVideoSizeChanged(OnVideoSizeChanged listener) {
    this._onVideoSizeChanged = listener;
  }

  ///播放器事件监听

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

  Future<List> getTrack() {
    return _channel?.invokeMethod("getTrack");
  }

  Future<List> setTrack(int index) {
    return _channel?.invokeMethod("setTrack",{
      "index":index.toString()
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
        eventBus.fire(AVPEventType.values[event["values"]]);
        break;
      case "onPlayerStatusChanged":
        currentStatus = AVPStatus.values[event["values"]];
        eventBus.fire(AVPStatus.values[(event["values"])]);
        break;
      case "onPrepared":
        eventBus.fire(AVPEventType.AVPEventPrepareDone);
        duration = new Duration(milliseconds: event['duration']);
        getTrack().then((value){
          tracks = value;
        });
        break;
      case "onCurrentPositionUpdate":
        eventBus.fire(PlayerPosition(event["values"]));
        break;
      case "onBufferedPositionUpdate":
        eventBus.fire(BufferPosition(event["values"]));
        break;
      case "onLoadingProcess":
        eventBus.fire(LoadProcess(event["percent"],event['kbps']));
        break;
      case "onVideoSizeChanged":
        this.height = event["height"];
        this.width = event["width"];
        if (this._onVideoSizeChanged != null) {
          this._onVideoSizeChanged();
        }
        break;
      case "onError":
        eventBus.fire(AVPError(errorCode: event["errorCode"],msg:event["msg"]));
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
      eventBus.fire(AVPEventType.AVPEventCreated);
    }
  }

  void enterFullScreen(context) {
    fullScreen = true;
    _pushFullScreenWidget(context);
    eventBus.fire(AVPScreenStatus.FULLSCREEN);
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
    eventBus.fire(AVPScreenStatus.NORMAL);
  }

  Future<dynamic> _pushFullScreenWidget(BuildContext context) async {
    final TransitionRoute<Null> route = PageRouteBuilder<Null>(
      settings: RouteSettings(),
      pageBuilder: _fullScreenRoutePageBuilder,
    );

    await SystemChrome.setEnabledSystemUIOverlays([]);
    await setOrientationLandscape();
    if(Platform.isAndroid){
      await Navigator.of(context).push(route);
      // widget.player.exitFullScreen();
      await setOrientationPortrait();
    }
    await SystemChrome.setEnabledSystemUIOverlays(
          [SystemUiOverlay.top, SystemUiOverlay.bottom]);
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