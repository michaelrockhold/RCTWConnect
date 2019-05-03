	//
	//  TWSession.m
	//  Here-I-Am
	//
	//  Created by Michael Rockhold on 6/30/10.
	//  Copyright 2010 The Rockhold Company. All rights reserved.
	//

#import "TWSession.h"
#import <OAuthConsumer.h>
#import "NSData+ResponseDecoding.h"
#import "RCError.h"

static TWSession* s_singleton = nil;

@interface TWSession ()

-(void)saveTwitterAccess;

-(void)readTwitterAccess;

@end

#pragma mark internal objects' private interfaces

@interface RequestTokenRequestor : OAAsynchronousDataFetcher < OADataFetcherDelegate >
{
	id<TWSessionRequestTokenDelegate> _requestTokenDelegate;
	TWSession* _session;
}
-(id)initWithDelegate:(id<TWSessionRequestTokenDelegate>)d session:(TWSession*)session request:(OAMutableURLRequest*)request;
@end

@interface AccessTokenRequestor : OAAsynchronousDataFetcher < OADataFetcherDelegate >
{
	id<TWSessionAccessTokenDelegate> _accessTokenDelegate;
	TWSession* _session;
}

-(id)initWithAccessTokenDelegate:(id<TWSessionAccessTokenDelegate>)d session:(TWSession*)session request:(OAMutableURLRequest*)request;
@end

@implementation RequestTokenRequestor

-(id)initWithDelegate:(id<TWSessionRequestTokenDelegate>)d session:(TWSession*)session request:(OAMutableURLRequest*)r
{
	if ( self = [super initWithRequest:r delegate:self] )
	{
		_requestTokenDelegate = [d retain];
		_session = [session retain];
	}
	return self;
}

-(void)dealloc
{
	[_requestTokenDelegate release];
	[_session release];
	[super dealloc];
}

-(void)dataFetcher:(OADataFetcher*)fetcher didFinishRequest:(NSURLRequest*)r response:(NSURLResponse*)resp data:(NSData*)data succeeded:(BOOL)ok
{
	if ( !ok )
	{
		NSString* msg = [NSHTTPURLResponse localizedStringForStatusCode:[(NSHTTPURLResponse*)resp statusCode]];
		[_requestTokenDelegate twSession:_session requestRequestTokenDidFailWithError:[RCError rcErrorWithSubdomain:@"TWConnect" errorMsgKey:msg]];
		[fetcher release];
	}
	else 
	{
		NSDictionary* responseDic = [data decodeResponse];
		
		_session.requestToken = [[OAToken alloc] initWithKey:[responseDic objectForKey:@"oauth_token"] secret:[responseDic objectForKey:@"oauth_token_secret"]];
		
		_session.callback_confirmed = [@"true" isEqualToString:[responseDic objectForKey:@"oauth_callback_confirmed"]];
		
		[_requestTokenDelegate twSessionRequestRequestTokenFinished:_session];
		[fetcher release];
	}	
}

-(void)dataFetcher:(OADataFetcher*)fetcher didFailRequest:(NSURLRequest*)r response:(NSURLResponse*)resp data:(NSData*)data error:(NSError*)error
{
	[_requestTokenDelegate twSession:_session requestRequestTokenDidFailWithError:error];
	[fetcher release];
}
@end

@implementation AccessTokenRequestor

-(id)initWithAccessTokenDelegate:(id<TWSessionAccessTokenDelegate>)d session:(TWSession*)session request:(OAMutableURLRequest*)r
{
	if ( self = [super initWithRequest:r delegate:self] )
	{
		_accessTokenDelegate = [d retain];
		_session = [session retain];
	}
	return self;
}

-(void)dealloc
{
	[_accessTokenDelegate release];
	[_session release];
	[super dealloc];
}

-(void)dataFetcher:(OADataFetcher*)fetcher didFailRequest:(NSURLRequest*)r response:(NSURLResponse*)resp data:(NSData*)data error:(NSError*)error
{
	[_accessTokenDelegate twSession:_session requestAccessTokenDidFailWithError:error responseDictionary:[data decodeResponse]];
	[fetcher release];
}

-(void)dataFetcher:(OADataFetcher*)fetcher didFinishRequest:(NSURLRequest*)r response:(NSURLResponse*)resp data:(NSData*)data succeeded:(BOOL)ok
{
	NSDictionary* responseDic = [data decodeResponse];

	if ( !ok )
	{
		NSString* msg = [NSHTTPURLResponse localizedStringForStatusCode:[(NSHTTPURLResponse*)resp statusCode]];
		[_accessTokenDelegate twSession:_session requestAccessTokenDidFailWithError:[RCError rcErrorWithSubdomain:@"TWConnect" errorMsgKey:msg] responseDictionary:responseDic];
		[fetcher release];
	}
	else
	{
		_session.accessToken = [[OAToken alloc] initWithKey:[responseDic objectForKey:@"oauth_token"] secret:[responseDic objectForKey:@"oauth_token_secret"]];
		
		_session.userName = [[responseDic objectForKey:@"screen_name"] retain];
		
		_session.userID = [[responseDic objectForKey:@"user_id"] retain];
		
		[_session saveTwitterAccess];
		
		[_accessTokenDelegate twSessionRequestAccessTokenFinished:_session];
		[fetcher release];
	}
}
@end

#pragma mark -
#pragma mark -

@implementation TWSession
@synthesize requestToken = _token;
@synthesize verifier = _verifier, callback = _authorizationCallback, userID = _user_id, userName = _user_screen_name;
@synthesize callback_confirmed = _callback_confirmed;

+(TWSession*)session { return s_singleton; }

+(NSString*)X_Auth_Service_Provider
{
	return [NSString stringWithString:@"https://api.twitter.com/1/account/verify_credentials.json"];
}

-(id)initWithOAConsumer:(id<OAConsumer>)consumer authorizationCallback:(NSString*)acb
{
	if ( self = [super init] )
	{
		if ( s_singleton != nil )
		{
			NSLog(@"Warning: multiple TWSession objects being created. This is not likely to be by design.");
		}
		
		s_singleton = self;
		
		_consumer = [consumer retain];
		_authorizationCallback = [acb retain];
		
		_token = nil;
		_verifier = nil;
		_accessToken = nil;
		
		_user_id = nil;
		_user_screen_name = nil;
		
		[self readTwitterAccess];
	}
	return self;
}

-(void)dealloc
{	
	[_consumer release];
	[_authorizationCallback release];
	[_token release];
	[_verifier release];
	[_user_id release];
	[_user_screen_name release];
	
	[_requestTokenRequestor release];
	[_accessTokenRequestor release];
	
	[super dealloc];
}

-(void)saveTwitterAccess
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if ( _accessToken )
		[defaults setObject:[NSKeyedArchiver archivedDataWithRootObject:_accessToken] forKey:@"TwitterAccessToken"];
	
	[defaults setObject:_user_screen_name forKey:@"TwitterScreenName"];
	[defaults setObject:_user_id forKey:@"TwitterUserID"];
}

-(void)readTwitterAccess
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	id accessData = [defaults objectForKey:@"TwitterAccessToken"];
	if ( accessData )
		_accessToken = [[NSKeyedUnarchiver unarchiveObjectWithData:accessData] retain];
	
	_user_screen_name = [[defaults stringForKey:@"TwitterScreenName"] retain];
	_user_id = [[defaults stringForKey:@"TwitterUserID"] retain];
}

-(BOOL)isConnected
{
	return _accessToken != nil;
}

-(void)logout
{
	self.accessToken = nil;
}

-(OAToken*)accessToken
{
	return _accessToken;
}

-(void)setAccessToken:(OAToken*)v
{
	if ( nil != _accessToken )
	{
		[[NSNotificationCenter defaultCenter] 
		 postNotificationName:cTWSessionLogoutNotification 
		 object:self 
		 userInfo:nil];
		[_accessToken release];
	}
	
	_accessToken = v;
	if ( nil != v )
	{
		[[NSNotificationCenter defaultCenter] 
		 postNotificationName:cTWSessionLoginNotification 
		 object:self 
		 userInfo:nil];
		[_accessToken retain];
	}
}

#pragma mark -

-(void)requestRequestTokenForDelegate:(id<TWSessionRequestTokenDelegate>)rtd
{
		// From OAuth Spec, Appendix A.5.3 "Requesting Protected Resource"
	_requestTokenRequestor = [[RequestTokenRequestor alloc] initWithDelegate:rtd 
																						   session:self
																						   request:[[[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://api.twitter.com/oauth/request_token"]
																																	  method:@"POST"
																																	consumer:_consumer
																																	   token:nil
																																	   realm:nil
																														   signatureProvider:[[[OAHMAC_SHA1SignatureProvider alloc] init] autorelease]
																																	callback:_authorizationCallback
																																	verifier:nil] autorelease]];
	[_requestTokenRequestor start];
}


-(void)requestAccessTokenForDelegate:(id<TWSessionAccessTokenDelegate>)atd
{
	_accessTokenRequestor = [[AccessTokenRequestor alloc] initWithAccessTokenDelegate:atd
																						session:self
																						request:[[[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://api.twitter.com/oauth/access_token"]
																																   method:@"POST"
																																 consumer:_consumer
																																	token:_token
																																	realm:nil
																														signatureProvider:nil
																																 callback:nil
																																 verifier:_verifier] autorelease]];
	[_accessTokenRequestor start];
}

#pragma mark -
-(OAMutableURLRequest*)makeStatusUpdateRequest:(NSString*)status
									coordinate:(CLLocationCoordinate2D)coordinate
							displayCoordinates:(BOOL)displayCoordinate
{
	OAMutableURLRequest* statusUpdateRequest = [[[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://api.twitter.com/1/statuses/update.xml"]
																				  method:@"POST"
																				consumer:_consumer
																				   token:_accessToken
																				   realm:nil
																	   signatureProvider:nil
																				callback:nil
																				verifier:nil]
												autorelease];
	
	statusUpdateRequest.parameters = [NSArray arrayWithObjects:
									  [OARequestParameter requestParameterWithName:@"status" value:status],
									  [OARequestParameter requestParameterWithName:@"lat" value:[NSString stringWithFormat:@"%lf", coordinate.latitude]],
									  [OARequestParameter requestParameterWithName:@"long" value:[NSString stringWithFormat:@"%lf", coordinate.longitude]],
									  [OARequestParameter requestParameterWithName:@"display_coordinates" value:(displayCoordinate ? @"true" : @"false")],
									  nil];
	
	return statusUpdateRequest;
}

-(OAMutableURLRequest*)newVerifyCredentialsRequest
{
	return [[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[TWSession X_Auth_Service_Provider]]
											  method:@"GET"
											consumer:_consumer
											   token:_accessToken
											   realm:@"http://api.twitter.com/"
								   signatureProvider:nil
											callback:nil
										   verifier:nil];
}


@end
