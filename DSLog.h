/**
 * This file is part of Dissector
 * Copyright 2013 Oliver Kuckertz <oliver.kuckertz@mologie.de>
 * See COPYING for licensing information.
 *
 * This file has been shamelessly copied from PreferenceLoader.
 * PreferenceLoader is licensed under the LGPLv3.
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
