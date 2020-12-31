//
//  SharedMediaFile.h
//  ReceiveSharingIntent
//
//  Created by Nitish Agrawal on 02/11/20.
//  Copyright © 2020 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, SharedMediaType) {
    SharedMediaType_image,
    SharedMediaType_video,
    SharedMediaType_file
};

@interface SharedMediaFile : NSObject
@property(strong, nullable) NSString* path;
@property(strong, nullable) NSString* thumbnail;
@property(assign) double duration;
@property(assign) SharedMediaType type;

-(instancetype _Nullable)initPath:(NSString *_Nullable)path thumbnail:(NSString *_Nullable)thumbnail duration:(double)duration type:(SharedMediaType)type;

@end
