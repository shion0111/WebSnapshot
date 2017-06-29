//
//  snapshot.m
//  ScrollCatch
//
//  Created by Antelis on 29/05/2017.
//  Copyright © 2017 shion. All rights reserved.
//

#import "snapshot.h"

#import <UIKit/UIKit.h>
#import <WebKit/Webkit.h>

@interface snapshot()<WKNavigationDelegate,WKUIDelegate,WKScriptMessageHandler>
@property (strong, nonatomic) WKWebView* webView;
@property (strong, nonatomic) UIView *containerView;
@end
@implementation snapshot

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message{

}
// to snapshot complete wkwebview, scroll webview itself inside a container view rather than scrolling webview's content

- (void)setupWebview:(CGSize)size {
    
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    [configuration.userContentController addScriptMessageHandler:self name:@"interOp"];
    
    self.webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height) configuration:configuration];
    self.webView.navigationDelegate = self;
    self.webView.UIDelegate = self;
    
    self.containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    
    [UIApplication.sharedApplication.delegate.window addSubview:self.containerView];
    
    [self.containerView addSubview:self.webView];
    
}

- (void)takeSnapshotOfWebView:(NSString *)webHeight withCompletionHandler:(void(^)(UIImage *, BOOL))completionHandler {
    //get complete size of the content including the hidden part
    CGSize contentSize = self.webView.scrollView.frame.size;
    
    self.webView.scrollView.contentOffset = CGPointZero;
    
    //change webview frame to content size
    CGRect frame = self.webView.frame;
    frame.size = contentSize;
    self.webView.frame = frame;
    
    UIGraphicsBeginImageContextWithOptions(contentSize, self.webView.scrollView.opaque, 0.0);
    
    [self capture:0 contentSize:contentSize completionHandler:completionHandler];
}

/*!
 * @discussion assuming only vertical scrollable webview, this would move up the webview(note: webview's frame
 * is moved up, webview's content is not scrolled up) by containerView's height each time and draw its
 * hierarchy in current bitmap at correct position. This is repeated until bottom of webview is reached.
 * @param yoffset part of webview content from which snapshot would be taken of height equal to containerView's height
 * @param contentSize size of webview content whose snapshot needs to be taken
 * @param completionHandler called with (UIImage *image, BOOL failure)
 * @return void
 */
- (void)capture:(CGFloat)yoffset contentSize:(CGSize)contentSize completionHandler:(void(^)(UIImage *, BOOL))completionHandler {
    
    BOOL scroll = YES;
    CGFloat mutableYoffset = yoffset;
    
    //if yoffset is such that there is no enough content as containerView's height below that, then
    //move webview such that bottom of webview touched bottom of container view
    if(mutableYoffset > contentSize.height - self.containerView.frame.size.height) {
        scroll = NO;
        mutableYoffset = contentSize.height - self.containerView.frame.size.height;
    }
    
    //move webview up
    CGRect splitFrame = CGRectMake(0, mutableYoffset, self.containerView.frame.size.width, self.containerView.frame.size.height);
    CGRect myFrame = self.webView.frame;
    myFrame.origin.y = -1 * mutableYoffset;
    self.webView.frame = myFrame;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        //snapshoting webview when app is not active return unexpected snapshots, so retry if app is inactive or in bg state
        if([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive) {
            UIGraphicsEndImageContext();
            
            self.webView.frame = CGRectMake(0, 0, self.containerView.frame.size.width, self.containerView.frame.size.height);
            self.webView.scrollView.contentOffset =  CGPointZero;
            
            if(completionHandler) {
                completionHandler(nil, YES);
            }
            return;
        }
        //render particular part of webview at correct position on bitmap
        [self.containerView drawViewHierarchyInRect:splitFrame afterScreenUpdates:YES];
        
        if(scroll) {
            [self capture:yoffset + self.containerView.frame.size.height contentSize:contentSize completionHandler:completionHandler];
        } else {
            UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
            
            UIGraphicsEndImageContext();
            
            self.webView.frame = CGRectMake(0, 0, self.containerView.frame.size.width, self.containerView.frame.size.height);
            self.webView.scrollView.contentOffset =  CGPointZero;
            
            if(completionHandler) {
                completionHandler(viewImage, NO);
            }
        }
    });
}



@end
