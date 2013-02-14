#import <Foundation/Foundation.h>
#import "JCNotificationBannerWindow.h"
#import "JCNotificationBannerView.h"

@interface JCNotificationBannerPresenter () {
  @private
  JCNotificationBannerWindow* bannerWindow;
}

- (void)willBeginPresentingNotifications;
- (void)didFinishPresentingNotifications;

#pragma mark - View helpers
- (UIView*) newContainerViewForNotification:(JCNotificationBanner*)notification;
- (JCNotificationBannerWindow*) newWindow;
- (JCNotificationBannerView*) newBannerViewForNotification:(JCNotificationBanner*)notification;

@end
