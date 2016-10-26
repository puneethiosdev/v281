//
//  OEXAppDelegate.m
//  edXVideoLocker
//
//  Created by Nirbhay Agarwal on 15/05/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

@import edXCore;
#import <Crashlytics/Crashlytics.h>
#import <Fabric/Fabric.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <GoogleSignIn/GoogleSignIn.h>
#import <NewRelicAgent/NewRelic.h>
#import <SEGAnalytics.h>

#import "OEXAppDelegate.h"

#import "edX-Swift.h"
#import "Logger+OEXObjC.h"

#import "OEXAuthentication.h"
#import "OEXConfig.h"
#import "OEXDownloadManager.h"
#import "OEXEnvironment.h"
#import "OEXFabricConfig.h"
#import "OEXFacebookConfig.h"
#import "OEXGoogleConfig.h"
#import "OEXGoogleSocial.h"
#import "OEXInterface.h"
#import "OEXNewRelicConfig.h"
#import "OEXPushProvider.h"
#import "OEXPushNotificationManager.h"
#import "OEXPushSettingsManager.h"
#import "OEXRouter.h"
#import "OEXSession.h"
#import "OEXSegmentConfig.h"

//kAMAT_CHANGES
#import "SEGReachability.h"
#import "OEXNetworkConstants.h"
#import "OEXUserLicenseAgreementViewController.h"
#import "OEXRegistrationViewController.h"
#import "OEXLoginSplashViewController.h"

//SFSafari
#import <SafariServices/SafariServices.h>

#import "OEXRouter.h"

#define USER_EMAIL @"USERNAME"

@interface OEXAppDelegate () <UIApplicationDelegate>{
    
    NSMutableDictionary *schemaDictionary;
    //SFSafari
    //bool isFromSourceApplicationAnnotation;
    
    //kAMAT_CHANGES
    NSURLConnection *vpnConnection;
    NSURLConnection *versionChkConnection;
    NSMutableData *versionData;
    NSUserDefaults *defaults;
    
}
@property (nonatomic, strong) NSMutableDictionary* dictCompletionHandler;
@property (nonatomic, strong) OEXEnvironment* environment;

//kAMAT_CHANGES
@property (strong, nonatomic) UIActivityIndicatorView* activityIndicator;

@end


@implementation OEXAppDelegate

@synthesize window = _window;

- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions {
#if DEBUG
    // Skip all this initialization if we're running the unit tests
    // So they can start from a clean state.
    // dispatch_async so that the XCTest bundle (where TestEnvironmentBuilder lives) has already loaded
    if([[NSProcessInfo processInfo].arguments containsObject:@"-UNIT_TEST"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            Class builder = NSClassFromString(@"TestEnvironmentBuilder");
            NSAssert(builder != nil, @"Can't find test environment builder");
            (void)[[builder alloc] init];
        });
        return YES;
    }
    if([[NSProcessInfo processInfo].arguments containsObject:@"-END_TO_END_TEST"]) {
        [[[OEXSession alloc] init] closeAndClearSession];
        [OEXFileUtility nukeUserData];
    }
#endif
    
    // logout user automatically if server changed
    [[[ServerChangedChecker alloc] init] logoutIfServerChanged];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    if ([self.reachability isReachableViaWWAN])
    {
        UIAlertView *cellularInternetAlert = [[UIAlertView alloc] initWithTitle:nil message:OEXLocalizedString(@"CONNECT_TO_WIFI_MESSAGE", nil) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [cellularInternetAlert show];
    }
    
    [self setupGlobalEnvironment];
    [self.environment.session performMigrations];
    [self.environment.router openInWindow:self.window];
    [self activateActivityIndictaor];
    
    [[FBSDKApplicationDelegate sharedInstance] application:application didFinishLaunchingWithOptions:launchOptions];
    return YES;
}

- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window{
    
    UIViewController *topController = self.window.rootViewController;
    
    return [topController supportedInterfaceOrientations];
}


- (BOOL)application:(UIApplication*)application openURL:(NSURL*)url sourceApplication:(NSString*)sourceApplication annotation:(id)annotation {
    BOOL handled = false;
    if (self.environment.config.facebookConfig.enabled) {
        handled = [[FBSDKApplicationDelegate sharedInstance] application:application openURL:url sourceApplication:sourceApplication annotation:annotation];
        if(handled) {
            return handled;
        }
        
    }
    
    if (self.environment.config.googleConfig.enabled){
        handled = [[GIDSignIn sharedInstance] handleURL:url sourceApplication:sourceApplication annotation:annotation];
        [[OEXGoogleSocial sharedInstance] setHandledOpenUrl:YES];
    }
    
    //SFSafari
    [self.window.rootViewController.presentedViewController dismissViewControllerAnimated:true completion:nil];
    
    if ([url.absoluteString containsString:UNDEFINED_USER]) {
        
        UIAlertView *alertUserSignUp = [[UIAlertView alloc] initWithTitle:@"" message:@"Please sign up" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        alertUserSignUp.tag = SIGN_UP_ALERT_TAG;
        [alertUserSignUp show];
    }else {
        
        NSString *urlSchemaString = [url.absoluteString stringByReplacingOccurrencesOfString:APP_SCHEMA_URL withString:@""];
        schemaDictionary = [[NSMutableDictionary alloc] init];
        NSArray *urlComponents = [urlSchemaString componentsSeparatedByString:@"&"];
        
        for (NSString *keyValuePair in urlComponents)
        {
            NSArray *pairComponents = [keyValuePair componentsSeparatedByString:@"="];
            NSString *key = [[pairComponents firstObject] stringByRemovingPercentEncoding];
            NSString *value = [[pairComponents lastObject] stringByRemovingPercentEncoding];
            
            [schemaDictionary setObject:value forKey:key];
        }
        
        NSLog(@"The Schema dictionary is:%@", schemaDictionary);
        
        NSDictionary *customAccessToken = [[NSDictionary alloc] initWithObjectsAndKeys:schemaDictionary[@"oauth"],@"access_token",
                                           @"", @"expires_in",
                                           @"", @"scope",
                                           @"Bearer", @"token_type",
                                           nil];
        NSDictionary *customUserDetails = [[NSDictionary alloc] initWithObjectsAndKeys:@"1",@"id",
                                           schemaDictionary[@"user"], @"username",
                                           schemaDictionary[@"user"], @"email",
                                           schemaDictionary[@"user"], @"name",
                                           [NSString stringWithFormat:@"%@api/mobile/v0.5/users/%@/course_enrollments/",SERVER_URL, schemaDictionary[@"user"]], @"course_enrollments",
                                           nil];
        
        OEXAccessToken *accessToken = [[OEXAccessToken alloc] initWithTokenDetails:customAccessToken];
        OEXUserDetails* userDetails = [[OEXUserDetails alloc] initWithUserDictionary:customUserDetails];
        [[OEXSession sharedSession] saveAccessToken:accessToken userDetails:userDetails];
        
        //These methods are implemented by edx after sign in
        [[OEXGoogleSocial sharedInstance] clearHandler];
        
        [OEXInterface setCCSelectedLanguage:@""];
        [[NSUserDefaults standardUserDefaults] setObject:schemaDictionary[@"user"] forKey:USER_EMAIL];
        // Analytics User Login
        
        [[OEXAnalytics sharedAnalytics] trackUserLogin:@"SSO"];
        
        //kAMAT_CHANGES for v2.0
        //Because two times openInWindow method is calling after successful SSO check
        //Here and applicationDidBecomeActive method.
        //So we are checking here
        //SFSafari
        //isFromSourceApplicationAnnotation = YES;
        [self.environment.router openInWindow:self.window];
    }
    
    return handled;
}

//kAMAT_CHANGES;
#pragma - Auto Connect VPN
- (void)applicationDidBecomeActive:(UIApplication *)application
{
    if(!self.reachability) {
        
        UIAlertView *noInternetAlert = [[UIAlertView alloc] initWithTitle:OEXLocalizedString(@"NETWORK_NOT_AVAILABLE_TITLE", nil) message:OEXLocalizedString(@"NETWORK_NOT_AVAILABLE_MESSAGE", nil) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [noInternetAlert show];
        
        [self stopRotatingActivityIndicator];
    }
    else{
        NSLog(@"%s - YES INTERNET ",__FUNCTION__);
        if ([[[UIWindow getVisibleViewControllerFrom:[self.window rootViewController]] childViewControllers] count] &&  [NSStringFromClass([[[[UIWindow getVisibleViewControllerFrom:[self.window rootViewController]] childViewControllers] objectAtIndex:0] class]) isEqualToString:@"OEXLoginSplashViewController"]) {
            
            NSLog(@"%@",[[[[UIWindow getVisibleViewControllerFrom:[self.window rootViewController]] childViewControllers] objectAtIndex:0] class]);
            NSLog(@"%@",[[UIWindow getVisibleViewControllerFrom:[self.window rootViewController]] childViewControllers]);
            
            if ([[[UIWindow getVisibleViewControllerFrom:[self.window rootViewController]] childViewControllers] count]) {
                [(OEXLoginSplashViewController*)[[[UIWindow getVisibleViewControllerFrom:[self.window rootViewController]] childViewControllers] objectAtIndex:0] rotateActivityIndicator];
                [self performVPNAvailability];
                NSLog(@"No Need of SSO because we are in signup,signin, eula");
            }
            
        }else{
            //NSLog(@"%@",[[UIWindow getVisibleViewControllerFrom:[self.window rootViewController]] childViewControllers]);
            [self performVPNAvailability];
        }
    }
}

//kAMAT_CHANGES
#pragma - VPN Check
- (void) performVPNAvailability
{
    [self rotateActivityIndicator];
    
    NSURL *ceoURL = [NSURL URLWithString:[VPN_CHECK_URL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    vpnConnection = [[NSURLConnection alloc ]initWithRequest:[NSURLRequest requestWithURL:ceoURL] delegate:self startImmediately:YES];
    [vpnConnection start];
}

#pragma mark SSO
-(void) checkDoWeNeedToCallSSO {
    
    [self stopRotatingActivityIndicator];
    
    //Check session
    OEXUserDetails* currentUser = self.environment.session.currentUser;
    if(currentUser == nil) {
        [self OpenSsoUrlInSafari];
    }else{
        [self.environment.router openInWindow:self.window];
    }
}
- (void)OpenSsoUrlInSafari{
    
    /*
     OEXUserDetails* currentUser = self.environment.session.currentUser;
     
     if(currentUser == nil) {
     [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@", PING_SSO_URL]]];
     }else{
     [self.environment.router openInWindow:self.window];
     }
     */
    SFSafariViewController *sfSafariVC = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@", PING_SSO_URL]]];
    [self.window.rootViewController presentViewController:sfSafariVC animated:true completion:nil];
}

#pragma mark Push Notifications

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    [self.environment.pushNotificationManager didReceiveRemoteNotificationWithUserInfo:userInfo];
    completionHandler(UIBackgroundFetchResultNewData);
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    [self.environment.pushNotificationManager didReceiveLocalNotificationWithUserInfo:notification.userInfo];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [self.environment.pushNotificationManager didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    [self.environment.pushNotificationManager didFailToRegisterForRemoteNotificationsWithError:error];
}

#pragma mark Background Downloading

- (void)application:(UIApplication*)application handleEventsForBackgroundURLSession:(NSString*)identifier completionHandler:(void (^)())completionHandler {
    [OEXDownloadManager sharedManager];
    [self addCompletionHandler:completionHandler forSession:identifier];
}

- (void)addCompletionHandler:(void (^)())handler forSession:(NSString*)identifier {
    if(!_dictCompletionHandler) {
        _dictCompletionHandler = [[NSMutableDictionary alloc] init];
    }
    if([self.dictCompletionHandler objectForKey:identifier]) {
        OEXLogError(@"DOWNLOADS", @"Error: Got multiple handlers for a single session identifier.  This should not happen.\n");
    }
    [self.dictCompletionHandler setObject:handler forKey:identifier];
}

- (void)callCompletionHandlerForSession:(NSString*)identifier {
    dispatch_block_t handler = [self.dictCompletionHandler objectForKey: identifier];
    if(handler) {
        [self.dictCompletionHandler removeObjectForKey: identifier];
        OEXLogInfo(@"DOWNLOADS", @"Calling completion handler for session %@", identifier);
        //[self presentNotification];
        handler();
    }
}

#pragma mark Environment

- (void)setupGlobalEnvironment {
    [UserAgentOverrideOperation overrideUserAgent:nil];
    
    self.environment = [[OEXEnvironment alloc] init];
    [self.environment setupEnvironment];
    
    OEXConfig* config = self.environment.config;
    
    //Logging
    [DebugMenuLogger setup];
    
    //Rechability
    self.reachability = [[InternetReachability alloc] init];
    [_reachability startNotifier];
    
    //SegmentIO
    OEXSegmentConfig* segmentIO = [config segmentConfig];
    if(segmentIO.apiKey && segmentIO.isEnabled) {
        [SEGAnalytics setupWithConfiguration:[SEGAnalyticsConfiguration configurationWithWriteKey:segmentIO.apiKey]];
    }
    
    //NewRelic Initialization with edx key
    OEXNewRelicConfig* newrelic = [config newRelicConfig];
    if(newrelic.apiKey && newrelic.isEnabled) {
        [NewRelicAgent enableCrashReporting:NO];
        [NewRelicAgent startWithApplicationToken:newrelic.apiKey];
    }
    
    //Initialize Fabric
    OEXFabricConfig* fabric = [config fabricConfig];
    if(fabric.appKey && fabric.isEnabled) {
        [Fabric with:@[CrashlyticsKit]];
    }
}

#pragma UIAlertView Delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;
{
    if (0 == buttonIndex) {
        if (VPN_ALERT_TAG == alertView.tag) {
            NSURL *vpnUrlSchema = [NSURL URLWithString:PULSE_SECURE_URL_SCHEMA];
            if ([[UIApplication sharedApplication] canOpenURL:vpnUrlSchema]) {
                [[UIApplication sharedApplication] openURL:vpnUrlSchema];
            }else{
                UIAlertView *vpnAlert = [[UIAlertView alloc] initWithTitle:@"VPN Connection" message:@"Go to Settings->VPN->Switch ON" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [vpnAlert show];
            }
        } else if (SIGN_UP_ALERT_TAG == alertView.tag)
        {
            [self.environment.router openInWindow:self.window];
        }
        
    } else if ((1 == buttonIndex) && (VERSION_ALERT_TAG == alertView.tag)) {
        if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:kDownloadURLForProduction]]) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:kDownloadURLForProduction]];
        }
    }
}

#pragma mark -  ActivityIndicator methods
-(void) activateActivityIndictaor{
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self.activityIndicator setCenter:self.window.center];
    [self.window addSubview:self.activityIndicator];
    [self.activityIndicator startAnimating];
}

-(void) rotateActivityIndicator{
    [self.activityIndicator startAnimating];
}
-(void) stopRotatingActivityIndicator{
    [self.activityIndicator stopAnimating];
    [self.activityIndicator hidesWhenStopped];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RemoveActivityIndicator" object:self];
}


#pragma mark Connection delegates
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if (versionChkConnection == connection) {
        versionChkConnection = nil;
        versionData = nil;
        
    }
    else if(vpnConnection == connection){
        
        [self stopRotatingActivityIndicator];
        
        if (error) {
            UIAlertView *vpnAlert = [[UIAlertView alloc] initWithTitle:@"VPN Connection" message:@"Please turn on VPN to use this app, Go to Settings->VPN->Switch ON" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            vpnAlert.tag = VPN_ALERT_TAG;
            [vpnAlert show];
        }
    }
}

- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection
{
    return YES;
}

/*
 * @Function    : connection:didReceiveAuthenticationChallenge
 * @Purpose     : Sent when a connection must authenticate a challenge in order to download its request.
 * @Parameters  : connection and challenge.
 * @Return Value: void
 * @Comments    : N/A.
 */
-(BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace{
    return YES;
}
- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    NSURLCredential *credential = [NSURLCredential credentialWithUser:GENRIC_USERNAME password:GENRIC_PASSWORD persistence:NSURLCredentialPersistenceForSession];
    
    [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
}

/*
 * @Function    : connection:didReceiveResponse
 * @Purpose     : Sent when the connection has received sufficient data to construct the URL response for its request.
 * @Parameters  : connection and response.
 * @Return Value: void
 * @Comments    : N/A.
 */
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
    int responseStatusCode = (int)[httpResponse statusCode];
    if (200 == responseStatusCode) {
        //kAMAT_CHANGES 2.0
        //[self.environment.router openInWindow:self.window];
        if (vpnConnection == connection) {
            //NSURL *versionChkUrl = [NSURL URLWithString:VERSION_CHECK_URL];
            //versionChkConnection = [[NSURLConnection alloc] initWithRequest:[NSURLRequest requestWithURL:versionChkUrl] delegate:self];
            //[versionChkConnection start];
            
            versionData = [[NSMutableData alloc] initWithCapacity:0];
            if (!versionChkConnection)
            {
                versionChkConnection = nil;
                versionData = nil;
            }
            
            
            [self performSelector:@selector(checkDoWeNeedToCallSSO) withObject:nil afterDelay:1.0f];
        }
        else if (versionChkConnection == connection) {
            [versionData setLength:0];
        }
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(nonnull NSData *)data
{
    if (versionChkConnection == connection) {
        [versionData appendData:data];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection;
{
    NSError *error;
    NSString* currentVersion;
    NSString *nextVersion;
    
    if (versionChkConnection == connection) {
        
        NSDictionary *versionJson = [NSJSONSerialization JSONObjectWithData:versionData options:NSJSONReadingMutableContainers error:&error];
        if ( versionJson.count && versionJson[@"app_version"]) {
            nextVersion = versionJson[@"app_version"];
        }
        
        //Getting the Bundle version
        NSDictionary* infoDict = [[NSBundle mainBundle] infoDictionary];
        if (infoDict && infoDict.count) {
            currentVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
        }
        
        //Comparing the versions
        if(![currentVersion isEqualToString:nextVersion]){
            UIAlertView *versionAlert = [[UIAlertView alloc] initWithTitle:@"AppliedX" message:[NSString stringWithFormat:@"%@ v%@ %@", kVERSION_ALERT_TEXT1, nextVersion, kVERSION_ALERT_TEXT2] delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Update", nil];
            [versionAlert setTag:VERSION_ALERT_TAG];
            //[versionAlert show];
            
        }
    }//version check
}

//kAMAT_Changes 2.0
- (BOOL)application:(UIApplication *)application
continueUserActivity: (NSUserActivity *)userActivity
 restorationHandler: (void(^)(NSArray *restorableObjects))restorationHandler
{
    NSString *subStr1 = [NSString stringWithFormat:@"%@", [userActivity.webpageURL absoluteString]];
    NSString *courseID;
    
    if (subStr1  && [subStr1 containsString:@"course-"]) {
        NSArray *courseSubstrings = [subStr1 componentsSeparatedByString:@"/"];
        if (courseSubstrings!=nil &&
            [courseSubstrings count]>=5 &&
            [courseSubstrings objectAtIndex:4]) {
            courseID = [courseSubstrings objectAtIndex:4];
        }
    } else if (subStr1  && [subStr1 containsString:@"/"]){
        NSArray *courseSubstrings = [subStr1 componentsSeparatedByString:@"/"];
        if ([courseSubstrings count]>=7) {
            if (courseSubstrings!=nil &&
                [courseSubstrings objectAtIndex:4]!=nil &&
                [courseSubstrings objectAtIndex:5]!=nil &&
                [courseSubstrings objectAtIndex:6]!=nil) {
                courseID = [NSString stringWithFormat:@"%@/%@/%@",
                            [courseSubstrings objectAtIndex:4],
                            [courseSubstrings objectAtIndex:5],
                            [courseSubstrings objectAtIndex:6]];
            }
        }
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:courseID forKey:@"isDeepLink"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    /*Handling Logout and inital launch...*/
    OEXUserDetails* currentUser = self.environment.session.currentUser;
    if (courseID && [courseID length] && [[OEXRouter sharedRouter] getCurrentViewController] && currentUser != nil) {
        if ([self.window.rootViewController.presentedViewController isKindOfClass:[MFMailComposeViewController class]] ) {
            [self.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
        }
        [[OEXRouter sharedRouter] showCourseCatalogDetail:courseID];
        return YES;
    } else {
        return NO;
    }
}


@end
