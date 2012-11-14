#import "JCNotificationPresenterDemoViewController.h"
#import "JCNotificationBannerPresenter.h"

@interface JCNotificationPresenterDemoViewController ()

@property (weak, nonatomic) IBOutlet UITextField* titleTextField;
@property (weak, nonatomic) IBOutlet UITextView* messageTextView;

@end

@implementation JCNotificationPresenterDemoViewController
- (IBAction) presentNotificationButtonTapped:(id)sender {
  [[JCNotificationBannerPresenter sharedPresenter] setDelegate:self];
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
    JCNotificationBannerView* view = [[JCNotificationBannerView alloc] initWithNotification:banner];
    view.backgroundColor = [UIColor redColor];
    return view;
}

- (BOOL) shouldCoverStatusBar {
    return NO;
}


- (void)viewDidUnload {
  [self setMessageTextView:nil];
  [self setTitleTextField:nil];
  [super viewDidUnload];
}
@end
