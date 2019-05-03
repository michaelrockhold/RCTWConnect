
#import "BaseLoginButton.h"

@class TWSession;

@interface TwitterLoginButton : BaseLoginButton
{
	TWSession* _session;
}

@end
