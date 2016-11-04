//
//  OEXAppDelegate.h
//  edXVideoLocker
//
//  Created by Nirbhay Agarwal on 15/05/14.
//  Copyright (c) 2014-2016 edX. All rights reserved.
//

@import UIKit;
@import MessageUI;
#import "Reachability.h"
//kAMAT_CHANGES
#import "UIWindow+TopController.h"
NS_ASSUME_NONNULL_BEGIN

@class OEXCourse;

@interface OEXAppDelegate : UIResponder

@property (nonatomic, strong) id <Reachability> reachability;
@property MFMailComposeViewController *appliedxMailVC;

@property (nonatomic)BOOL isVRVideosPlaying;

//kAMAT_CHANGES
- (void) performVPNAvailability;

- (void)callCompletionHandlerForSession:(NSString*)identifier;

@end

NS_ASSUME_NONNULL_END