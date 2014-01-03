/**
 * This file is part of Dissector
 * Copyright 2013 Oliver Kuckertz <oliver.kuckertz@mologie.de>
 * See COPYING for licensing information.
 */

#import "DSAlertViewHandler.h"
#import <UIKit/UIKit.h>
#import "UIApplication+Private.h"

@implementation DSAlertViewHandler
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	[[UIApplication sharedApplication] terminateWithSuccess];
}
@end
