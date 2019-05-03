//
//  TwitterOAuthLogin.h
//  Here-I-Am
//
//  Created by Michael Rockhold on 6/30/10.
//  Copyright 2010 The Rockhold Company. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol TwitterOAuthLoginDelegate;
@class TWSession;

@interface TwitterOAuthLogin : NSObject
{
	id<TwitterOAuthLoginDelegate> _delegate;
}

-(id)initWithTwitterOAuthLoginDelegate:(id<TwitterOAuthLoginDelegate>)delegate;

-(void)start;

@end

@protocol TwitterOAuthLoginDelegate < NSObject >

@property (nonatomic, retain, readonly) TWSession* session;
@property (nonatomic, retain, readonly) UINavigationController* navigationController;
@property (nonatomic, readonly) BOOL pushControllerAnimated;

-(void)twitterOAuthLogin:(TwitterOAuthLogin*)twitterOAuthLogin didLogin:(BOOL)ok;

-(void)twitterOAuthLogin:(TwitterOAuthLogin*)twitterOAuthLogin didFailWithError:(NSError*)error;

@end
