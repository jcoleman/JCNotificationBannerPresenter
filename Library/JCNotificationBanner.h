#import <Foundation/Foundation.h>

typedef void (^JCNotificationBannerTapHandlingBlock)();

@interface JCNotificationBanner : NSObject

@property (nonatomic) NSString* title;
@property (nonatomic) NSString* message;
@property (nonatomic, copy) JCNotificationBannerTapHandlingBlock tapHandler;

- (JCNotificationBanner*) initWithTitle:(NSString*)title
                                message:(NSString*)message
                             tapHandler:(JCNotificationBannerTapHandlingBlock)tapHandler;

@end
