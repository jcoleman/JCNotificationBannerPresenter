#import "JCNotificationPresenterDemoViewController.h"
#import "JCNotificationBannerPresenter.h"
#import "JCNotificationBannerViewIOSStyle.h"

@interface JCNotificationPresenterDemoViewController ()

@property (weak, nonatomic) IBOutlet UITextField* titleTextField;
@property (weak, nonatomic) IBOutlet UITextView* messageTextView;
@property (weak, nonatomic) IBOutlet UISegmentedControl* styleSwitch;


@end

@implementation JCNotificationPresenterDemoViewController

- (IBAction) presentNotificationButtonTapped:(id)sender {
  JCNotificationBannerStyle style = kJCNotificationBannerPresenterStyleAndroidToast;
  if (self.styleSwitch.selectedSegmentIndex) {
    style = kJCNotificationBannerPresenterStyleIOSBanner;
  }

  [JCNotificationBannerPresenter enqueueNotificationWithTitle:self.titleTextField.text
                                                      message:self.messageTextView.text
                                                        style:style
                                                   tapHandler:^{
                                                     UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Tapped notification"
                                                                                                     message:@"Perform some custom action on notification tap event..."
                                                                                                    delegate:nil
                                                                                           cancelButtonTitle:@"OK"
                                                                                           otherButtonTitles:nil];
                                                     [alert show];
                                                   }];
}

- (void) viewDidUnload {
  [self setMessageTextView:nil];
  [self setTitleTextField:nil];
  [super viewDidUnload];
}

@end
