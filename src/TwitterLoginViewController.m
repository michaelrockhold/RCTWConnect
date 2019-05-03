//
//  TwitterLoginViewController.m
//  Aktuala Loko
//
//  Created by Michael Rockhold on 6/4/2010.
//  Copyright 2010 The Rockhold Company. All rights reserved.
//

#import "TwitterLoginViewController.h"
#import "NSString+ResponseDecoding.h"
#import "TWSession.h"

@implementation TwitterLoginViewController

- (id)initWithDelegate:(id<RCWebDialogViewControllerDelegate>)d session:(TWSession*)session
{
	if ( self = [super initWithDelegate:d] )
	{
		_session = [session retain];
	}
	return self;
}

- (void)dealloc
{
	[_session release];
	[super dealloc];
}
  
 // Override to allow orientations other than the default portrait orientation.
 - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	// Return YES for supported orientations
	return ( interfaceOrientation == UIInterfaceOrientationPortrait );
}

-(void)loadPage
{
	[super loadPage];

	[self loadURL:@"https://api.twitter.com/oauth/authorize" 
		   method:@"GET" 
			  get:[NSDictionary dictionaryWithObjectsAndKeys:
				   _session.requestToken.key,	@"oauth_token", 
				   nil] 
			 post:nil];
}

- (void)dismiss:(BOOL)animated
{
	[super dismiss:animated];
}

- (void)dialogDidSucceed:(NSURL*)url
{
	[self dismissWithSuccess:YES animated:YES info:nil];
}

#pragma mark UIWebViewDelegate methods

- (BOOL)              webView:(UIWebView*)webView 
   shouldStartLoadWithRequest:(NSURLRequest*)request
			   navigationType:(UIWebViewNavigationType)navigationType
{
	NSURL* url = request.URL;
	if ( [url.absoluteString hasPrefix:_session.callback] )
	{
		NSString* paramStr = [url query];
		if ( !paramStr )
		{
			NSLog(@"webView:%@ shouldStartLoadWithRequest:%@ navigationType:%08x bogus response", webView, request, navigationType);
			goto nope;
		}
		
		NSDictionary* paramsDic = [paramStr decodeResponse];

		if ( ![[paramsDic objectForKey:@"oauth_token"] isEqualToString:_session.requestToken.key] )
		{
			NSLog(@"webView:%@ shouldStartLoadWithRequest:%@ navigationType:%08x oauth token missing or mismatch", webView, request, navigationType);
			goto nope;
		}
		
		NSString* verifier = [paramsDic objectForKey:@"oauth_verifier"];
		if ( verifier == nil )
		{
			NSLog(@"webView:%@ shouldStartLoadWithRequest:%@ navigationType:%08x missing oauth verifier", webView, request, navigationType);
			goto nope;
		}

		_session.verifier = verifier;
		[self dismissWithSuccess:YES animated:YES info:verifier];
		return NO;
		
	nope:
		[self cancel:self];
		return NO;
	}
	else
	{
		return [super webView:webView shouldStartLoadWithRequest:request navigationType:navigationType];
	}
}

@end
