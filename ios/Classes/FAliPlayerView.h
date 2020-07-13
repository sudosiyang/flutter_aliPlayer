//
//  FAliPlayerView.h
//  Pods
//
//  Created by susu on 2020/6/30.
//
#import <Foundation/Foundation.h>
#import "Flutter/Flutter.h"
#import "AliyunPlayer/AVPDelegate.h"

@interface FAliPlayerView : NSObject<FlutterPlatformView,FlutterStreamHandler,AVPDelegate>
- (instancetype _Nullable)initWithWithFrame:(CGRect)frame
                             viewIdentifier:(int64_t)viewId
                                  arguments:(id _Nullable)args
                                     player:(id _Nullable)player
                            binaryMessenger:(NSObject <FlutterBinaryMessenger> *_Nullable)messenger;
@end
