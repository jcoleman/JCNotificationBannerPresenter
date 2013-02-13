#import <Foundation/Foundation.h>
#import "JCNotificationBanner.h"

@interface JCNotificationBannerPresenter : NSObject

/** Adds notification with iOS banner Style to queue with given parameters. */
+ (void) enqueueNotificationWithTitle:(NSString*)title
                              message:(NSString*)message
                           tapHandler:(JCNotificationBannerTapHandlingBlock)tapHandler;

/** Adds notification to queue with given parameters. */
+ (void) enqueueNotificationWithTitle:(NSString*)title
                              message:(NSString*)message
                                style:(JCNotificationBannerStyle)style
                           tapHandler:(JCNotificationBannerTapHandlingBlock)tapHandler;

@end
