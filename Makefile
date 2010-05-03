
# This needs GNU make. Really.

# Package name and version number:
dist = pure-gtksv-$(version)
version = 0.6

# Try to guess the installation prefix:
prefix = $(patsubst %/bin/pure,%,$(shell which pure 2>/dev/null))
ifeq ($(strip $(prefix)),)
# Fall back to /usr/local.
prefix = /usr/local
endif

# Installation goes into $(libdir)/pure, you can also set this directly
# instead of $(prefix).
libdir = $(prefix)/lib

# Try to guess the host system type.
host = $(shell ./config.guess)

# Platform-specific defaults, edit this as needed.
#PIC = -fPIC # uncomment for x86-64 compilation
DLL = .so
shared = -shared

PURE_COPTS=-I. -L.

# Take care of some common systems.
ifneq "$(findstring -mingw,$(host))" ""
# Windows
DLL = .dll
PURE_COPTS += -L$(includedir)/../bin
endif
ifneq "$(findstring -darwin,$(host))" ""
# OSX (untested)
DLL = .dylib
shared = -dynamiclib
endif
ifneq "$(findstring x86_64-,$(host))" ""
# 64 bit, needs -fPIC flag
PIC = -fPIC
endif

# Default CFLAGS are -g -O2, CPPFLAGS, LDFLAGS and LIBS are empty by default.
# These can be set from the command line as usual. Use CFLAGS, CPPFLAGS and
# LDFLAGS for compiler (-O etc.), preprocessor (-I etc.) and linker (-L etc.) 
# options, respectively. LIBS is to be used for additional libraries to be
# linked (-l etc.).

CFLAGS = -g -O2

# Extra pure-gen flags.
#PGFLAGS = -v

# Stuff to build.

# These are the core APIs related to gtksourceview-2.0.
core = gtksv.pure gtksvlangmgr.pure gtksviter.pure gtksvmark.pure gtksvprintcompositor.pure gtksvstyleschememgr.pure

# Uncomment this to build various auxiliary interfaces. You might also wish to
# add glade.pure to get the libglade interface which isn't built by default.
# addons = atk.pure cairo.pure pango.pure

modules = $(core) $(addons)
c-modules = $(modules:.pure=.c)
dlls = $(modules:.pure=$(DLL))

# examples = examples/hello examples/uiexample examples/life

# No need to edit below this line, usually.

FLAGS = $(CPPFLAGS) $(CFLAGS) $(PIC) $(LDFLAGS)

# DISTFILES = COPYING COPYING.LESSER Makefile README config.guess \
# examples/*.pure examples/*.glade $(modules) $(c-modules)
DISTFILES = Makefile README config.guess \
examples/*.pure $(modules) $(c-modules)

.PHONY: all clean realclean generate examples install uninstall dist distcheck

all: $(dlls)

clean:
	rm -f *$(DLL) *~ *.a *.o $(examples)

realclean: clean
	rm -f $(modules) $(c-modules)

generate:
	rm -f $(dlls) *.o $(modules) $(c-modules)
	$(MAKE) all

# Compile the examples.

examples: $(examples)

examples/%: examples/%.pure
	pure $(PURE_COPTS) -c $< -o $@

# Install targets.

install:
	test -d "$(DESTDIR)$(libdir)/pure" || mkdir -p "$(DESTDIR)$(libdir)/pure"
	cp $(modules) $(dlls) "$(DESTDIR)$(libdir)/pure"

uninstall:
	rm -f $(addprefix "$(DESTDIR)$(libdir)/pure/", $(modules) $(dlls))

# Roll a distribution tarball.

dist:
	rm -rf $(dist)
	mkdir $(dist) && mkdir $(dist)/examples
	for x in $(DISTFILES); do ln -sf $$PWD/$$x $(dist)/$$x; done
	rm -f $(dist).tar.gz
	tar cfzh $(dist).tar.gz $(dist)
	rm -rf $(dist)

distcheck: dist
	tar xfz $(dist).tar.gz
	cd $(dist) && make && make install DESTDIR=./BUILD
	rm -rf $(dist)

#############################################################################
# Generator stuff. You only need this if you want to regenerate the wrappers.
# You need pure-gen and the GTK headers to do this.
#############################################################################

# Path to the installed GTK, Glib, Cairo and Pango headers. The headers are
# assumed to live in the gtk-2.0, glib-2.0 etc. subdirectories under this
# directory. If your system uses a different layout then you can also adjust
# the individual include directories below.

# NOTE: The paths need to be valid at generation time only. The generated C
# source uses relative paths which should work on most systems which have GTK+
# installed.

includedir = /usr/include

gtksvdir = $(includedir)/gtksourceview-2.0

# PURE_GEN = /PATH/TO/pure-gen
PURE_GEN = pure-gen

# gtksv

GTKSV_CFLAGS = $(shell pkg-config --cflags gtksourceview-2.0)
GTKSV_INCLUDES = $(shell pkg-config --cflags-only-I gtksourceview-2.0)
GTKSV_LIBS = $(shell pkg-config --libs gtksourceview-2.0)

gtksv$(DLL): gtksv.c
	$(CC) $(shared) $(FLAGS) $(GTKSV_CFLAGS) -o $@ $< $(GTKSV_LIBS)

gtksviter$(DLL): gtksviter.c
	$(CC) $(shared) $(FLAGS) $(GTKSV_CFLAGS) -o $@ $< $(GTKSV_LIBS)

gtksvlangmgr$(DLL): gtksvlangmgr.c
	$(CC) $(shared) $(FLAGS) $(GTKSV_CFLAGS) -o $@ $< $(GTKSV_LIBS)

gtksvmark$(DLL): gtksvmark.c
	$(CC) $(shared) $(FLAGS) $(GTKSV_CFLAGS) -o $@ $< $(GTKSV_LIBS)

gtksvprintcompositor$(DLL): gtksvprintcompositor.c
	$(CC) $(shared) $(FLAGS) $(GTKSV_CFLAGS) -o $@ $< $(GTKSV_LIBS)

gtksvstyleschememgr$(DLL): gtksvstyleschememgr.c
	$(CC) $(shared) $(FLAGS) $(GTKSV_CFLAGS) -o $@ $< $(GTKSV_LIBS)

gtksv.pure gtksv.c:
	$(PURE_GEN) $(PGFLAGS) $(GTKSV_INCLUDES) -s '$(gtksvdir)/gtksourceview/*.h;' -p gtk -m gtksv -o gtksv.pure -c gtksv.c -fc $(gtksvdir)/gtksourceview/gtksourceview.h
	sed -e 's|#include \"$(gtksvdir)/\(\([A-Za-z-]\+/\)\?[A-Za-z-]\+\.h\)\"|#include <\1>|g' < gtksv.c > gtksv.c.new && rm gtksv.c && mv gtksv.c.new gtksv.c

gtksviter.pure gtksviter.c:
	$(PURE_GEN) $(PGFLAGS) $(GTKSV_INCLUDES) -s '$(gtksvdir)/gtksourceview/*.h;' -p gtk -m gtksv -o gtksviter.pure -c gtksviter.c -fc $(gtksvdir)/gtksourceview/gtksourceiter.h
	sed -e 's|#include \"$(gtksvdir)/\(\([A-Za-z-]\+/\)\?[A-Za-z-]\+\.h\)\"|#include <\1>|g' < gtksviter.c > gtksviter.c.new && rm gtksviter.c && mv gtksviter.c.new gtksviter.c

gtksvlangmgr.pure gtksvlangmgr.c:
	$(PURE_GEN) $(PGFLAGS) $(GTKSV_INCLUDES) -s '$(gtksvdir)/gtksourceview/*.h;' -p gtk -m gtksv -o gtksvlangmgr.pure -c gtksvlangmgr.c -fc $(gtksvdir)/gtksourceview/gtksourcelanguagemanager.h
	sed -e 's|#include \"$(gtksvdir)/\(\([A-Za-z-]\+/\)\?[A-Za-z-]\+\.h\)\"|#include <\1>|g' < gtksvlangmgr.c > gtksvlangmgr.c.new && rm gtksvlangmgr.c && mv gtksvlangmgr.c.new gtksvlangmgr.c

gtksvmark.pure gtksvmark.c:
	$(PURE_GEN) $(PGFLAGS) $(GTKSV_INCLUDES) -s '$(gtksvdir)/gtksourceview/*.h;' -p gtk -m gtksv -o gtksvmark.pure -c gtksvmark.c -fc $(gtksvdir)/gtksourceview/gtksourcemark.h
	sed -e 's|#include \"$(gtksvdir)/\(\([A-Za-z-]\+/\)\?[A-Za-z-]\+\.h\)\"|#include <\1>|g' < gtksvmark.c > gtksvmark.c.new && rm gtksvmark.c && mv gtksvmark.c.new gtksvmark.c

gtksvprintcompositor.pure gtksvprintcompositor.c:
	$(PURE_GEN) $(PGFLAGS) $(GTKSV_INCLUDES) -s '$(gtksvdir)/gtksourceview/*.h;' -p gtk -m gtksv -o gtksvprintcompositor.pure -c gtksvprintcompositor.c -fc $(gtksvdir)/gtksourceview/gtksourceprintcompositor.h
	sed -e 's|#include \"$(gtksvdir)/\(\([A-Za-z-]\+/\)\?[A-Za-z-]\+\.h\)\"|#include <\1>|g' < gtksvprintcompositor.c > gtksvprintcompositor.c.new && rm gtksvprintcompositor.c && mv gtksvprintcompositor.c.new gtksvprintcompositor.c

gtksvstyleschememgr.pure gtksvstyleschememgr.c:
	$(PURE_GEN) $(PGFLAGS) $(GTKSV_INCLUDES) -s '$(gtksvdir)/gtksourceview/*.h;' -p gtk -m gtksv -o gtksvstyleschememgr.pure -c gtksvstyleschememgr.c -fc $(gtksvdir)/gtksourceview/gtksourcestyleschememanager.h
	sed -e 's|#include \"$(gtksvdir)/\(\([A-Za-z-]\+/\)\?[A-Za-z-]\+\.h\)\"|#include <\1>|g' < gtksvstyleschememgr.c > gtksvstyleschememgr.c.new && rm gtksvstyleschememgr.c && mv gtksvstyleschememgr.c.new gtksvstyleschememgr.c

# eof
