/**
 * This file is part of Dissector
 * Copyright 2013 Oliver Kuckertz <oliver.kuckertz@mologie.de>
 * See COPYING for licensing information.
 */

#pragma once

#define kDSSettingsPlist @"/var/mobile/Library/Preferences/com.mologie.dissector.plist"
#define kDSApplicationsPlist @"/var/mobile/Library/Preferences/com.mologie.dissector.applications.plist"

typedef enum _DSDebuggerType {
	kDSNoDebugger,
	kDSSparkInspectorDebugger,
	kDSRevealDebugger
} DSDebuggerType;

typedef unsigned DSDebuggerFlags;

#define kDSDebuggerDefaultFlag                  (0)
#define kDSDebuggerSupportsSpringBoardFlag      (1 << 0)
#define kDSDebuggerSupportsDynamicUnloadingFlag (1 << 1)

typedef void *DSDebuggerHandle;

typedef struct _DSDebuggerActions {
	DSDebuggerHandle (*load)(void);
	void (*unload)(DSDebuggerHandle handle);
} DSDebuggerActions;

typedef struct _DSDebugger {
	DSDebuggerType   type;
	DSDebuggerHandle handle;
} DSDebugger;

typedef struct _DSDebuggerProperties {
	DSDebuggerFlags   flags;
	DSDebuggerActions actions;
} DSDebuggerProperties;
