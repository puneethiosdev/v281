//
//  WebKitController.h
//  D3iOS
//
//  Created by Puneet JR on 04/03/17.
//  Copyright (c) 2017 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import "Constants.h"

@interface WebKitController : NSObject <WKScriptMessageHandler>

@property (nonatomic, strong) WKWebViewConfiguration *config;
@property (nonatomic, strong) WKUserContentController *contentController;
@property (nonatomic, strong) WKUserScript *d3script;


+(id)sharedInstance;

@end
