#=================================================
# Makefile settings
#=================================================
-include dependency.mk # - do not abort if file does not exist

.PHONY: create_dir depend default all clean cscope qa# specify phony target, do not generate file as target name

.DEFAULT_GOAL=default # specify default target if there is no target specified

VPATH=include library bin unit_test # specify directory where to check target file update to date or not


#=================================================
# Compiler settings
#=================================================
CC        = gcc
CXX       = g++
FLEX      = flex 
FLEX_FLAG = 
BISON     = bison 
LINKER    = ${CXX}
CFLAGS    = -O2 -Wfatal-errors -Wall -std=gnu99 ${DEFINES} -fPIC
CXXFLAGS  = -O2 -Wfatal-errors -Wall -std=c++11 ${DEFINES} -fPIC
LIBS      = -lm -L/usr/lib/x86_64-linux-gnu -lfl -lreadline
INCLUDE   = -I./include
MOVE      = mv -f

#=================================================
# Build target
#=================================================
BIN_DIR          = bin
UNIT_TEST_DIR    = unit_test
LIBRARY_DIR      = library
CALCULATOR_OBJ   = cal.l.o main.o hash.o
LEX_YACC_TARGET  = cal.l.c cal.y.c
UNIT_TEST_OBJ    = 
SO_TARGET        =
CALCULATOR_TARGET= calculator
UNIT_TEST_TARGET = 

#=================================================
# Compile implicit rules
#=================================================
%.o:%.c
	$(CC) -c $< -o $@ $(CFLAGS) $(INCLUDE)
	@$(MOVE) $@ $(LIBRARY_DIR) # @ means do not echo command

%.e:%.c
	$(CC) -E $< -o $@ $(CFLAGS) $(INCLUDE)
	@$(MOVE) $@ $(LIBRARY_DIR)

%.o:%.cxx
	$(CXX) -c $< -o $@ $(CXXFLAGS) $(INCLUDE)
	@$(MOVE) $@ $(LIBRARY_DIR)

%.e:%.cxx
	$(CXX) -E $< -o $@ $(CXXFLAGS) $(INCLUDE)
	@$(MOVE) $@ $(LIBRARY_DIR)

%.l.c:%.l
	$(FLEX) $(FLEX_FLAG) -o $@ $< 

%.y.c:%.y
	$(BISON) -v -y -Wall -o $@ $<

%.lxx.c:%.lxx
	$(FLEX) $(FLEX_FLAG) --c++ -o $@ $< 

%.yxx.c:%.yxx
	$(BISON) -v -y -Wall -o $@ $<

#=================================================
# Target rules
#=================================================
default: $(CALCULATOR_TARGET) $(SO_TARGET) 

all: $(CALCULATOR_TARGET) $(SO_TARGET) $(UNIT_TEST_TARGET)

debug: set_debug_flag default

set_debug_flag:
	$(eval FLEX_FLAG += -d )
	$(eval CFLAGS += -g3 )

create_dir:
	@mkdir -p $(LIBRARY_DIR) $(BIN_DIR) $(UNIT_TEST_DIR)

$(CALCULATOR_TARGET): create_dir $(LEX_YACC_TARGET) $(CALCULATOR_OBJ)
	cd $(LIBRARY_DIR);\
	$(LINKER) -o $@ $(CALCULATOR_OBJ) $(LIBS);\
	$(MOVE) $@ ../$(BIN_DIR)

$(UNIT_TEST_TARGET): create_dir $(UNIT_TEST_OBJ)
	cd $(LIBRARY_DIR);\
	cd $(LIBRARY_DIR);\
	$(LINKER) -o $@ $(UNIT_TEST_OBJ) $(LIBS);\
	$(MOVE) $@ ../$(UNIT_TEST_DIR)

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
	cd $(UNIT_TEST_DIR);\
	echo "`../bin/$(CALCULATOR_TARGET) < input1`" > ../output;

