//
//  TWSession.h
//  Here-I-Am
//
//  Created by Michael Rockhold on 6/30/10.
//  Copyright 2010 The Rockhold Company. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAToken.h"
#import "OAConsumer.h"
#import <CoreLocation/CoreLocation.h>
#import "OAMutableURLRequest.h"

@protocol TWSessionRequestTokenDelegate;
@protocol TWSessionAccessTokenDelegate;
@class RequestTokenRequestor;
@class AccessTokenRequestor;

@interface TWSession : NSObject
{
	id<OAConsumer> _consumer;
	OAToken* _token;
	OAToken* _accessToken;
	BOOL _callback_confirmed;
	NSString* _verifier;
	NSString* _authorizationCallback;
	
	NSString* _user_screen_name;
	NSString* _user_id;
	
	RequestTokenRequestor* _requestTokenRequestor;
	AccessTokenRequestor* _accessTokenRequestor;
}

@property (nonatomic, readonly)			BOOL isConnected;
@property (nonatomic, retain)			OAToken* requestToken;
@property (nonatomic, retain)			OAToken* accessToken;
@property (nonatomic, retain, readonly) NSString* callback;
@property (nonatomic)					BOOL callback_confirmed;
@property (nonatomic, retain)			NSString* verifier;

@property (nonatomic, retain)			NSString* userID;
@property (nonatomic, retain)			NSString* userName;

+(NSString*)X_Auth_Service_Provider;

+(TWSession*)session; // class-wide singleton

-(id)initWithOAConsumer:(id<OAConsumer>)consumer authorizationCallback:(NSString*)acb;

-(void)logout;

-(OAMutableURLRequest*)makeStatusUpdateRequest:(NSString*)status
									coordinate:(CLLocationCoordinate2D)coordinate
							displayCoordinates:(BOOL)displayCoordinate;

-(OAMutableURLRequest*)newVerifyCredentialsRequest;

-(void)requestRequestTokenForDelegate:(id<TWSessionRequestTokenDelegate>)rtd;

-(void)requestAccessTokenForDelegate:(id<TWSessionAccessTokenDelegate>)atd;

@end

@protocol TWSessionRequestTokenDelegate <NSObject>

-(void)twSessionRequestRequestTokenFinished:(TWSession*)session;

-(void)twSession:(TWSession*)session requestRequestTokenDidFailWithError:(NSError*)error;

@end

@protocol TWSessionAccessTokenDelegate <NSObject>

-(void)twSessionRequestAccessTokenFinished:(TWSession*)session;

-(void)twSession:(TWSession*)session requestAccessTokenDidFailWithError:(NSError*)error responseDictionary:(NSDictionary*)respDic;

@end

#define cTWSessionLoginNotification @"TWSessionLoginNotification"
#define cTWSessionDidNotLoginNotification @"TWSessionDidNotLoginNotification"
#define cTWSessionLogoutNotification @"TWSessionLogoutNotification"
#define cTWSessionWillLogoutNotification @"TWSessionWillLogoutNotification"

