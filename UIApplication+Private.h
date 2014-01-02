#pragma once

@interface UIApplication (Private)
- (void)terminateWithSuccess;
- (void)suspend;
- (BOOL)launchApplicationWithIdentifier:(NSString *)identifier suspended:(BOOL)suspended;
@end
