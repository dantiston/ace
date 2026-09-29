This is repp 0.2.2 (http://sweaglesw.org/linguistics/repp-0.2.2.tar.gz,
LGPL, (C) 2009 Woodley Packard), trimmed to just the three files ACE
actually needs (`librepp/unicode.c`, `librepp/preprocessor.c`,
`librepp/load_repp.c`, `include/librepp.h`, `librepp/unicode.h`), with the
autotools build scaffolding removed -- the Makefile at the repo root builds
these directly, it doesn't run `./configure`.

Patches applied, all for the same underlying reason: current Boost releases
dropped the plain-C `<boost/regex.h>` POSIX API this code was written
against (only its C++ mode still works), and repp has never been updated
upstream to match:

- `include/librepp.h`, `librepp/unicode.h`: wrapped the function
  declarations in `extern "C" { ... }` so the public API keeps C linkage
  when compiled as C++ (needed below), since ACE's own C code calls it.
- `librepp/preprocessor.c`, `librepp/load_repp.c`: compiled as C++ instead
  of C (the Makefile uses `${CXX}` for just these two files), since that's
  the only way to reach Boost.Regex's real implementation at all now. That
  needed: a small compat shim mapping the plain `regcomp`/`regexec`/
  `regfree`/`regerror`/`regex_t` names this code calls to the `UNICODE`
  (wide-char) Boost symbols the header actually exports now; explicit
  casts on `malloc`/`calloc`/`realloc` returns (C++ doesn't allow the
  implicit `void*` conversion); the one GNU nested function in
  `preprocessor.c` (`process_lost_char`) turned into a C++ lambda, since
  nested functions are a C-only GNU extension; and brace-scoping one
  `switch` case in `load_repp.c` whose local variable declarations
  otherwise cross a case label, which C++ (unlike C) rejects.

See `vendor/repp/lib/librepp.a` for the actual build output -- the Makefile
rebuilds it here (via the `vendor/repp/lib/librepp.a` rule) for whatever
machine/arch/OS is running `make`, rather than shipping a prebuilt archive.
