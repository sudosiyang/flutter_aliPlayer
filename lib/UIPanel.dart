import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:aliPlayer/controller.dart';

class UIPanel extends StatefulWidget {
  final APController player;
  final BuildContext buildContext;
  final Size viewSize;
  final Rect texturePos;
  final List sources;

  const UIPanel(
      {@required this.player,
      this.buildContext,
      this.viewSize,
      this.texturePos,
      this.sources});

  @override
  UIPanelPanelState createState() => UIPanelPanelState();
}

class UIPanelPanelState extends State<UIPanel> {
  APController get player => widget.player;
  Duration _duration = Duration();
  Duration _currentPos = Duration();

  // Duration _bufferPos = Duration();
  bool _playing = false;
  bool _prepared = false;
  String _exception;

  // bool _buffering = false;

  double _seekPos = -1.0;

  StreamSubscription _stateEvent;
  StreamSubscription _positionEvent;
  // StreamSubscription _currentPosSubs;

  //StreamSubscription _bufferPosSubs;
  //StreamSubscription _bufferingSubs;

  Timer _hideTimer;
  bool _hideStuff = true;
  int _index = 0;
  double _speed = 1;
  int _qulityIndex = 0;
  double _volume = 1.0;

  final barHeight = 40.0;

  @override
  void initState() {
    super.initState();
    _duration = player.duration;
    _currentPos = new Duration(milliseconds: 0);
    _prepared = player.currentStatus >= AVPStatus.AVPStatusPrepared.index;
    _playing = player.currentStatus == AVPStatus.AVPStatusStarted.index;

    _positionEvent =
        player.eventBus.on<CurrentPositionUpdate>().listen((event) {
      setState(() {
        _currentPos = Duration(milliseconds: event.position); //position;
      });
    });
    _stateEvent = player.eventBus.on<StateChangeEvent>().listen((event) {
      setState(() {
        _playing = event.state == AVPStatus.AVPStatusStarted.index;
      });
    });
  }

  void _playOrPause() {
    if (_playing == true) {
      player.pause();
    } else {
      player.start();
    }
  }

  @override
  void dispose() {
    super.dispose();
    _positionEvent?.cancel();
    _stateEvent?.cancel();
    _hideTimer?.cancel();
  }

  void _startHideTimer() {
    _hideTimer = Timer(const Duration(seconds: 3), () {
      setState(() {
        _hideStuff = true;
      });
    });
  }

  void _cancelAndRestartTimer() {
    if (_hideStuff == true) {
      _hideTimer?.cancel();
      _startHideTimer();
    }
    setState(() {
      _hideStuff = !_hideStuff;
    });
  }

  AnimatedOpacity _buildBottomBar(BuildContext context) {
    double duration = _duration.inMilliseconds.toDouble();
    double currentValue =
        _seekPos > 0 ? _seekPos : _currentPos.inMilliseconds.toDouble();
    currentValue = min(currentValue, duration);
    currentValue = max(currentValue, 0);
    return AnimatedOpacity(
      opacity: _hideStuff ? 0.0 : 0.8,
      duration: Duration(milliseconds: 400),
      child: Container(
        height: barHeight +
            (player.fullScreen ? MediaQuery.of(context).padding.bottom : 0),
        decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
          Color(0xFF000000).withOpacity(0.0),
          Color(0xFF000000).withOpacity(0.7),
        ], begin: FractionalOffset(0, 0), end: FractionalOffset(0, 0.9))),
        child: DefaultTextStyle(
          style: TextStyle(color: Colors.white),
          child: Row(
            children: <Widget>[
              IconButton(
                  icon: Icon(
                    _playing ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    _playing ? player.pause() : player.start();
                  }),
              Padding(
                padding: EdgeInsets.only(right: 5.0, left: 5),
                child: Text(
                  '${_duration2String(_currentPos)}',
                  style: TextStyle(fontSize: 14.0),
                ),
              ),

              _duration.inMilliseconds == 0
                  ? Expanded(
                      child: Center(),
                    )
                  : Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: 0, left: 0),
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: Theme.of(context).accentColor,
                            overlayShape: RoundSliderOverlayShape(
                              //可继承SliderComponentShape自定义形状
                              overlayRadius: 10, //滑块外圈大小
                            ),
                            thumbShape: RoundSliderThumbShape(
                              //可继承SliderComponentShape自定义形状
                              disabledThumbRadius: 6, //禁用是滑块大小
                              enabledThumbRadius: 6, //滑块大小
                            ),
                          ),
                          child: Slider(
                            value: currentValue,
                            activeColor: Colors.white,
                            inactiveColor: Color.fromRGBO(255, 255, 255, 0.4),
                            min: 0.0,
                            max: duration,
                            label: '$currentValue',
                            onChanged: (v) {
                              setState(() {
                                _seekPos = v;
                              });
                            },
                            onChangeEnd: (v) {
                              setState(() {
                                player.seekTo(v.toInt());
                                print("seek to $v");
                                _currentPos =
                                    Duration(milliseconds: _seekPos.toInt());
                                _seekPos = -1;
                              });
                            },
                          ),
                        ),
                      ),
                    ),

              // duration / position
              _duration.inMilliseconds == 0
                  ? Container(child: const Text(""))
                  : Padding(
                      padding: EdgeInsets.only(right: 5.0, left: 5),
                      child: Text(
                        '${_duration2String(_duration)}',
                        style: TextStyle(
                          fontSize: 14.0,
                        ),
                      ),
                    ),
              player.fullScreen
                  ? InkWell(
                      onTap: () {
                        this._index = 1;
                      },
                      child: Container(
                        margin: const EdgeInsets.only(left: 5, right: 5),
                        child: Text(_speed == 1 ? '倍速' : '${_speed}X'),
                      ),
                    )
                  : Center(),
              player.fullScreen && widget.sources != null
                  ? InkWell(
                      onTap: () {
                        this._index = 2;
                      },
                      child: Container(
                        margin: const EdgeInsets.only(left: 5, right: 5),
                        child: Text('清晰度'),
                      ),
                    )
                  : Center(),
              IconButton(
                icon: Icon(player.fullScreen
                    ? Icons.fullscreen_exit
                    : Icons.fullscreen),
                padding: EdgeInsets.only(left: 10.0, right: 10.0),
                color: Colors.white,
                onPressed: () {
                  widget.player.fullScreen
                      ? player.exitFullScreen(context)
                      : player.enterFullScreen(context);
                },
              )
              //
            ],
          ),
        ),
      ),
    );
  }

  Widget speedPanel() {
    return Container(
      padding: const EdgeInsets.all(10),
      color: Colors.black.withOpacity(0.8),
      alignment: Alignment.bottomLeft,
      height: MediaQuery.of(context).size.height,
      child: InkWell(
        onTap: () {
          setState(() {
            this._index = 0;
          });
        },
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.all(7.0),
                child: Text(
                  '播放速度',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
              ),
              Row(
                children: _speedContainer(),
              )
            ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(index: _index, children: <Widget>[
      Container(
          height: widget.viewSize.height,
          child: GestureDetector(
            onTap: _cancelAndRestartTimer,
            child: AbsorbPointer(
              absorbing: _hideStuff,
              child: Column(
                children: <Widget>[
                  AnimatedOpacity(
                    opacity: _hideStuff ? 0 : 0.8,
                    duration: Duration(milliseconds: 400),
                    child: Container(
                        height: player.fullScreen ? 50 : barHeight,
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                                colors: [
                              Color(0xFF000000).withOpacity(0.5),
                              Color(0xFF000000).withOpacity(0.0),
                            ],
                                begin: FractionalOffset(0, 0),
                                end: FractionalOffset(0, 1))),
                        child: Row(
                          children: <Widget>[
                            IconButton(
                              icon: Icon(
                                Icons.navigate_before,
                                size: 40,
                              ),
                              color: Colors.white,
                              iconSize: 40,
                              onPressed: () {
                                player.fullScreen == true
                                    ? player.exitFullScreen(context)
                                    : Navigator.of(context).pop();
                              },
                            )
                          ],
                        )),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        _cancelAndRestartTimer();
                      },
                      child: Container(
                        color: Colors.transparent,
                        height: double.infinity,
                        width: double.infinity,
                        child: Center(
                            child: _exception != null
                                ? Text(
                                    _exception,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 25,
                                    ),
                                  )
                                : _prepared
                                    ? AnimatedOpacity(
                                        opacity: _hideStuff ? 0.0 : 0.7,
                                        duration: Duration(milliseconds: 400),
                                        child: IconButton(
                                            iconSize: barHeight * 2,
                                            icon: Icon(
                                                _playing
                                                    ? Icons.pause
                                                    : Icons.play_arrow,
                                                color: _playing
                                                    ? Colors.transparent
                                                    : Colors.white),
                                            padding: EdgeInsets.only(
                                                left: 10.0, right: 10.0),
                                            onPressed: _playOrPause))
                                    : SizedBox(
                                        width: barHeight,
                                        height: barHeight,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation(
                                                Colors.white)),
                                      )),
                      ),
                    ),
                  ),
                  _buildBottomBar(context),
                ],
              ),
            ),
          )),
      speedPanel(),
    ]);
  }

  _qualityContainer() {
    List<Widget> widgets = [];
    if (widget.sources == null) {
      return widgets;
    }
    for (var i = 0; i < widget.sources.length; i++) {
      var item = widget.sources[i];
      widgets.add(Expanded(
        flex: 1,
        child: GestureDetector(
          onTap: () async {
            // await player.stop();
            // await player.reset();
            // await player.setDataSource(item['url'], autoPlay: true);
            setState(() {
              this._qulityIndex = i;
              this._hideStuff = true;
              this._index = 0;
            });
          },
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4)),
            height: 60,
            margin: const EdgeInsets.all(5),
            child: Text('${item['title']}',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _qulityIndex == i
                        ? Theme.of(context).accentColor
                        : Colors.white)),
          ),
        ),
      ));
    }
    return widgets;
  }

  _speedContainer() {
    List<double> list = [0.75, 1, 1.25, 1.5, 2];
    List<Widget> widgets = [];
    list.forEach((speed) {
      widgets.add(Expanded(
        flex: 1,
        child: GestureDetector(
          onTap: () async {
            player.setSpeed(speed);
            setState(() {
              this._speed = speed;
              this._hideStuff = true;
              this._index = 0;
            });
          },
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4)),
            height: 60,
            margin: const EdgeInsets.all(5),
            child: Text('${speed}X',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _speed == speed
                        ? Theme.of(context).accentColor
                        : Colors.white)),
          ),
        ),
      ));
    });
    return widgets;
  }
}

String _duration2String(Duration duration) {
  if (duration.inMilliseconds < 0) return "-: negtive";

  String twoDigits(int n) {
    if (n >= 10) return "$n";
    return "0$n";
  }

  String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
  String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
  int inHours = duration.inHours;
  return inHours > 0
      ? "$inHours:$twoDigitMinutes:$twoDigitSeconds"
      : "$twoDigitMinutes:$twoDigitSeconds";
}
