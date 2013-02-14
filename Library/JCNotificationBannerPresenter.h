#import <Foundation/Foundation.h>
#import "JCNotificationBanner.h"

@interface JCNotificationBannerPresenter : NSObject

/** Adds notification to queue with given parameters. */
+ (void) enqueueNotificationWithTitle:(NSString*)title
                              message:(NSString*)message
                           tapHandler:(JCNotificationBannerTapHandlingBlock)tapHandler;

@end
