//
//  OEXMyVideosVRViewController.m
//  edX
//
//  Created by Prudvee on 26/10/16.
//  Copyright © 2016 edX. All rights reserved.
//

#import "OEXMyVideosVRViewController.h"
#import "GVRVideoView.h"

@interface OEXMyVideosVRViewController () <GVRVideoViewDelegate>
@property(nonatomic) GVRVideoView *vrPlayerVideoView;

@end

@implementation OEXMyVideosVRViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    
    self.vrPlayerVideoView = [[GVRVideoView alloc] initWithFrame:self.view.frame];
    self.vrPlayerVideoView.delegate = self;
    self.vrPlayerVideoView.enableFullscreenButton = YES;
    self.vrPlayerVideoView.enableCardboardButton = YES;
    [self.view addSubview:self.vrPlayerVideoView];
    //self.vrPlayerVideoView.displayMode = kGVRWidgetDisplayModeFullscreenVR;
    
    //NSFileManager* filemgr = [NSFileManager defaultManager];
    //NSString* path = [self.currentTappedVideo.filePath stringByAppendingPathExtension:@"mp4"];
    
    [self.vrPlayerVideoView loadFromUrl:self.videoURL];
    
    
    
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - GVRVideoViewDelegate

- (void)widgetViewDidTap:(GVRWidgetView *)widgetView {
    
}

- (void)widgetView:(GVRWidgetView *)widgetView didLoadContent:(id)content {
    NSLog(@"Finished loading video");
}
- (void)widgetView:(GVRWidgetView *)widgetView
didChangeDisplayMode:(GVRWidgetDisplayMode)displayMode{
    [widgetView.subviews[0] setNeedsLayout];
    
    switch (displayMode) {
        case kGVRWidgetDisplayModeEmbedded:
        {
            [self.vrPlayerVideoView stop];
            [self.vrPlayerVideoView removeFromSuperview];
            [self.navigationController popViewControllerAnimated:YES];
        }
            break;
            
        default:
            break;
    }
}

- (void)widgetView:(GVRWidgetView *)widgetView
didFailToLoadContent:(id)content
  withErrorMessage:(NSString *)errorMessage {
    NSLog(@"Failed to load video: %@", errorMessage);
}

- (void)videoView:(GVRVideoView*)videoView didUpdatePosition:(NSTimeInterval)position{
    // Loop the video when it reaches the end.
    //[videoView.subviews[0] setNeedsLayout];
    
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
