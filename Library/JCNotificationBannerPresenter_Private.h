#import <Foundation/Foundation.h>
#import "JCNotificationBannerWindow.h"
#import "JCNotificationBannerView.h"

@interface JCNotificationBannerPresenter () {
  @private
  NSMutableArray* enqueuedNotifications;
  NSLock* isPresentingMutex;
  NSObject* notificationQueueMutex;
}

- (JCNotificationBanner*) dequeueNotification;
- (void) beginPresentingNotifications;
- (void) presentNotification:(JCNotificationBanner*)notification;
- (void) donePresentingNotification:(JCNotificationBanner*)notification;

- (void) enqueueNotificationWithTitle:(NSString*)title
                              message:(NSString*)message
                           tapHandler:(JCNotificationBannerTapHandlingBlock)tapHandler;

#pragma mark - View helpers

- (JCNotificationBannerWindow*) newWindowForNotification:(JCNotificationBanner*)notification;
- (UIView*) newContainerViewForNotification:(JCNotificationBanner*)notification;
- (JCNotificationBannerView*) newBannerViewForNotification:(JCNotificationBanner*)notification;

@end
