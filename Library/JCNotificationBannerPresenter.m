#import "JCNotificationBannerPresenter.h"
#import "JCNotificationBannerPresenter_Private.h"
#import "JCNotificationBannerPresenterIOSStyle.h"
#import "JCNotificationBannerViewIOSStyle.h"
#import "JCNotificationBannerView.h"
#import "JCNotificationBannerWindow.h"
#import "JCNotificationBannerViewController.h"
#import <QuartzCore/QuartzCore.h>

@implementation JCNotificationBannerPresenter

- (void) presentNotification:(JCNotificationBanner*)notification
                    finished:(JCNotificationBannerPresenterFinishedBlock)finished {
  // Abstract. Override this and call finished() whenever you are
  // done showing the notification.
}

#pragma mark - View helpers

- (JCNotificationBannerWindow*) newWindowForNotification:(JCNotificationBanner*)notification {
  JCNotificationBannerWindow* window = [[JCNotificationBannerWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  window.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  window.userInteractionEnabled = YES;
  window.autoresizesSubviews = YES;
  window.opaque = NO;
  window.hidden = NO;
  return window;
}

- (UIView*) newContainerViewForNotification:(JCNotificationBanner*)notification {
  UIView* container = [UIView new];
  container.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  container.userInteractionEnabled = YES;
  container.opaque = NO;
  return container;
}

- (JCNotificationBannerView*) newBannerViewForNotification:(JCNotificationBanner*)notification {
  JCNotificationBannerView* view = [[JCNotificationBannerView alloc]
                                    initWithNotification:notification];
  view.userInteractionEnabled = YES;
  view.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin
                        | UIViewAutoresizingFlexibleLeftMargin
                        | UIViewAutoresizingFlexibleRightMargin;
  return view;
}

@end
