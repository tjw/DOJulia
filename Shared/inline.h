#ifndef _inline_h
#define _inline_h

#if defined(__GNUC__) && !defined(NO_INLINE)
#define INLINE inline
#else
#define INLINE
#endif

#endif
