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
#import "OEXAppDelegate.h"

@implementation OEXLoginSplashViewControllerEnvironment

- (id)initWithRouter:(OEXRouter *)router {
    self = [super init];
    if(self != nil) {
        _router = router;
    }
    return self;
}

@end

@interface OEXLoginSplashViewController ()

@property (strong, nonatomic) IBOutlet UIButton* signInButton;
@property (strong, nonatomic) IBOutlet UIButton* signUpButton;

@property (strong, nonatomic) OEXLoginSplashViewControllerEnvironment* environment;
@property (strong, nonatomic) UIActivityIndicatorView* activityIndicator;

@end

@implementation OEXLoginSplashViewController

- (id)initWithEnvironment:(OEXLoginSplashViewControllerEnvironment*)environment {
    self = [super initWithNibName:nil bundle:nil];
    if(self != nil) {
        self.environment = environment;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.signInButton setTitle:[Strings loginSplashSignIn] forState:UIControlStateNormal];
    [self.signUpButton setTitle:[Strings loginSplashSignUp] forState:UIControlStateNormal];
    
        //kAMAT_CHANGES
    [self.signUpButton setHidden:YES];
    [self activateActivityIndictaor];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopRotatingActivityIndicator) name:@"RemoveActivityIndicator" object:nil];
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
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (IBAction)showLogin:(id)sender {
        //[self.environment.router showLoginScreenFromController:self completion:nil];
    
    [(OEXAppDelegate *)[[UIApplication sharedApplication] delegate] performVPNAvailability];
    
        //First we dispaly the activity indicator
    [self rotateActivityIndicator];
}

- (IBAction)showRegistration:(id)sender {
    [self.environment.router showSignUpScreenFromController:self completion:nil];
}

- (BOOL) shouldAutorotate {
    return false;
}

- (UIInterfaceOrientationMask) supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

@end
