//
//  FAliPlayerView.m
//  player
//
//  Created by susu on 2020/6/30.
//

#import "FAliPlayerView.h"
#import "FAliPlayerView.h"
#import "AliyunPlayer/AliPlayer.h"


@implementation FAliPlayerView {
    UIView *playerView;
    FlutterMethodChannel *channel;
    FlutterEventSink eventSink;
    AliPlayer *aliPlayer;
}
- (FAliPlayerView *)initWithWithFrame:(CGRect)frame viewIdentifier:(int64_t)viewId arguments:(id _Nullable)args player:(id _Nullable)player binaryMessenger:(NSObject <FlutterBinaryMessenger> *_Nullable)messenger {
    if ([super init]) {
        ///初始化渠道
        [self initChannel:viewId messenger:messenger];
        ///初始化view
        aliPlayer = [[AliPlayer alloc] init];
        aliPlayer.delegate = self;
        aliPlayer.scalingMode = AVP_SCALINGMODE_SCALEASPECTFIT;///画面铺面.dart层控制宽高

        ///循环播放
        aliPlayer.loop = @([args[@"loop"] intValue]).boolValue;
        if(args[@"vid"] != NSNull.null){
            AVPVidAuthSource *source = [[AVPVidAuthSource alloc] init];
            source.playAuth = args[@"playAuth"];
            source.vid = args[@"vid"];
            [aliPlayer setAuthSource:source];
        }else{
            AVPUrlSource *source = [[AVPUrlSource alloc] init];
            source.playerUrl = [NSURL URLWithString:args[@"url"]];
            [aliPlayer setUrlSource:source];
        }
        [aliPlayer prepare];
        playerView = [UIView new];
        aliPlayer.playerView = playerView;
        aliPlayer.playerView.frame = frame;
        aliPlayer.autoPlay = YES;
    }

    return self;
}

- (void)initChannel:(int64_t)viewId messenger:(NSObject <FlutterBinaryMessenger> *)messenger {
    NSString *methodChannelName = [NSString stringWithFormat:@"plugin.honghu.com/ali_video_play_single_%lld", viewId];
    NSString *eventChannelName = [NSString stringWithFormat:@"plugin.honghu.com/eventChannel/ali_video_play_single_%lld", viewId];
    [[FlutterEventChannel
            eventChannelWithName:eventChannelName
                 binaryMessenger:messenger] setStreamHandler:self];
    channel = [FlutterMethodChannel methodChannelWithName:methodChannelName binaryMessenger:messenger];
    __weak __typeof__(self) weakSelf = self;
    [channel setMethodCallHandler:^(FlutterMethodCall *call, FlutterResult result) {
        [weakSelf onMethodCall:call result:result];
    }];
}

- (UIView *)view {
    return aliPlayer.playerView;
}


- (void)onMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    NSLog(@"call method:%@", call.method);

    if ([call.method isEqualToString:@"start"]) {
        [aliPlayer start];
    } else if ([call.method isEqualToString:@"pause"]) {
        [aliPlayer pause];
    } else if ([call.method isEqualToString:@"seekTo"]) {
        int64_t time = (int64_t) [call.arguments[@"position"] intValue];
        [aliPlayer seekToTime:time seekMode:AVP_SEEKMODE_INACCURATE];
    } else if ([call.method isEqualToString:@"setScalingMode"]) {
        int mode = [call.arguments[@"mode"] intValue];
        aliPlayer.scalingMode = (AVPScalingMode) mode;///画面铺面.dart层控制宽高
    } else if ([call.method isEqualToString:@"setSpeed"]){
        float speed = [call.arguments[@"speed"] floatValue];
        [aliPlayer setRate:speed];
    } else if ([call.method isEqualToString:@"release"]){
        [aliPlayer destroy];
    } else if ([call.method isEqualToString:@"setSource"]){
        if(call.arguments[@"vid"] != NSNull.null){
            AVPVidAuthSource *source = [[AVPVidAuthSource alloc] init];
            source.playAuth = call.arguments[@"playAuth"];
            source.vid = call.arguments[@"vid"];
            [aliPlayer setAuthSource:source];
        }else{
            AVPUrlSource *source = [[AVPUrlSource alloc] init];
            source.playerUrl = [NSURL URLWithString:call.arguments[@"url"]];
            [aliPlayer setUrlSource:source];
        }
        [aliPlayer prepare];
        [aliPlayer start];
    }
}

////获取缓存文件路径
//- (NSString *)getCachesPath {
//    // 获取Caches目录路径
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
//    NSString *cachesDir = paths[0];
//
//    //指定文件名
//    NSString *filePath = [cachesDir stringByAppendingPathComponent:@"com.st.video"];
//    long size = [self fileSizeAtPath:filePath];
//    NSLog(@"缓存目录:%@", cachesDir);
//    NSLog(@"缓存目录2:%@", filePath);
//    NSLog(@"缓存目录大小:%ld", size);
//    return filePath;
//}
//
//- (long long)fileSizeAtPath:(NSString *)filePath {
//    NSFileManager *manager = [NSFileManager defaultManager];
//    if ([manager fileExistsAtPath:filePath]) {
//
////        //取得一个目录下得所有文件名
//        NSArray *files = [manager subpathsAtPath:filePath];
//        NSLog(@"files1111111%@ == %ld", files, files.count);
////
////        // 从路径中获得完整的文件名（带后缀）
////        NSString *exe = [filePath lastPathComponent];
////        NSLog(@"exeexe ====%@",exe);
////
////        // 获得文件名（不带后缀）
////        exe = [exe stringByDeletingPathExtension];
////
////        // 获得文件名（不带后缀）
////        NSString *exestr = [[files objectAtIndex:1] stringByDeletingPathExtension];
////        NSLog(@"files2222222%@  ==== %@",[files objectAtIndex:1],exestr);
//
//
//        return [[manager attributesOfItemAtPath:filePath error:nil] fileSize];
//    }
//
//    return 0;
//}

- (FlutterError *_Nullable)onListenWithArguments:(id _Nullable)arguments eventSink:(FlutterEventSink)events {
    eventSink = events;
    return nil;
}

- (FlutterError *_Nullable)onCancelWithArguments:(id _Nullable)arguments {
    eventSink = nil;
    return nil;
}

- (void)onPlayerStatusChanged:(AliPlayer *)player oldStatus:(AVPStatus)oldStatus newStatus:(AVPStatus)newStatus {
    NSLog(@"onPlayerStatusChanged:%@", @(newStatus));
    if (eventSink) {
        eventSink(@{
                @"eventType": @"onPlayerStatusChanged",
                @"values": @(newStatus)
        });
    }
}
- (void)onTrackReady:(AliPlayer *)player info:(NSArray<AVPTrackInfo *> *)info {
//    NSLog(@"onTrackReady :%d === %d", info[0].videoWidth,info[0].videoHeight);
//    if(info[0].videoWidth<info[0].videoHeight){
//        aliPlayer.scalingMode = AVP_SCALINGMODE_SCALEASPECTFILL;
//    }else{
//        aliPlayer.scalingMode = AVP_SCALINGMODE_SCALEASPECTFIT;
//    }
}
- (void)onVideoSizeChanged:(AliPlayer *)player width:(int)width height:(int)height rotation:(int)rotation {
    eventSink(@{
            @"eventType": @"onVideoSizeChanged",
            @"height": @(height),
            @"width": @(width),
    });
}

- (void)onPlayerEvent:(AliPlayer *)player eventType:(AVPEventType)eventType {
//    NSLog(@"onPlayerEvent:%@", @(eventType));
    if (eventSink) {
        eventSink(@{
                @"eventType": @"onPlayerEvent",
                @"values": @(eventType)
        });
    }
    switch (eventType) {
        case AVPEventPrepareDone: {
            // 准备完成
            AVPMediaInfo *info = [aliPlayer getMediaInfo];
            int duration = info.duration;
           eventSink(@{
               @"eventType":@"onPrepared",
               @"duration": @(duration)
           });
        }
            break;
    }
}

- (void)onBufferedPositionUpdate:(AliPlayer *)player position:(int64_t)position {
    if (eventSink) {
        eventSink(@{
                @"eventType": @"onBufferedPositionUpdate",
                @"values": @(position)
        });
    }
}


- (void)onCurrentPositionUpdate:(AliPlayer *)player position:(int64_t)position {
    if (eventSink) {
        eventSink(@{
                @"eventType": @"onCurrentPositionUpdate",
                @"values": @(position)
        });
    }
}

- (void)onError:(AliPlayer *)player errorModel:(AVPErrorModel *)errorModel {
    NSLog(@"onError:%@", errorModel.message);
}

@end
