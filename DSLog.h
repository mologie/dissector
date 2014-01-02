/**
 * DSLog.h - enable logging if DEBUG is specified
 * Shamelessly copied from PreferenceLoader
 */

#pragma once

#ifndef DEBUG_TAG
#	define DEBUG_TAG "Dissector"
#endif

#ifdef DEBUG
#	define DSLog(...) NSLog(@ DEBUG_TAG "! %s:%d: %@", __FILE__, __LINE__, [NSString stringWithFormat:__VA_ARGS__])
#else
#	define DSLog(...)
#endif
