//
//  JCNotificationBannerCustomView.m
//  JCNotificationBannerPresenterDemo
//
//  Created by Abe Fettig on 11/16/12.
//  Copyright (c) 2012 James Coleman. All rights reserved.
//

#import "JCNotificationBannerCustomView.h"

@implementation JCNotificationBannerCustomView

- (id) initWithNotification:(JCNotificationBanner*)notification {
  self = [super initWithNotification:notification];
  if (self) {
    self.titleLabel.textColor = [UIColor darkTextColor];
    self.messageLabel.textColor = [UIColor darkTextColor];
    self.backgroundColor = [UIColor whiteColor];
      
    // Add a drop shadow
    [[self layer] setShadowOffset:CGSizeMake(0, 1)];
    [[self layer] setShadowColor:[[UIColor darkGrayColor] CGColor]];
    [[self layer] setShadowRadius:3.0];
    [[self layer] setShadowOpacity:0.8];
      
  }
  return self;
}

- (void) layoutSubviews {
  [super layoutSubviews];
  CGRect messageFrame = [self.messageLabel frame];
  messageFrame.origin.y = 7;
    self.messageLabel.frame = messageFrame;
    
 
    
}

- (void)drawRect:(CGRect)rect {

}


@end
