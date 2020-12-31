@import UIKit;
@import Photos;
@import Foundation;

#import "ReceiveSharingIntent.h"
#import "SharedMediaFile.h"

@interface ReceiveSharingIntent()

@property (strong,nullable) NSMutableArray<SharedMediaFile *> *initialMedia;
@property (strong,nullable) NSMutableArray<SharedMediaFile *> *latestMedia;
@property (strong,nullable) NSString *initialText;
@property (strong,nullable) NSString *latestText;

@end

@implementation ReceiveSharingIntent
+(BOOL)requiresMainQueueSetup {
    return true;
}

-(NSString * _Nullable)_getAbsolutePathForIdentifier:(NSString *)identifier {
    if ([identifier hasPrefix:@"file://"] ||
        [identifier hasPrefix:@"/var/mobile/Media"] ||
        [identifier hasPrefix:@"/private/var/mobile"])
    {
        return [identifier stringByReplacingOccurrencesOfString:@"file://" withString:@""];
    }
    
    PHAsset *phAsset = [[PHAsset fetchAssetsWithLocalIdentifiers:@[identifier] options: nil] firstObject];
    if (phAsset == nil) {
        return nil;
    }
    return [self _getFullSizeImageURLAndOrientationForAsset:phAsset];
}

-(NSString * _Nullable)_getFullSizeImageURLAndOrientationForAsset:(PHAsset *)asset {
    __block NSString * url = nil;
    __block NSInteger orientation = 0;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    PHContentEditingInputRequestOptions *options2 = [PHContentEditingInputRequestOptions new];
    options2.networkAccessAllowed = true;
    [asset requestContentEditingInputWithOptions:options2 completionHandler:^(PHContentEditingInput * _Nullable contentEditingInput, NSDictionary * _Nonnull info) {
        orientation = [contentEditingInput fullSizeImageOrientation];
        url = [[contentEditingInput fullSizeImageURL] path];
        dispatch_semaphore_signal(semaphore);
    }];
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return url;
}

-(void)getFileName:(NSString *)url resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject {
    NSURL *fileURL = [NSURL URLWithString:url];
    NSString *json = [self _handleUrl:fileURL];
    if ([json isEqualToString: @"error"]) {
        NSError *error = [[NSError alloc] initWithDomain:@"" code:400 userInfo:nil];
        reject(@"message", @"file type is Invalid", error);
    } else if([json isEqualToString:@"invalid group name"]) {
        NSError *error = [[NSError alloc] initWithDomain:@"" code:400 userInfo:nil];
        reject(@"message", @"invalid group name. Please check your share extention bundle name is same as `group.mainbundle name`  ", error);
    } else {
        resolve(json);
    }
}

-(NSString * _Nullable)_handleUrl:(NSURL *)url {
    if (url != nil) {
        NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
        NSString *suiteName = [NSString stringWithFormat:@"group.%@", appDomain];
        NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:suiteName];
        
        if ([url.fragment isEqualToString:@"media"]) {
            NSString *key = [[url.host componentsSeparatedByString:@"="] lastObject];
            NSData *json = (NSData *)[userDefaults objectForKey: key];
            if (key != nil && json != nil) {
                NSArray <SharedMediaFile*> *sharedArray = [self _decode:json];
                NSMutableArray<SharedMediaFile *> *sharedMediaFiles = [[NSMutableArray alloc] init];
                for (SharedMediaFile *mediaFile in sharedArray) {
                    if (mediaFile.path != nil) {
                        if (mediaFile.type == SharedMediaType_video && mediaFile.thumbnail != nil) {
                            NSString *thumbnail = [self _getAbsolutePathForIdentifier:mediaFile.thumbnail];
                            SharedMediaFile *tmpObject = [[SharedMediaFile alloc] initPath:mediaFile.path thumbnail:thumbnail duration:mediaFile.duration type:mediaFile.type];
                            [sharedMediaFiles addObject:tmpObject];
                        } else if (mediaFile.type == SharedMediaType_video && mediaFile.thumbnail == nil) {
                            SharedMediaFile *tmpObject = [[SharedMediaFile alloc] initPath:mediaFile.path thumbnail: nil duration:mediaFile.duration type:mediaFile.type];
                            [sharedMediaFiles addObject:tmpObject];
                        } else {
                            NSString *path = [self _getAbsolutePathForIdentifier:mediaFile.path];
                            SharedMediaFile *tmpObject = [[SharedMediaFile alloc] initPath:path thumbnail: nil duration:mediaFile.duration type:mediaFile.type];
                            [sharedMediaFiles addObject:tmpObject];
                        }
                    }
                }
                self.latestMedia = sharedMediaFiles;
            }
            NSString * jsonString = [self _toJson:self.latestMedia];
            return jsonString;
        }
        
        if ([url.fragment isEqualToString:@"file"]) {
            NSString *key = [[url.host componentsSeparatedByString:@"="] lastObject];
            NSData *json = (NSData *)[userDefaults objectForKey: key];
            if (key != nil && json != nil) {
                NSArray <SharedMediaFile*> *sharedArray = [self _decode:json];
                NSMutableArray<SharedMediaFile *> *sharedMediaFiles = [[NSMutableArray alloc] init];
                for (SharedMediaFile *mediaFile in sharedArray) {
                    if ([self _getAbsolutePathForIdentifier:mediaFile.path] != nil) {
                        SharedMediaFile *tmpObj = [[SharedMediaFile alloc] initPath:mediaFile.path thumbnail:nil duration:-1 type:mediaFile.type];
                        [sharedMediaFiles addObject:tmpObj];
                    }
                }
                self.latestMedia = sharedMediaFiles;
            }
            NSString * jsonString = [self _toJson:self.latestMedia];
            return jsonString;
        }
        
        if ([url.fragment isEqualToString:@"text"]) {
            NSString *key = [[url.host componentsSeparatedByString:@"="] lastObject];
            NSArray <NSString *> *sharedArray = (NSArray <NSString *> *)[userDefaults arrayForKey:key];
            if (key != nil && sharedArray != nil) {
                self.latestText = [sharedArray componentsJoinedByString:@","];
                if (self.latestText != nil) {
                    return [@"text:" stringByAppendingString:self.latestText];
                }
                return self.latestText;
            }
        } else {
            self.latestText = [url absoluteString];
            if (self.latestText != nil) {
                return [@"webUrl:" stringByAppendingString:self.latestText];
            }
        }
        return @"error";
    }
    
    return @"invalid group name";
}

-(NSArray<SharedMediaFile *> *)_decode:(NSData *)data {
    NSMutableArray <SharedMediaFile *> *mediaFileArray = [[NSMutableArray alloc] init];
    
    NSArray <NSDictionary<NSString *, id>*>*arrayOfDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
    for (NSDictionary<NSString *, id> *dict in arrayOfDict) {
        SharedMediaFile *tmpObj = [[SharedMediaFile alloc] initPath:dict[@"path"] thumbnail:dict[@"thumbnail"] duration:[dict[@"duration"] doubleValue] type: (SharedMediaType)[dict[@"type"] integerValue]];
        [mediaFileArray addObject: tmpObj];
    }
    
    return mediaFileArray;
}

-(NSString * _Nullable)_toJson:(NSArray<SharedMediaFile*> *)mediaFiles {
    if (mediaFiles == nil) {
        return nil;
    }
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:mediaFiles options:NSJSONWritingPrettyPrinted error:nil];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

@end
