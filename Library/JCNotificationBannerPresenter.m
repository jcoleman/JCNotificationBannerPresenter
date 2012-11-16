#import "JCNotificationBannerPresenter.h"

@interface JCNotificationBannerPresenter () {
  NSMutableArray* enqueuedNotifications;
  NSLock* isPresentingMutex;
  NSObject* notificationQueueMutex;
  JCNotificationBannerWindow* overlayWindow;
  UIViewController* bannerViewController;
}

- (JCNotificationBanner*) dequeueNotification;
- (void) beginPresentingNotifications;
- (void) presentNotification:(JCNotificationBanner*)notification;

@end

@implementation JCNotificationBannerPresenter

@synthesize delegate;
    
+ (JCNotificationBannerPresenter*) sharedPresenter {
  static JCNotificationBannerPresenter* sharedPresenter = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedPresenter = [JCNotificationBannerPresenter new];
  });
  return sharedPresenter;
}

+ (void) enqueueNotificationWithTitle:(NSString*)title
                              message:(NSString*)message
                           tapHandler:(JCNotificationBannerTapHandlingBlock)tapHandler {
  [[JCNotificationBannerPresenter sharedPresenter] enqueueNotificationWithTitle:title
                                                                        message:message
                                                                     tapHandler:tapHandler];
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

- (void) enqueueNotificationWithTitle:(NSString*)title
                       message:(NSString*)message
                    tapHandler:(JCNotificationBannerTapHandlingBlock)tapHandler {
  JCNotificationBanner* notification = [[JCNotificationBanner alloc] initWithTitle:title
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
    
  BOOL shouldCoverStatusBar = YES;
  if ([self delegate] && [[self delegate] respondsToSelector:@selector(shouldCoverStatusBar)]) {
      NSLog(@"using delegate for shouldCoverStatusBar");
    shouldCoverStatusBar = [[self delegate] shouldCoverStatusBar];
  } else {
      NSLog(@"not using %@", self.delegate);
  }

  overlayWindow = [[JCNotificationBannerWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  overlayWindow.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  overlayWindow.userInteractionEnabled = YES;
  overlayWindow.autoresizesSubviews = YES;
  overlayWindow.opaque = NO;
  overlayWindow.hidden = NO;
  if (shouldCoverStatusBar) {
    overlayWindow.windowLevel = UIWindowLevelStatusBar;
  }

  NSLog(@"my protocol is %@", [self delegate]);
  JCNotificationBannerView* banner;
  if ([self delegate] && [[self delegate] respondsToSelector:@selector(makeViewForNotification:)]) {
       NSLog(@"using delegate for makeViewForNotification");
    banner = [[self delegate] makeViewForNotification:notification];
  } else {
      NSLog(@"not using %@", self.delegate);
    banner = [[JCNotificationBannerView alloc] initWithNotification: notification];
  }
  banner.userInteractionEnabled = YES;
//banner.autoresizingMask = UIViewAutoresizingFlexibleWidth;

  bannerViewController = [JCNotificationBannerViewController new];
  overlayWindow.rootViewController = bannerViewController;

  UIView* containerView = [UIView new];
  containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  containerView.userInteractionEnabled = YES;
  containerView.autoresizesSubviews = YES;
  containerView.opaque = NO;

  overlayWindow.bannerView = banner;

  [containerView addSubview:banner];
  bannerViewController.view = containerView;

 banner.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin
                            | UIViewAutoresizingFlexibleLeftMargin
                            | UIViewAutoresizingFlexibleRightMargin;

  UIView* view = ((UIView*)[[[[UIApplication sharedApplication] keyWindow] subviews] objectAtIndex:0]);
  containerView.bounds = view.bounds;
  containerView.transform = view.transform;
  [banner getCurrentPresentingStateAndAtomicallySetPresentingState:YES];
    
  CGSize statusBarSize = [[UIApplication sharedApplication] statusBarFrame].size;
  CGFloat width = 340;
  CGFloat x = (MAX(statusBarSize.width, statusBarSize.height) - width) / 2;
  CGFloat y = -60 - (MIN(statusBarSize.width, statusBarSize.height));
  if (!shouldCoverStatusBar) {
    y += MIN(statusBarSize.height, statusBarSize.width);
  }
  banner.frame = CGRectMake(x, y, 340, 60);

  JCNotificationBannerTapHandlingBlock originalTapHandler = notification.tapHandler;
  JCNotificationBannerTapHandlingBlock wrappingTapHandler = ^{
    if ([banner getCurrentPresentingStateAndAtomicallySetPresentingState:NO]) {
      if (originalTapHandler) {
        originalTapHandler();
      }

      [banner removeFromSuperview];
      [overlayWindow removeFromSuperview];
      overlayWindow = nil;

      // Process any notifications enqueued during this one's presentation.
      [isPresentingMutex unlock];
      [self beginPresentingNotifications];
    }
  };
  notification.tapHandler = wrappingTapHandler;

  double startOpacity;
  if ([self delegate] && [[self delegate] respondsToSelector:@selector(getStartOpacity)]) {
    startOpacity = [[self delegate] getStartOpacity];
  } else {
    startOpacity = 0;
  }
  double endOpacity;
  if ([self delegate] && [[self delegate] respondsToSelector:@selector(getEndOpacity)]) {
    endOpacity = [[self delegate] getEndOpacity];
  } else {
    endOpacity = 0.9;
  }
  double animationDuration;
  if ([self delegate] && [[self delegate] respondsToSelector:@selector(getAnimationDurationSeconds)]) {
    animationDuration = [[self delegate] getAnimationDurationSeconds];
  } else {
    animationDuration = 0.5;
  }
    
  // Slide it down while fading it in.
  banner.alpha = startOpacity;    
  [UIView animateWithDuration:animationDuration delay:0
                      options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseOut
                   animations:^{
                     CGRect newFrame = CGRectOffset(banner.frame, 0, banner.frame.size.height);
                     banner.frame = newFrame;
                     banner.alpha = endOpacity;
                   } completion:^(BOOL finished) {
                     // Empty.
                   }];


  // On timeout, slide it up while fading it out.
  double delayInSeconds;
  if ([self delegate] && [[self delegate] respondsToSelector:@selector(getDisplayDurationSeconds)]) {
    delayInSeconds = [[self delegate] getDisplayDurationSeconds];
  } else {
    delayInSeconds = 5.0;
  }
  dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
  dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
    [UIView animateWithDuration:animationDuration delay:0 options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                       banner.frame = CGRectOffset(banner.frame, 0, -banner.frame.size.height);
                       banner.alpha = startOpacity;
                     } completion:^(BOOL finished) {
                       if ([banner getCurrentPresentingStateAndAtomicallySetPresentingState:NO]) {
                         [banner removeFromSuperview];
                         [overlayWindow removeFromSuperview];
                         overlayWindow = nil;

                         // Process any notifications enqueued during this one's presentation.
                         [isPresentingMutex unlock];
                         [self beginPresentingNotifications];
                       }
                     }];
  });
}


@end
