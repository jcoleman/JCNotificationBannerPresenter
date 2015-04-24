#import <Foundation/Foundation.h>
#import "JCNotificationBannerWindow.h"
#import "JCNotificationBannerView.h"

static const CGFloat kJCNotificationStandardStatusBarHeight = 20.0;

@interface JCNotificationBannerPresenter () {
  @private
  JCNotificationBannerWindow* bannerWindow;
}

- (void) presentNotification:(JCNotificationBanner*)notification
                    inWindow:(JCNotificationBannerWindow*)window
                    finished:(JCNotificationBannerPresenterFinishedBlock)finished;

#pragma mark - View helpers
- (UIView*) newContainerViewForNotification:(JCNotificationBanner*)notification;
- (JCNotificationBannerWindow*) newWindow;
- (JCNotificationBannerView*) newBannerViewForNotification:(JCNotificationBanner*)notification;

@end
