BUILD_CONFIG ?= relwithdebinfo
ifeq ($(BUILD_CONFIG), relwithdebinfo)
	BUILD_CONFIG_NAME := relwithdebinfo
	CPPFLAGS = -g -O2 -fno-omit-frame-pointer -DNDEBUG -D_NDEBUG
	CFLAGS = -g -O2  -Wall -Werror -Wno-unused -DNDEBUG -D_NDEBUG
else
	BUILD_CONFIG_NAME := debug
	CPPFLAGS = -g -O0 -DDEBUG -D_DEBUG
	CFLAGS = -g -O0  -Wall -Werror -Wno-unused -DNDEBUG -D_NDEBUG
endif
###############################################################################
# system info

ifeq ($(ROOT_PATH), )
	ROOT_PATH = $(shell pwd)
endif

PWD_PATH = $(shell pwd)
THIRDPARTY_PATH = $(shell $(if $(wildcard $(PWD_PATH)/thirdparty),find ./thirdparty -maxdepth 1 -type d ! -path "./thirdparty",))
THIRDPARTY_NAME = $(shell $(if $(wildcard $(PWD_PATH)/thirdparty),ls ./thirdparty | awk '{print $0}',))
###############################################################################

define call_thirdparty_link
	$(if $(wildcard $(1)/Makefile),LIBS += -l$(1),)
endef

define call_thirdparty_make
	$(warning ROOT_PATH=$(ROOT_PATH))
	$(if $(wildcard $(1)/Makefile),@cd $(1) && make ROOT_PATH=$(ROOT_PATH) && cd ../../,)
endef

define call_thirdparty_include
	INC_DIR += -I$(1) -I$(1)/src -I$(1)/test -I$(1)/include
endef
###############################################################################
#CC = distcc /usr/bin/g++  do not define CC and CXX in Makefile,defined in /etc/profile
SRC_DIR := $(shell find . -type d ! -path "./thirdparty" ! -path "./thirdparty/*" ! -path "./bin" ! -path "./bin/*" ! -path "./build" ! -path "./build/*" ! -path "./.git" ! -path "./.git/*")
INC_DIR := $(addprefix -I,$(SRC_DIR))
SRC_DIR += 
INC_DIR += 
$(foreach thirddir, $(THIRDPARTY_PATH), $(eval $(call call_thirdparty_include,$(PWD_PATH)/$(thirddir))))

LIB_DIR = -L$(ROOT_PATH)/bin/$(BUILD_CONFIG_NAME)
LIBS += -Wl,--rpath=./ -Wl,-rpath-link=./lib/$(BUILD_CONFIG_NAME) -Wl,-Bdynamic -lpthread -ldl -lrt
$(foreach thirdname, $(THIRDPARTY_NAME), $(eval $(call call_thirdparty_link,$(thirdname))))

DEST_DIR = $(ROOT_PATH)/bin/$(BUILD_CONFIG_NAME)

DEST_NAME = dmmakefiletest

OUTPUT = $(ROOT_PATH)/build/$(BUILD_CONFIG_NAME)/dmmakefiletest

DEST = $(DEST_DIR)/$(DEST_NAME)

SRCS = $(shell find $(SRC_DIR) -maxdepth 10 -name "*.cpp" ! -path "./thirdparty" ! -path "./thirdparty/*" ! -path "./bin" ! -path "./bin/*" ! -path "./build" ! -path "./build/*" ! -path "./.git" ! -path "./.git/*")
OBJS = $(patsubst %.cpp, $(OUTPUT)/%.o, $(SRCS))
DEPS = $(patsubst %.o, %.d, $(OBJS))

SRCS2 = $(shell find $(SRC_DIR) -maxdepth 10 -name "*.c" ! -path "./thirdparty" ! -path "./thirdparty/*" ! -path "./bin" ! -path "./bin/*" ! -path "./build" ! -path "./build/*" ! -path "./.git" ! -path "./.git/*")
OBJS2 = $(patsubst %.c, $(OUTPUT)/%.o, $(SRCS2))
DEPS2 = $(patsubst %.o, %.d, $(OBJS2))

SRCS3 = $(shell find $(SRC_DIR) -maxdepth 10 -name "*.cc" ! -path "./thirdparty" ! -path "./thirdparty/*" ! -path "./bin" ! -path "./bin/*" ! -path "./build" ! -path "./build/*" ! -path "./.git" ! -path "./.git/*")
OBJS3 = $(patsubst %.cc, $(OUTPUT)/%.o, $(SRCS3))
DEPS3 = $(patsubst %.o, %.d, $(OBJS3))

$(foreach dir, $(SRC_DIR), $(eval OBJ_DIR += $(OUTPUT)/$(dir)))
#$(shell touch Makefile)

CPPFLAGS += -Wall -fcheck-new -fexceptions -fnon-call-exceptions -std=c++17 -Wno-unknown-pragmas -fpermissive -fPIC
LDFLAGS = $(LIB_DIR) $(LIBS)

$(shell rm -f $(DEST))
$(shell mkdir -p ${DEST_DIR})
$(shell mkdir -p ${OUTPUT})

all: $(DEST)
$(shell mkdir -p $(sort $(OBJ_DIR)))
-include $(DEPS) $(DEPS2) $(DEPS3)

$(DEST): $(OBJS) $(OBJS2) $(OBJS3)
	$(foreach thirddir, $(THIRDPARTY_PATH), $(call call_thirdparty_make,$(PWD_PATH)/$(thirddir)))
	@echo "LIBS: $(LIBS)"
	@echo "THIRDPARTY_PATH: $(THIRDPARTY_PATH)"
	@echo "THIRDPARTY_NAME: $(THIRDPARTY_NAME)"
	@echo "[0;32;1mINC_DIR: $(INC_DIR)[0;33;1m"
	@echo
	@echo "[0;32;1m$(CXX) -o $@ $^ $(LDFLAGS)[0;33;1m"
	@$(CXX)  -o $@ $^ $(LDFLAGS)
	@echo
	@echo "[0;31;1m--- make ok !!! $(DEST) ---[0;33;1m"

$(OUTPUT)/%.o: %.cpp
	@echo "[0;32;1m$(CXX) $(CPPFLAGS) -c $< -o $@[0;33;1m"
	@$(CXX) -o $@ -c $< $(CPPFLAGS) $(INC_DIR)

$(OUTPUT)/%.d: %.cpp
	@set -e; rm -f $@; \
	$(CXX) -MM $(CPPFLAGS) $(INC_DIR) $< > $@.$$$$; \
	sed 's,.*\.o[ :]*,$(patsubst %.d,%.o,$@) $@ : ,g' < $@.$$$$ > $@; \
	rm -f $@.$$$$

$(OUTPUT)/%.o: %.c
	@echo "[0;32;1m$(CXX) $(CPPFLAGS) -c $< -o $@[0;33;1m"
	@$(CXX) -o $@ -c $< $(CPPFLAGS) $(INC_DIR)

$(OUTPUT)/%.d: %.c
	@set -e; rm -f $@; \
	$(CXX) -MM $(CPPFLAGS) $(INC_DIR) $< > $@.$$$$; \
	sed 's,.*\.o[ :]*,$(patsubst %.d,%.o,$@) $@ : ,g' < $@.$$$$ > $@; \
	rm -f $@.$$$$
	
$(OUTPUT)/%.o: %.cc
	@echo "[0;32;1m$(CXX) $(CPPFLAGS) -c $< -o $@[0;33;1m"
	@$(CXX) -o $@ -c $< $(CPPFLAGS) $(INC_DIR)

$(OUTPUT)/%.d: %.cc
	@set -e; rm -f $@; \
	$(CXX) -MM $(CPPFLAGS) $(INC_DIR) $< > $@.$$$$; \
	sed 's,.*\.o[ :]*,$(patsubst %.d,%.o,$@) $@ : ,g' < $@.$$$$ > $@; \
	rm -f $@.$$$$

#$(shell echo $$(svn info | grep -E 'Revision:|版本:' | awk 'NR==1{ print $$NF}') > $(DEST_DIR)/version.txt)
#$(shell echo $$(svn info | grep -E 'Last Changed Rev:|最后修改的版本:' | awk 'NR==1{ print $$NF}') > $(DEST_DIR)/update.info)

clean:
	@echo
	@echo "[0;32;1mrm -rf $(OUTPUT) $(DEST)[0;33;1m"
	@-rm -rf $(OUTPUT) $(DEST)
	@echo "[0;31;1m--- clean $(DEST) ---[0;33;1m"
