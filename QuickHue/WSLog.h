//
//  WSLog.h
//  DPHue
//
//  This is in the public domain.
//  Originally created by Dan Parsons in 2012.
//
//  https://github.com/danparsons/QuickHue

#ifndef WSLog_h
#define WSLog_h

#ifdef DEBUG
#define WSLog(...) NSLog(__VA_ARGS__)
#else
#define WSLog(...) do {} while(0)
#endif

#endif
