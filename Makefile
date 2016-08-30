######################################################################
# User configuration
######################################################################
# Path to nodemcu-uploader (https://github.com/kmpm/nodemcu-uploader)
NODEMCU-UPLOADER=../nodemcu-uploader/nodemcu-uploader.py
# Serial port
PORT=/dev/ttyUSB0
SPEED=115200

######################################################################
# End of user config
######################################################################
HTTP_FILES := $(wildcard http/*)
LUA_FILES := message3.lua myds3.lua myemoncms.lua myNtpTime.lua getDST.lua \
init.lua config.lua main3.lua dns.lua telnet.lua button.lua \
startup.lua display2.lua display_drv.lua

# Print usage
usage:
	@echo "make upload FILE:=<file>  to upload a specific file (i.e make upload FILE:=init.lua)"
	@echo "make upload_all           to upload all"
	@echo $(TEST)

# Upload one files only
upload:
	@$(NODEMCU-UPLOADER) -B $(SPEED) -b $(SPEED) -p $(PORT) upload $(FILE) --verify=raw

# Upload all
upload_all: $(LUA_FILES)
	@$(NODEMCU-UPLOADER) -B $(SPEED) -b $(SPEED) -p $(PORT) upload $(foreach f, $^, $(f)) --verify=raw
