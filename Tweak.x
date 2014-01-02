/**
 * Tweak.x - Dissector Cydia Substrate addin
 *
 * Dissector: Attach popular runtime debuggers to any application
 * Copyright 2013 Oliver Kuckertz <oliver.kuckertz@mologie.de>
 *
 * This Cydia Substrate addin is responsible for loading or unloading the
 * appropriate debugger frameworks. It is injected into every graphical
 * application and, upon being loaded, registers observers for the following
 * events:
 *    com.mologie.settingschanged
 *    com.mologie.applicationschanged
 *
 * When an event is fired, this addin will evaluate whether it should switch to
 * a different debugging backend, and will thereby possibly restart the
 * application.
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <dlfcn.h>
#import <stdbool.h>
#import <unistd.h>
#import "DSLog.h"
#import "UIApplication+Private.h"

// Terminate the application when a runtime library is unloaded. Right now, neither Spark Inspector nor Reveal properly support dynamic unloading. Uncomming the following should this every change.
#define DS_QUIT_ON_UNLOAD

typedef enum _DSDebugger {
	kDSNoDebugger,
	kDSSparkInspectorDebugger,
	kDSRevealDebugger
} DSDebugger;

#define kDSSettingsPlist @"/var/mobile/Library/Preferences/com.mologie.dissector.plist"
#define kDSApplicationsPlist @"/var/mobile/Library/Preferences/com.mologie.dissector.applications.plist"

// environment
static bool isSpringBoard = false;

// global configuration, updated as notifications arrive
static DSDebugger configDebugger = kDSNoDebugger;
static bool configEnabledForCurrentBundle = false;

// local state
static bool initialized = false;
static DSDebugger currentDebugger = kDSNoDebugger;
static void* currentDebuggerDylib = NULL;
static bool willExit = false;

static const char* DSGetDebuggerRuntimePath(DSDebugger debugger)
{
	switch (debugger)
	{
	case kDSSparkInspectorDebugger:
		return "/Library/Dissector/Runtime/SparkInspector.dylib";

	case kDSRevealDebugger:
		return "/Library/Dissector/Runtime/Reveal.dylib";
		
	default:
		return NULL;
	}
}

@interface DSTerminationAlertViewHandler : NSObject <UIAlertViewDelegate>
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;
@end
@implementation DSTerminationAlertViewHandler
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	[[UIApplication sharedApplication] terminateWithSuccess];
}
@end

@interface DSSuspensionAlertViewHandler : NSObject <UIAlertViewDelegate>
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;
@end
@implementation DSSuspensionAlertViewHandler
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	[[UIApplication sharedApplication] suspend];
}
@end

static void DSRestartApplication(void)
{
	DSLog(@"The current debugger backend requires restarting the application for unloading.");
	if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {
		DSTerminationAlertViewHandler *handler = [[DSTerminationAlertViewHandler alloc] init]; 
		NSString *message = @"This application must be terminated in order to unload the debugger.";
		NSString *buttonTitle = @"Terminate";
		if (isSpringBoard) {
			message = @"SpringBoard must be restarted in order to close the debugger connection.";
			buttonTitle = @"Restart SpringBoard"; 
		}
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Dissector" message:message delegate:handler cancelButtonTitle:buttonTitle otherButtonTitles:nil];
		[alert show];
		willExit = true;
	} else {
		[[UIApplication sharedApplication] terminateWithSuccess];
	}
}

#ifndef DS_QUIT_ON_UNLOAD
static void DSUnloadDebuggerDylib(void)
{
	dlclose(currentDebuggerDylib);
	currentDebuggerDylib = NULL;
	currentDebugger = kDSNoDebugger;
}
#endif

static void DSUnloadDebugger(void)
{
	switch (currentDebugger) {
	case kDSNoDebugger:
		return;

	case kDSSparkInspectorDebugger:
		DSRestartApplication();
		return;

	case kDSRevealDebugger:
#ifdef DS_QUIT_ON_UNLOAD
		DSRestartApplication();
#else
		DSUnloadDebuggerDylib();
#endif
		return;
	}
}

static void DSLoadDebugger(DSDebugger newDebugger)
{
	if (newDebugger != kDSNoDebugger) {
		const char* dylibPath = DSGetDebuggerRuntimePath(newDebugger);
		currentDebuggerDylib = dlopen(dylibPath, RTLD_LAZY);
		if (currentDebuggerDylib) {
			currentDebugger = newDebugger;
			DSLog(@"Loaded debugger dylib %s", dylibPath);
			if (initialized && !isSpringBoard && [[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {
				DSSuspensionAlertViewHandler *handler = [[DSSuspensionAlertViewHandler alloc] init]; 
				NSString *message = @"This application must be suspended in order to initialize the debugger.";
				NSString *buttonTitle = @"Suspend";
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Dissector" message:message delegate:handler cancelButtonTitle:buttonTitle otherButtonTitles:nil];
				[alert show];
			}
		} else {
			DSLog(@"Failed to load debugger dylib %s", dylibPath);
		}
	} else {
		DSLog(@"No debugger has been selected");
	}
}

static void DSSynchronizeWithConfiguration(void)
{
	DSDebugger newDebugger = configEnabledForCurrentBundle ? configDebugger : kDSNoDebugger;
	
	// Only Spark Inspector is compatible with SpringBoard at the time of writing this extension
	if (isSpringBoard && newDebugger != kDSSparkInspectorDebugger)
		newDebugger = kDSNoDebugger;
	
	if (newDebugger != currentDebugger) {
		DSUnloadDebugger();
		if (!willExit)
			DSLoadDebugger(newDebugger);
	} else {
		DSLog(@"Debugger did not change");
	}
}

static void DSLoadSettings(void)
{
	NSDictionary *settings = [[NSDictionary alloc] initWithContentsOfFile:kDSSettingsPlist];
	if (![[settings objectForKey:@"Enable"] boolValue]) {
		configDebugger = kDSNoDebugger;
		DSLog(@"Disabled in preferences, or no preference file exists");
	} else {
		NSString *debuggerName = [settings objectForKey:@"Debugger"];
		if ([debuggerName isEqualToString:@"Spark Inspector"])
			configDebugger = kDSSparkInspectorDebugger;
		else if ([debuggerName isEqualToString:@"Reveal"])
			configDebugger = kDSRevealDebugger;
		else
			configDebugger = kDSNoDebugger;
	}
	DSLog(@"Settings loaded, using debugger %d", configDebugger);
}

static void DSSettingsChangedNotification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	DSLoadSettings();
	DSSynchronizeWithConfiguration();
}

static void DSLoadApplications(void)
{
	NSDictionary *applications = [[NSDictionary alloc] initWithContentsOfFile:kDSApplicationsPlist];
	NSString *currentBundleId = [[NSBundle mainBundle] bundleIdentifier];
	configEnabledForCurrentBundle = [[applications objectForKey:currentBundleId] boolValue];
	DSLog(@"Applications loaded, enabled for current bundle = %@", configEnabledForCurrentBundle ? @"true" : @"false");
}

static void DSApplicationsChangedNotification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	DSLoadApplications();
	DSSynchronizeWithConfiguration();
}

static void DSRegisterNotificationObservers()
{
	CFNotificationCenterAddObserver(
		CFNotificationCenterGetDarwinNotifyCenter(),
		NULL,
		DSSettingsChangedNotification,
		CFSTR("com.mologie.dissector.settingschanged"),
		NULL,
		CFNotificationSuspensionBehaviorCoalesce
		);
	CFNotificationCenterAddObserver(
		CFNotificationCenterGetDarwinNotifyCenter(),
		NULL,
		DSApplicationsChangedNotification,
		CFSTR("com.mologie.dissector.applicationschanged"),
		NULL, 
		CFNotificationSuspensionBehaviorCoalesce
		);
	DSLog(@"Registered notification observers");
}

static void DSSetupEnvironment(void)
{
	NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
	isSpringBoard = [bundleId isEqualToString:@"com.apple.springboard"];
}

%ctor
{
	DSLog(@"Extension loaded");
	DSSetupEnvironment();
	DSLoadSettings();
	DSLoadApplications();
	DSSynchronizeWithConfiguration();
	DSRegisterNotificationObservers();
	initialized = true;
}
