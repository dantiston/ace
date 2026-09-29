PREFIX=/usr/local

# [incr tsdb()] support needs a LOGON installation's headers and libs; only
# enable it when LOGONROOT points at one, so plain Linux builds still work.
ifdef LOGONROOT
DELPHIN_CFLAGS=-isystem ${LOGONROOT}/lingo/lkb/include -DTSDB
DELPHIN_LIBS=-L ${LOGONROOT}/lingo/lkb/lib/linux.x86.64 -Wl,-Bstatic -litsdb -lpvm3 -Wl,-Bdynamic
endif

POST_CFLAGS=-I post/ -DPOST
POST_LIBS=-Wl,-Bstatic -lutil -Wl,-Bdynamic	# for openpty for calling out to tnt (which uses fully buffered stdio)

# repp doesn't build against current Boost releases upstream (Boost dropped
# the plain-C regex.h API it's written against); vendor/repp-src carries a
# patch for that, built into vendor/repp/lib/librepp.a below -- for whatever
# machine/arch/OS is actually running `make`, rather than relying on a
# system package (which for repp specifically, no distro ships anyway).
REPP_CFLAGS=-I vendor/repp/include
REPP_LIBS=vendor/repp/lib/librepp.a
REPP_BUILD_DEP=vendor/repp/lib/librepp.a
BOOST_CFLAGS=

BOOST_REGEX_LIBS=-lboost_regex -lstdc++

# GNU ld (Linux) vs Apple ld64 (macOS) spell "record this shared lib's
# install name" differently; MacOSX.config overrides this for Darwin.
SONAME_FLAG=-Wl,-soname,libace.so

#CPU=-m32
CC=gcc
CXX=g++
#CFLAGS=-g -O6 -fomit-frame-pointer -funsigned-char -falign-loops=32 -funroll-loops ${CPU} -fprofile-generate=./profile-data/
#REPP_LIBS+=-lgcov
#CFLAGS=-g -O6 -fomit-frame-pointer -funsigned-char -falign-loops=32 -funroll-loops ${CPU} -fprofile-use=./profile-data/

#CFLAGS=-g -O6 -fomit-frame-pointer -funsigned-char -falign-loops=32 -funroll-loops ${CPU}
CFLAGS=-g -O6 -fno-omit-frame-pointer -funsigned-char -falign-loops=32 -funroll-loops ${CPU}
#CFLAGS=-g -O6 -funsigned-char -falign-loops=32 -funroll-loops ${CPU}  -pg
#CFLAGS=-g -O2 -funsigned-char
#CFLAGS=-g -O2 -pg -funsigned-char
#CFLAGS=-g -funsigned-char
#CFLAGS+=-fPIC

# gnu89 restores implicit-int/-function as warnings instead of the hard
# errors modern compilers (gcc 14+, clang 16+) default to; this codebase's
# K&R-ish style relies on that being legal.
CFLAGS+=-std=gnu89

EXPORT_DYNAMIC_CFLAG=-Wl,--export-dynamic

# MacOSX.config is macOS-only (Homebrew paths, -lc++, etc.) -- only pull it
# in when actually building on Darwin, so Linux keeps its own defaults above.
ifeq (${shell uname -s},Darwin)
include MacOSX.config
endif

CFLAGS+=${DELPHIN_CFLAGS} ${POST_CFLAGS} ${REPP_CFLAGS} ${BOOST_CFLAGS}

OBJ=lexicon.o chart.o dag.o type.o tdl.o rule.o morpho.o roots.o freeze.o unify.o qc.o agenda.o net.o glb.o semindex.o hash.o mrs.o mrsvpm.o mrsdg.o itsdb.o pack.o unpack.o maxent.o generate.o parse.o lui.o conf.o preprocessor.o treebank-control.o token.o lattice-mapping.o lexical-parse.o generalize.o transfer.o transfer-result.o edge-vectors.o forest-out.o exunpack.o semilattice.o rebuild-th.o compile-qc.o idiom.o yy.o lisp.o tnt.o tree.o reconstruct.o arbiter.o profiler.o qcparse.o rule-use-model.o ubertag.o dublin.o licenses.o dag-provenance.o semi.o timeout.o csaw/csaw.o csaw/naive.o csaw/normalize.o

PICOBJS=$(patsubst %,pic/%,${OBJ} libace.o)
HIDDENPICOBJS=pic/timer.o
APPOBJ=${OBJ} main.o post/post.o timer.o linenoise.o lui-cli.o

all: ace libace.so libace.a

vendor/repp/lib/librepp.a: vendor/repp-src/librepp/preprocessor.c vendor/repp-src/librepp/load_repp.c vendor/repp-src/librepp/unicode.c vendor/repp-src/include/librepp.h vendor/repp-src/librepp/unicode.h
	mkdir -p vendor/repp/lib vendor/repp/include
	cp vendor/repp-src/include/librepp.h vendor/repp-src/librepp/unicode.h vendor/repp/include/
	${CC} -std=gnu89 -O2 -fPIC -I vendor/repp-src/include -I vendor/repp-src/librepp -c vendor/repp-src/librepp/unicode.c -o vendor/repp/lib/unicode.o
	${CXX} -std=c++17 -O2 -fPIC ${BOOST_CFLAGS} -I vendor/repp-src/include -I vendor/repp-src/librepp -c vendor/repp-src/librepp/preprocessor.c -o vendor/repp/lib/preprocessor.o
	${CXX} -std=c++17 -O2 -fPIC ${BOOST_CFLAGS} -I vendor/repp-src/include -I vendor/repp-src/librepp -c vendor/repp-src/librepp/load_repp.c -o vendor/repp/lib/load_repp.o
	ar cru vendor/repp/lib/librepp.a vendor/repp/lib/unicode.o vendor/repp/lib/preprocessor.o vendor/repp/lib/load_repp.o
	ranlib vendor/repp/lib/librepp.a

# preprocessor.c is the one ACE source file that includes librepp.h
preprocessor.o pic/preprocessor.o: ${REPP_BUILD_DEP}

ace: ${APPOBJ} ${REPP_BUILD_DEP}
	${CC} ${LDFLAGS} ${EXPORT_DYNAMIC_CFLAG} ${CFLAGS} ${APPOBJ} -o ace ${POST_LIBS} ${REPP_LIBS} ${DELPHIN_LIBS} -lpthread -lm ${BOOST_REGEX_LIBS} -ldl

static: ${APPOBJ}
	${CC} -Wl,--dynamic-list=dylist.txt ${CFLAGS} ${APPOBJ} -Wl,-Bstatic -static ${POST_LIBS} ${REPP_LIBS} ${DELPHIN_LIBS} -static -lpthread -lm -L ~/local/lib/ -lboost_regex -lstdc++ -la -ldl -o ace.static

post/post.o:
	${MAKE} -C post

${PICOBJS} : pic/%.o: %.c
	mkdir -p pic pic/csaw
	${CC} ${CFLAGS} -fPIC -c $< -o $@

${HIDDENPICOBJS} : pic/%.o: %.c
	mkdir -p pic
	${CC} ${CFLAGS} -fvisibility=hidden -fPIC -c $< -o $@

libace.so: ${PICOBJS} ${HIDDENPICOBJS} post/post.o ${REPP_BUILD_DEP}
	rm -f libace.so
	${CC} -shared ${PICOBJS} ${HIDDENPICOBJS} post/post.o ${SONAME_FLAG} -o libace.so -L vendor/repp/lib -lrepp ${DELPHIN_LIBS} -ldl -lutil ${BOOST_REGEX_LIBS}
# note: -lutil cannot be compiled statically into a shared library, because the bozos that built it didn't use -fPIC...

libace.a: ${PICOBJS} ${HIDDENPICOBJS} post/post.o
	rm -f libace.a
	ar cru libace.a ${PICOBJS} ${HIDDENPICOBJS} post/post.o
	ranlib libace.a

install: ace libace.so libace.a
	cp ace ${PREFIX}/bin/
	cp libace.so ${PREFIX}/lib/
	cp libace.a ${PREFIX}/lib/
	mkdir -p ${PREFIX}/include/ace
	cp *.h ${PREFIX}/include/ace/

clean:
	rm -f ${OBJ} ${APPOBJ} ace ace.static
	rm -f libace.a libace.so
	rm -f ${PICOBJS}
	rm -rf vendor/repp/lib vendor/repp/include
	make -C post clean
