#import <Foundation/Foundation.h>
#import "JCNotificationBannerWindow.h"

@interface JCNotificationBannerPresenter () {
  @private
  NSMutableArray* enqueuedNotifications;
  NSLock* isPresentingMutex;
  NSObject* notificationQueueMutex;
  @protected
  JCNotificationBannerWindow* overlayWindow;
  UIViewController* bannerViewController;
}

- (JCNotificationBanner*) dequeueNotification;
- (void) beginPresentingNotifications;
- (void) presentNotification:(JCNotificationBanner*)notification;
- (void) donePresentingNotification:(JCNotificationBanner*)notification;

- (void) enqueueNotificationWithTitle:(NSString*)title
                              message:(NSString*)message
                           tapHandler:(JCNotificationBannerTapHandlingBlock)tapHandler;

@end
