//
//  TwitterLoginViewController.h
//  Aktuala Loko
//
//  Created by Michael Rockhold on 6/4/2010.
//  Copyright 2010 The Rockhold Company. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCWebDialogViewController.h"

@class TWSession;

@interface TwitterLoginViewController : RCWebDialogViewController
{
	TWSession* _session;
}

- (id)initWithDelegate:(id<RCWebDialogViewControllerDelegate>)d session:(TWSession*)session;

@end
