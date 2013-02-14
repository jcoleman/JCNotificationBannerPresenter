#import <Foundation/Foundation.h>
#import "JCNotificationBannerWindow.h"
#import "JCNotificationBannerView.h"

@interface JCNotificationBannerPresenter ()

#pragma mark - View helpers
- (JCNotificationBannerWindow*) newWindowForNotification:(JCNotificationBanner*)notification;
- (UIView*) newContainerViewForNotification:(JCNotificationBanner*)notification;
- (JCNotificationBannerView*) newBannerViewForNotification:(JCNotificationBanner*)notification;

@end
