//
//  TwitterOAuthLogin.m
//  Here-I-Am
//
//  Created by Michael Rockhold on 6/30/10.
//  Copyright 2010 The Rockhold Company. All rights reserved.
//

#import "TwitterOAuthLogin.h"
#import "TwitterLoginViewController.h"
#import "TWSession.h"
#import "RCError.h"

@interface TwitterOAuthLogin () < TWSessionRequestTokenDelegate, TWSessionAccessTokenDelegate, RCWebDialogViewControllerDelegate >

-(void)displayTwitterLoginDialog;

@end

@implementation TwitterOAuthLogin

-(id)initWithTwitterOAuthLoginDelegate:(id<TwitterOAuthLoginDelegate>)delegate
{
	if ( self = [super init] )
	{
		_delegate = [delegate retain];
	}
	return self;
}

-(void)dealloc
{
	[_delegate release];
	[super dealloc];
}

-(void)start
{
	[_delegate.session requestRequestTokenForDelegate:self];
}

#pragma mark TWSessionRequestTokenDelegate methods

-(void)twSessionRequestRequestTokenFinished:(TWSession*)session
{
	[self displayTwitterLoginDialog];
}

-(void)twSession:(TWSession*)session requestRequestTokenDidFailWithError:(NSError*)error
{
	[_delegate twitterOAuthLogin:self didFailWithError:error];
}

#pragma mark TwitterLoginViewController to get verifier or something
-(void)displayTwitterLoginDialog
{
	TwitterLoginViewController* loginWebDialog = [[TwitterLoginViewController alloc] initWithDelegate:self session:_delegate.session];
	[_delegate.navigationController pushViewController:loginWebDialog animated:_delegate.pushControllerAnimated];
	[loginWebDialog release];
}

#pragma mark RCWebDialogViewControllerDelegate methods

-(void)webDialogViewController:(RCWebDialogViewController*)wdvc didSucceed:(BOOL)succeeded info:(id)info
{
	[_delegate.navigationController popViewControllerAnimated:_delegate.pushControllerAnimated];
	
	if ( !succeeded )
	{
			// not necessarily an error; user may have cancelled out of login web page
		[_delegate twitterOAuthLogin:self didFailWithError:nil];
	}
	else
	{
		_delegate.session.verifier = info;
		[_delegate.session requestAccessTokenForDelegate:self];		
	}
}

-(void)webDialogViewController:(RCWebDialogViewController*)wdvc didFailWithError:(NSError*)error
{
	[_delegate.navigationController popViewControllerAnimated:_delegate.pushControllerAnimated];
	[_delegate twitterOAuthLogin:self didFailWithError:error];
}

- (BOOL)webDialogViewController:(RCWebDialogViewController*)wdvc shouldOpenURLInExternalBrowser:(NSURL*)url
{
	return NO;
}

#pragma mark TWSessionAccessTokenDelegate methods

-(void)twSessionRequestAccessTokenFinished:(TWSession*)session
{
	[_delegate twitterOAuthLogin:self didLogin:YES];
}

-(void)twSession:(TWSession*)session requestAccessTokenDidFailWithError:(NSError*)error responseDictionary:(NSDictionary*)respDic
{
	[_delegate twitterOAuthLogin:self didFailWithError:error];
}


@end
