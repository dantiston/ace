CC=gcc
CFLAGS=-O3 -g -fPIC
#CFLAGS=-g
OBJS = train.o words.o tags.o hmm.o

ifeq (${shell uname -s},Darwin)
include ../MacOSX.config
endif

# gnu89 restores implicit-int/-function as warnings instead of the hard
# errors modern compilers default to; this codebase's K&R-ish style relies
# on that being legal. (Not inherited from MacOSX.config -- this is its own
# separate `make -C post` invocation, and needs it on Linux too.)
CFLAGS += -std=gnu89

# compilation flags:

CFLAGS += -DUSE_HMM
# uncomment the above line and recompile
# to enable bigram HMM tagging.

#CFLAGS += -DNO_MORPH_RULES
# uncomment the above line and recompile
# to disable rules for classifying unknown words.
# in this case, all unknown words will be tagged as NN.

post.o: ${OBJS}
	ld -r -o post.o ${OBJS}

clean:
	rm -f ${OBJS} post.o
