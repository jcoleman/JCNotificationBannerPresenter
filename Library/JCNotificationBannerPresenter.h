#import <Foundation/Foundation.h>
#import "JCNotificationBannerView.h"
#import "JCNotificationBanner.h"
#import "JCNotificationBannerWindow.h"
#import "JCNotificationBannerViewController.h"

@protocol JCNotificationAppearanceDelegate <NSObject>
@optional

- (JCNotificationBannerView*) makeViewForNotification: (JCNotificationBanner*) banner;
- (BOOL) shouldCoverStatusBar;
- (double) getDisplayDurationSeconds;
- (double) getAnimationDurationSeconds;
- (double) getStartOpacity;
- (double) getEndOpacity;

@end

@interface JCNotificationBannerPresenter : NSObject
{
    id <JCNotificationAppearanceDelegate,NSObject> delegate;
}
@property (strong) id <JCNotificationAppearanceDelegate,NSObject> delegate;

+ (JCNotificationBannerPresenter*) sharedPresenter;
+ (void) enqueueNotificationWithTitle:(NSString*)title
                              message:(NSString*)message
                           tapHandler:(JCNotificationBannerTapHandlingBlock)tapHandler;



- (void) enqueueNotificationWithTitle:(NSString*)title
                              message:(NSString*)message
                           tapHandler:(JCNotificationBannerTapHandlingBlock)tapHandler;


@end
