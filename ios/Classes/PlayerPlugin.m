#import "PlayerPlugin.h"


#import "FAliPlayListFactory.h"
#import "FAliPlayerView.h"

@implementation PlayerPlugin
+ (void)registerWithRegistrar:(NSObject <FlutterPluginRegistrar> *)registrar {
    FlutterMethodChannel *channel = [FlutterMethodChannel
            methodChannelWithName:@"faliplayer"
                  binaryMessenger:[registrar messenger]];
    PlayerPlugin *instance = [[PlayerPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
    FAliPlayListFactory *aliPlayerFactory = [[FAliPlayListFactory alloc] initWithMessenger:registrar.messenger];
    [registrar registerViewFactory:aliPlayerFactory withId:@"plugin.honghu.com/ali_video_play_single_"];
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    if ([@"getPlatformVersion" isEqualToString:call.method]) {
        result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
    } else {
        result(FlutterMethodNotImplemented);
    }
}

@end
