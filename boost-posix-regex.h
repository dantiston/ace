#ifndef	BOOST_POSIX_REGEX_H
#define	BOOST_POSIX_REGEX_H

/*
 * ACE's own C code (as opposed to vendor/repp, which is compiled as C++)
 * calls Boost.Regex's legacy POSIX-style C API (regcomp/regexec/regfree,
 * REG_PERL) directly from plain C, via <boost/regex.h>. That header still
 * declares a fully C-compatible API -- the underlying struct/typedef
 * definitions all have working #else branches for non-C++ compilation --
 * but boost/regex.h and boost/cregex.hpp unconditionally pull in
 * boost/regex/config.hpp first, which drags in C++-only headers (e.g.
 * boost/assert.hpp) that a C compiler can't parse at all.
 *
 * config.hpp's only job for our purposes is to define a handful of
 * feature/linkage macros before cregex.hpp uses them. On non-Windows with
 * static linking (our case) they're all empty, so pre-defining them lets
 * us include the real, ABI-correct declarations while skipping the
 * C++-only config chain. Deliberately including the stable top-level
 * <boost/cregex.hpp> here rather than reaching into its internal
 * version-namespaced path (boost/regex/vN/cregex.hpp, where N has changed
 * across Boost releases) -- that internal path is themselves resolved by
 * whichever N a given Boost install actually uses, so this works across
 * Boost versions rather than pinning to whatever's on the machine this
 * was last tested on.
 */
#define	BOOST_REGEX_CONFIG_HPP
#define	BOOST_REGEX_DECL
#define	BOOST_REGEX_CCALL
#define	BOOST_REGEX_MODULE_EXPORT
#include	<boost/cregex.hpp>

#endif
