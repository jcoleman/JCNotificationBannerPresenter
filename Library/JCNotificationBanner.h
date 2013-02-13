#import <Foundation/Foundation.h>

typedef enum
{
  kJCNotificationBannerPresenterStyleAndroidToast,
  kJCNotificationBannerPresenterStyleIOSBanner,
} JCNotificationBannerStyle;

typedef void (^JCNotificationBannerTapHandlingBlock)();

@interface JCNotificationBanner : NSObject

@property (nonatomic) NSString* title;
@property (nonatomic) NSString* message;
@property (nonatomic, copy) JCNotificationBannerTapHandlingBlock tapHandler;
@property (nonatomic, assign) JCNotificationBannerStyle style;

- (JCNotificationBanner*) initWithTitle:(NSString*)title
                                message:(NSString*)message
                                  style:(JCNotificationBannerStyle)style
                             tapHandler:(JCNotificationBannerTapHandlingBlock)tapHandler;

@end
