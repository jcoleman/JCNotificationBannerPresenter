#import "JCNotificationBannerPresenter.h"
#import <QuartzCore/QuartzCore.h>

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

typedef struct CGVector
{
    CGFloat x,y,z;
} CGVector;

CGVector CGVectorMake(CGFloat x, CGFloat y, CGFloat z)
{
    CGVector vec = {x,y,z};
    return vec;
}

@implementation JCNotificationBannerPresenter
    
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
  if ([_delegate respondsToSelector:@selector(shouldCoverStatusBar)]) {
      shouldCoverStatusBar = [[self delegate] shouldCoverStatusBar];
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

  JCNotificationBannerView* banner;
  if ([_delegate respondsToSelector:@selector(makeViewForNotification:)]) {
    banner = [[self delegate] makeViewForNotification:notification];
  } else {
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
  if ([_delegate respondsToSelector:@selector(getStartOpacity)]) {
    startOpacity = [[self delegate] getStartOpacity];
  } else {
    startOpacity = 0;
  }
  double endOpacity;
  if ([_delegate respondsToSelector:@selector(getEndOpacity)]) {
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

    // Prepare view transform
    CALayer *layer = [banner layer];
    banner.alpha = startOpacity;    
    layer.anchorPoint = CGPointMake(0.5f, 0);
    banner.frame = CGRectOffset(banner.frame, 0, banner.frame.size.height * 0.5);
    banner.alpha = endOpacity;
    [self rotateLayer:layer fromAngle: 90 toAngle: 0 duration: animationDuration onCompleted: ^(){} ];

    // Add image of background to layer.
    UIImage *image = [UIImage imageNamed:@"fake.png"];
    CALayer *imageLayer = [CALayer layer];
    imageLayer.anchorPoint = CGPointMake(0.5f, 1);
    imageLayer.frame = banner.frame;
    imageLayer.contents = (id)[image CGImage];
    [self rotateLayer:imageLayer fromAngle: 0 toAngle: 90 duration: animationDuration onCompleted: ^(){} ];
    [[containerView layer] addSublayer:imageLayer];
  // On timeout, slide it up while fading it out.
  double delayInSeconds;
  if ([self delegate] && [[self delegate] respondsToSelector:@selector(getDisplayDurationSeconds)]) {
    delayInSeconds = [[self delegate] getDisplayDurationSeconds];
  } else {
    delayInSeconds = 5.0;
  }
  dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
  dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
      CALayer *layer = [banner layer];
      layer.anchorPoint = CGPointMake(0.5f, 1);
      banner.frame = CGRectOffset(banner.frame, 0, banner.frame.size.height);
      [self rotateLayer:layer fromAngle: 0 toAngle:-90 duration: animationDuration onCompleted:^(){
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

#pragma mark Animation Helpers

- (void) rotateLayer: (CALayer *) imageLayer fromAngle: (CGFloat) fromAngle toAngle: (CGFloat) toAngle duration: (CFTimeInterval) duration onCompleted: (void (^)()) onCompletedBlock
{
    CGFloat fromInRadians = fromAngle * M_PI / 180.0f;
    CGFloat toInRadians = toAngle * M_PI / 180.0f;

    // Create animation that rotates by to the end rotation.
    CABasicAnimation *myAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.x"];
    myAnimation.delegate = self;
    myAnimation.duration = duration;
    myAnimation.fromValue = @(fromInRadians);
    myAnimation.toValue = @(toInRadians);
    myAnimation.fillMode = kCAFillModeForwards;
    myAnimation.removedOnCompletion = NO;
    [myAnimation setValue: imageLayer forKey: @"layer"];
    [myAnimation setValue: [onCompletedBlock copy] forKey: @"onCompleted"];
    [imageLayer addAnimation:myAnimation forKey:@"transform.rotation.x"];
}

typedef void(^simpleCallbackBlock)();

- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag
{
    if(flag) {
        simpleCallbackBlock onCompletedBlock = [theAnimation valueForKey:@"onCompleted"];
        
        if (onCompletedBlock)
            onCompletedBlock();
        
    }
}


@end
