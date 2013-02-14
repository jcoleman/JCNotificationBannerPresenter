#import "JCNotificationBannerPresenterAndroidStyle.h"
#import "JCNotificationBannerPresenter_Private.h"
#import "JCNotificationBannerView.h"
#import "JCNotificationBannerViewController.h"

@implementation JCNotificationBannerPresenterAndroidStyle

- (id) init {
  if (self = [super init]) {
    self.minimumHorizontalMargin = 10.0;
    self.bannerMaxWidth = 350.0;
    self.bannerHeight = 60.0;
  }
  return self;
}

- (void) presentNotification:(JCNotificationBanner *)notification
                    finished:(JCNotificationBannerPresenterFinishedBlock)finished {
  JCNotificationBannerWindow* overlayWindow = [self newWindowForNotification:notification];

  JCNotificationBannerView* banner = [self newBannerViewForNotification:notification];

  JCNotificationBannerViewController* bannerViewController = [JCNotificationBannerViewController new];
  overlayWindow.rootViewController = bannerViewController;

  UIView* containerView = [self newContainerViewForNotification:notification];

  overlayWindow.bannerView = banner;

  [containerView addSubview:banner];
  bannerViewController.view = containerView;

  UIView* view = ((UIView*)[[[[UIApplication sharedApplication] keyWindow] subviews] objectAtIndex:0]);
  containerView.bounds = view.bounds;
  containerView.transform = view.transform;
  [banner getCurrentPresentingStateAndAtomicallySetPresentingState:YES];

  CGSize statusBarSize = [[UIApplication sharedApplication] statusBarFrame].size;
  // Make the banner fill the width of the screen, minus any requested margins,
  // up to self.bannerMaxWidth.
  CGSize bannerSize = CGSizeMake(MIN(self.bannerMaxWidth, view.bounds.size.width - self.minimumHorizontalMargin * 2.0), self.bannerHeight);
  // Center the banner horizontally.
  CGFloat x = (MAX(statusBarSize.width, statusBarSize.height) / 2) - (bannerSize.width / 2);
  // Position the banner offscreen vertically.
  CGFloat y = -self.bannerHeight - (MIN(statusBarSize.width, statusBarSize.height));
  banner.frame = CGRectMake(x, y, bannerSize.width, bannerSize.height);

  JCNotificationBannerTapHandlingBlock originalTapHandler = banner.notificationBanner.tapHandler;
  JCNotificationBannerTapHandlingBlock wrappingTapHandler = ^{
    if ([banner getCurrentPresentingStateAndAtomicallySetPresentingState:NO]) {
      if (originalTapHandler) {
        originalTapHandler();
      }

      [banner removeFromSuperview];
      overlayWindow.rootViewController = nil;
      [overlayWindow removeFromSuperview];
      finished();
    }
  };
  banner.notificationBanner.tapHandler = wrappingTapHandler;

  // Slide it down while fading it in.
  banner.alpha = 0;
  [UIView animateWithDuration:0.5 delay:0
                      options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseOut
                   animations:^{
                     CGRect newFrame = CGRectOffset(banner.frame, 0, banner.frame.size.height);
                     banner.frame = newFrame;
                     banner.alpha = 0.9;
                   } completion:^(BOOL finished) {
                     // Empty.
                   }];


  // On timeout, slide it up while fading it out.
  double delayInSeconds = 5.0;
  dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
  dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
    [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                       banner.frame = CGRectOffset(banner.frame, 0, -banner.frame.size.height);
                       banner.alpha = 0;
                     } completion:^(BOOL didFinish) {
                       if ([banner getCurrentPresentingStateAndAtomicallySetPresentingState:NO]) {
                         [banner removeFromSuperview];
                         overlayWindow.rootViewController = nil;
                         [overlayWindow removeFromSuperview];

                         finished();
                       }
                     }];
  });
}

#pragma mark - View helpers

- (JCNotificationBannerWindow*) newWindowForNotification:(JCNotificationBanner*)notification {
  JCNotificationBannerWindow* window = [super newWindowForNotification:notification];
  window.windowLevel = UIWindowLevelStatusBar;
  return window;
}

@end
