#import "JCNotificationBanner.h"

@implementation JCNotificationBanner

@synthesize title;
@synthesize message;
@synthesize tapHandler;

- (JCNotificationBanner*) initWithTitle:(NSString*)_title
                                message:(NSString*)_message
                             tapHandler:(JCNotificationBannerTapHandlingBlock)_tapHandler
                                  style:(JCNotificationBannerStyle)style {
  self = [super init];
  if (self) {
    self.title = _title;
    self.message = _message;
    self.tapHandler = _tapHandler;
    self.style = style;
  }
  return self;
}

@end
