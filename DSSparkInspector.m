/**
 * This file is part of Dissector
 * Copyright 2013 Oliver Kuckertz <oliver.kuckertz@mologie.de>
 * See COPYING for licensing information.
 */

#import "DSSparkInspector.h"
#import <Foundation/Foundation.h>
#import <dlfcn.h>

DSDebuggerHandle DSSparkInspectorLoad(void)
{
	DSDebuggerHandle handle = dlopen("/Library/Dissector/Runtime/SparkInspector.dylib", RTLD_NOW);
	
	if (handle) {
		id sc = [NSClassFromString(@"IBARevealLoader") performSelector:@selector(sharedClient)];
		[sc performSelector:@selector(enableObservation)];
	}
	
	return handle;
}
