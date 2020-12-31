
#import "SharedMediaFile.h"

@implementation SharedMediaFile
-(instancetype _Nullable)initPath:(NSString *_Nullable)path thumbnail:(NSString *_Nullable)thumbnail duration:(double)duration type:(SharedMediaType)type {
    if (self  = [super init]) {
        self.path = path;
        self.thumbnail = thumbnail;
        self.duration = duration;
        self.type = type;
    }
  
    return self;
}

@end
