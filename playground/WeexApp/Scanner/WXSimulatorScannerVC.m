//
//  WXSimulatorScannerVC.m
//  WeexApp
//
//  Created by 韩炜伟 on 16/8/13.
//  Copyright © 2016年 taobao. All rights reserved.
//

#ifdef DEBUG

#import "AppDelegate.h"
#import "UIViewController+WXDemoNaviBar.h"
#import "WXDemoViewController.h"

#import "WXDebugTool.h"
#import "WXDevTool.h"

#import <AudioToolbox/AudioToolbox.h>
#import <WeexSDK/WXSDKEngine.h>
#import "WXSimulatorScannerVC.h"



@interface WXSimulatorScannerVC ()

@property (weak, nonatomic) IBOutlet UITextField *tfDebugHost;
@property (weak, nonatomic) IBOutlet UITextField *tfDebugPort;

@property (weak, nonatomic) IBOutlet UITextField *tfPageUrl;


@end

@implementation WXSimulatorScannerVC

#pragma mark - lifeCircle

- (void)dealloc {
    
}

- (IBAction)connectDebugServer:(id)sender {
    
    NSString *url = @"http://%@:8088/devtool_fake.html?_wx_devtool=ws://%@:%@/debugProxy/native";
    url = [NSString stringWithFormat:url,_tfDebugHost.text,_tfDebugHost.text,_tfDebugPort.text];
    [self remoteDebug:[NSURL URLWithString:url]];
}

- (IBAction)viewPage:(id)sender {
    NSString *url = _tfPageUrl.text;
    if (url && ![@"" isEqualToString:url] ) {
        [self openURL:url];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    [self setupNaviBar];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
}


- (void)openURL:(NSString*)URL
{
    NSURL *url = [NSURL URLWithString:URL];
    if ([self remoteDebug:url]) {
        return;
    }
    [self jsReplace:url];
    WXDemoViewController * controller = [[WXDemoViewController alloc] init];
    controller.url = url;
    controller.source = @"scan";
    
    if ([url.port integerValue] == 8081) {
        NSURL *socketURL = [NSURL URLWithString:[NSString stringWithFormat:@"ws://%@:8082", url.host]];
        controller.hotReloadSocket = [[SRWebSocket alloc] initWithURL:socketURL protocols:@[@"echo-protocol"]];
        controller.hotReloadSocket.delegate = controller;
        [controller.hotReloadSocket open];
    }
    
    [[self navigationController] pushViewController:controller animated:YES];
}

#pragma mark - Replace JS
- (void)jsReplace:(NSURL *)url
{
    if ([[url host] isEqualToString:@"weex-remote-debugger"]){
        NSString* path = [url path];
        if ([path isEqualToString:@"/dynamic/replace/bundle"]){
            for (NSString * param in [[url query] componentsSeparatedByString:@"&"]) {
                NSArray* elts = [param componentsSeparatedByString:@"="];
                if ([elts count] < 2) {
                    continue;
                }
                if ([[elts firstObject] isEqualToString:@"bundle"]){
                    [WXDebugTool setReplacedBundleJS:[NSURL URLWithString:[elts lastObject]]];
                }
            }
        }
        
        if ([path isEqualToString:@"/dynamic/replace/framework"]){
            for (NSString * param in [[url query] componentsSeparatedByString:@"&"]) {
                NSArray* elts = [param componentsSeparatedByString:@"="];
                if ([elts count] < 2) {
                    continue;
                }
                if ([[elts firstObject] isEqualToString:@"framework"]){
                    [WXDebugTool setReplacedJSFramework:[NSURL URLWithString:[elts lastObject]]];
                }
            }
        }
    }
}

#pragma mark Remote debug
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
- (BOOL)remoteDebug:(NSURL *)url
{
    if ([url.scheme isEqualToString:@"ws"]) {
        [WXSDKEngine connectDebugServer:url.absoluteString];
        [WXSDKEngine initSDKEnviroment];
        
        return YES;
    }
    
    NSString *query = url.query;
    for (NSString *param in [query componentsSeparatedByString:@"&"]) {
        NSArray *elts = [param componentsSeparatedByString:@"="];
        if([elts count] < 2) continue;
        if ([[elts firstObject] isEqualToString:@"_wx_debug"]) {
            [WXDebugTool setDebug:YES];
            [WXSDKEngine connectDebugServer:[[elts lastObject]  stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
            if ([[[self.navigationController viewControllers] objectAtIndex:0] isKindOfClass:NSClassFromString(@"WXDemoViewController")]) {
                WXDemoViewController * vc = (WXDemoViewController*)[[self.navigationController viewControllers] objectAtIndex:0];
                [vc performSelector:NSSelectorFromString(@"loadRefreshCtl")];
                [self.navigationController popToViewController:vc animated:NO];
            }
            return YES;
        } else if ([[elts firstObject] isEqualToString:@"_wx_devtool"]) {
            NSString *devToolURL = [[elts lastObject]  stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            [WXDevTool setDebug:YES];
            [WXDevTool launchDevToolDebugWithUrl:devToolURL];
            
            [WXSDKEngine restart];
            
            if ([[[self.navigationController viewControllers] objectAtIndex:0] isKindOfClass:NSClassFromString(@"WXDemoViewController")]) {
                WXDemoViewController * vc = (WXDemoViewController*)[[self.navigationController viewControllers] objectAtIndex:0];
                [self.navigationController popToViewController:vc animated:NO];
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshInstance" object:nil];
            
            return YES;
        }
    }
    
    return NO;
}
#pragma clang diagnostic pop


@end


#endif