
#import "TwitterLoginButton.h"
#import "TWSession.h"

///////////////////////////////////////////////////////////////////////////////////////////////////

@implementation TwitterLoginButton

+ (void)initialize
{
	if (self == [TwitterLoginButton class])
	{
		[self setImage:[UIImage imageNamed:@"TwitterLib.bundle/images/logout.png"]		connected:YES wide:NO highlighted:NO];
		[self setImage:[UIImage imageNamed:@"TwitterLib.bundle/images/logout_down.png"]	connected:YES wide:NO highlighted:YES];
		
		[self setImage:[UIImage imageNamed:@"TwitterLib.bundle/images/login.png"]		connected:NO wide:NO highlighted:NO];
		[self setImage:[UIImage imageNamed:@"TwitterLib.bundle/images/login_down.png"]	connected:NO wide:NO highlighted:YES];
		
	}
}

-(BOOL)connected { return _session.isConnected; }

- (void)initButton
{
	_session = [[TWSession session] retain];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionLoginNotification:) name:cTWSessionLoginNotification object:_session];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionLoginNotification:) name:cTWSessionLogoutNotification object:_session];
	
	[super initButton];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// NSObject

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:_session];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:_session];
	[_session release];
	
	[super dealloc];
}

-(void)sessionLoginNotification:(NSNotification*)notification
{
	[super updateImage];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// UIAccessibility informal protocol (on 3.0 only)

- (NSString *)accessibilityLabel
{
	return NSLocalizedString(self.connected ? @"Disconnect from Twitter" : @"Connect to Twitter", @"Accessibility label");
}

@end
