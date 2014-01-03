/**
 * This file is part of Dissector
 * Copyright 2013 Oliver Kuckertz <oliver.kuckertz@mologie.de>
 * See COPYING for licensing information.
 */

#import "DSReveal.h"
#import <Foundation/Foundation.h>
#import <dlfcn.h>

DSDebuggerHandle DSRevealLoad(void)
{
	DSDebuggerHandle handle = dlopen("/Library/Dissector/Runtime/Reveal.dylib", RTLD_NOW);
	
	if (handle) {
		[NSClassFromString(@"IBARevealLoader") performSelector:@selector(startServer)];
	}
	
	return handle;
}

void DSRevealUnload(DSDebuggerHandle handle)
{
	if (handle) {
		[NSClassFromString(@"IBARevealLoader") performSelector:@selector(stopServer)];
		dlclose(handle);
	}
}
