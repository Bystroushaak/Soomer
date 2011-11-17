# Generic D project makefile by Bystroushaak (bystrousak@kitakitsune.org)
# Version: 1.0.0
# Date:    17.11.2011

.PHONY: all
.PHONY: modules
.PHONY: toolkit
.PHONY: run
.PHONY: clean
.PHONY: distclean
.PHONY: help

BIND    = bin
SRCD    = src
MODD    = modules

PROG    = $(BIND)/soomer

DC      = dmd
DFLAGS  = -I$(MODD)/ -I$(SRCD)/ -J$(SRCD)/ -c -O -debug
LDFLAGS =

# get source & object filenames
SRCS    = $(wildcard $(SRCD)/*.d)
OBJS    = $(SRCS:.d=.o)

all: modules $(OBJS)
	-mkdir $(BIND)
	@echo
	
	@echo "Linking together:"
	$(DC) $(LDFLAGS) $(SRCD)/*.o $(MODD)/*.o -of$(PROG)
	@echo
	
	@echo "Striping binaries:"
	-strip $(BIND)/*
	
	@echo "Successfully compiled"

modules:
	cd $(MODD); make download; make

run: all
	@clear
	@$(PROG)

%.o: %.d
	$(DC) $(DFLAGS) $? -of$@

clean:
	-rm *.o 
	-rm $(SRCD)/*.o
	
	cd $MODD; make clean
	-rm -fr $(BIND)
	
distclean: clean
	cd $(MODD); make distclean

help:
	@echo "all (default)"
	@echo "    Build project (needs 'git' and 'dmd' > v2.55)."
	@echo
	@echo run
	@echo "    Make and run binary."
	@echo
	@echo clean
	@echo "    Remove *.o and binary."
	@echo
	@echo distclean
	@echo "    Remove *.o, binaries and modules."
	@echo
	@echo help
	@echo "    Show this help."
