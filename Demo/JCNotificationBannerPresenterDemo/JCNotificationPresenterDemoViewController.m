#import "JCNotificationPresenterDemoViewController.h"
#import "JCNotificationBannerPresenter.h"
#import "JCNotificationBannerCustomView.h"

@interface JCNotificationPresenterDemoViewController ()

@property (weak, nonatomic) IBOutlet UITextField* titleTextField;
@property (weak, nonatomic) IBOutlet UITextView* messageTextView;
@property (weak, nonatomic) IBOutlet UISwitch* customizationSwitch;


@end

@implementation JCNotificationPresenterDemoViewController
- (IBAction) presentNotificationButtonTapped:(id)sender {
    NSLog(@"state is %d", self.customizationSwitch.on);
  if (self.customizationSwitch.on) {
    [[JCNotificationBannerPresenter sharedPresenter] setDelegate:self];
  } else {
    [[JCNotificationBannerPresenter sharedPresenter] setDelegate:nil];
  }

  [JCNotificationBannerPresenter enqueueNotificationWithTitle:self.titleTextField.text
                                                      message:self.messageTextView.text
                                                   tapHandler:^{
                                                     UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Tapped notification"
                                                                                                     message:@"Perform some custom action on notification tap event..."
                                                                                                    delegate:nil
                                                                                           cancelButtonTitle:@"OK"
                                                                                           otherButtonTitles:nil];
                                                     [alert show];
                                                   }];
}

- (JCNotificationBannerView*) makeViewForNotification:(JCNotificationBanner *)banner {
    JCNotificationBannerCustomView* view = [[JCNotificationBannerCustomView alloc] initWithNotification:banner];
    return view;
}

- (BOOL) shouldCoverStatusBar {
    return NO;
}

- (double) getStartOpacity {
    return 1.0;
}

- (double) getEndOpacity {
    return 1.0;
}


- (void)viewDidUnload {
  [self setMessageTextView:nil];
  [self setTitleTextField:nil];
  [super viewDidUnload];
}
@end
