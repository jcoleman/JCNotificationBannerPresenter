#import <Foundation/Foundation.h>
#import "JCNotificationBanner.h"

typedef void (^JCNotificationBannerPresenterFinishedBlock)();

@interface JCNotificationBannerPresenter : NSObject

- (void) presentNotification:(JCNotificationBanner*)notification finished:(JCNotificationBannerPresenterFinishedBlock)finished;

@end
