#import "JCNotificationBannerPresenter.h"
#import "JCNotificationBannerViewIOSStyle.h"
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
- (void) enqueueNotificationWithTitle:(NSString*)title
                              message:(NSString*)message
                           tapHandler:(JCNotificationBannerTapHandlingBlock)tapHandler
                                style:(JCNotificationBannerStyle) style;

@end

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
    sharedPresenter = [JCNotificationBannerPresenter new];
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
  [[self sharedPresenter] enqueueNotificationWithTitle: title
                                               message: message
                                            tapHandler: tapHandler
                                                 style: kJCNotificationBannerPresenterStyleIOSBanner];
}

/** Adds notification to queue with given parameters. */
+ (void) enqueueNotificationWithTitle:(NSString*)title
                              message:(NSString*)message
                           tapHandler:(JCNotificationBannerTapHandlingBlock)tapHandler
                                style:(JCNotificationBannerStyle)style
{
  [[self sharedPresenter] enqueueNotificationWithTitle: title
                                               message: message
                                            tapHandler: tapHandler
                                                 style: style ];
}

- (void) enqueueNotificationWithTitle:(NSString*)title
                       message:(NSString*)message
                    tapHandler:(JCNotificationBannerTapHandlingBlock)tapHandler
                         style:(JCNotificationBannerStyle) style {
  JCNotificationBanner* notification = [[JCNotificationBanner alloc] initWithTitle:title
                                                                           message:message
                                                                        tapHandler:tapHandler
                                                                             style:style];
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

- (void) presentNotification:(JCNotificationBanner*)notification
{
  switch (notification.style) {
    case kJCNotificationBannerPresenterStyleAndroidToast:
      [self presentNotificationAndroidStyle: notification];
      break;
    case kJCNotificationBannerPresenterStyleIOSBanner:
      [self presentNotificationIOSStyle: notification];
    default:
      break;
  }
}

- (void) presentNotificationAndroidStyle:(JCNotificationBanner*)notification {
    overlayWindow = [[JCNotificationBannerWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    overlayWindow.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    overlayWindow.userInteractionEnabled = YES;
    overlayWindow.opaque = NO;
    overlayWindow.hidden = NO;
    overlayWindow.windowLevel = UIWindowLevelStatusBar;

    JCNotificationBannerView* banner = [[JCNotificationBannerView alloc] initWithNotification:notification];
    banner.userInteractionEnabled = YES;

    bannerViewController = [JCNotificationBannerViewController new];
    overlayWindow.rootViewController = bannerViewController;

    UIView* containerView = [UIView new];
    containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    containerView.userInteractionEnabled = YES;
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
    CGFloat x = (MAX(statusBarSize.width, statusBarSize.height) / 2) - (350 / 2);
    CGFloat y = -60 - (MIN(statusBarSize.width, statusBarSize.height));
    banner.frame = CGRectMake(x, y, 350, 60);

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

- (void) presentNotificationIOSStyle:(JCNotificationBanner*)notification {
  overlayWindow = [[JCNotificationBannerWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  overlayWindow.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  overlayWindow.userInteractionEnabled = YES;
  overlayWindow.autoresizesSubviews = YES;
  overlayWindow.opaque = NO;
  overlayWindow.hidden = NO;

  JCNotificationBannerView* banner = [[JCNotificationBannerViewIOSStyle alloc] initWithNotification:notification];
  banner.userInteractionEnabled = YES;

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

  UIView* view = [[[[UIApplication sharedApplication] keyWindow] subviews] objectAtIndex:0];
  containerView.bounds = view.bounds;
  containerView.transform = view.transform;
  [banner getCurrentPresentingStateAndAtomicallySetPresentingState:YES];
    
  CGSize statusBarSize = [[UIApplication sharedApplication] statusBarFrame].size;
  CGFloat width = 320.0;
  CGFloat height = 60.0;
  CGFloat x = (MAX(statusBarSize.width, statusBarSize.height) - width) / 2.0;
  CGFloat y = -60.0;
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

  double startOpacity = 1.0;
  double endOpacity = 1.0;
  double animationDuration = 0.5;

  CGRect bannerFrameAfterTransition = banner.frame;
  bannerFrameAfterTransition.origin.y = MIN(statusBarSize.width, statusBarSize.height);
  UIImage *image = [self captureWindowPartWithRect: bannerFrameAfterTransition];

  // Prepare view transform
  CALayer* layer = banner.layer;
  banner.alpha = startOpacity;
  banner.frame = CGRectOffset(banner.frame, 0, banner.frame.size.height);
  banner.alpha = endOpacity;
  layer.anchorPointZ = 0.5f * banner.frame.size.height;
  [self rotateLayer:layer fromAngle:-90.0 toAngle:0.0 duration:animationDuration onCompleted:^(){}];

  // Add image of background to layer.
  CALayer* imageLayer = [CALayer layer];
  imageLayer.frame = banner.frame;
  imageLayer.anchorPointZ = 0.5f * banner.frame.size.height;
  imageLayer.contents = (id)image.CGImage;
  imageLayer.shadowOffset = CGSizeMake(0, 1);
  imageLayer.shadowColor = [UIColor darkGrayColor].CGColor;
  imageLayer.shadowRadius = 3.0;
  imageLayer.shadowOpacity = 0.8;
  [self rotateLayer:imageLayer fromAngle: 0 toAngle: 90 duration: animationDuration onCompleted: ^(){} ];
  [containerView.layer addSublayer:imageLayer];

  // On timeout, slide it up while fading it out.
  double delayInSeconds = 5.0;
  dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
  dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
    // Add image of background to layer.
    CALayer* imageLayer = [CALayer layer];
    imageLayer.frame =  banner.frame;
    imageLayer.anchorPointZ = 0.5f * banner.frame.size.height;
    imageLayer.contents = (id)image.CGImage;
    imageLayer.shadowOffset = CGSizeMake(0, 1);
    imageLayer.shadowColor = [UIColor darkGrayColor].CGColor;
    imageLayer.shadowRadius = 3.0;
    imageLayer.shadowOpacity = 0.8;
    [self rotateLayer:imageLayer fromAngle: -90 toAngle: 0 duration: animationDuration onCompleted: ^(){} ];
    [[containerView layer] addSublayer:imageLayer];

    CALayer* layer = [banner layer];
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

#pragma mark - Animation Helpers

- (void) rotateLayer:(CALayer*)imageLayer
           fromAngle:(CGFloat)fromAngle
             toAngle:(CGFloat)toAngle
            duration:(CFTimeInterval)duration
         onCompleted:(void (^)())onCompletedBlock {
  CGFloat fromInRadians = fromAngle * M_PI / 180.0f;
  CGFloat toInRadians = toAngle * M_PI / 180.0f;

  // Create animation that rotates by to the end rotation.
  CABasicAnimation* animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.x"];
  animation.delegate = self;
  animation.duration = duration;
  animation.fromValue = @(fromInRadians);
  animation.toValue = @(toInRadians);
  animation.fillMode = kCAFillModeForwards;
  animation.removedOnCompletion = NO;
  [animation setValue:imageLayer forKey:@"layer"];
  [animation setValue:[onCompletedBlock copy] forKey:@"onCompleted"];
  [imageLayer addAnimation:animation forKey:@"transform.rotation.x"];
}

- (void)animationDidStop:(CAAnimation*)animation finished:(BOOL)finished {
  if (finished) {
    void(^onCompletedBlock)() = [animation valueForKey:@"onCompleted"];
    if (onCompletedBlock)
      onCompletedBlock();
    }
}

#pragma mark - Screenshot 

/**
 * @returns part of the keyWindow screenshot rotated by 180 degrees.
 */
- (UIImage*) captureWindowPartWithRect:(CGRect)rect {
  UIWindow* keyWindow = [[UIApplication sharedApplication] keyWindow];

  CGRect firstCaptureRect = keyWindow.bounds;

  UIGraphicsBeginImageContextWithOptions(firstCaptureRect.size,YES,0.0f);
  CGContextRef context = UIGraphicsGetCurrentContext();
  [keyWindow.layer renderInContext:context];
  UIImage* capturedImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();

  CGRect contentRectToCrop = rect;
  CGFloat rotationNeeded = 0;
  CGRect originalRect = rect;
  switch ([UIApplication sharedApplication].statusBarOrientation) {
    case UIInterfaceOrientationLandscapeLeft:
      rotationNeeded = 90;
      contentRectToCrop.origin.x = originalRect.origin.y;
      contentRectToCrop.origin.y = keyWindow.bounds.size.height - originalRect.origin.x - originalRect.size.width;
      contentRectToCrop.size.width = originalRect.size.height;
      contentRectToCrop.size.height = originalRect.size.width;
      break;

    case UIInterfaceOrientationLandscapeRight:
      rotationNeeded = -90;
      contentRectToCrop.origin.x = keyWindow.bounds.size.width - originalRect.origin.y - originalRect.size.height;
      contentRectToCrop.origin.y = keyWindow.bounds.size.height - originalRect.origin.x - originalRect.size.width ;
      contentRectToCrop.size.width = originalRect.size.height;
      contentRectToCrop.size.height = originalRect.size.width;
      break;

    case UIInterfaceOrientationPortrait:
      break;

    case UIInterfaceOrientationPortraitUpsideDown:
      rotationNeeded = 180;
      contentRectToCrop.origin.x = originalRect.origin.x;
      contentRectToCrop.origin.y = keyWindow.bounds.size.height - originalRect.origin.y - originalRect.size.height;
      contentRectToCrop.size.width = originalRect.size.width;
      contentRectToCrop.size.height = originalRect.size.height;
      break;
  }

  contentRectToCrop.origin.x *= capturedImage.scale;
  contentRectToCrop.origin.y *= capturedImage.scale;
  contentRectToCrop.size.width *= capturedImage.scale;
  contentRectToCrop.size.height *= capturedImage.scale;

  CGImageRef imageRef = CGImageCreateWithImageInRect([capturedImage CGImage], contentRectToCrop);
  UIImage* croppedImage = [UIImage imageWithCGImage:imageRef scale:capturedImage.scale orientation: UIImageOrientationUp];
  CGImageRelease(imageRef);

  if (rotationNeeded) {
    croppedImage = [JCNotificationBannerPresenter rotateImage:croppedImage byDegrees:rotationNeeded];
  }

  return croppedImage;
}

// -----------------------------------------------------------------------
// UIImage Extensions for preparing screenshots under banner by HardyMacia
// (Catamount Software).
// http://www.catamount.com/forums/viewtopic.php?f=21&t=967

CGFloat DegreesToRadians(CGFloat degrees) { return degrees * M_PI / 180.0; };
CGFloat RadiansToDegrees(CGFloat radians) { return radians * 180.0 / M_PI; };

+ (UIImage*) rotateImage:(UIImage*)image byDegrees:(CGFloat)degrees {
  // Calculate the size of the rotated view's containing box for our drawing space
  UIView* rotatedViewBox = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, image.size.width, image.size.height)];
  CGAffineTransform transform = CGAffineTransformMakeRotation(DegreesToRadians(degrees));
  rotatedViewBox.transform = transform;
  CGSize rotatedSize = rotatedViewBox.frame.size;

  // Create the bitmap context
  UIGraphicsBeginImageContext(rotatedSize);
  CGContextRef bitmap = UIGraphicsGetCurrentContext();

  // Move the origin to the middle of the image so we will rotate and scale around the center.
  CGContextTranslateCTM(bitmap, rotatedSize.width/2, rotatedSize.height/2);

  // Rotate the image context
  CGContextRotateCTM(bitmap, DegreesToRadians(degrees));

  // Now, draw the rotated/scaled image into the context
  CGContextScaleCTM(bitmap, 1.0, -1.0);
  CGRect imageRect = CGRectMake(-image.size.width / 2.0, -image.size.height / 2.0, image.size.width, image.size.height);
  CGContextDrawImage(bitmap, imageRect, image.CGImage);

  UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();

  return newImage;
}

// -----------------------------------------------------------------------

@end
