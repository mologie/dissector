/**
 * This file is part of Dissector
 * Copyright 2013 Oliver Kuckertz <oliver.kuckertz@mologie.de>
 * See COPYING for licensing information.
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

#import "Dissector.h"
#import "DSAlertViewHandler.h"
#import "DSLog.h"
#import "DSSparkInspector.h"
#import "DSReveal.h"
#import <stdbool.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "UIApplication+Private.h"

// TODO import the contents of this table from bundle files
static const DSDebuggerProperties kDSDebuggerProperties[] = {
	{ kDSDebuggerDefaultFlag, { NULL, NULL } },
	{ kDSDebuggerSupportsSpringBoardFlag, { DSSparkInspectorLoad, NULL } },
	{ kDSDebuggerSupportsDynamicUnloadingFlag, { DSRevealLoad, DSRevealUnload } }
};

// environment, determined once when loaded
static bool isSpringBoard = false;

// global configuration, updated as notifications arrive
static DSDebuggerType configDebugger = kDSNoDebugger;
static bool configEnabledForCurrentBundle = false;

// local state, updates after notifications have been processed
static DSDebugger currentDebugger;
static bool willExit;

static void DSQueueApplicationTermination(void)
{
	if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {
		DSAlertViewHandler *handler = [[DSAlertViewHandler alloc] init]; 
		NSString *message = @"This application must be terminated in order to unload the debugger.";
		NSString *buttonTitle = @"Terminate";
		if (isSpringBoard) {
			message = @"SpringBoard must be restarted in order to unload the debugger.";
			buttonTitle = @"Restart SpringBoard"; 
		}
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Dissector" message:message delegate:handler cancelButtonTitle:buttonTitle otherButtonTitles:nil];
		[alert show];
		willExit = true;
	} else {
		[[UIApplication sharedApplication] terminateWithSuccess];
	}
}

static void DSSwitchDebugger(DSDebuggerType newDebuggerType)
{
	if (currentDebugger.type != kDSNoDebugger) {
		const DSDebuggerProperties *properties = &kDSDebuggerProperties[currentDebugger.type];
		if (properties->flags & kDSDebuggerSupportsDynamicUnloadingFlag) {
			properties->actions.unload(currentDebugger.handle);
			currentDebugger.type = kDSNoDebugger;
			DSLog(@"Unloaded previous debugger %d", currentDebugger.type);	
		} else {
			DSLog(@"Debugger %d does not support dynamic unloading", currentDebugger.type);
			DSQueueApplicationTermination();
			return;
		}
	}
	
	if (newDebuggerType != kDSNoDebugger) {
		const DSDebuggerProperties *properties = &kDSDebuggerProperties[newDebuggerType];
		currentDebugger.handle = properties->actions.load();
		if (currentDebugger.handle) {
			currentDebugger.type = newDebuggerType;
			DSLog(@"Loaded debugger %d", newDebuggerType);				
		} else {
			DSLog(@"Load action for debugger %d failed", newDebuggerType);
		}
	}
}

static void DSSynchronizeWithConfiguration(void)
{
	if (willExit)
		return;
	
	DSDebuggerType newDebuggerType = configEnabledForCurrentBundle ? configDebugger : kDSNoDebugger;
	const DSDebuggerProperties *properties = &kDSDebuggerProperties[newDebuggerType];
	
	if (newDebuggerType != kDSNoDebugger) {
		if (isSpringBoard && !(properties->flags & kDSDebuggerSupportsSpringBoardFlag)) {
			DSLog(@"Debugger %d does not support SpringBoard", newDebuggerType);
			newDebuggerType = kDSNoDebugger;
		}
	}
	
	if (newDebuggerType != currentDebugger.type) {
		DSSwitchDebugger(newDebuggerType);
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
}
