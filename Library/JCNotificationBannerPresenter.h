#import <Foundation/Foundation.h>
#import "JCNotificationBannerView.h"
#import "JCNotificationBanner.h"
#import "JCNotificationBannerWindow.h"
#import "JCNotificationBannerViewController.h"

@interface JCNotificationBannerPresenter : NSObject

/** Adds notification with iOS banner Style to queue with given parameters. */
+ (void) enqueueNotificationWithTitle:(NSString*)title
                              message:(NSString*)message
                           tapHandler:(JCNotificationBannerTapHandlingBlock)tapHandler;

/** Adds notification to queue with given parameters. */
+ (void) enqueueNotificationWithTitle:(NSString*)title
                              message:(NSString*)message
                           tapHandler:(JCNotificationBannerTapHandlingBlock)tapHandler
                                style:(JCNotificationBannerStyle)style;

@end
