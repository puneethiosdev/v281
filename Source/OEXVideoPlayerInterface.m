//
//  OEXVideoPlayerInterface.m
//  edX_videoStreaming
//
//  Created by Nirbhay Agarwal on 13/05/14.
//  Copyright (c) 2014 edX, Inc. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

#import "OEXVideoPlayerInterface.h"

#import "edX-Swift.h"
#import "Logger+OEXObjC.h"

#import "OEXHelperVideoDownload.h"
#import "OEXInterface.h"
#import "OEXMathUtilities.h"
#import "OEXStyles.h"
#import "OEXVideoSummary.h"

//kAMAT_Changes 3.0
#import "GVRVideoView.h"


@interface OEXVideoPlayerInterface () <GVRVideoViewDelegate>
{
    UILabel* labelTitle;
    //kAMAT_CHANGES 2.0
    NSMutableData      *responseData;
    NSTimer *m_timer; //Timer to trigger handle the movie player straming
    UILabel *bufferingLable;
    
    
    OEXHelperVideoDownload *globalVideo;
    
    //KAMAT_CHANGES 3.0
    GVRVideoView *_videoView;
    BOOL _isPaused;
    BOOL isVRVideo;
}

@property(nonatomic, assign) CGRect defaultFrame;
@property(nonatomic) CGFloat lastPlayedTime;
@property(nonatomic, strong) OEXHelperVideoDownload* currentVideo;
@property(nonatomic, strong) OEXHelperVideoDownload* lastPlayedVideo;
@property(nonatomic, strong) NSURL* currentUrl;

@end

@implementation OEXVideoPlayerInterface

- (void)resetPlayer {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self.moviePlayerController.controls];
    [[NSNotificationCenter defaultCenter] removeObserver:self.moviePlayerController];
    [self.moviePlayerController setContentURL:nil];
    self.moviePlayerController.delegate = nil;
    [self.moviePlayerController resetMoviePlayer];
    self.moviePlayerController.controls = nil;
    self.moviePlayerController = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _videoPlayerVideoView = self.view;
    self.fadeInOnLoad = YES;
    
    isVRVideo = NO;
    
    //straming
    bufferingLable = nil;
    
    
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    //Add observer
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(exitFullScreenMode:) name:MPMoviePlayerDidExitFullscreenNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterFullScreenMode:) name:MPMoviePlayerDidEnterFullscreenNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playbackStateChanged:)
                                                 name:MPMoviePlayerPlaybackStateDidChangeNotification object:_moviePlayerController];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playbackEnded:)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification object:_moviePlayerController];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    /*
     [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(movieDurationNotification) name:MPMovieDurationAvailableNotification object:nil];
     
     dispatch_async(dispatch_get_main_queue(), ^{
     m_timer = [NSTimer scheduledTimerWithTimeInterval:0.5
     target:self
     selector:@selector(movieDurationNotification)
     userInfo:nil
     repeats:YES];
     [m_timer fire];
     });
     */
    
    //create a player
    self.moviePlayerController = [[CLVideoPlayer alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    self.moviePlayerController.view.alpha = 0.f;
    self.moviePlayerController.delegate = self; //IMPORTANT!
    
    //create the controls
    CLVideoPlayerControls* movieControls = [[CLVideoPlayerControls alloc] initWithMoviePlayer:self.moviePlayerController style:CLVideoPlayerControlsStyleDefault];
    [movieControls setBarColor:[UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:0.9]];
    [movieControls setTimeRemainingDecrements:YES];
    //assign controls
    [self.moviePlayerController setControls:movieControls];
    _shouldRotate = YES;
    
    
    
    NSError* error = nil;
    BOOL success = [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&error];
    if(!success) {
        OEXLogInfo(@"VIDEO", @"error: could not set audio session category => AVAudioSessionCategoryPlayback");
    }
    
    //7-10-2016 kAMAT_changes
    //kAMAT_Changes
    //remove this code this is for testing the VR player orientation
    if (!isVRVideo)
        [self enableFullscreenAutorotation];
}

- (void) enableFullscreenAutorotation {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];
}

//kAMAT_CHANGES 2.0
- (void)playVideoFor:(OEXHelperVideoDownload*)video {
    
    if ([video.summary.videoURL containsString:@"ET_Conf_11Dec_VR_Video"]) {
        
        NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentPath = [searchPaths objectAtIndex:0];
        NSString* pathOfLocalFile = [documentPath stringByAppendingPathComponent:@"AMV4-HB_Intro.mp4"];
        
        float timeinterval = [[OEXInterface sharedInterface] lastPlayedIntervalForVideo:video];
        
        [self playVideoFromURL:[NSURL fileURLWithPath:pathOfLocalFile] withTitle:video.summary.name timeInterval:timeinterval videoURL:video.summary.videoURL];
        
        
    }else if([video.summary.videoURL containsString:@"_VR_Video"]){
        
        
        NSURL* url = [NSURL URLWithString:video.summary.videoURL];
        
        NSFileManager* filemgr = [NSFileManager defaultManager];
        NSString* path = [video.filePath stringByAppendingPathExtension:@"mp4"];
        
        if([filemgr fileExistsAtPath:path]) {
            url = [NSURL fileURLWithPath:path];
        }
        
        if(video.downloadState == OEXDownloadStateComplete && ![filemgr fileExistsAtPath:path]) {
            return;
        }
        
        float timeinterval = [[OEXInterface sharedInterface] lastPlayedIntervalForVideo:video];
        [self updateLastPlayedVideoWith:video];
        
        if(video.downloadState == OEXDownloadStateComplete && [filemgr fileExistsAtPath:path]) {
            [self playVideoFromURL:url withTitle:video.summary.name timeInterval:timeinterval videoURL:video.summary.videoURL];
            
        }else{
            
            //Disable streaming videos
            UIAlertView *orientationAlert  = [[UIAlertView alloc] initWithTitle:@"" message:@"Please download VRVideo before watching" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [orientationAlert show];
            [self.navigationController popViewControllerAnimated:NO];
            
            
            //Enable steaming videos
            //[self checkCloudFrontURL:video withTimeInterval:timeinterval];
            
        }
    }
    else{
        _moviePlayerController.videoTitle = video.summary.name;
        _moviePlayerController.controls.video = video;
        NSURL* url = [NSURL URLWithString:video.summary.videoURL];
        
        NSFileManager* filemgr = [NSFileManager defaultManager];
        NSString* path = [video.filePath stringByAppendingPathExtension:@"mp4"];
        
        if([filemgr fileExistsAtPath:path]) {
            url = [NSURL fileURLWithPath:path];
        }
        
        if(video.downloadState == OEXDownloadStateComplete && ![filemgr fileExistsAtPath:path]) {
            return;
        }
        
        float timeinterval = [[OEXInterface sharedInterface] lastPlayedIntervalForVideo:video];
        [self updateLastPlayedVideoWith:video];
        
        if(video.downloadState == OEXDownloadStateComplete && [filemgr fileExistsAtPath:path]) {
            [self playVideoFromURL:url withTitle:video.summary.name timeInterval:timeinterval videoURL:video.summary.videoURL];
            
        }else{
            //kAMAT_CHANGES 2.0
            [self checkCloudFrontURL:video withTimeInterval:timeinterval];
        }
    }
    
    //kAMAT_CHANGES 2.0
    //    [self playVideoFromURL:url withTitle:video.summary.name timeInterval:timeinterval];
}

//kAMAT_CHANGES 2.0
- (void)checkCloudFrontURL:(OEXHelperVideoDownload*)video withTimeInterval:(float)timeinterval{
    //kAMAT_CHANGES 2.0
    globalVideo = video;
    NSURL* url = [NSURL URLWithString:video.summary.videoURL];
    
    //Validate empty URL
    if (video.summary.videoURL.length == 0) {
        [self playVideoFromURL:url withTitle:video.summary.name timeInterval:timeinterval videoURL:video.summary.videoURL];
    }else{
        
        //        OEXSession* session = [OEXSession sharedSession];
        //        NSString *bearerToken =  [NSString stringWithFormat:@"Bearer %@", session.token.accessToken];
        
        //Validate cloudfront URL
        if ([video.summary.videoURL containsString:CLOUD_FRONT_HOST_NAME]) {
            NSMutableURLRequest *signingRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@", SERVER_URL, VIDEO_SIGNED_URL, [video.summary.videoURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]]];
            //NSLog(@"Signing Request %@",signingRequest);
            //NSLog(@"%s -- Unsigned URL -%@",__FUNCTION__,signingRequest);
            [signingRequest addValue:@"application/json" forHTTPHeaderField:@"Accept"];
            //            [signingRequest addValue:bearerToken forHTTPHeaderField:@"Autherization"];
            [NSURLConnection connectionWithRequest:signingRequest delegate:self];
        } else {
            [self playVideoFromURL:url withTitle:video.summary.name timeInterval:timeinterval videoURL:video.summary.videoURL];
        }
    }
    
}

- (void)setViewFromVideoPlayerView:(UIView*)videoPlayerView {
    BOOL wasLoaded = self.isViewLoaded;
    
    //To overcome the UIViewControllerHierarchyInconsistency exception, we are having this try catch block
    @try {
        self.view = videoPlayerView;
    } @catch (NSException *exception) {
        
    } @finally {
        
    }
    if(!wasLoaded) {
        // Call this manually since if we set self.view ourselves it doesn't ever get called.
        // This whole thing should get factored so that we just always use our own view
        // And owners can add it where they choose and the whole thing goes through the natural
        // view controller APIs
        [self viewDidLoad];
        [self beginAppearanceTransition:true animated:true];
        [self endAppearanceTransition];
    }
    
}

- (void)setVideoPlayerVideoView:(UIView*)videoPlayerVideoView {
    _videoPlayerVideoView = videoPlayerVideoView;
    [self setViewFromVideoPlayerView:_videoPlayerVideoView];
}
//To get the Video type (i.e VR type), we are changing this method parameters
//- (void)playVideoFromURL:(NSURL*)URL withTitle:(NSString*)title timeInterval:(NSTimeInterval)interval
- (void)playVideoFromURL:(NSURL*)URL withTitle:(NSString*)title timeInterval:(NSTimeInterval)interval videoURL : (NSString*) signed_VideoURL;
{
    //  NSString *videoPath = [[NSBundle mainBundle] pathForResource:@"congo" ofType:@"mp4"];
    //  [_videoView loadFromUrl:[[NSURL alloc] initFileURLWithPath:videoPath]];
    
    //to test..
    
    //NSString *URL1 = @"https://www.youtube.com/watch?v=g7btxyIbQQ0&list=PLU8wpH_LfhmtKoee0Uv90nmscm5iezRoW&index=2";
    
    if(!URL) {
        return;
    }
    
    self.view = _videoPlayerVideoView;
    [self setViewFromVideoPlayerView:_videoPlayerVideoView];
    
    
    
    if ([signed_VideoURL containsString:@"_VR_Video"]) {
        
        //kAMAT_Changes 3.0
        if (_videoView == nil) {
            _videoView = [[GVRVideoView alloc] initWithFrame:_videoPlayerVideoView.bounds];
        }
        //_videoView = [[GVRVideoView alloc] init];
        
        
        _videoView.delegate = self;
        _videoView.enableFullscreenButton = YES;
        _videoView.enableCardboardButton = YES;
        _videoView.enableTouchTracking = YES;
        //_videoView.displayMode = kGVRWidgetDisplayModeFullscreen;
        
        _isPaused = NO;
        
        [self.view addSubview:_videoView];
        [self.view bringSubviewToFront:_videoView];
        
        //Customization of VR player button colors
        for (UIButton *playerContolBtn in _videoView.subviews) {
            playerContolBtn.tintColor = [UIColor colorWithRed:65/255.0f green:119/255.0f blue:187/255.0f alpha:1.0];
        }
        
        [_videoView setFrame:CGRectMake(_videoPlayerVideoView.frame.origin.x, _videoPlayerVideoView.frame.origin.y, _videoPlayerVideoView.frame.size.width, _videoPlayerVideoView.frame.size.height)];
        [_videoView loadFromUrl:URL];
        
        isVRVideo = YES;
    }else{
        
        isVRVideo = NO;
        _moviePlayerController.videoTitle = title;
        self.lastPlayedTime = interval;
        [_moviePlayerController.view setBackgroundColor:[UIColor blackColor]];
        [_moviePlayerController setContentURL:URL];
        [_moviePlayerController prepareToPlay];
        [_moviePlayerController setAutoPlaying:YES];
        _moviePlayerController.lastPlayedTime = interval;
        //kAMAT_Changes
        _moviePlayerController.movieSourceType = MPMovieSourceTypeStreaming;
        [_moviePlayerController play];
        
        float speed = [OEXInterface getOEXVideoSpeed:[OEXInterface getCCSelectedPlaybackSpeed]];
        
        _moviePlayerController.controls.playbackRate = speed;
        [_moviePlayerController setCurrentPlaybackRate:speed];
        if(!_moviePlayerController.isFullscreen) {
            [_moviePlayerController.view setFrame:_videoPlayerVideoView.bounds];
            [self.view addSubview:_moviePlayerController.view];
        }
        
        if(self.fadeInOnLoad) {
            self.moviePlayerController.view.alpha = 0.0f;
            double delayInSeconds = 0.3;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [UIView animateWithDuration:1.0 animations:^{
                    self.moviePlayerController.view.alpha = 1.f;
                }];
            });
        }
        else {
            self.moviePlayerController.view.alpha = 1;
        }
    }
}

- (void)setAutoPlaying:(BOOL)playing {
    [self.moviePlayerController setAutoPlaying:playing];
}

- (void)updateLastPlayedVideoWith:(OEXHelperVideoDownload*)video {
    if(_currentVideo) {
        _lastPlayedVideo = _currentVideo;
    }
    else {
        _lastPlayedVideo = video;
    }
    _currentVideo = video;
}

#pragma mark video player delegate

- (void)movieTimedOut {
    [self.delegate movieTimedOut];
}

#pragma mark notification methods

- (void)playbackStateChanged:(NSNotification*)notification {
    switch([_moviePlayerController playbackState])
    {
        case MPMoviePlaybackStateStopped:
            OEXLogInfo(@"VIDEO", @"Stopped");
            break;
        case MPMoviePlaybackStatePlaying:
            OEXLogInfo(@"VIDEO", @"Playing");
            break;
        case MPMoviePlaybackStatePaused:
            OEXLogInfo(@"VIDEO", @"Playing");
            break;
        case MPMoviePlaybackStateInterrupted:
            OEXLogInfo(@"VIDEO", @"Interrupted");
            break;
        case MPMoviePlaybackStateSeekingForward:
            OEXLogInfo(@"VIDEO", @"Seeking Forward");
            break;
        case MPMoviePlaybackStateSeekingBackward:
            OEXLogInfo(@"VIDEO", @"Seeking Backward");
            break;
    }
}

- (void)playbackEnded:(NSNotification*)notification {
    int reason = [[[notification userInfo] valueForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey] intValue];
    if(reason == MPMovieFinishReasonPlaybackEnded) {
        //NSLog(@"Reason: movie finished playing");
    }
    else if(reason == MPMovieFinishReasonUserExited) {
        //NSLog(@"Reason: user hit done button");
    }
    else if(reason == MPMovieFinishReasonPlaybackError) {
        //NSLog(@"Reason: error --> VideoPlayerInterface.m");
        [self.moviePlayerController.view removeFromSuperview];
    }
}

- (void)willResignActive:(NSNotification*)notification {
    [self.moviePlayerController.controls hideOptionsAndValues];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [_moviePlayerController setShouldAutoplay:NO];
    
    // There appears to be an OS bug on iOS 8
    // where if you don't call "stop" before a movie player view disappears
    // it can cause a crash
    // See http://stackoverflow.com/questions/31188035/overreleased-mpmovieplayercontroller-under-arc-in-ios-sdk-8-4-on-ipad
    if([UIDevice isOSVersionAtLeast9]) {
        [_moviePlayerController pause];
    }
    else {
        [_moviePlayerController stop];
    }
    //Stop VR Video
    if (_videoView != nil) {
        [_videoView stop];
    }
    _shouldRotate = NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [_moviePlayerController setShouldAutoplay:YES];
    _shouldRotate = YES;
}

- (void)videoPlayerShouldRotate {
    [_moviePlayerController setShouldAutoplay:YES];
    _shouldRotate = YES;
}

- (void)orientationChanged:(NSNotification*)notification {
    //To enable landscape orientation in MyVideos section, we are commenting this code.
    //AMAT
    if (!isVRVideo) {
        
    }else{
        // _videoView.displayMode = kGVRWidgetDisplayModeFullscreenVR;
        
        if(_shouldRotate) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(manageOrientation) object:nil];
            
            if(![self isVerticallyCompact]) {
                [self manageOrientation];
            }
            else {
                [self performSelector:@selector(manageOrientation) withObject:nil afterDelay:0.8];
            }
        }
    }
    
}
- (void) stopVRPlayer{
    if (_videoView != nil) {
        [_videoView pause];
    }
}
- (void) rotateVRPlayerInLandscape{
    _videoView.displayMode = kGVRWidgetDisplayModeFullscreenVR;
    [self setNeedsStatusBarAppearanceUpdate];
    
}
- (void)manageOrientation {
    
    if (!isVRVideo) {
        
        if(!((self.moviePlayerController.playbackState == MPMoviePlaybackStatePlaying) || self.moviePlayerController.playbackState == MPMoviePlaybackStatePaused ) && !_moviePlayerController.isFullscreen) {
            return;
        }
        
        UIInterfaceOrientation deviceOrientation = [self currentOrientation];
        
        if(deviceOrientation == UIInterfaceOrientationPortrait) {      // PORTRAIT MODE
            if(self.moviePlayerController.fullscreen) {
                //7-10-2016 kAMAT_changes
                //[_moviePlayerController setFrame:self.defaultFrame];
                
                [_moviePlayerController setFullscreen:NO withOrientation:UIInterfaceOrientationPortrait];
                _moviePlayerController.controlStyle = MPMovieControlStyleNone;
                [_moviePlayerController.controls setStyle:CLVideoPlayerControlsStyleEmbedded];
            }
        }   //LANDSCAPE MODE
        else if(deviceOrientation == UIDeviceOrientationLandscapeLeft || deviceOrientation == UIInterfaceOrientationLandscapeRight) {
            [_moviePlayerController setFullscreen:NO withOrientation:deviceOrientation animated:YES forceRotate:YES];
            _moviePlayerController.controlStyle = MPMovieControlStyleNone;
            [_moviePlayerController.controls setStyle:CLVideoPlayerControlsStyleFullscreen];
        }
        
        
    }else{
        UIInterfaceOrientation deviceOrientation = [self currentOrientation];
        
        if(deviceOrientation == UIInterfaceOrientationPortrait) {      // PORTRAIT MODE
            //        if(self.moviePlayerController.fullscreen) {
            //            [_moviePlayerController setFullscreen:NO withOrientation:UIInterfaceOrientationPortrait];
            //            _moviePlayerController.controlStyle = MPMovieControlStyleNone;
            //            [_moviePlayerController.controls setStyle:CLVideoPlayerControlsStyleEmbedded];
            //        }
            //[_videoView setFrame:self.defaultFrame];
            
        }   //LANDSCAPE MODE
        else if(deviceOrientation == UIDeviceOrientationLandscapeLeft || deviceOrientation == UIInterfaceOrientationLandscapeRight ||
                /* kAMAT_Changes*/  deviceOrientation == UIDeviceOrientationLandscapeRight ||
                deviceOrientation == UIInterfaceOrientationLandscapeLeft) {
            
            //Showing an alert to tell user to put the device in Anti clock-wise horizontal mode.
            if (/* kAMAT_Changes*/  deviceOrientation == UIDeviceOrientationLandscapeRight ||
                deviceOrientation == UIInterfaceOrientationLandscapeLeft) {
                UIAlertView *orientationAlert;
                if (orientationAlert == nil){
                    /*
                    orientationAlert  = [[UIAlertView alloc] initWithTitle:@"appliedx" message:@"Please turn your device in anti clock wise to view VR Video in Split mode" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                    [orientationAlert show];
                    
                    [self.view bringSubviewToFront:orientationAlert];
                     */
                }
            }
            else  {
                [self.videoPlayerVideoView bringSubviewToFront:_videoView];
                _videoView.displayMode = kGVRWidgetDisplayModeFullscreenVR;
            }
            
            //[_videoView setFrame:self.defaultFrame];
            
            //        [_moviePlayerController setFullscreen:YES withOrientation:deviceOrientation animated:YES forceRotate:YES];
            //        _moviePlayerController.controlStyle = MPMovieControlStyleNone;
            //        [_moviePlayerController.controls setStyle:CLVideoPlayerControlsStyleFullscreen];
            //dispatch_after_seconds(0.01) {
            //    if let button = self.videoView.subviews[1] as? UIButton {
            //
            //        button.sendActionsForControlEvents(.TouchUpInside)
            //    }
            
        }
    }
    
    /*
     if(!((self.moviePlayerController.playbackState == MPMoviePlaybackStatePlaying) || self.moviePlayerController.playbackState == MPMoviePlaybackStatePaused ) && !_moviePlayerController.isFullscreen) {
     return;
     }
     
     UIInterfaceOrientation deviceOrientation = [self currentOrientation];
     
     if(deviceOrientation == UIInterfaceOrientationPortrait) {      // PORTRAIT MODE
     if(self.moviePlayerController.fullscreen) {
     [_moviePlayerController setFullscreen:NO withOrientation:UIInterfaceOrientationPortrait];
     _moviePlayerController.controlStyle = MPMovieControlStyleNone;
     [_moviePlayerController.controls setStyle:CLVideoPlayerControlsStyleEmbedded];
     }
     }   //LANDSCAPE MODE
     else if(deviceOrientation == UIDeviceOrientationLandscapeLeft || deviceOrientation == UIInterfaceOrientationLandscapeRight) {
     [_moviePlayerController setFullscreen:YES withOrientation:deviceOrientation animated:YES forceRotate:YES];
     _moviePlayerController.controlStyle = MPMovieControlStyleNone;
     [_moviePlayerController.controls setStyle:CLVideoPlayerControlsStyleFullscreen];
     }
     */
    
    //    if(!((_videoView.playbackState == MPMoviePlaybackStatePlaying) || self.moviePlayerController.playbackState == MPMoviePlaybackStatePaused ) && !_moviePlayerController.isFullscreen) {
    //        return;
    //    }
    
    
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)exitFullScreenMode:(NSNotification*)notification {
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)enterFullScreenMode:(NSNotification*)notification {
    [self setNeedsStatusBarAppearanceUpdate];
}
//- (void)movieDurationNotification:(NSNotification*)notification {

- (void)movieDurationNotification {
    
    //NSLog(@" duration %f",_moviePlayerController.duration);
    //NSLog(@" playableDuration %f",_moviePlayerController.playableDuration);
    if (bufferingLable == nil)
    {
        bufferingLable = [[UILabel alloc] init];
        bufferingLable.textColor = [UIColor blueColor];
        bufferingLable.text = @"Buffering..Please wait";
        
        CGSize size = [bufferingLable.text sizeWithAttributes:
                       @{NSFontAttributeName: [UIFont systemFontOfSize:17.0f]}];
        
        // Values are fractional -- you should take the ceilf to get equivalent values
        CGSize adjustedSize = CGSizeMake(ceilf(size.width), ceilf(size.height));
        [bufferingLable setFrame:CGRectMake(0, 0, adjustedSize.width, adjustedSize.height)];
        bufferingLable.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight| UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin);
        
        [bufferingLable setCenter:_moviePlayerController.view.center];
        [_moviePlayerController.view addSubview:bufferingLable];
        
    }
    
    if (_moviePlayerController.duration > 0.0 && _moviePlayerController.playableDuration > 0.0)
    {
        if (_moviePlayerController.playableDuration >= _moviePlayerController.duration / 10)
        {
            // playable duration is half of the player duration.
            // That is half of the video is buffered.
            bufferingLable.hidden = YES;
            
            [_moviePlayerController play];
            [m_timer invalidate];
        } else {
            [_moviePlayerController pause];
            //bufferingLable.hidden = NO;
        }
    } else {
        [_moviePlayerController pause];
        //bufferingLable.hidden = NO;
    }
}

- (void)viewDidLayoutSubviews {
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        _width = 700.f;
        _height = 535.f;
    }
    else {
        if (!_width)
            _width = self.view.frame.size.width;
        
        if ([self isVerticallyCompact]) {
            if (!_height)
                _height = [[UIScreen mainScreen] bounds].size.height - 84; // height of nav n toolbar
            
        }
        else {
            if (!_height)
                _height = 220;
        }
        
    }
    //calulate the frame on every rotation, so when we're returning from fullscreen mode we'll know where to position the movie player
    self.defaultFrame = CGRectMake(self.view.frame.size.width / 2 - _width / 2, 0, _width, _height);
    
    //only manage the movie player frame when it's not in fullscreen. when in fullscreen, the frame is automatically managed
    
    if(self.moviePlayerController.isFullscreen) {
        return;
    }
    
    //you MUST use [CLMoviePlayerController setFrame:] to adjust frame, NOT [CLMoviePlayerController.view setFrame:]
    if (!isVRVideo)
    {
        [self.moviePlayerController setFrame:self.defaultFrame];
    }else {
        [_videoView setFrame:self.defaultFrame];
    }
    //KAMAT_changes
    //    [_videoView setFrame:self.defaultFrame];
    //    id fullScreenButton = _videoView.subviews[1];
    //    if  ([fullScreenButton isKindOfClass:[UIButton class]]){
    //        [fullScreenButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    //    }
    
    //    self.moviePlayerController.view.layer.borderColor = [UIColor redColor].CGColor;
    //    self.moviePlayerController.view.layer.borderWidth = 2;
    
    //    _videoView.displayMode = kGVRWidgetDisplayModeFullscreenVR;
}

- (void)moviePlayerWillMoveFromWindow {
    //movie player must be readded to this view upon exiting fullscreen mode.
    
    if(![self.view.subviews containsObject:self.moviePlayerController.view]) {
        [self.view addSubview:self.moviePlayerController.view];
    }
    
    //you MUST use [CLMoviePlayerController setFrame:] to adjust frame, NOT [CLMoviePlayerController.view setFrame:]
    //NSLog(@"set frame from  player delegate ");
    [self.moviePlayerController setFrame:self.defaultFrame];
}

- (void)playerDidStopPlaying:(NSURL*)videoUrl atPlayBackTime:(float)currentTime {
    NSString* url = [videoUrl absoluteString];
    
    if([_lastPlayedVideo.summary.videoURL isEqualToString:url] || [_lastPlayedVideo.filePath isEqualToString:url]) {
        if(currentTime > 0) {
            NSTimeInterval totalTime = self.moviePlayerController.duration;
            
            [[OEXInterface sharedInterface] markLastPlayedInterval:currentTime forVideo:_lastPlayedVideo];
            OEXPlayedState state = OEXDoublesWithinEpsilon(totalTime, currentTime) ? OEXPlayedStateWatched : OEXPlayedStatePartiallyWatched;
            [[OEXInterface sharedInterface] markVideoState:state forVideo:_lastPlayedVideo];
        }
    }
    else {
        if(currentTime > 0) {
            [[OEXInterface sharedInterface] markLastPlayedInterval:currentTime forVideo:_currentVideo];
        }
    }
}

- (void) videoPlayerTapped:(UIGestureRecognizer *) sender {
    if([self.delegate respondsToSelector:@selector(videoPlayerTapped:)]) {
        [self.delegate videoPlayerTapped:sender];
    }
}

- (BOOL)prefersStatusBarHidden {
    return [self.moviePlayerController isFullscreen];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return [OEXStyles sharedStyles].standardStatusBarStyle;
}

- (BOOL)hidesNextPrev {
    return self.moviePlayerController.controls.hidesNextPrev;
}

- (void)setHidesNextPrev:(BOOL)hidesNextPrev {
    [self.moviePlayerController.controls setHidesNextPrev:hidesNextPrev];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    _moviePlayerController.delegate = nil;
}

#pragma mark - NSURLConnection Delegate methods

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
    NSLog(@"Is Authentication Required ? YES");
    return YES;
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    
    //    NSURLCredential *credential = [NSURLCredential credentialWithUser:@"staff" password:@"edx123" persistence:NSURLCredentialPersistenceForSession];
    //
    NSURLCredential *credential = [NSURLCredential credentialWithUser:@"" password:@"" persistence:NSURLCredentialPersistenceForSession];
    
    [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSLog(@"%s", __func__);
    responseData = [NSMutableData new];
    
}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSLog(@"%s", __func__);
    [responseData appendData:data];
    
    
}
- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error
{
    NSLog(@"Connection failed! Error - %@ ",[error localizedDescription]) ;
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSLog(@"%s", __func__);
    if (responseData != nil) {
        NSString *response = [[NSString alloc] initWithData:responseData encoding:NSASCIIStringEncoding];
        //NSLog(@"%s -- Signed URL -%@",__FUNCTION__,response);
        //NSLog(@"%s -- Signed URL After replacing spaces -%@",__FUNCTION__,[response  stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]);
        if (response) {
            //[self playSignedVideo:[response  stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] inTable:self.table_Videos atIndex:selectedVideoIndexPath];
            //            [self playSignedVideo:response inTable:self.table_Videos atIndex:selectedVideoIndexPath];
            float timeinterval = [[OEXInterface sharedInterface] lastPlayedIntervalForVideo:globalVideo];
            [self playVideoFromURL:[NSURL URLWithString:response] withTitle:globalVideo.summary.name
                      timeInterval:timeinterval videoURL:globalVideo.summary.videoURL];
            
        }
    }else{
        UIAlertView *nilDataAlert = [[UIAlertView alloc] initWithTitle:kAppName message:@"Unable to Play video. Please try again" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [nilDataAlert show];
    }
}

#pragma mark - GVRVideoViewDelegate

- (void)widgetViewDidTap:(GVRWidgetView *)widgetView {
    //Customization of VR player button colors
    //    for (UIButton *playerContolBtn in _videoView.subviews) {
    //        playerContolBtn.tintColor = [UIColor colorWithRed:65/255.0f green:119/255.0f blue:187/255.0f alpha:1.0];
    //    }
    
    if (_isPaused) {
        [_videoView resume];
    } else {
        [_videoView pause];
    }
    _isPaused = !_isPaused;
}

- (void)widgetView:(GVRWidgetView *)widgetView didLoadContent:(id)content {
    NSLog(@"Finished loading video");
}

- (void)widgetView:(GVRWidgetView *)widgetView
didFailToLoadContent:(id)content
  withErrorMessage:(NSString *)errorMessage {
    //Customization of VR player button colors
    //    for (UIButton *playerContolBtn in _videoView.subviews) {
    //        playerContolBtn.tintColor = [UIColor colorWithRed:65/255.0f green:119/255.0f blue:187/255.0f alpha:1.0];
    //    }
    
    NSLog(@"Failed to load video: %@", errorMessage);
}

- (void)videoView:(GVRVideoView*)videoView didUpdatePosition:(NSTimeInterval)position {
    
    //Customization of VR player button colors
    //    for (UIButton *playerContolBtn in _videoView.subviews) {
    //        playerContolBtn.tintColor = [UIColor colorWithRed:65/255.0f green:119/255.0f blue:187/255.0f alpha:1.0];
    //    }
    
    // Loop the video when it reaches the end.
    //    if (position == videoView.duration) {
    //        [_videoView seekTo:0];
    //        [_videoView resume];
    //    }
}
- (void)widgetView:(GVRWidgetView *)widgetView
didChangeDisplayMode:(GVRWidgetDisplayMode)displayMode{
    
    switch (displayMode) {
        case kGVRWidgetDisplayModeEmbedded:
        {
            [_videoView stop];
            [_videoView removeFromSuperview];
            
            [self.navigationController popViewControllerAnimated:YES];
        }
            break;
            
        default:
            break;
    }
}
@end
