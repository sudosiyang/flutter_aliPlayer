package com.honghu.player;

import android.content.Context;
//import android.os.Build;
//import android.support.annotation.NonNull;
//import android.support.annotation.RequiresApi;
import android.util.Log;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.View;

import com.aliyun.player.AliPlayer;
import com.aliyun.player.AliPlayerFactory;
import com.aliyun.player.IPlayer;
import com.aliyun.player.bean.ErrorInfo;
import com.aliyun.player.bean.InfoBean;
import com.aliyun.player.nativeclass.CacheConfig;
import com.aliyun.player.nativeclass.PlayerConfig;
import com.aliyun.player.nativeclass.TrackInfo;
import com.aliyun.player.source.UrlSource;
import com.aliyun.player.source.VidAuth;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.platform.PlatformView;

public class FAliPlayerSingleTextureView implements PlatformView,
        IPlayer.OnCompletionListener,
        IPlayer.OnTrackChangedListener,
        MethodChannel.MethodCallHandler,IPlayer.OnSeekCompleteListener,IPlayer.OnStateChangedListener,IPlayer.OnVideoSizeChangedListener, IPlayer.OnPreparedListener,IPlayer.OnLoadingStatusListener, IPlayer.OnInfoListener,IPlayer.OnRenderingStartListener ,IPlayer.OnErrorListener {
    int viewId;
    private AliPlayer aliPlayer;
    private MethodChannel methodChannel;
    private EventChannel eventChannel;
    private EventChannel.EventSink eventSink;
    private SurfaceView surfaceView;


//    @RequiresApi(api = Build.VERSION_CODES.O)
    FAliPlayerSingleTextureView(Context context, BinaryMessenger messenger, HashMap args, int viewId) {
        createView(context, args);
        initChannel(messenger, viewId);
        this.viewId = viewId;
    }

    private void createView(Context context, HashMap args) {
        aliPlayer = AliPlayerFactory.createAliPlayer(context);

        aliPlayer.setOnStateChangedListener(this);
        aliPlayer.setOnPreparedListener(this);
        aliPlayer.setOnInfoListener(this);
        aliPlayer.setOnVideoSizeChangedListener(this);
        aliPlayer.setOnLoadingStatusListener(this);
        aliPlayer.setOnErrorListener(this);
        aliPlayer.setOnRenderingStartListener(this);
        aliPlayer.setOnSeekCompleteListener(this);
        aliPlayer.setOnCompletionListener(this);
        aliPlayer.setOnTrackChangedListener(this);
        aliPlayer.setScaleMode(IPlayer.ScaleMode.SCALE_ASPECT_FIT);
        aliPlayer.setMute(false);
        aliPlayer.setLoop((Boolean) args.get("loop"));

//        PlayerConfig config = aliPlayer.getConfig();
        //设置网络超时时间，单位ms
//        config.mNetworkTimeout = 5000;
        //设置超时重试次数。每次重试间隔为networkTimeout。networkRetryCount=0则表示不重试，重试策略app决定，默认值为2
//        config.mNetworkRetryCount = 2;
        surfaceView = new SurfaceView(context);
        surfaceView.getHolder().addCallback(new SurfaceHolder.Callback() {
            @Override
            public void surfaceCreated(SurfaceHolder surfaceHolder) {
                System.out.println("surfaceCreated");
                aliPlayer.setDisplay(surfaceHolder);
            }

            @Override
            public void surfaceChanged(SurfaceHolder surfaceHolder, int i, int i1, int i2) {
                System.out.println("surfaceChanged");
                aliPlayer.redraw();
            }

            @Override
            public void surfaceDestroyed(SurfaceHolder surfaceHolder) {
                System.out.println("surfaceDestroyed");
                aliPlayer.setDisplay(null);
            }
        });
    }

    private void initChannel(BinaryMessenger messenger, int viewId) {
        this.methodChannel = new MethodChannel(messenger, "plugin.honghu.com/ali_video_play_single_" + viewId);
        this.eventChannel = new EventChannel(messenger, "plugin.honghu.com/eventChannel/ali_video_play_single_" + viewId);
        eventChannel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object arguments, EventChannel.EventSink events) {
                eventSink = events;
            }

            @Override
            public void onCancel(Object arguments) {
                eventSink = null;
            }
        });
        methodChannel.setMethodCallHandler(this);
    }



    @Override
    public View getView() {
        return surfaceView;
    }

    @Override
    public void dispose() {
        methodChannel = null;
        eventChannel = null;
    }

    @Override
    public void onMethodCall(MethodCall call, MethodChannel.Result result) {
        switch (call.method) {
            case "start":
                aliPlayer.start();
                result.success(null);
                break;
            case "getTrack":
                List<TrackInfo> info = aliPlayer.getMediaInfo().getTrackInfos();
                List<String> list = new ArrayList();
                for(TrackInfo  i:info) {
                    list.add(i.getVodDefinition());
                    System.out.println("==========");
                    System.out.println(i.getVodDefinition());
                }
                result.success(list);
                break;
            case "setTrack":
                String index = call.argument("index");
                aliPlayer.selectTrack(Integer.parseInt(index),true);
                result.success(null);
                break;
            case "setSource":
                String url = call.argument("url");
                aliPlayer.stop();
                if(url != null){
                    UrlSource source= new UrlSource();
                    source.setUri(url);
                    aliPlayer.setDataSource(source);
                } else {
                    VidAuth vidAuth = new VidAuth();
                    vidAuth.setPlayAuth((String) call.argument("playAuth"));
                    vidAuth.setVid((String) call.argument("vid"));
                    aliPlayer.setDataSource(vidAuth);
                }
                aliPlayer.prepare();
                aliPlayer.start();
                result.success(null);
                break;
            case "pause":
                aliPlayer.pause();
                result.success(null);
                break;
            case "stop":
                aliPlayer.stop();
                result.success(null);
                break;
            case "seekTo":
                int position = call.argument("position");
                BigDecimal b = new BigDecimal(position);
                aliPlayer.seekTo(b.longValue(), IPlayer.SeekMode.Accurate);
                result.success(null);
                break;
            case "setSpeed":
                double speed = call.argument("speed");
                aliPlayer.setSpeed((float) speed);
                result.success(null);
                break;
            case "release":
                aliPlayer.release();
                result.success(null);
                break;
        }
    }

    @Override
    public void onStateChanged(int i) {
        System.out.println("onPlayerStatusChanged：" + i);
        if (eventSink != null) {
            HashMap<String, Object> map = new HashMap<>();
            map.put("eventType", "onPlayerStatusChanged");
            map.put("values", i);
            eventSink.success(map);
        }
    }

    @Override
    public void onPrepared() {
        System.out.println("onPrepared：");
//        List<TrackInfo> trackInfos  = aliPlayer.getMediaInfo().getTrackInfos();
//        System.out.println(trackInfos);
//        for(TrackInfo  i:trackInfos) {
//            System.out.println("======");
//            System.out.println(i.getIndex());
//            System.out.println(i.getVodDefinition());
//        }
        if (eventSink != null) {
            HashMap<String, Object> map = new HashMap<>();
            map.put("eventType", "onPrepared");
            map.put("duration", aliPlayer.getMediaInfo().getDuration());
            eventSink.success(map);
        }
    }

    @Override
    public void onInfo(InfoBean infoBean) {
        HashMap<String, Object> map = new HashMap<>();
        switch (infoBean.getCode().getValue()) {
            case 1:
                map.put("eventType", "onBufferedPositionUpdate");
                map.put("values", infoBean.getExtraValue());
                eventSink.success(map);
                break;
            case 2:
                map.put("eventType", "onCurrentPositionUpdate");
                map.put("values", infoBean.getExtraValue());
                eventSink.success(map);
                break;
        }
    }

    @Override
    public void onError(ErrorInfo errorInfo) {
        System.out.println("onError：" + errorInfo.getMsg());
        if (eventSink != null) {
            HashMap<String, Object> map = new HashMap<>();
            map.put("eventType", "onError");
            map.put("msg", errorInfo.getMsg());
            map.put("errorCode", errorInfo.getCode().getValue());
            eventSink.success(map);
        }
    }

    @Override
    public void onVideoSizeChanged(int i, int i1) {
        if (eventSink != null) {
            HashMap<String, Object> map = new HashMap<>();
            map.put("eventType", "onVideoSizeChanged");
            map.put("width", i);
            map.put("height", i1);
            eventSink.success(map);
        }
    }

    @Override
    public void onLoadingBegin() {
        HashMap<String, Object> map = new HashMap<>();
        map.put("eventType", "onPlayerEvent");
        map.put("values", 4);
        eventSink.success(map);
    }

    @Override
    public void onLoadingProgress(int i, float v) {
        HashMap<String, Object> map = new HashMap<>();
        map.put("eventType", "onLoadingProcess");
        map.put("percent",i);
        map.put("kbps",v);
        eventSink.success(map);
    }

    @Override
    public void onLoadingEnd() {
        HashMap<String, Object> map = new HashMap<>();
        map.put("eventType", "onPlayerEvent");
        map.put("values", 5);
        eventSink.success(map);
    }

    @Override
    public void onRenderingStart() {
        HashMap<String, Object> map = new HashMap<>();
        map.put("eventType", "onPlayerEvent");
        map.put("values", 2);
        eventSink.success(map);
    }

    @Override
    public void onSeekComplete() {
        HashMap<String, Object> map = new HashMap<>();
        map.put("eventType", "onPlayerEvent");
        map.put("values", 6);
        eventSink.success(map);
    }

    @Override
    public void onCompletion() {
        HashMap<String, Object> map = new HashMap<>();
        map.put("eventType", "onPlayerEvent");
        map.put("values", 3);
        eventSink.success(map);
    }

    @Override
    public void onChangedSuccess(TrackInfo trackInfo) {
        HashMap<String, Object> map = new HashMap<>();
        map.put("eventType", "onPlayerEvent");
        map.put("values", 7);
        eventSink.success(map);
    }

    @Override
    public void onChangedFail(TrackInfo trackInfo, ErrorInfo errorInfo) {
        HashMap<String, Object> map = new HashMap<>();
        map.put("eventType", "onPlayerEvent");
        map.put("values", 8);
        eventSink.success(map);
    }
}