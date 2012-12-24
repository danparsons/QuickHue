//
//  WSLog.h
//  QuickHue
//
//  Created by Dan Parsons on 12/16/12.
//  Copyright (c) 2012 Dan Parsons. All rights reserved.
//

#ifndef Nerdfeed_WSLog_h
#define Nerdfeed_WSLog_h

#ifdef DEBUG
#define WSLog(...) NSLog(__VA_ARGS__)
#else
#define WSLog(...) do {} while(0)
#endif

#endif
