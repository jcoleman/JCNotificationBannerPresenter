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
  CGFloat width = 320;
  CGFloat height = 60;
  CGFloat statusBarHeight = (MIN(statusBarSize.width, statusBarSize.height));
  CGFloat x = (MAX(statusBarSize.width, statusBarSize.height) - width) / 2;
  CGFloat y = -60 - ((shouldCoverStatusBar )? statusBarHeight : 0);
  banner.frame = CGRectMake(x, y, width, height);

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

    CGRect bannerFrameAfterTransition = banner.frame;
    bannerFrameAfterTransition.origin.y = 0 + ((!shouldCoverStatusBar )? statusBarHeight : 0);
    UIImage *image = [self captureWindowPartWithRect: bannerFrameAfterTransition];

    // Prepare view transform
    CALayer *layer = [banner layer];
    banner.alpha = startOpacity;
    banner.frame = CGRectOffset(banner.frame, 0, banner.frame.size.height);
    banner.alpha = endOpacity;
    layer.anchorPointZ = 0.5f * banner.frame.size.height;
    [self rotateLayer:layer fromAngle: -90 toAngle: 0 duration: animationDuration onCompleted: ^(){} ];

    // Add image of background to layer.
    CALayer *imageLayer = [CALayer layer];
    imageLayer.frame = banner.frame;
    imageLayer.anchorPointZ = 0.5f * banner.frame.size.height;
    imageLayer.contents = (id)[image CGImage];
    [imageLayer setShadowOffset:CGSizeMake(0, 1)];
    [imageLayer setShadowColor:[[UIColor darkGrayColor] CGColor]];
    [imageLayer setShadowRadius:3.0];
    [imageLayer setShadowOpacity:0.8];
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

      // Add image of background to layer.
      CALayer *imageLayer = [CALayer layer];
      imageLayer.frame =  banner.frame;
      imageLayer.anchorPointZ = 0.5f * banner.frame.size.height;
      imageLayer.contents = (id)[image CGImage];
      [imageLayer setShadowOffset:CGSizeMake(0, 1)];
      [imageLayer setShadowColor:[[UIColor darkGrayColor] CGColor]];
      [imageLayer setShadowRadius:3.0];
      [imageLayer setShadowOpacity:0.8];
      [self rotateLayer:imageLayer fromAngle: -90 toAngle: 0 duration: animationDuration onCompleted: ^(){} ];
      [[containerView layer] addSublayer:imageLayer];

      CALayer *layer = [banner layer];
      [self rotateLayer:layer fromAngle: 0 toAngle:90 duration: animationDuration onCompleted:^(){
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

#pragma mark Screenshot 

/**
 * @returns part of the keyWindow screenshot rotated by 180 degrees.
 */
- (UIImage *) captureWindowPartWithRect: (CGRect) rect
{
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];

    CGRect firstCaptureRect = keyWindow.bounds;
    
    UIGraphicsBeginImageContextWithOptions(firstCaptureRect.size,YES,0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [keyWindow.layer renderInContext:context];
    UIImage *capturedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    CGRect contentRectToCrop = rect;

    CGRect originalRect = rect;
    switch ([UIApplication sharedApplication].statusBarOrientation) {
        case UIInterfaceOrientationLandscapeLeft:
            contentRectToCrop.origin.x = originalRect.origin.y;
            contentRectToCrop.origin.y = keyWindow.bounds.size.height - originalRect.origin.x - originalRect.size.width;
            contentRectToCrop.size.width = originalRect.size.height;
            contentRectToCrop.size.height = originalRect.size.width;
            break;

        case UIInterfaceOrientationLandscapeRight:
            contentRectToCrop.origin.x = keyWindow.bounds.size.width - originalRect.origin.y - originalRect.size.height;
            contentRectToCrop.origin.y = keyWindow.bounds.size.height - originalRect.origin.x - originalRect.size.width ;
            contentRectToCrop.size.width = originalRect.size.height;
            contentRectToCrop.size.height = originalRect.size.width;
            break;

        case UIInterfaceOrientationPortrait:
            break;

        case UIInterfaceOrientationPortraitUpsideDown:
            break;

        default:
            break;
    }

    contentRectToCrop.origin.x *= capturedImage.scale;
    contentRectToCrop.origin.y *= capturedImage.scale;
    contentRectToCrop.size.width *= capturedImage.scale;
    contentRectToCrop.size.height *= capturedImage.scale;

    CGImageRef imageRef = CGImageCreateWithImageInRect([capturedImage CGImage], contentRectToCrop);
    UIImage *croppedImage = [UIImage imageWithCGImage:imageRef scale:capturedImage.scale orientation: [[UIApplication sharedApplication] statusBarOrientation]];

    // Uncomment this to save image in documents for debugging.
//    
    NSString *imagePath = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/capturedImage.jpg"]];
    [UIImageJPEGRepresentation(capturedImage, 0.95) writeToFile:imagePath atomically:YES];

    imagePath = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/croppedImage.jpg"]];
    [UIImageJPEGRepresentation(croppedImage, 0.95) writeToFile:imagePath atomically:YES];

    return croppedImage;
}

@end
