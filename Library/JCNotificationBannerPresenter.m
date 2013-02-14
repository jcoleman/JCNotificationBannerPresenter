#import "JCNotificationBannerPresenter.h"
#import "JCNotificationBannerPresenter_Private.h"
#import "JCNotificationBannerPresenterIOSStyle.h"
#import "JCNotificationBannerViewIOSStyle.h"
#import "JCNotificationBannerView.h"
#import "JCNotificationBannerWindow.h"
#import "JCNotificationBannerViewController.h"
#import <QuartzCore/QuartzCore.h>

typedef struct CGVector {
  CGFloat x,y,z;
} CGVector;

CGVector CGVectorMake(CGFloat x, CGFloat y, CGFloat z) {
  CGVector vec = {x,y,z};
  return vec;
}

@implementation JCNotificationBannerPresenter
    
+ (JCNotificationBannerPresenter*) sharedPresenter {
  static JCNotificationBannerPresenter* sharedPresenter = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    // Use the iOS style by default
    sharedPresenter = [JCNotificationBannerPresenterIOSStyle new];
  });
  return sharedPresenter;
}

- (JCNotificationBannerPresenter*) init {
  self = [super init];
  if (self) {
    enqueuedNotifications = [NSMutableArray new];
    isPresentingMutex = [NSLock new];
    notificationQueueMutex = [NSObject new];
  }
  return self;
}

/** Adds notification with iOS banner Style to queue with given parameters. */
+ (void) enqueueNotificationWithTitle:(NSString*)title
                              message:(NSString*)message
                           tapHandler:(JCNotificationBannerTapHandlingBlock)tapHandler {
  [[self sharedPresenter] enqueueNotificationWithTitle:title
                                               message:message
                                            tapHandler:tapHandler];
}

- (void) enqueueNotificationWithTitle:(NSString*)title
                              message:(NSString*)message
                           tapHandler:(JCNotificationBannerTapHandlingBlock)tapHandler {
  JCNotificationBanner* notification = [[JCNotificationBanner alloc]
                                        initWithTitle:title
                                        message:message
                                        tapHandler:tapHandler];
  @synchronized(notificationQueueMutex) {
    [enqueuedNotifications addObject:notification];
  }
  [self beginPresentingNotifications];
}

- (JCNotificationBanner*) dequeueNotification {
  JCNotificationBanner* notification;
  @synchronized(notificationQueueMutex) {
    if ([enqueuedNotifications count] > 0) {
      notification = [enqueuedNotifications objectAtIndex:0];
      [enqueuedNotifications removeObjectAtIndex:0];
    }
  }
  return notification;
}

- (void) beginPresentingNotifications {
  dispatch_async(dispatch_get_main_queue(), ^{
    if ([isPresentingMutex tryLock]) {
      JCNotificationBanner* nextNotification = [self dequeueNotification];
      if (nextNotification) {
        [self presentNotification:nextNotification];
      } else {
        [isPresentingMutex unlock];
      }
    } else {
      // Notification presentation already in progress; do nothing.
    }
  });
}

- (void) presentNotification:(JCNotificationBanner*)notification {
  // Abstract. Subclass and override. Make sure you call this when
  // you are finished showing the notification:
  [self donePresentingNotification:notification];
}

- (void) donePresentingNotification:(JCNotificationBanner*)notification {
  // Process any notifications enqueued during this one's presentation.
  [isPresentingMutex unlock];
  [self beginPresentingNotifications];
}

@end
