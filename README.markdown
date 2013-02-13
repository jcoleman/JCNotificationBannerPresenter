Why?
----

Apple doesn't provide an API in iOS for presenting notification banners while the app is running. For many projects the most sensible way to respond to a remote push notification would be to display that notification (in the same style it is presented if your app is not foreground) and allow the user to determine whether the notification merits a response.

What?
-----

JCNotificationBannerPresenter allows you to display notification banners asynchronously from any piece of code in your application. It is not view/view-controller specific, you can use it directly from the AppDelegate, for example. It doesn't attempt to mimic the style of Apple's notifications; it seems better to avoid the uncanny valley presented by that endeavor. Just like Apple's notifications, however, this project slides down a banner from the middle of the status bar that times out after a set period of time and slides back up. The banner also can be dismissed by tapping on it, and a custom tap handler can be assigned to trigger some custom action.

Usage?
----

    #import "JCNotificationBannerPresenter.h"
    
    …
    
    - (void) application:(UIApplication*)application didReceiveRemoteNotification:(NSDictionary*)notification {
      NSString* title = @"Push Notification";
      NSDictionary* aps = [notification objectForKey:@"aps"];
      NSString* alert = [aps objectForKey:@"alert"];
      [JCNotificationBannerPresenter enqueueNotificationWithTitle:title
                                                          message:alert
                                                       tapHandler:^{
                                                         NSLog(@"Received tap on notification banner!");
                                                       }];
    }

Installation?
-------------

This project includes a `podspec` for usage with [CocoaPods](http://http://cocoapods.org/). Simply add

    pod 'JCNotificationBannerPresenter'

to your `Podfile` and run `pod install`.

Alternately, you can configure your project to include the `QuartzCore` (`CoreGraphics` already includes `QuartzCore` ) framework and add all of the `.h` and `.m` files in this project. If your project does not use ARC, you will need to enable ARC on these files. You can enabled ARC per-file by adding the -fobjc-arc flag, as described on [a common StackOverflow question](http://stackoverflow.com/questions/6646052/how-can-i-disable-arc-for-a-single-file-in-a-project).

License
-------

This project is licensed under the MIT license. All copyright rights are retained by myself.

Copyright (c) 2012 James Coleman

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
