#=================================================
# Makefile settings
#=================================================
-include dependency.mk # - do not abort if file does not exist

.PHONY: create_dir depend default clean cscope qa# specify phony target, do not generate file as target name

.DEFAULT_GOAL=default # specify default target if there is no target specified

VPATH=include library bin unit_test # specify directory where to check target file update to date or not


#=================================================
# Compiler settings
#=================================================
CC        = gcc
FLEX      = flex 
FLEX_FLAG = 
DEFINES   =
YACC      = bison -Wall
YACC_FLAG = 
LINKER    = $(CC)
CFLAGS    = $(DEFINES) -O2 -Wfatal-errors -Wall -Wextra -std=gnu99 -fPIC
LIBS      = -lm -L/usr/lib/x86_64-linux-gnu -lfl -lreadline
INCLUDE   = -I./include
MOVE      = mv -f

#=================================================
# Build target
#=================================================
BIN_DIR          = bin
UNIT_TEST_DIR    = unit_test
LIBRARY_DIR      = library
LEX_YECC_TARGET  = ascii_to_spice3.l.c 
LEX_YECC_OBJ     = $(LEX_YECC_TARGET:.c=.o)
PARSER_OBJ       = main.o opts.o 
PARSER_TARGET    = raw_to_waveform

#=================================================
# Compile implicit rules
#=================================================
%.o:%.c
	$(CC) -c $< -o $@ $(CFLAGS) $(INCLUDE)
	@$(MOVE) $@ $(LIBRARY_DIR) # @ means do not echo command

%.e:%.c
	$(CC) -E $< -o $@ $(CFLAGS) $(INCLUDE)
	@$(MOVE) $@ $(LIBRARY_DIR)

%.l.c:%.l
	$(FLEX) $(FLEX_FLAG) -o $@ $< 

%.y.c:%.y
	$(YACC) $(YACC_FLAG) -v -y -Wall -o $@ $<

#=================================================
# Target rules
#=================================================
default: $(PARSER_TARGET) 

debug: set_debug_flag default

set_debug_flag:
	$(eval FLEX_FLAG += -d )
	$(eval CFLAGS += -g3 )

create_dir:
	@mkdir -p $(LIBRARY_DIR) $(BIN_DIR) 

$(LEX_YECC_OBJ): $(LEX_YECC_TARGET)

$(PARSER_TARGET): create_dir $(LEX_YECC_OBJ) $(PARSER_OBJ) 
	cd $(LIBRARY_DIR);\
	$(LINKER) -o $@ $(PARSER_OBJ) $(LEX_YECC_OBJ) $(LIBS);\
	$(MOVE) $@ ../$(BIN_DIR)

clean:
	rm -f dependency.mk
	rm -rf $(LIBRARY_DIR)/*

depend:
	rm -f dependency.mk
	for file in $(shell find . -name "*.c" -o -name "*.cxx" -o -name "*.h" -o -name "*.hxx"); do $(CC) -M $(INCLUDE) $$file >> dependency.mk; done

cscope:
	find . -name "*.c" -o -name "*.cxx" -o -name "*.h" -o -name "*.hxx" > cscope.files
	cscope -Rbq -i cscope.files

qa:

