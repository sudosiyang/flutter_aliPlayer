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
import java.util.HashMap;
import java.util.List;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.platform.PlatformView;

public class FAliPlayerSingleTextureView implements PlatformView, MethodChannel.MethodCallHandler, IPlayer.OnStateChangedListener,IPlayer.OnVideoSizeChangedListener, IPlayer.OnPreparedListener, IPlayer.OnInfoListener, IPlayer.OnErrorListener {
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
        aliPlayer.setOnErrorListener(this);
        aliPlayer.enableLog(false);
        if(args.get("url") != null){
            UrlSource urlSource= new UrlSource();
            urlSource.setUri((String) args.get("url"));
            aliPlayer.setDataSource(urlSource);
        }
        if(args.get("vid")!=null) {
            VidAuth vidAuth = new VidAuth();
            vidAuth.setPlayAuth((String) args.get("playAuth"));
            vidAuth.setVid((String) args.get("vid"));
            aliPlayer.setDataSource(vidAuth);
        }
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
        aliPlayer.prepare();
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
                aliPlayer.seekTo(b.longValue());
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
        List<TrackInfo> trackInfos  = aliPlayer.getMediaInfo().getTrackInfos();
        System.out.println(trackInfos);
        for(TrackInfo  i:trackInfos) {
            System.out.println("======");
            System.out.println(i.getIndex());
            System.out.println(i.getVodDefinition());
        }
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
            map.put("errorCode", errorInfo.getCode());
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
}