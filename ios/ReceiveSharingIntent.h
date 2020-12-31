//
//  ReceiveSharingIntent.h
//  ReceiveSharingIntent
//
//  Created by Nitish Agrawal on 02/11/20.
//  Copyright © 2020 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>

NS_ASSUME_NONNULL_BEGIN

@interface ReceiveSharingIntent : NSObject <RCTBridgeModule>
+(BOOL)requiresMainQueueSetup;
-(void)getFileName:(NSString *)url resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject;
@end

NS_ASSUME_NONNULL_END
