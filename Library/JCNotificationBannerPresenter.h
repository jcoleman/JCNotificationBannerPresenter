#import <Foundation/Foundation.h>
#import "JCNotificationBannerView.h"
#import "JCNotificationBanner.h"
#import "JCNotificationBannerWindow.h"
#import "JCNotificationBannerViewController.h"

@protocol JCNotificationAppearanceDelegate <NSObject>
@required

- (JCNotificationBannerView*) makeViewForNotification: (JCNotificationBanner*) banner;
- (BOOL) shouldCoverStatusBar;

@end

@interface JCNotificationBannerPresenter : NSObject
{
    id <JCNotificationAppearanceDelegate> delegate;
}
@property (retain) id delegate;

+ (JCNotificationBannerPresenter*) sharedPresenter;
+ (void) enqueueNotificationWithTitle:(NSString*)title
                              message:(NSString*)message
                           tapHandler:(JCNotificationBannerTapHandlingBlock)tapHandler;



- (void) enqueueNotificationWithTitle:(NSString*)title
                              message:(NSString*)message
                           tapHandler:(JCNotificationBannerTapHandlingBlock)tapHandler;


@end
