//
//  WKViewController.h
//  D3iOS
//
//  Created by Puneet JR on 04/03/17.
//  Copyright (c) 2017 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@class SpinnerView;



@interface D3WKViewController : UIViewController <WKNavigationDelegate, WKUIDelegate,UIWebViewDelegate>

@property (nonatomic, strong) NSString *currentUsername;
//@property (nonatomic,weak) id <myDelegate>delegate;
//@property (weak, nonatomic) IBOutlet UIButton *cameraButton;
@property (weak, nonatomic) IBOutlet UIButton *cameraBtn;


- (IBAction)cameraAction:(id)sender;


@end