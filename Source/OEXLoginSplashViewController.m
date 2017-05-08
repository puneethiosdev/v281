//
//  LoginSplashViewController.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 16/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXLoginSplashViewController.h"

#import "edX-Swift.h"

#import "OEXRouter.h"
#import "OEXLoginViewController.h"
#import "OEXSession.h"

@interface OEXLoginSplashViewController ()

@property (strong, nonatomic) IBOutlet UIButton* signInButton;
@property (strong, nonatomic) IBOutlet UIButton* signUpButton;

@property (strong, nonatomic) RouterEnvironment* environment;
@property (strong, nonatomic) UIActivityIndicatorView* activityIndicator;

@end

@implementation OEXLoginSplashViewController

- (id)initWithEnvironment:(RouterEnvironment*)environment {
    self = [super initWithNibName:nil bundle:nil];
    if(self != nil) {
        self.environment = environment;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.signInButton setTitle:[Strings loginSplashSignIn] forState:UIControlStateNormal];
    [self.signUpButton applyButtonStyle:[self.environment.styles filledPrimaryButtonStyle] withTitle:[Strings loginSplashSignUp]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (IBAction)showLogin:(id)sender {
    [self.environment.router showLoginScreenFromController:self completion:nil];
}

- (IBAction)showRegistration:(id)sender {
    [self.environment.router showSignUpScreenFromController:self completion:nil];
}

- (BOOL) shouldAutorotate {
    return false;
}

-(void) activateActivityIndictaor{
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    
    [self.activityIndicator setCenter:[[[[UIApplication sharedApplication] delegate]window] center]];
    [self.view addSubview:self.activityIndicator];
    
}

-(void) rotateActivityIndicator{
    [self.activityIndicator startAnimating];
}
-(void) stopRotatingActivityIndicator{
    [self.activityIndicator stopAnimating];
    [self.activityIndicator hidesWhenStopped];
    NSLog(@"%s--Stopped",__FUNCTION__);
}


- (UIInterfaceOrientationMask) supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

@end
