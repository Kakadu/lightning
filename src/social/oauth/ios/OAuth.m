//
//  VKAuthController.m
//  vktest
//
//  Created by Yury Lasty on 2/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OAuth.h"
#import "../../ios/LightViewController.h"
#import <caml/mlvalues.h>                                                                                                                               
#import <caml/callback.h>                                                                                                                               
#import <caml/alloc.h>
#import <caml/threads.h> 

static OAuth * sharedOAuth = nil;

@implementation OAuth

/* 
 * Initialize
 */
-(id)init {
	self = [super init];

	if (self != nil) {
		self.modalPresentationStyle = UIModalPresentationFormSheet;
	}

	return self;
}


+(OAuth *)sharedInstance {
  if (sharedOAuth == nil) {
    sharedOAuth = [[OAuth alloc] init];
  }
  
  return sharedOAuth;
}


/*
 * Вконтакте выставляют в мета тэге viewport атрибут width в device-width, поэтому при модальном показе на iPad
 * длинна контента получается 768 (или 1024 в зависимости от ориентации). Из-за этого появляется скрол и вообще выглядит как говно.
 */
-(NSString *) setViewportWidth:(CGFloat)inWidth {
	UIWebView * w = (UIWebView *)self.view;
	NSString *result = [w stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"(function ( inWidth ) { "
		"var result = ''; "
		"var viewport = null; "
		"var content = 'width = ' + inWidth; "
		"var document_head = document.getElementsByTagName('head')[0]; "
		"var child = document_head.firstChild; "
		"while ( child ) { "
		"if ( null == viewport && child.nodeType == 1 && child.nodeName == 'META' && child.getAttribute( 'name' ) == 'viewport' ) { "
		"viewport = child; "
		"content = child.getAttribute( 'content' ); "
		"if ( content.search( /width\\s\?=\\s\?[^,]+/ ) < 0 ) { "
		"content = 'width = ' + inWidth + ', ' + content; "
		"} else { "
		"content = content.replace( /width\\s\?=\\s\?[^,]+/ , 'width = ' + inWidth ); "
		"} "
		"} "
		"child = child.nextSibling; "
		"} "
		"if ( null != content ) { "
		"child = document.createElement( 'meta' ); "
		"child.setAttribute( 'name' , 'viewport' ); "
		"child.setAttribute( 'content' , content ); "
		"if ( null == viewport ) { "
		"document_head.appendChild( child ); "
		"result = 'append viewport ' + content; "
		"} else { "
		"document_head.replaceChild( child , viewport ); "
		"result = 'replace viewport ' + content; "
		"} "
		"} "
		"return result; "
		"})( %d )" , (int)inWidth]];

	return result;
}



/*                                                                                                                                                                                      
 *                                                                                                                                                                                      
 */                                                                                                                                                                                     
-(void)loadView {                                                                                                                                                                       
    CGRect rect = [UIScreen mainScreen].applicationFrame;                                                                                                                               
    _webview = [[UIWebView alloc] initWithFrame: rect];                                                                                                                                 
    _webview.delegate = self;                                                                                                                                                           
    _webview.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;                                                                                     
    _webview.scalesPageToFit = NO;                                                                                                                                                      
    self.view = _webview;   
    
    _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    _spinner.center = CGPointMake(CGRectGetMidX(_webview.frame), CGRectGetMidY(_webview.frame));
    _spinner.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin ;
    [self.view addSubview:_spinner];
}                                                                                                                                                                                       


/*                                                                                                                                                                                      
 *                                                                                                                                                                                      
 */                                                                                                                                                                                     
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation {                                                                                                    
    return YES;                                                                                                                                                                         
}                                                                                                                                                                                       


/*                                                                                                                                                                                      
 *  Show auth dialog                                                                                                                                                                    
 */                                                                                                                                                                                     
-(void)authorize:(NSURL *)url { 
    NSRange redirect_range = [url.query rangeOfString:@"redirect_uri="];
    NSRange amp_search_range;
    amp_search_range.location = redirect_range.location + redirect_range.length;
    amp_search_range.length = [url.query length] - amp_search_range.location;
        
    NSRange amp_range = [url.query rangeOfString:@"&" options:0 range:amp_search_range];
    NSRange substr_range;
    substr_range.location = amp_search_range.location;
    
    if (amp_range.location == NSNotFound) {
        substr_range.length   = [url.query length] - redirect_range.length - redirect_range.location;
    } else {
        substr_range.length   = amp_range.location - substr_range.location;    
    }
     
    NSURL * u = [NSURL URLWithString:[[url.query substringWithRange:substr_range] stringByReplacingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
    _redirectURIpath = [u.path retain];
    
    NSLog(@"Saved path %@", _redirectURIpath);
    
    /*                                                                                                                                                                                      
     NSString * urlstr = [NSString stringWithFormat:@"http://oauth.vkontakte.ru/authorize?client_id=%@&scope=%@&redirect=%@&display=touch&response_type=token",                          
     _appid, permissions, [@"http://oauth.vkontakte.ru/blank.html" stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];                                                
     */                                                                                                                                                                                      
    
    [_webview loadRequest:[NSURLRequest requestWithURL: url]];                                                                                                                          
}                                                                                                                                                                                       


/*                                                                                                                                                                                      
 * webview delegate                                                                                                                                                                     
 */                                                                                                                                                                                     
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {                                                                                                            
    NSLog(@"HERE: didFaileLoad");
    [_spinner stopAnimating];
	[self dismissModalViewControllerAnimated: YES];
	NSString * errorUrl = [NSString stringWithFormat: @"%@#error=server_error&error_description=webViewdidFailLoadWithError", _redirectURIpath];
    value * mlf = (value*)caml_named_value("oauth_redirected"); 
    caml_acquire_runtime_system();
    caml_callback(*mlf, caml_copy_string([errorUrl UTF8String]));
    caml_release_runtime_system();        	
}       


/*                                                                                                                                                                                      
 *                                                                                                                                                                                      
 */                                                                                                                                                                                     
-(void)webViewDidFinishLoad:(UIWebView *)webView {                                                                                                                                      
    [_spinner stopAnimating];
	NSString * content = [webView stringByEvaluatingJavaScriptFromString: @"document.body.innerHTML"];
	
	
	// В VK если сперва вбили левый логин, а потом нажали cancel, то нас не редиректят на blank.html
	if ([@"security breach" isEqualToString: content]) {
		[self dismissModalViewControllerAnimated: YES];
		value *mlf = (value*)caml_named_value("oauth_redirected");
		NSString * errorUrl = [NSString stringWithFormat: @"%@#error=access_denied", _redirectURIpath];
		caml_acquire_runtime_system();
		if (mlf != NULL) {                                                                                                        
		    caml_callback(*mlf, caml_copy_string([errorUrl UTF8String]));
		}
		caml_release_runtime_system();
		return;
	}  

    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        [self setViewportWidth: 540.0f];
    }
}


/*
 *
 */
-(void)webViewDidStartLoad:(UIWebView *)webView {
    [_spinner startAnimating];
}


/*
 *
 */
-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSLog(@"Saved path: %@ My path %@", _redirectURIpath, request.URL.path);
    
    if ([request.URL.path isEqualToString: _redirectURIpath]) {
        [self dismissModalViewControllerAnimated:YES];
        [_spinner stopAnimating];
        value * mlf = (value*)caml_named_value("oauth_redirected"); 
        caml_acquire_runtime_system();
        caml_callback(*mlf, caml_copy_string([request.URL.absoluteString UTF8String]));
        caml_release_runtime_system();        
        return NO;
    }
    return YES;
}


@end

