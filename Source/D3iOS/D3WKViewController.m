//
//  D3WKViewController.m
//  D3iOS
//
//  Created by Puneet JR on 04/03/17.
//  Copyright (c) 2017 edX. All rights reserved.
//

#import "D3WKViewController.h"
#import "WebKitController.h"
#import "edX-Swift.h"
#import "OEXRouter.h"

@interface D3WKViewController () {
    SpinnerView *spinnerD3;
    QRCViewController *qrScanCamera;
}

@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) NSOperationQueue *scriptQueue;
//@property (strong, nonatomic) UIStoryboard* mainStoryboard;
@end

@implementation D3WKViewController

- (IBAction)qrScanAction:(id)sender {
    
    //    self.mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    //    QRCViewController *qrCodeController = [self.mainStoryboard instantiateViewControllerWithIdentifier:@"QRCodeVC"];
    
    [[OEXRouter sharedRouter] scanMyQRCode:qrScanCamera];
}


#pragma mark - UIView
-(void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"My Points & Badges";
    
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setupWebView];
    [self.view addSubview:_webView];
    //bring camera button for QR code scanner
    [self.view bringSubviewToFront:_cameraBtn];
    
    _scriptQueue = [[NSOperationQueue alloc] init];
    _scriptQueue.qualityOfService = NSOperationQueuePriorityVeryHigh;
    
    [[NSNotificationCenter defaultCenter] addObserverForName:D3_NOTE_JS_MESSAGE_SAMPLE
                                                      object:self
                                                       queue:_scriptQueue
                                                  usingBlock:^(NSNotification *note) {
                                                      
                                                      //From here add these as part of the arguments for the script we are sending this to.
                                                      //                                                      NSString *name = note.name;
                                                      //                                                      NSDictionary *jsObject = note.userInfo;
                                                      //                                                      NSLog(@"Name: %@\njsObject: %@", name, jsObject);
                                                      
                                                      [_webView evaluateJavaScript:@"NEED SOMETHING HERE"
                                                                 completionHandler:^(id object, NSError *error) {
                                                                     
                                                                 }];
                                                  }];
    
    
    [[NSNotificationCenter defaultCenter] addObserverForName:D3_NOTE_UPDATE_DATA
                                                      object:self
                                                       queue:_scriptQueue
                                                  usingBlock:^(NSNotification *note) {
                                                      
                                                      NSString *js = [NSString stringWithFormat:@""];
                                                      
                                                      [_webView evaluateJavaScript:js
                                                                 completionHandler:^(id object, NSError * error) {
                                                                     if (error) {
                                                                         NSLog(@"Error: %@", error.localizedDescription);
                                                                     }
                                                                 }];
                                                  }];
    
}

-(void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    //pass badges api URL
    NSMutableString *badgesURLUser = [[NSMutableString alloc] initWithString:POINTS_BADGES_URL];
    
    _webView.hidden = false;
    [_webView evaluateJavaScript:[NSString stringWithFormat:@"loadPieChart('%@','%@')",badgesURLUser,self.currentUsername] completionHandler:nil];
    [[OEXRouter sharedRouter] hideMyActivityIndicator:spinnerD3];
    
    //    [_webView evaluateJavaScript:@"loadPieChart()" completionHandler:nil];
    //    [badgesURLUser appendFormat:@"%@", self.currentUsername];
    //    [_webView evaluateJavaScript:[NSString stringWithFormat:@"DATAG_MOD.newDataSet('%@')", badgesURLUser] completionHandler:nil];
    
    //    pass username to datagenerator.js
    //    NSString * param  = @"rahulshenoy";
    //    NSString * jsCallBack = [NSString stringWithFormat:@"updateGraph(%@)",param];
    //    [_webView evaluateJavaScript:jsCallBack completionHandler:nil];
}


-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    //Remove Observers added!
    //    [[NSNotificationCenter defaultCenter] removeObserver:<#(id)#> name:<#(NSString *)#> object:<#(id)#>];
}

#pragma mark - Setup
-(void)setupWebView
{
    //SetupWebView
    WebKitController *wkController = [WebKitController sharedInstance];
    _webView = [[WKWebView alloc] initWithFrame:CGRectMake(0,10,self.view.frame.size.width,self.view.frame.size.height) /*(self.view.frame.size.width/24, self.view.center.y, self.view.frame.size.width-(self.view.frame.size.width/12), self.view.frame.size.height)*/ configuration:wkController.config];
    _webView.UIDelegate = self;
    _webView.navigationDelegate = self;
    _webView.allowsBackForwardNavigationGestures = NO; //This disables the ability to go back and go forward (we will be updating manually).
    
    _webView.hidden =true;
    
    spinnerD3 = [[OEXRouter sharedRouter] showMyActivityIndicator:self];
    
    //Passing html url of the path to be opened on D3ViewController.
    NSString *indexPath = [[NSBundle mainBundle] pathForResource:EXP_D3_PIE ofType:@"html"];
    NSURL *indexURL = [NSURL fileURLWithPath:indexPath];
    NSString *indexFile = [NSString stringWithContentsOfURL:indexURL encoding:NSUTF8StringEncoding error:nil];
    
    
    //    [_webView loadHTMLString:indexFile baseURL:indexURL];
    
    //Passing current username value to html for Points & badges value from API.
    NSString *usernameURL = [NSString stringWithFormat:@"%@?username=%@",indexPath,self.currentUsername];
    //    NSLog(@"indexURL: %@", usernameURL);
    //    NSLog(@"indexfile: %@", indexFile);
    //    NSLog(@"index:%@", indexURL);
    
    //converting url path with username to NSURL path
    NSURL *usernameURLIndex = [NSURL fileURLWithPath:usernameURL];
    [_webView loadHTMLString:indexFile baseURL:usernameURLIndex];
    
    
    //    [_webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"DARAG_MOD('%@')", badgesURLUser]];
    //    NSString *jsBadgesString = [NSString stringWithFormat:@"newDataSet('%@')", badgesURLUser];
    
    
}

#pragma mark - WKWebView
//Where the App 'injects' itself.

#pragma mark WKNavigationDelegate
-(void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    switch (navigationAction.navigationType) {
        case WKNavigationTypeOther:
        case WKNavigationTypeReload:
            //This is the action for loading from a local HTML document.
            NSLog(@"Navigation Allowed.");
            decisionHandler(WKNavigationActionPolicyAllow);
            break;
            
        case WKNavigationTypeBackForward:
        case WKNavigationTypeFormSubmitted:
        case WKNavigationTypeFormResubmitted:
        case WKNavigationTypeLinkActivated:
            NSLog(@"Navigation Denied.");
            decisionHandler(WKNavigationActionPolicyCancel);
            break;
            
        default:
            break;
    }
    
    /*//Sample implementation for future...
     NSURL *url = navigationAction.request.URL;
     if (![url.host.lowercaseString hasPrefix:@"https://"]) {
     decisionHandler(WKNavigationActionPolicyCancel);
     return;
     }
     */
}

-(void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler
{
    //This is not being used at the moment, this would be what would be called right after the decidePolicy, this will return true as long as the type of file is visible at the moment.
    //Handle Reponse
    if (navigationResponse.canShowMIMEType) {
        decisionHandler(WKNavigationResponsePolicyAllow);
    } else {
        decisionHandler(WKNavigationResponsePolicyCancel);
    }
    
}

#pragma mark - IBAction
- (IBAction)refreshWebView:(id)sender {
    //    NSLog(@"Reloaded");
    //    [_webView evaluateJavaScript:@"window.webkit.messageHandlers.{NAME}.postMessage({body: "" })"
    //               completionHandler:^(id object, NSError * error) {
    //        [_webView reload];
    //    }];
    //    [_webView evaluateJavaScript:@"fireOffCustomEvent();" completionHandler:nil];
    [_webView evaluateJavaScript:@"updateGraph()" completionHandler:nil];
}

@end


////API Implementation
//    NSURL *url = [NSURL URLWithString:@"https://badges.appliedxvpcdev.amat.com/api/v0/chart?username=puneethkumarsrinivasvenkate"]; //hard coded
//    NSURLRequest *request = [NSURLRequest requestWithURL:url];
//    [_webView loadRequest:request];
//    request = nil;

//    //Passing value through html
//    NSString * curretUsername  = @"rahulshenoy";
//    NSString * jsCallBack = [NSString stringWithFormat:@"updateGraph(%@)",curretUsername];
//    [_webView evaluateJavaScript:jsCallBack completionHandler:nil];

//This is found in the D3Samples folder in the Supporting files.
//    NSString * currentUsername  = @"puneethkumarsrinivasvenkate";
