/*
 Licensed to the Apache Software Foundation (ASF) under one
 or more contributor license agreements.  See the NOTICE file
 distributed with this work for additional information
 regarding copyright ownership.  The ASF licenses this file
 to you under the Apache License, Version 2.0 (the
 "License"); you may not use this file except in compliance
 with the License.  You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing,
 software distributed under the License is distributed on an
 "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 KIND, either express or implied.  See the License for the
 specific language governing permissions and limitations
 under the License.
 */

#import "CDVWKInAppBrowser.h"

#if __has_include(<Cordova/CDVWebViewProcessPoolFactory.h>) // Cordova-iOS >=6
  #import <Cordova/CDVWebViewProcessPoolFactory.h>
#elif __has_include("CDVWKProcessPoolFactory.h") // Cordova-iOS <6 with WKWebView plugin
  #import "CDVWKProcessPoolFactory.h"
#endif

#import <Cordova/CDVPluginResult.h>

#define    kInAppBrowserTargetSelf @"_self"
#define    kInAppBrowserTargetSystem @"_system"
#define    kInAppBrowserTargetBlank @"_blank"

#define    kInAppBrowserToolbarBarPositionBottom @"bottom"
#define    kInAppBrowserToolbarBarPositionTop @"top"

#define    IAB_BRIDGE_NAME @"cordova_iab"
#define    IAB_BRIDGE_DOWNLOAD_NAME @"cordova_iab_download"

#define    TOOLBAR_HEIGHT 44.0
#define    LOCATIONBAR_HEIGHT 21.0
#define    FOOTER_HEIGHT TOOLBAR_HEIGHT

#pragma mark CDVWKInAppBrowser

@interface CDVWKInAppBrowser () {
    NSInteger _previousStatusBarStyle;
}
@end

@implementation CDVWKInAppBrowser

static CDVWKInAppBrowser* instance = nil;

+ (id) getInstance{
    return instance;
}

- (void)pluginInitialize
{
    instance = self;
    _previousStatusBarStyle = -1;
    _callbackIdPattern = nil;
    _beforeload = @"";
    _waitForBeforeload = NO;
}

- (void)onReset
{
    [self close:nil];
}

- (void)close:(CDVInvokedUrlCommand*)command
{
    if (self.inAppBrowserViewController == nil) {
        NSLog(@"IAB.close() called but it was already closed.");
        return;
    }
    
    // Things are cleaned up in browserExit.
    [self.inAppBrowserViewController close];
}

- (BOOL) isSystemUrl:(NSURL*)url
{
    if ([[url host] isEqualToString:@"itunes.apple.com"]) {
        return YES;
    }
    
    return NO;
}

- (void)open:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult;
    
    NSString* url = [command argumentAtIndex:0];
    NSString* target = [command argumentAtIndex:1 withDefault:kInAppBrowserTargetSelf];
    NSString* options = [command argumentAtIndex:2 withDefault:@"" andClass:[NSString class]];
    
    self.callbackId = command.callbackId;
    
    if (url != nil) {
        NSURL* baseUrl = [self.webViewEngine URL];
        NSURL* absoluteUrl = [[NSURL URLWithString:url relativeToURL:baseUrl] absoluteURL];
        
        if ([self isSystemUrl:absoluteUrl]) {
            target = kInAppBrowserTargetSystem;
        }
        
        if ([target isEqualToString:kInAppBrowserTargetSelf]) {
            [self openInCordovaWebView:absoluteUrl withOptions:options];
        } else if ([target isEqualToString:kInAppBrowserTargetSystem]) {
            [self openInSystem:absoluteUrl];
        } else { // _blank or anything else
            self.CDVBrowserOptions  = [CDVInAppBrowserOptions parseOptions:options];
            [self openInInAppBrowser:absoluteUrl withOptions:options];
        }
        
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"incorrect number of arguments"];
    }
    
    [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)openInInAppBrowser:(NSURL*)url withOptions:(NSString*)options
{
    CDVInAppBrowserOptions* browserOptions = [CDVInAppBrowserOptions parseOptions:options];
    
    WKWebsiteDataStore* dataStore = [WKWebsiteDataStore defaultDataStore];
    if (browserOptions.cleardata) {
        
        NSDate* dateFrom = [NSDate dateWithTimeIntervalSince1970:0];
        [dataStore removeDataOfTypes:[WKWebsiteDataStore allWebsiteDataTypes] modifiedSince:dateFrom completionHandler:^{
            NSLog(@"Removed all WKWebView data");
            self.inAppBrowserViewController.webView.configuration.processPool = [[WKProcessPool alloc] init]; // create new process pool to flush all data
        }];
    }
    
    if (browserOptions.clearcache) {
        bool isAtLeastiOS11 = false;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 110000
        if (@available(iOS 11.0, *)) {
            isAtLeastiOS11 = true;
        }
#endif
            
        if(isAtLeastiOS11){
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 110000
            // Deletes all cookies
            WKHTTPCookieStore* cookieStore = dataStore.httpCookieStore;
            [cookieStore getAllCookies:^(NSArray* cookies) {
                NSHTTPCookie* cookie;
                for(cookie in cookies){
                    [cookieStore deleteCookie:cookie completionHandler:nil];
                }
            }];
#endif
        }else{
            // https://stackoverflow.com/a/31803708/777265
            // Only deletes domain cookies (not session cookies)
            [dataStore fetchDataRecordsOfTypes:[WKWebsiteDataStore allWebsiteDataTypes]
             completionHandler:^(NSArray<WKWebsiteDataRecord *> * __nonnull records) {
                 for (WKWebsiteDataRecord *record  in records){
                     NSSet<NSString*>* dataTypes = record.dataTypes;
                     if([dataTypes containsObject:WKWebsiteDataTypeCookies]){
                         [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:record.dataTypes
                               forDataRecords:@[record]
                               completionHandler:^{}];
                     }
                 }
             }];
        }
    }
    
    if (browserOptions.clearsessioncache) {
        bool isAtLeastiOS11 = false;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 110000
        if (@available(iOS 11.0, *)) {
            isAtLeastiOS11 = true;
        }
#endif
        if (isAtLeastiOS11) {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 110000
            // Deletes session cookies
            WKHTTPCookieStore* cookieStore = dataStore.httpCookieStore;
            [cookieStore getAllCookies:^(NSArray* cookies) {
                NSHTTPCookie* cookie;
                for(cookie in cookies){
                    if(cookie.sessionOnly){
                        [cookieStore deleteCookie:cookie completionHandler:nil];
                    }
                }
            }];
#endif
        }else{
            NSLog(@"clearsessioncache not available below iOS 11.0");
        }
    }

    if (self.inAppBrowserViewController == nil) {
        self.inAppBrowserViewController = [[CDVWKInAppBrowserViewController alloc] initWithBrowserOptions: browserOptions andSettings:self.commandDelegate.settings];
        self.inAppBrowserViewController.navigationDelegate = self;
        
        if ([self.viewController conformsToProtocol:@protocol(CDVScreenOrientationDelegate)]) {
            self.inAppBrowserViewController.orientationDelegate = (UIViewController <CDVScreenOrientationDelegate>*)self.viewController;
        }
    }
    
    [self.inAppBrowserViewController showLocationBar:browserOptions.location];
    [self.inAppBrowserViewController showToolBar:browserOptions.toolbar :browserOptions.toolbarposition];
    if (browserOptions.closebuttoncaption != nil || browserOptions.closebuttoncolor != nil) {
        int closeButtonIndex = browserOptions.lefttoright ? (browserOptions.hidenavigationbuttons ? 1 : 4) : 0;
        [self.inAppBrowserViewController setCloseButtonTitle:browserOptions.closebuttoncaption :browserOptions.closebuttoncolor :closeButtonIndex];
    }
    // Set Presentation Style
    UIModalPresentationStyle presentationStyle = UIModalPresentationFullScreen; // default
    if (browserOptions.presentationstyle != nil) {
        if ([[browserOptions.presentationstyle lowercaseString] isEqualToString:@"pagesheet"]) {
            presentationStyle = UIModalPresentationPageSheet;
        } else if ([[browserOptions.presentationstyle lowercaseString] isEqualToString:@"formsheet"]) {
            presentationStyle = UIModalPresentationFormSheet;
        }
    }
    self.inAppBrowserViewController.modalPresentationStyle = presentationStyle;
    
    // Set Transition Style
    UIModalTransitionStyle transitionStyle = UIModalTransitionStyleCoverVertical; // default
    if (browserOptions.transitionstyle != nil) {
        if ([[browserOptions.transitionstyle lowercaseString] isEqualToString:@"fliphorizontal"]) {
            transitionStyle = UIModalTransitionStyleFlipHorizontal;
        } else if ([[browserOptions.transitionstyle lowercaseString] isEqualToString:@"crossdissolve"]) {
            transitionStyle = UIModalTransitionStyleCrossDissolve;
        }
    }
    self.inAppBrowserViewController.modalTransitionStyle = transitionStyle;
    
    //prevent webView from bouncing
    if (browserOptions.disallowoverscroll) {
        if ([self.inAppBrowserViewController.webView respondsToSelector:@selector(scrollView)]) {
            ((UIScrollView*)[self.inAppBrowserViewController.webView scrollView]).bounces = NO;
        } else {
            for (id subview in self.inAppBrowserViewController.webView.subviews) {
                if ([[subview class] isSubclassOfClass:[UIScrollView class]]) {
                    ((UIScrollView*)subview).bounces = NO;
                }
            }
        }
    }
    
    // use of beforeload event
    if([browserOptions.beforeload isKindOfClass:[NSString class]]){
        _beforeload = browserOptions.beforeload;
    }else{
        _beforeload = @"yes";
    }
    _waitForBeforeload = ![_beforeload isEqualToString:@""];
    
    [self.inAppBrowserViewController navigateTo:url];
    if (!browserOptions.hidden) {
        [self show:nil withNoAnimate:browserOptions.hidden];
    }
}

- (void)show:(CDVInvokedUrlCommand*)command{
    [self show:command withNoAnimate:NO];
}

- (void)show:(CDVInvokedUrlCommand*)command withNoAnimate:(BOOL)noAnimate
{
    BOOL initHidden = NO;
    if(command == nil && noAnimate == YES){
        initHidden = YES;
    }
    
    if (self.inAppBrowserViewController == nil) {
        NSLog(@"Tried to show IAB after it was closed.");
        return;
    }
    if (_previousStatusBarStyle != -1) {
        NSLog(@"Tried to show IAB while already shown");
        return;
    }
    
    if(!initHidden){
        _previousStatusBarStyle = [UIApplication sharedApplication].statusBarStyle;
    }
    
    [self setLayout:initHidden :noAnimate];
}

- (void)hide:(CDVInvokedUrlCommand*)command
{
    // Set tmpWindow to hidden to make main webview responsive to touch again
    // https://stackoverflow.com/questions/4544489/how-to-remove-a-uiwindow
    self->tmpWindow.hidden = YES;
    self->tmpWindow = nil;

    if (self.inAppBrowserViewController == nil) {
        NSLog(@"Tried to hide IAB after it was closed.");
        return;
        
        
    }
    if (_previousStatusBarStyle == -1) {
        NSLog(@"Tried to hide IAB while already hidden");
        return;
    }
    
    _previousStatusBarStyle = [UIApplication sharedApplication].statusBarStyle;
    
    // Run later to avoid the "took a long time" log message.
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.inAppBrowserViewController != nil) {
            _previousStatusBarStyle = -1;
            [self.inAppBrowserViewController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
        }
    });
}

- (void)openInCordovaWebView:(NSURL*)url withOptions:(NSString*)options
{
    NSURLRequest* request = [NSURLRequest requestWithURL:url];
    // the webview engine itself will filter for this according to <allow-navigation> policy
    // in config.xml for cordova-ios-4.0
    [self.webViewEngine loadRequest:request];
}

- (void)openInSystem:(NSURL*)url
{
    if ([[UIApplication sharedApplication] openURL:url] == NO) {
        [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:CDVPluginHandleOpenURLNotification object:url]];
        [[UIApplication sharedApplication] openURL:url];
    }
}

- (void)loadAfterBeforeload:(CDVInvokedUrlCommand*)command
{
    NSString* urlStr = [command argumentAtIndex:0];

    if ([_beforeload isEqualToString:@""]) {
        NSLog(@"unexpected loadAfterBeforeload called without feature beforeload=get|post");
    }
    if (self.inAppBrowserViewController == nil) {
        NSLog(@"Tried to invoke loadAfterBeforeload on IAB after it was closed.");
        return;
    }
    if (urlStr == nil) {
        NSLog(@"loadAfterBeforeload called with nil argument, ignoring.");
        return;
    }

    NSURL* url = [NSURL URLWithString:urlStr];
    //_beforeload = @"";
    _waitForBeforeload = NO;
    [self.inAppBrowserViewController navigateTo:url];
}

- (void)setOptions:(CDVInvokedUrlCommand *)command
{
    NSString* options = [command argumentAtIndex:0 withDefault:@"" andClass:[NSString class]];
    self.CDVBrowserOptions = [CDVInAppBrowserOptions parseOptions:options];
    [self.inAppBrowserViewController updateBrowserOptions: self->_CDVBrowserOptions];

    [self.inAppBrowserViewController showToolBar:self->_CDVBrowserOptions.toolbar :self->_CDVBrowserOptions.toolbarposition];
}

- (void)setLayout:(CDVInvokedUrlCommand*)command
{
    self->_CDVBrowserOptions.x = [command argumentAtIndex:0];
    self->_CDVBrowserOptions.y = [command argumentAtIndex:1];
    self->_CDVBrowserOptions.width = [command argumentAtIndex:2];
    self->_CDVBrowserOptions.height = [command argumentAtIndex:3];

    [self.inAppBrowserViewController updateBrowserOptions: self->_CDVBrowserOptions];

    if (_previousStatusBarStyle == -1) {
        return;
    }

    [self setLayout:NO :YES];
}

- (void)setLayout:(bool)initHidden :(bool)noAnimate
{
    __block CDVInAppBrowserNavigationController* nav = [[CDVInAppBrowserNavigationController alloc]
                                                        initWithRootViewController:self.inAppBrowserViewController];
    nav.orientationDelegate = self.inAppBrowserViewController;
    nav.navigationBarHidden = YES;
    nav.modalPresentationStyle = self.inAppBrowserViewController.modalPresentationStyle;

    __weak CDVWKInAppBrowser* weakSelf = self;

    // Run later to avoid the "took a long time" log message.
    dispatch_async(dispatch_get_main_queue(), ^{
        if (weakSelf.inAppBrowserViewController != nil) {
            float osVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
            __strong __typeof(weakSelf) strongSelf = weakSelf;

            CGRect frame = [[UIScreen mainScreen] bounds];
            if(initHidden && osVersion < 11){
               frame.origin.x = -10000;
            }

            frame = [strongSelf calcWindowFrame:frame];
            if (!strongSelf->tmpWindow) {
                strongSelf->tmpWindow = [[UIWindow alloc] initWithFrame:frame];
            } else {
                strongSelf->tmpWindow.frame = frame;
            }

            [strongSelf.inAppBrowserViewController rePositionViews];

            UIViewController *tmpController = [[UIViewController alloc] init];
            [strongSelf->tmpWindow setRootViewController:tmpController];
            [strongSelf->tmpWindow setWindowLevel:UIWindowLevelNormal];

            if(!initHidden || osVersion < 11){
                [strongSelf->tmpWindow makeKeyAndVisible];
            }

            [tmpController presentViewController:nav animated:!noAnimate completion:nil];
        }
    });
}

- (CGRect)calcWindowFrame:(CGRect) frame
{
    CGRect bounds = [[UIScreen mainScreen] bounds];

    double x        = self->_CDVBrowserOptions.x      != nil ? [self->_CDVBrowserOptions.x       doubleValue] : frame.origin.x;
    double y        = self->_CDVBrowserOptions.y      != nil ? [self->_CDVBrowserOptions.y       doubleValue] : frame.origin.y;
    double width    = self->_CDVBrowserOptions.width  != nil ? [self->_CDVBrowserOptions.width   doubleValue] : (frame.size.width - x); // For taking in consideration if (x) is set , custom width not set
    double height   = self->_CDVBrowserOptions.height != nil ? [self->_CDVBrowserOptions.height  doubleValue] : (frame.size.height - y); // For taking in consideration if (y) is set , custom height not set

    return CGRectMake(x , y , width , height );
}

- (CGRect)calcWebviewFrame:(CGRect) windowFrame
{
    BOOL locationbarVisible = !self.inAppBrowserViewController.addressLabel.hidden;
    BOOL toolbarVisible = !self.inAppBrowserViewController.toolbar.hidden;

    CGRect webViewBounds = self.inAppBrowserViewController.webView.bounds;
    webViewBounds.origin.x = windowFrame.origin.x;
    webViewBounds.origin.y = windowFrame.origin.y;
    webViewBounds.size.width = windowFrame.size.width;
    webViewBounds.size.height = windowFrame.size.height;

    if (self->_CDVBrowserOptions.location || self->_CDVBrowserOptions.toolbar) {
        if (locationbarVisible) {
            // webViewBounds.size.height -= LOCATIONBAR_HEIGHT;
        }

        if (toolbarVisible) {
            webViewBounds.size.height -= TOOLBAR_HEIGHT;
        }
    }

    return webViewBounds;
}

- (void)sendAuthBasic:(CDVInvokedUrlCommand*)command
{
    NSString* username = [command argumentAtIndex:0];
    NSString* password = [command argumentAtIndex:1];
    [self.inAppBrowserViewController sendAuthBasic:username :password];
}

- (void)cancelAuthBasic:(CDVInvokedUrlCommand*)command
{
    [self.inAppBrowserViewController cancelAuthBasic];
}

- (void)goBack:(CDVInvokedUrlCommand*)command
{
    [self.inAppBrowserViewController goBack];
}

- (void)goForward:(CDVInvokedUrlCommand*)command
{
    [self.inAppBrowserViewController goForward];
}

// This is a helper method for the inject{Script|Style}{Code|File} API calls, which
// provides a consistent method for injecting JavaScript code into the document.
//
// If a wrapper string is supplied, then the source string will be JSON-encoded (adding
// quotes) and wrapped using string formatting. (The wrapper string should have a single
// '%@' marker).
//
// If no wrapper is supplied, then the source string is executed directly.

- (void)injectDeferredObject:(NSString*)source withWrapper:(NSString*)jsWrapper
{
    // Ensure a message handler bridge is created to communicate with the CDVWKInAppBrowserViewController
    [self evaluateJavaScript: [NSString stringWithFormat:@"(function(w){if(!w._cdvMessageHandler) {w._cdvMessageHandler = function(id,d){w.webkit.messageHandlers.%@.postMessage({d:d, id:id});}}})(window)", IAB_BRIDGE_NAME]];
    
    if (jsWrapper != nil) {
        NSData* jsonData = [NSJSONSerialization dataWithJSONObject:@[source] options:0 error:nil];
        NSString* sourceArrayString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        if (sourceArrayString) {
            NSString* sourceString = [sourceArrayString substringWithRange:NSMakeRange(1, [sourceArrayString length] - 2)];
            NSString* jsToInject = [NSString stringWithFormat:jsWrapper, sourceString];
            [self evaluateJavaScript:jsToInject];
        }
    } else {
        [self evaluateJavaScript:source];
    }
}


//Synchronus helper for javascript evaluation
- (void)evaluateJavaScript:(NSString *)script {
    __block NSString* _script = script;
    [self.inAppBrowserViewController.webView evaluateJavaScript:script completionHandler:^(id result, NSError *error) {
        if (error == nil) {
            if (result != nil) {
                NSLog(@"%@", result);
            }
        } else {
            NSLog(@"evaluateJavaScript error : %@ : %@", error.localizedDescription, _script);
        }
    }];
}

- (void)injectScriptCode:(CDVInvokedUrlCommand*)command
{
    NSString* jsWrapper = nil;
    
    if ((command.callbackId != nil) && ![command.callbackId isEqualToString:@"INVALID"]) {
        jsWrapper = [NSString stringWithFormat:@"_cdvMessageHandler('%@',JSON.stringify([eval(%%@)]));", command.callbackId];
    }
    [self injectDeferredObject:[command argumentAtIndex:0] withWrapper:jsWrapper];
}

- (void)injectScriptFile:(CDVInvokedUrlCommand*)command
{
    NSString* jsWrapper;
    
    if ((command.callbackId != nil) && ![command.callbackId isEqualToString:@"INVALID"]) {
        jsWrapper = [NSString stringWithFormat:@"(function(d) { var c = d.createElement('script'); c.src = %%@; c.onload = function() { _cdvMessageHandler('%@'); }; d.body.appendChild(c); })(document)", command.callbackId];
    } else {
        jsWrapper = @"(function(d) { var c = d.createElement('script'); c.src = %@; d.body.appendChild(c); })(document)";
    }
    [self injectDeferredObject:[command argumentAtIndex:0] withWrapper:jsWrapper];
}

- (void)injectStyleCode:(CDVInvokedUrlCommand*)command
{
    NSString* jsWrapper;
    
    if ((command.callbackId != nil) && ![command.callbackId isEqualToString:@"INVALID"]) {
        jsWrapper = [NSString stringWithFormat:@"(function(d) { var c = d.createElement('style'); c.innerHTML = %%@; c.onload = function() { _cdvMessageHandler('%@'); }; d.body.appendChild(c); })(document)", command.callbackId];
    } else {
        jsWrapper = @"(function(d) { var c = d.createElement('style'); c.innerHTML = %@; d.body.appendChild(c); })(document)";
    }
    [self injectDeferredObject:[command argumentAtIndex:0] withWrapper:jsWrapper];
}

- (void)injectStyleFile:(CDVInvokedUrlCommand*)command
{
    NSString* jsWrapper;
    
    if ((command.callbackId != nil) && ![command.callbackId isEqualToString:@"INVALID"]) {
        jsWrapper = [NSString stringWithFormat:@"(function(d) { var c = d.createElement('link'); c.rel='stylesheet'; c.type='text/css'; c.href = %%@; c.onload = function() { _cdvMessageHandler('%@'); }; d.body.appendChild(c); })(document)", command.callbackId];
    } else {
        jsWrapper = @"(function(d) { var c = d.createElement('link'); c.rel='stylesheet', c.type='text/css'; c.href = %@; d.body.appendChild(c); })(document)";
    }
    [self injectDeferredObject:[command argumentAtIndex:0] withWrapper:jsWrapper];
}

- (BOOL)isValidCallbackId:(NSString *)callbackId
{
    NSError *err = nil;
    // Initialize on first use
    if (self.callbackIdPattern == nil) {
        self.callbackIdPattern = [NSRegularExpression regularExpressionWithPattern:@"^InAppBrowser[0-9]{1,10}$" options:0 error:&err];
        if (err != nil) {
            // Couldn't initialize Regex; No is safer than Yes.
            return NO;
        }
    }
    if ([self.callbackIdPattern firstMatchInString:callbackId options:0 range:NSMakeRange(0, [callbackId length])]) {
        return YES;
    }
    return NO;
}

/**
 * The message handler bridge provided for the InAppBrowser is capable of executing any oustanding callback belonging
 * to the InAppBrowser plugin. Care has been taken that other callbacks cannot be triggered, and that no
 * other code execution is possible.
 */
- (void)webView:(WKWebView *)theWebView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    
    NSURL* url = navigationAction.request.URL;
    NSURL* mainDocumentURL = navigationAction.request.mainDocumentURL;
    BOOL isTopLevelNavigation = [url isEqual:mainDocumentURL];
    BOOL shouldStart = YES;
    BOOL useBeforeLoad = NO;
    NSString* httpMethod = navigationAction.request.HTTPMethod;
    NSString* errorMessage = nil;
    
    if([_beforeload isEqualToString:@"post"]){
        //TODO handle POST requests by preserving POST data then remove this condition
        errorMessage = @"beforeload doesn't yet support POST requests";
    }
    else if(isTopLevelNavigation && (
           [_beforeload isEqualToString:@"yes"]
       || ([_beforeload isEqualToString:@"get"] && [httpMethod isEqualToString:@"GET"])
    // TODO comment in when POST requests are handled
    // || ([_beforeload isEqualToString:@"post"] && [httpMethod isEqualToString:@"POST"])
    )){
        useBeforeLoad = YES;
    }

    // When beforeload, on first URL change, initiate JS callback. Only after the beforeload event, continue.
    if (_waitForBeforeload && useBeforeLoad) {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                      messageAsDictionary:@{@"type":@"beforeload", @"url":[url absoluteString]}];
        [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
        
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    
    if(errorMessage != nil){
        NSLog(errorMessage);
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                      messageAsDictionary:@{@"type":@"loaderror", @"url":[url absoluteString], @"code": @"-1", @"message": errorMessage}];
        [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
    }
    
    //if is an app store, tel, sms, mailto or geo link, let the system handle it, otherwise it fails to load it
    NSArray * allowedSchemes = @[@"itms-appss", @"itms-apps", @"tel", @"sms", @"mailto", @"geo"];
    if ([allowedSchemes containsObject:[url scheme]]) {
        [theWebView stopLoading];
        [self openInSystem:url];
        shouldStart = NO;
    }
    else if ((self.callbackId != nil) && isTopLevelNavigation) {
        // Send a loadstart event for each top-level navigation (includes redirects).
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                      messageAsDictionary:@{@"type":@"loadstart", @"url":[url absoluteString]}];
        [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
        
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
    }

    if (useBeforeLoad) {
        _waitForBeforeload = YES;
    }
    
    if(shouldStart){
        // Fix GH-417 & GH-424: Handle non-default target attribute
        // Based on https://stackoverflow.com/a/25713070/777265
        if (!navigationAction.targetFrame){
            [theWebView loadRequest:navigationAction.request];
            decisionHandler(WKNavigationActionPolicyCancel);
        }else{
            decisionHandler(WKNavigationActionPolicyAllow);
        }
    }else{
        decisionHandler(WKNavigationActionPolicyCancel);
    }
}

#pragma mark WKScriptMessageHandler delegate
- (void)userContentController:(nonnull WKUserContentController *)userContentController didReceiveScriptMessage:(nonnull WKScriptMessage *)message {
    
    CDVPluginResult* pluginResult = nil;
    
    if([message.body isKindOfClass:[NSDictionary class]]){
        NSDictionary* messageContent = (NSDictionary*) message.body;
        NSString* scriptCallbackId = messageContent[@"id"];
        
        if([messageContent objectForKey:@"d"]){
            NSString* scriptResult = messageContent[@"d"];
            NSError* __autoreleasing error = nil;
            NSData* decodedResult = [NSJSONSerialization JSONObjectWithData:[scriptResult dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&error];
            if ((error == nil) && [decodedResult isKindOfClass:[NSArray class]]) {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:(NSArray*)decodedResult];
            } else {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_JSON_EXCEPTION];
            }
        } else {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:@[]];
        }
        [self.commandDelegate sendPluginResult:pluginResult callbackId:scriptCallbackId];
    }else if(self.callbackId != nil){
        // Send a message event
        NSString* messageContent = (NSString*) message.body;
        NSError* __autoreleasing error = nil;
        NSData* decodedResult = [NSJSONSerialization JSONObjectWithData:[messageContent dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&error];
        if (error == nil) {
            NSMutableDictionary* dResult = [NSMutableDictionary new];
            [dResult setValue:@"message" forKey:@"type"];
            [dResult setObject:decodedResult forKey:@"data"];
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dResult];
            [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
        }
    }
}

- (void)didStartProvisionalNavigation:(WKWebView*)theWebView
{
    NSLog(@"didStartProvisionalNavigation");
//    self.inAppBrowserViewController.currentURL = theWebView.URL;
}

- (void)didFinishNavigation:(WKWebView*)theWebView
{
    if (self.callbackId != nil) {
        NSString* url = [theWebView.URL absoluteString];
        if(url == nil){
            if(self.inAppBrowserViewController.currentURL != nil){
                url = [self.inAppBrowserViewController.currentURL absoluteString];
            }else{
                url = @"";
            }
        }
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                      messageAsDictionary:@{@"type":@"loadstop", @"url":url}];
        [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
        
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
    }

    [self.inAppBrowserViewController overrideFileSaverSaveAsFunction];
}

- (void)webView:(WKWebView*)theWebView didFailNavigation:(NSError*)error
{
    if (self.callbackId != nil) {
        NSString* url = [theWebView.URL absoluteString];
        if(url == nil){
            if(self.inAppBrowserViewController.currentURL != nil){
                url = [self.inAppBrowserViewController.currentURL absoluteString];
            }else{
                url = @"";
            }
        }
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                      messageAsDictionary:@{@"type":@"loaderror", @"url":url, @"code": [NSNumber numberWithInteger:error.code], @"message": error.localizedDescription}];
        [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
        
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
    }
}

- (void)browserExit
{
    if (self.callbackId != nil) {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                      messageAsDictionary:@{@"type":@"exit"}];
        
        if (!IsAtLeastiOSVersion(@"15.0") || IsAtLeastiOSVersion(@"16.0")) {
            [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
        }

        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
    }
    
    if (IsAtLeastiOSVersion(@"15.0") && !IsAtLeastiOSVersion(@"16.0")) {
        if (self.callbackId != nil) {
            self.callbackId = nil;
        }
    
        [self.inAppBrowserViewController.configuration.userContentController removeScriptMessageHandlerForName:IAB_BRIDGE_NAME];
        [self.inAppBrowserViewController.configuration.userContentController removeScriptMessageHandlerForName:IAB_BRIDGE_DOWNLOAD_NAME];
        self.inAppBrowserViewController.configuration = nil;
    
        [self.inAppBrowserViewController.webView stopLoading];
        [self.inAppBrowserViewController.webView removeFromSuperview];
        [self.inAppBrowserViewController.webView setUIDelegate:nil];
        [self.inAppBrowserViewController.webView setNavigationDelegate:nil];
        self.inAppBrowserViewController.webView = nil;
    
        // Set navigationDelegate to nil to ensure no callbacks are received from it.
        self.inAppBrowserViewController.navigationDelegate = nil;
        self.inAppBrowserViewController = nil;

        // Set tmpWindow to hidden to make main webview responsive to touch again
        // Based on https://stackoverflow.com/questions/4544489/how-to-remove-a-uiwindow
        self->tmpWindow.hidden = YES;
        self->tmpWindow = nil;

        if (IsAtLeastiOSVersion(@"7.0")) {
            if (_previousStatusBarStyle != -1) {
                [[UIApplication sharedApplication] setStatusBarStyle:_previousStatusBarStyle];
            }
        }
    
        _previousStatusBarStyle = -1; // this value was reset before reapplying it. caused statusbar to stay black on ios7
    } else {
    }
}

@end //CDVWKInAppBrowser

#pragma mark CDVWKInAppBrowserViewController

@implementation CDVWKInAppBrowserViewController

@synthesize currentURL;

CGFloat lastReducedStatusBarHeight = 0.0;
BOOL isExiting = FALSE;
NSURLAuthenticationChallenge *authBasicChallenge = nil;
void (^authBasicCompletionHandler)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential) = nil;

- (id)initWithBrowserOptions: (CDVInAppBrowserOptions*) browserOptions andSettings:(NSDictionary *)settings
{
    self = [super init];
    if (self != nil) {
        _browserOptions = browserOptions;
        _settings = settings;
        self.webViewUIDelegate = [[CDVWKInAppBrowserUIDelegate alloc] initWithTitle:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"]];
        [self.webViewUIDelegate setViewController:self];
        
        [self createViews];
    }
    
    return self;
}

- (void)updateBrowserOptions: (CDVInAppBrowserOptions*) browserOptions
{
    _browserOptions = browserOptions;
}

-(void)dealloc {
    //NSLog(@"dealloc");
}

- (void)createViews
{
    // We create the views in code for primarily for ease of upgrades and not requiring an external .xib to be included
    
    CGRect webViewBounds = self.view.bounds;
    BOOL toolbarIsAtBottom = ![_browserOptions.toolbarposition isEqualToString:kInAppBrowserToolbarBarPositionTop];
    webViewBounds.size.height -= _browserOptions.location ? FOOTER_HEIGHT : TOOLBAR_HEIGHT;
    WKUserContentController* userContentController = [[WKUserContentController alloc] init];
    
    WKWebViewConfiguration* configuration = [[WKWebViewConfiguration alloc] init];
    
    NSString *userAgent = configuration.applicationNameForUserAgent;
    if (
        [self settingForKey:@"OverrideUserAgent"] == nil &&
        [self settingForKey:@"AppendUserAgent"] != nil
        ) {
        userAgent = [NSString stringWithFormat:@"%@ %@", userAgent, [self settingForKey:@"AppendUserAgent"]];
    }
    configuration.applicationNameForUserAgent = userAgent;
    configuration.userContentController = userContentController;
#if __has_include(<Cordova/CDVWebViewProcessPoolFactory.h>)
    configuration.processPool = [[CDVWebViewProcessPoolFactory sharedFactory] sharedProcessPool];
#elif __has_include("CDVWKProcessPoolFactory.h")
    configuration.processPool = [[CDVWKProcessPoolFactory sharedFactory] sharedProcessPool];
#endif
    [configuration.userContentController addScriptMessageHandler:self name:IAB_BRIDGE_NAME];
    [configuration.userContentController addScriptMessageHandler:self name:IAB_BRIDGE_DOWNLOAD_NAME];
    
    //WKWebView options
    configuration.allowsInlineMediaPlayback = _browserOptions.allowinlinemediaplayback;
    if (IsAtLeastiOSVersion(@"10.0")) {
        configuration.ignoresViewportScaleLimits = _browserOptions.enableviewportscale;
        if(_browserOptions.mediaplaybackrequiresuseraction == YES){
            configuration.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeAll;
        }else{
            configuration.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeNone;
        }
    }else{ // iOS 9
        configuration.mediaPlaybackRequiresUserAction = _browserOptions.mediaplaybackrequiresuseraction;
    }
    
    if (@available(iOS 13.0, *)) {
        NSString *contentMode = [self settingForKey:@"PreferredContentMode"];
        if ([contentMode isEqual: @"mobile"]) {
            configuration.defaultWebpagePreferences.preferredContentMode = WKContentModeMobile;
        } else if ([contentMode  isEqual: @"desktop"]) {
            configuration.defaultWebpagePreferences.preferredContentMode = WKContentModeDesktop;
        }
        
    }
    

    if (IsAtLeastiOSVersion(@"15.0")) {
        self.webView = [[WKWebView alloc] initWithFrame:webViewBounds configuration:configuration];
    
        [self.view addSubview:self.webView];
        [self.view sendSubviewToBack:self.webView];
    } else {
        if (nil == self.webView) {
            self.webView = [[WKWebView alloc] initWithFrame:webViewBounds configuration:configuration];

            [self.view addSubview:self.webView];
        } else {
            self.webView.frame = webViewBounds;
        }

        [self.view sendSubviewToBack:self.webView];
    }
    
    
    self.webView.navigationDelegate = self;
    self.webView.UIDelegate = self.webViewUIDelegate;
    self.webView.backgroundColor = [UIColor whiteColor];
    if ([self settingForKey:@"OverrideUserAgent"] != nil) {
        self.webView.customUserAgent = [self settingForKey:@"OverrideUserAgent"];
    }
    
    self.webView.clearsContextBeforeDrawing = YES;
    self.webView.clipsToBounds = YES;
    self.webView.contentMode = UIViewContentModeScaleToFill;
    self.webView.multipleTouchEnabled = YES;
    self.webView.opaque = YES;
    self.webView.userInteractionEnabled = YES;
    self.automaticallyAdjustsScrollViewInsets = YES ;
    [self.webView setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
    self.webView.allowsLinkPreview = NO;
    self.webView.allowsBackForwardNavigationGestures = NO;
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 110000
   if (@available(iOS 11.0, *)) {
       [self.webView.scrollView setContentInsetAdjustmentBehavior:UIScrollViewContentInsetAdjustmentNever];
   }
#endif
    
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.spinner.alpha = 1.000;
    self.spinner.autoresizesSubviews = YES;
    self.spinner.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin);
    self.spinner.clearsContextBeforeDrawing = NO;
    self.spinner.clipsToBounds = NO;
    self.spinner.contentMode = UIViewContentModeScaleToFill;
    self.spinner.frame = CGRectMake(CGRectGetMidX(self.webView.frame), CGRectGetMidY(self.webView.frame), 20.0, 20.0);
    self.spinner.hidden = NO;
    self.spinner.hidesWhenStopped = YES;
    self.spinner.multipleTouchEnabled = NO;
    self.spinner.opaque = NO;
    self.spinner.userInteractionEnabled = NO;
    [self.spinner stopAnimating];
    
    self.closeButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(close)];
    self.closeButton.enabled = YES;
    
    UIBarButtonItem* flexibleSpaceButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    UIBarButtonItem* fixedSpaceButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixedSpaceButton.width = 20;
    
    float toolbarY = toolbarIsAtBottom ? self.view.bounds.size.height - TOOLBAR_HEIGHT : 0.0;
    CGRect toolbarFrame = CGRectMake(0.0, toolbarY, self.view.bounds.size.width, TOOLBAR_HEIGHT);
    
    self.toolbar = [[UIToolbar alloc] initWithFrame:toolbarFrame];
    self.toolbar.alpha = 1.000;
    self.toolbar.autoresizesSubviews = YES;
    self.toolbar.autoresizingMask = toolbarIsAtBottom ? (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin) : UIViewAutoresizingFlexibleWidth;
    self.toolbar.barStyle = UIBarStyleBlackOpaque;
    self.toolbar.clearsContextBeforeDrawing = NO;
    self.toolbar.clipsToBounds = NO;
    self.toolbar.contentMode = UIViewContentModeScaleToFill;
    self.toolbar.hidden = NO;
    self.toolbar.multipleTouchEnabled = NO;
    self.toolbar.opaque = NO;
    self.toolbar.userInteractionEnabled = YES;
    if (_browserOptions.toolbarcolor != nil) { // Set toolbar color if user sets it in options
      self.toolbar.barTintColor = [self colorFromHexString:_browserOptions.toolbarcolor];
    }
    if (!_browserOptions.toolbartranslucent) { // Set toolbar translucent to no if user sets it in options
      self.toolbar.translucent = NO;
    }
    
    CGFloat labelInset = 5.0;
    float locationBarY = toolbarIsAtBottom ? self.view.bounds.size.height - FOOTER_HEIGHT : self.view.bounds.size.height - LOCATIONBAR_HEIGHT;
    
    self.addressLabel = [[UILabel alloc] initWithFrame:CGRectMake(labelInset, locationBarY, self.view.bounds.size.width - labelInset, LOCATIONBAR_HEIGHT)];
    self.addressLabel.adjustsFontSizeToFitWidth = NO;
    self.addressLabel.alpha = 1.000;
    self.addressLabel.autoresizesSubviews = YES;
    self.addressLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    self.addressLabel.backgroundColor = [UIColor clearColor];
    self.addressLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    self.addressLabel.clearsContextBeforeDrawing = YES;
    self.addressLabel.clipsToBounds = YES;
    self.addressLabel.contentMode = UIViewContentModeScaleToFill;
    self.addressLabel.enabled = YES;
    self.addressLabel.hidden = NO;
    self.addressLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    
    if ([self.addressLabel respondsToSelector:NSSelectorFromString(@"setMinimumScaleFactor:")]) {
        [self.addressLabel setValue:@(10.0/[UIFont labelFontSize]) forKey:@"minimumScaleFactor"];
    } else if ([self.addressLabel respondsToSelector:NSSelectorFromString(@"setMinimumFontSize:")]) {
        [self.addressLabel setValue:@(10.0) forKey:@"minimumFontSize"];
    }
    
    self.addressLabel.multipleTouchEnabled = NO;
    self.addressLabel.numberOfLines = 1;
    self.addressLabel.opaque = NO;
    self.addressLabel.shadowOffset = CGSizeMake(0.0, -1.0);
    self.addressLabel.text = NSLocalizedString(@"Loading...", nil);
    self.addressLabel.textAlignment = NSTextAlignmentLeft;
    self.addressLabel.textColor = [UIColor colorWithWhite:1.000 alpha:1.000];
    self.addressLabel.userInteractionEnabled = NO;
    
    NSString* frontArrowString = NSLocalizedString(@"►", nil); // create arrow from Unicode char
    self.forwardButton = [[UIBarButtonItem alloc] initWithTitle:frontArrowString style:UIBarButtonItemStylePlain target:self action:@selector(goForward:)];
    self.forwardButton.enabled = YES;
    self.forwardButton.imageInsets = UIEdgeInsetsZero;
    if (_browserOptions.navigationbuttoncolor != nil) { // Set button color if user sets it in options
      self.forwardButton.tintColor = [self colorFromHexString:_browserOptions.navigationbuttoncolor];
    }

    NSString* backArrowString = NSLocalizedString(@"◄", nil); // create arrow from Unicode char
    self.backButton = [[UIBarButtonItem alloc] initWithTitle:backArrowString style:UIBarButtonItemStylePlain target:self action:@selector(goBack:)];
    self.backButton.enabled = YES;
    self.backButton.imageInsets = UIEdgeInsetsZero;
    if (_browserOptions.navigationbuttoncolor != nil) { // Set button color if user sets it in options
      self.backButton.tintColor = [self colorFromHexString:_browserOptions.navigationbuttoncolor];
    }

    self.toolbarTitle = [[UIBarButtonItem alloc] initWithCustomView:self.addressLabel];
    self.toolbarTitle.enabled = YES;
    self.toolbarTitle.imageInsets = UIEdgeInsetsZero;
    if (_browserOptions.navigationbuttoncolor != nil) { // Set button color if user sets it in options
      self.toolbarTitle.tintColor = [self colorFromHexString:_browserOptions.navigationbuttoncolor];
    }

    // Filter out Navigation Buttons if user requests so
    if (_browserOptions.hidenavigationbuttons) {
        self.addressLabel.textAlignment = NSTextAlignmentLeft;
        if (_browserOptions.lefttoright) {
            [self.toolbar setItems:@[self.toolbarTitle, flexibleSpaceButton, self.closeButton]];
        } else {
            [self.toolbar setItems:@[self.closeButton, fixedSpaceButton, self.toolbarTitle]];
        }
    } else if (_browserOptions.lefttoright) {
        self.addressLabel.textAlignment = NSTextAlignmentCenter;
        [self.toolbar setItems:@[self.backButton, flexibleSpaceButton, self.toolbarTitle, flexibleSpaceButton, self.forwardButton, fixedSpaceButton, self.closeButton]];
    } else {
        self.addressLabel.textAlignment = NSTextAlignmentCenter;
        [self.toolbar setItems:@[self.closeButton, fixedSpaceButton, self.backButton, flexibleSpaceButton, self.toolbarTitle, flexibleSpaceButton, self.forwardButton]];
    }
    
    self.view.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.toolbar];
    [self.view addSubview:self.addressLabel];
    [self.view addSubview:self.spinner];
}

- (id)settingForKey:(NSString*)key
{
    return [_settings objectForKey:[key lowercaseString]];
}

- (void) setWebViewFrame : (CGRect) frame {
    NSLog(@"Setting the WebView's frame to %@", NSStringFromCGRect(frame));
    [self.webView setFrame:frame];
}

- (void)setCloseButtonTitle:(NSString*)title : (NSString*) colorString : (int) buttonIndex
{
    // the advantage of using UIBarButtonSystemItemDone is the system will localize it for you automatically
    // but, if you want to set this yourself, knock yourself out (we can't set the title for a system Done button, so we have to create a new one)
    self.closeButton = nil;
    // Initialize with title if title is set, otherwise the title will be 'Done' localized
    self.closeButton = title != nil ? [[UIBarButtonItem alloc] initWithTitle:title style:UIBarButtonItemStyleBordered target:self action:@selector(close)] : [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(close)];
    self.closeButton.enabled = YES;
    // If color on closebutton is requested then initialize with that that color, otherwise use initialize with default
    self.closeButton.tintColor = colorString != nil ? [self colorFromHexString:colorString] : [UIColor colorWithRed:60.0 / 255.0 green:136.0 / 255.0 blue:230.0 / 255.0 alpha:1];
    
    NSMutableArray* items = [self.toolbar.items mutableCopy];
    [items replaceObjectAtIndex:buttonIndex withObject:self.closeButton];
    [self.toolbar setItems:items];
}

- (void)showLocationBar:(BOOL)show
{
//    CGRect locationbarFrame = self.addressLabel.frame;
//
//    BOOL toolbarVisible = !self.toolbar.hidden;
//
//    // prevent double show/hide
//    if (show == !(self.addressLabel.hidden)) {
//        return;
//    }
//
//    if (show) {
//        self.addressLabel.hidden = NO;
//
//        if (toolbarVisible) {
//            // toolBar at the bottom, leave as is
//            // put locationBar on top of the toolBar
//
//            CGRect webViewBounds = self.view.bounds;
//            webViewBounds.size.height -= FOOTER_HEIGHT;
//            [self setWebViewFrame:webViewBounds];
//
//            locationbarFrame.origin.y = webViewBounds.size.height;
//            self.addressLabel.frame = locationbarFrame;
//        } else {
//            // no toolBar, so put locationBar at the bottom
//
//            CGRect webViewBounds = self.view.bounds;
//            webViewBounds.size.height -= LOCATIONBAR_HEIGHT;
//            [self setWebViewFrame:webViewBounds];
//
//            locationbarFrame.origin.y = webViewBounds.size.height;
//            self.addressLabel.frame = locationbarFrame;
//        }
//    } else {
//        self.addressLabel.hidden = YES;
//
//        if (toolbarVisible) {
//            // locationBar is on top of toolBar, hide locationBar
//
//            // webView take up whole height less toolBar height
//            CGRect webViewBounds = self.view.bounds;
//            webViewBounds.size.height -= TOOLBAR_HEIGHT;
//            [self setWebViewFrame:webViewBounds];
//        } else {
//            // no toolBar, expand webView to screen dimensions
//            [self setWebViewFrame:self.view.bounds];
//        }
//    }
}

- (void)showToolBar:(BOOL)show : (NSString *) toolbarPosition
{
    CGRect toolbarFrame = self.toolbar.frame;
    CGRect locationbarFrame = self.addressLabel.frame;
    
    BOOL locationbarVisible = !self.addressLabel.hidden;
    
    // prevent double show/hide
    if (show == !(self.toolbar.hidden)) {
        return;
    }
    
    if (show) {
        self.toolbar.hidden = NO;
        CGRect webViewBounds = self.view.bounds;
        
        if (locationbarVisible) {
            // locationBar at the bottom, move locationBar up
            // put toolBar at the bottom
            webViewBounds.size.height -= FOOTER_HEIGHT;
            locationbarFrame.origin.y = webViewBounds.size.height;
            self.addressLabel.frame = locationbarFrame;
            self.toolbar.frame = toolbarFrame;
        } else {
            // no locationBar, so put toolBar at the bottom
            CGRect webViewBounds = self.view.bounds;
            webViewBounds.size.height -= TOOLBAR_HEIGHT;
            self.toolbar.frame = toolbarFrame;
        }
        
        if ([toolbarPosition isEqualToString:kInAppBrowserToolbarBarPositionTop]) {
            toolbarFrame.origin.y = 0;
            webViewBounds.origin.y += toolbarFrame.size.height;
            [self setWebViewFrame:webViewBounds];
        } else {
            // toolbarFrame.origin.y = (webViewBounds.size.height + LOCATIONBAR_HEIGHT);
        }
        [self setWebViewFrame:webViewBounds];
        
    } else {
        self.toolbar.hidden = YES;
        
        if (locationbarVisible) {
            // locationBar is on top of toolBar, hide toolBar
            // put locationBar at the bottom
            
            // webView take up whole height less locationBar height
            CGRect webViewBounds = self.view.bounds;
            // webViewBounds.size.height -= LOCATIONBAR_HEIGHT;
            [self setWebViewFrame:webViewBounds];
            
            // move locationBar down
            locationbarFrame.origin.y = webViewBounds.size.height;
            self.addressLabel.frame = locationbarFrame;
        } else {
            // no locationBar, expand webView to screen dimensions
            [self setWebViewFrame:self.view.bounds];
        }
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    if (isExiting && (self.navigationDelegate != nil) && [self.navigationDelegate respondsToSelector:@selector(browserExit)]) {
        [self.navigationDelegate browserExit];
        isExiting = FALSE;
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    NSString* statusBarStylePreference = [self settingForKey:@"InAppBrowserStatusBarStyle"];
    if (statusBarStylePreference && [statusBarStylePreference isEqualToString:@"lightcontent"]) {
        return UIStatusBarStyleLightContent;
    } else if (statusBarStylePreference && [statusBarStylePreference isEqualToString:@"darkcontent"]) {
        if (@available(iOS 13.0, *)) {
            return UIStatusBarStyleDarkContent;
        } else {
            return UIStatusBarStyleDefault;
        }
    } else {
        return UIStatusBarStyleDefault;
    }
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (void)close
{
    self.previousURL = nil;
    self.currentURL = nil;
    
    __weak UIViewController* weakSelf = self;
    
    // Run later to avoid the "took a long time" log message.
    dispatch_async(dispatch_get_main_queue(), ^{
        isExiting = TRUE;
        if (IsAtLeastiOSVersion(@"15.0") && !IsAtLeastiOSVersion(@"16.0")) {
            if ([weakSelf respondsToSelector:@selector(presentingViewController)]) {
                [[weakSelf presentingViewController] dismissViewControllerAnimated:YES completion:nil];
            } else {
                [[weakSelf parentViewController] dismissViewControllerAnimated:YES completion:nil];
            }
        }

        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                      messageAsDictionary:@{@"type":@"exit"}];
        [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
        [self.navigationDelegate.commandDelegate sendPluginResult:pluginResult callbackId:self.navigationDelegate.callbackId];
    });
}

- (void)navigateTo:(NSURL*)url
{
    if ([url.scheme isEqualToString:@"file"]) {
        [self.webView loadFileURL:url allowingReadAccessToURL:url];
    } else {
        NSURLRequest* request = [NSURLRequest requestWithURL:url];
        [self.webView loadRequest:request];
    }
}

- (void)goBack:(id)sender
{
    [self.webView goBack];
}

- (void)goForward:(id)sender
{
    [self.webView goForward];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self rePositionViews];
    
    [super viewWillAppear:animated];
}

- (void)sendAuthBasic:(NSString*)username : (NSString*) password
{
    NSURLCredential *credential = [NSURLCredential credentialWithUser:username password:password persistence:NSURLCredentialPersistenceForSession];
    self.authBasicCompletionHandler(NSURLSessionAuthChallengeUseCredential, credential);

    self.authBasicChallenge = nil;
    self.authBasicCompletionHandler = nil;
}

- (void)cancelAuthBasic
{
    if (nil != self.authBasicChallenge ) {
        [self.authBasicChallenge.sender cancelAuthenticationChallenge:self.authBasicChallenge];
    }

    if (nil != self.authBasicCompletionHandler ) {
        self.authBasicCompletionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
    }

    self.authBasicChallenge = nil;
    self.authBasicCompletionHandler = nil;
}

//
// On iOS 7 the status bar is part of the view's dimensions, therefore it's height has to be taken into account.
// The height of it could be hardcoded as 20 pixels, but that would assume that the upcoming releases of iOS won't
// change that value.
//
- (float) getStatusBarOffset {
    return (float) IsAtLeastiOSVersion(@"7.0") ? [[UIApplication sharedApplication] statusBarFrame].size.height : 0.0;
}

- (void) rePositionViews {
    CGRect viewBounds = [self.webView bounds];
    viewBounds = [self.navigationDelegate calcWindowFrame:viewBounds];
    viewBounds = [self.navigationDelegate calcWebviewFrame:viewBounds];

    CGFloat statusBarHeight = [self getStatusBarOffset];
    
    // orientation portrait or portraitUpsideDown: status bar is on the top and web view is to be aligned to the bottom of the status bar
    // orientation landscapeLeft or landscapeRight: status bar height is 0 in but lets account for it in case things ever change in the future
    viewBounds.origin.y = statusBarHeight;
    
    // account for web view height portion that may have been reduced by a previous call to this method
    viewBounds.size.height = viewBounds.size.height - statusBarHeight;
    
    if ((_browserOptions.toolbar) && ([_browserOptions.toolbarposition isEqualToString:kInAppBrowserToolbarBarPositionTop])) {
        // if we have to display the toolbar on top of the web view, we need to account for its height
        viewBounds.origin.y += TOOLBAR_HEIGHT;
        self.toolbar.frame = CGRectMake(self.toolbar.frame.origin.x, statusBarHeight, self.toolbar.frame.size.width, self.toolbar.frame.size.height);
        if (!IsAtLeastiOSVersion(@"15.0")) {
            self.addressLabel.frame = CGRectMake(self.addressLabel.frame.origin.x, 0, self.addressLabel.frame.size.width, self.addressLabel.frame.size.height);
        }
    }

    self.webView.frame = viewBounds;
}

// Helper function to convert hex color string to UIColor
// Assumes input like "#00FF00" (#RRGGBB).
// Taken from https://stackoverflow.com/questions/1560081/how-can-i-create-a-uicolor-from-a-hex-string
- (UIColor *)colorFromHexString:(NSString *)hexString {
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:1]; // bypass '#' character
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}

/*
 * Override "saveAs" function (FileSaver) because without that, the download of blob URL not working
 * Only for < 14.5
 */
- (void)overrideFileSaverSaveAsFunction
{
    if (!@available(iOS 14.5, *)) {
        NSString* script = @""
            "if (saveAs && !originalSaveAs) {"
                "var originalSaveAs = saveAs;"
                "saveAs = function (blob, name, opts) {"
                    "if (!(blob instanceof Blob)) {"
                        "originalSaveAs(blob, name, opts);"
                    "} else {"
                        "const fr = new FileReader();"
                        "fr.onload = () => {"
                            "window.webkit.messageHandlers.cordova_iab_download.postMessage({ status: 'success', data: { content: fr.result, mimeType: blob.type, filename: name } });"
                        "};"
                        "fr.addEventListener('error', (err) => {"
                            "window.webkit.messageHandlers.cordova_iab_download.postMessage({ status: 'error', error: err })"
                        "});"
                        "fr.readAsDataURL(blob);"
                    "}"
                "}"
            "}"
            // null is needed here as this eval returns the last statement and we can't return a promise
            "null;"
        ;

        [self.navigationDelegate evaluateJavaScript:script];
    }
}

- (NSString*)generateFilename:(NSString *)suggestedFilename
{
    NSString* filename = suggestedFilename;

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy_MM_dd_HH_mm_ss"];
    NSString *filenameSuffix = [dateFormatter stringFromDate:[NSDate date]];

    NSRange range = [filename rangeOfString:@"." options:NSBackwardsSearch];
    if (NSNotFound == range.location) {
        filename = [NSString stringWithFormat:@"%@_%@", filename, filenameSuffix];
    } else {
        filename = [
            NSString stringWithFormat:@"%@_%@%@",
            [filename substringWithRange:NSMakeRange(0, range.location)],
            filenameSuffix,
            [filename substringWithRange:NSMakeRange(range.location, [filename length] - range.location)]
        ];
    }

    return filename;
}

- (void)downloadDataUri:(NSString*)dataUri :(NSString*)mimeType :(NSString*)filename
{
    NSLog(@"downloadDataUri: %@", dataUri);
    NSLog(@"mimeType: %@", mimeType);
    NSLog(@"filename: %@", filename);

    NSData* data = [[NSData alloc] initWithContentsOfURL:[[NSURL alloc] initWithString:dataUri]];
    
    if (data != nil) {
        NSString* filenameUniq = [self generateFilename :filename];

        // Save to Documents
        NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        NSString *filePath = [documentPath stringByAppendingPathComponent:filenameUniq];
        bool success = [data writeToFile:filePath atomically:YES];

        if (success) {
            [self downloadSucceed :filePath :mimeType];
        } else {
            NSLog(@"success ios false");
            [self downloadFailed :@"unknown" :0];
        }
    } else {
        NSLog(@"data is nil");
        [self downloadFailed :@"unknown" :0];
    }
}

- (void)downloadSucceed:(NSString *)path :(NSString *)mimeType {
    if (!mimeType) {
        NSURL* fileUrl = [NSURL fileURLWithPath:path];
        //NSURLRequest* fileUrlRequest = [[NSURLRequest alloc] initWithURL:fileUrl];
        NSURLRequest* fileUrlRequest = [[NSURLRequest alloc] initWithURL:fileUrl cachePolicy:NSURLCacheStorageNotAllowed timeoutInterval:.1];

        NSError* error = nil;
        NSURLResponse* response = nil;
        NSData* fileData = [NSURLConnection sendSynchronousRequest:fileUrlRequest returningResponse:&response error:&error];

        fileData; // Ignore this if you're using the timeoutInterval
                  // request, since the data will be truncated.

        mimeType = [response MIMEType];

//        [fileUrlRequest release];
    }

    NSMutableDictionary* data = [NSMutableDictionary new];
    [data setValue:path forKey:@"path"];
    [data setValue:mimeType forKey:@"mimeType"];

    NSMutableDictionary* dResult = [NSMutableDictionary new];
    [dResult setValue:@"downloadend" forKey:@"type"];
    [dResult setValue:data forKey:@"data"];
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dResult];
    [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];

    [self.navigationDelegate.commandDelegate sendPluginResult:pluginResult callbackId:self.navigationDelegate.callbackId];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.addressLabel.text = [self.currentURL absoluteString];
    });
}

- (void) downloadFailed:(NSString *)message :(int *)errorCode {
    NSMutableDictionary* dError = [NSMutableDictionary new];
    [dError setValue:[NSString stringWithFormat:@"%d", errorCode] forKey:@"code"];
    [dError setValue:message forKey:@"message"];

    NSMutableDictionary* dResult = [NSMutableDictionary new];
    [dResult setValue:@"downloaderror" forKey:@"type"];
    [dResult setValue:dError forKey:@"error"];
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:dResult];
    [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];

    [self.navigationDelegate.commandDelegate sendPluginResult:pluginResult callbackId:self.navigationDelegate.callbackId];

    dispatch_async(dispatch_get_main_queue(), ^{
        self.addressLabel.text = [self.currentURL absoluteString];
    });
}

#pragma mark WKNavigationDelegate

- (void)webView:(WKWebView *)theWebView didStartProvisionalNavigation:(WKNavigation *)navigation{
    
    // loading url, start spinner, update back/forward
    
    self.addressLabel.text = NSLocalizedString(@"Loading...", nil);
    self.backButton.enabled = theWebView.canGoBack;
    self.forwardButton.enabled = theWebView.canGoForward;
    
    NSLog(_browserOptions.hidespinner ? @"Yes" : @"No");
    if(!_browserOptions.hidespinner) {
        [self.spinner startAnimating];
    }
    
    return [self.navigationDelegate didStartProvisionalNavigation:theWebView];
}

- (void)webView:(WKWebView *)theWebView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    if (navigationAction.navigationType == WKNavigationTypeBackForward) {
        if (self.webView.canGoBack) {
            decisionHandler(WKNavigationActionPolicyAllow);
            return;
        }
    }

    if (@available(iOS 14.5, *)) {
        if (navigationAction.shouldPerformDownload) {
            decisionHandler(WKNavigationActionPolicyDownload);
            return;
        }
    }

    NSURL *url = navigationAction.request.URL;
    NSURL *mainDocumentURL = navigationAction.request.mainDocumentURL;
    
    BOOL isTopLevelNavigation = [url isEqual:mainDocumentURL];
    
    if (isTopLevelNavigation) {
        if (![[self.currentURL absoluteString] isEqualToString:[url absoluteString]]) {
            self.previousURL = self.currentURL;
        }

        self.currentURL = url;
    }
    
    [self.navigationDelegate webView:theWebView decidePolicyForNavigationAction:navigationAction decisionHandler:decisionHandler];
}

- (void)webView:(WKWebView *)theWebView didFinishNavigation:(WKNavigation *)navigation
{
    // update url, stop spinner, update back/forward
    
    self.addressLabel.text = [self.currentURL absoluteString];
    self.backButton.enabled = theWebView.canGoBack;
    self.forwardButton.enabled = theWebView.canGoForward;
    theWebView.scrollView.contentInset = UIEdgeInsetsZero;
    
    [self.spinner stopAnimating];
    
    [self.navigationDelegate didFinishNavigation:theWebView];
}
    
- (void)webView:(WKWebView*)theWebView failedNavigation:(NSString*) delegateName withError:(nonnull NSError *)error{
    // log fail message, stop spinner, update back/forward
    NSLog(@"webView:%@ - %ld: %@", delegateName, (long)error.code, [error localizedDescription]);
    
    self.backButton.enabled = theWebView.canGoBack;
    self.forwardButton.enabled = theWebView.canGoForward;
    [self.spinner stopAnimating];
    
    self.addressLabel.text = NSLocalizedString(@"Load Error", nil);
    
    [self.navigationDelegate webView:theWebView didFailNavigation:error];
}

- (void)webView:(WKWebView*)theWebView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(nonnull NSError *)error
{
    [self webView:theWebView failedNavigation:@"didFailNavigation" withError:error];
}
    
- (void)webView:(WKWebView*)theWebView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(nonnull NSError *)error
{
    [self webView:theWebView failedNavigation:@"didFailProvisionalNavigation" withError:error];
}

- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{
    if (NSURLAuthenticationMethodHTTPBasic == challenge.protectionSpace.authenticationMethod) {
        self.authBasicChallenge = challenge;
        self.authBasicCompletionHandler = completionHandler;

        NSMutableDictionary* dResult = [NSMutableDictionary new];
        [dResult setValue:@"authbasic" forKey:@"type"];
        [dResult setValue:challenge.protectionSpace.host forKey:@"host"];
        [dResult setValue:challenge.protectionSpace.realm forKey:@"realm"];
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dResult];
        [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];

        [self.navigationDelegate.commandDelegate sendPluginResult:pluginResult callbackId:self.navigationDelegate.callbackId];
    } else {
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
    }
}

- (void)webView:(WKWebView *)theWebView decidePolicyForNavigationResponse:(nonnull WKNavigationResponse *)navigationResponse decisionHandler:(nonnull void (^)(WKNavigationResponsePolicy))decisionHandler {
    NSDictionary *headers = ((NSHTTPURLResponse *)navigationResponse.response).allHeaderFields;
    NSString *contentType = [headers valueForKey:@"Content-Type"];
    if (
        navigationResponse.canShowMIMEType
        && ![contentType isEqualToString:@"application/pdf"]
    ) {
        decisionHandler(WKNavigationResponsePolicyAllow);
    } else {
        if (@available(iOS 14.5, *)) {
            decisionHandler(WKNavigationResponsePolicyDownload);
        } else {
            NSURL* downloadUrl = navigationResponse.response.URL;
            if ([downloadUrl.scheme isEqualToString:@"blob"]) {
                [self downloadBlobUrl:downloadUrl];
            } else {
                NSURLSessionDataTask* dataTask = [NSURLSession.sharedSession dataTaskWithURL:downloadUrl completionHandler:^(NSData* data, NSURLResponse* response, NSError* error) {
                    if (data != nil) {
                        NSString* filename = [self generateFilename :navigationResponse.response.suggestedFilename];

                        // Save to Documents
                        NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
                        NSString *filePath = [documentPath stringByAppendingPathComponent:filename];

                        bool success = [data writeToFile:filePath atomically:YES];

                        if (success) {
                            [self downloadSucceed :filePath :nil];
                        } else {
                            [self downloadFailed :error.description :0];
                        }
                    }
                }];

                [dataTask resume];
            }

            decisionHandler(WKNavigationResponsePolicyCancel);
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            self.currentURL = self.previousURL;
            self.addressLabel.text = [self.currentURL absoluteString];
        });
    }
}

/*
 Intercept the download of documents in webView, trigger the download in JavaScript and pass the binary file to JavaScript handler in Swift code
 */
- (void)downloadBlobUrl:(NSURL*)url
{
    NSString* urlAsString = url.absoluteString;
    if (nil != urlAsString) {
        NSString* script = [
            NSString stringWithFormat:@""
                "if (saveAs) {"
                    "var originalSaveAs = saveAs;"
                    "saveAs = function (blob, name, opts) {"
                        "const fr = new FileReader();"
                        "fr.onload = () => {"
                            "window.webkit.messageHandlers.cordova_iab_download.postMessage({ status: 'success', data: { content: fr.result, mimeType: blob.type, filename: name } });"
                        "};"
                        "fr.addEventListener('error', (err) => {"
                            "window.webkit.messageHandlers.cordova_iab_download.postMessage({ status: 'error', error: err })"
                        "});"
                        "fr.readAsDataURL(blob);"
                    "}"
                "}"
//                "(async function download() {"
//                    "const url = '%@';"
//                    "window.open(url);"
//                    "try {"
//                        // we use a second try block here to have more detailed error information
//                        // because of the nature of JS the outer try-catch doesn't know anything where the error happended
//                        "let res;"
//                        "try {"
//                            "res = await fetch(url, {"
//                                "credentials: 'include'"
//                            "});"
//                        "} catch (err) {"
//                            "window.webkit.messageHandlers.jsError.postMessage(`fetch threw, error: ${err}, url: ${url}`);"
//                            "return;"
//                        "}"
//                        "if (!res.ok) {"
//                            "window.webkit.messageHandlers.jsError.postMessage(`Response status was not ok, status: ${res.status}, url: ${url}`);"
//                            "return;"
//                        "}"
//                        "const contentDisp = res.headers.get('content-disposition');"
//                        "if (contentDisp) {"
//                            "const match = contentDisp.match(/(^;|)\\s*filename=\\s*(\"([^\"]*)\"|([^;\\s]*))\\s*(;|$)/i);"
//                            "if (match) {"
//                                "filename = match[3] || match[4];"
//                            "} else {"
//                                // TODO: we could here guess the filename from the mime-type (e.g. unnamed.pdf for pdfs, or unnamed.tiff for tiffs)
//                                "window.webkit.messageHandlers.jsError.postMessage(`content-disposition header could not be matched against regex, content-disposition: ${contentDisp} url: ${url}`);"
//                            "}"
//                        "} else {"
//                            "window.webkit.messageHandlers.jsError.postMessage(`content-disposition header missing, url: ${url}`);"
//                            "return;"
//                        "}"
//                        "if (!filename) {"
//                            "const contentType = res.headers.get('content-type');"
//                            "if (contentType) {"
//                                "if (contentType.indexOf('application/json') === 0) {"
//                                    "filename = 'unnamed.pdf';"
//                                "} else if (contentType.indexOf('image/tiff') === 0) {"
//                                    "filename = 'unnamed.tiff';"
//                                "}"
//                            "}"
//                        "}"
//                        "if (!filename) {"
//                            "window.webkit.messageHandlers.jsError.postMessage(`Could not determine filename from content-disposition nor content-type, content-dispositon: ${contentDispositon}, content-type: ${contentType}, url: ${url}`);"
//                        "}"
//                        "let data;"
//                        "try {"
//                            "data = await res.blob();"
//                        "} catch (err) {"
//                            "window.webkit.messageHandlers.jsError.postMessage(`res.blob() threw, error: ${err}, url: ${url}`);"
//                            "return;"
//                        "}"
//                        "const fr = new FileReader();"
//                        "fr.onload = () => {"
//                            "window.webkit.messageHandlers.openDocument.postMessage(`${filename};${fr.result}`)"
//                        "};"
//                        "fr.addEventListener('error', (err) => {"
//                            "window.webkit.messageHandlers.jsError.postMessage(`FileReader threw, error: ${err}`)"
//                        "});"
//                        "fr.readAsDataURL(data);"
//                    "} catch (err) {"
//                        // TODO: better log the error, currently only TypeError: Type error
//                        "window.webkit.messageHandlers.jsError.postMessage(`JSError while downloading document, url: ${url}, err: ${err}`)"
//                    "}"
//                "})();"
                // null is needed here as this eval returns the last statement and we can't return a promise
                "null;"
            ,
            urlAsString
        ];

        NSLog(@"downloadBlobUrl - URL : %@ - script : %@", url, script);
        [self.navigationDelegate evaluateJavaScript:script];
    }
}

- (void)webView:(WKWebView *)theWebView navigationAction:(WKNavigationAction *)navigationAction didBecomeDownload:(WKDownload *)download {
    download.delegate = self;
}

- (void)webView:(WKWebView *)theWebView navigationResponse:(WKNavigationResponse *)navigationResponse didBecomeDownload:(WKDownload *)download {
    download.delegate = self;
}

#pragma mark WKDownloadDelegate

NSString* downloadedFilePath = @"";

- (void)download:(WKDownload *)download decideDestinationUsingResponse:(NSURLResponse *)response suggestedFilename:(NSString *)suggestedFilename completionHandler:(void (^)(NSURL * _Nullable))completionHandler {
    NSString* filename = [self generateFilename :suggestedFilename];

    // Save to Documents
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *filePath = [documentPath stringByAppendingPathComponent:filename];
    NSURL* url = [NSURL fileURLWithPath:filePath];

    downloadedFilePath = filePath;

    completionHandler(url);
}

- (void)downloadDidFinish:(WKDownload *)download {
    [self downloadSucceed :downloadedFilePath :nil];
}

- (void) download:(WKDownload *)download didFailWithError:(NSError *)error resumeData:(NSData *)resumeData {
    [self downloadFailed :error.description :error.code];
}

#pragma mark WKScriptMessageHandler delegate
- (void)userContentController:(nonnull WKUserContentController *)userContentController didReceiveScriptMessage:(nonnull WKScriptMessage *)message {
    if (![message.name isEqualToString:IAB_BRIDGE_NAME]) {
        if ([message.name isEqualToString:IAB_BRIDGE_DOWNLOAD_NAME]) {
//            NSLog(@"Received script message from %@: %@", IAB_BRIDGE_DOWNLOAD_NAME, message.body);
            
            NSDictionary* messageContent = (NSDictionary*) message.body;
            NSString* scriptCallbackId = messageContent[@"id"];
            
            if([messageContent objectForKey:@"data"]){
                NSDictionary* scriptResult = messageContent[@"data"];
                if([scriptResult objectForKey:@"content"]){
                    NSString* mimeType = [scriptResult objectForKey:@"mimeType"] ?: @"";
                    NSString* filename = [scriptResult objectForKey:@"filename"] ?: @"";

                    [self downloadDataUri :scriptResult[@"content"] :mimeType :filename];
                } else {
                    if([messageContent objectForKey:@"error"]) {
                        [self downloadFailed :[messageContent objectForKey:@"error"] :0];
                    } else {
                        [self downloadFailed :@"unknown" :0];
                    }
                }
            } else {
                [self downloadFailed :@"unknown" :0];
            }
        }

        return;
    }
    //NSLog(@"Received script message %@", message.body);
    [self.navigationDelegate userContentController:userContentController didReceiveScriptMessage:message];
}

#pragma mark CDVScreenOrientationDelegate

- (BOOL)shouldAutorotate
{
    if ((self.orientationDelegate != nil) && [self.orientationDelegate respondsToSelector:@selector(shouldAutorotate)]) {
        return [self.orientationDelegate shouldAutorotate];
    }
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    if ((self.orientationDelegate != nil) && [self.orientationDelegate respondsToSelector:@selector(supportedInterfaceOrientations)]) {
        return [self.orientationDelegate supportedInterfaceOrientations];
    }
    
    return 1 << UIInterfaceOrientationPortrait;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context)
    {
//        [self rePositionViews];
        [self.navigationDelegate setLayout:NO :YES];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context)
    {

    }];

    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}


@end //CDVWKInAppBrowserViewController