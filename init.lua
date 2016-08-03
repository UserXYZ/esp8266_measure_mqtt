-- prepare files
local compileAndRemoveIfNeeded = function(f)
    if file.open(f) then
	file.close()
	print('Compiling:', f)
	node.compile(f)
	file.remove(f)
	collectgarbage()
    end
end
-- main()
local serverFiles = {'dns.lua', 'telnet.lua','main3.lua','message3.lua', 'myds3.lua', 'myNtpTime.lua', 'getDST.lua', 'myemoncms.lua', 'button.lua', 'display.lua'}
for i, f in ipairs(serverFiles) do
    compileAndRemoveIfNeeded(f)
end

compileAndRemoveIfNeeded = nil
serverFiles = nil
collectgarbage()
-- start configuration
local conf = require("config")
local wifiConfig = {}
wifiConfig.mode = wifi.STATION
wifiConfig.stationPointConfig = {}

wifi.setmode(wifiConfig.mode)
wifi.sta.config(conf.wlan.ssid, conf.wlan.pwd)
wifiConfig = nil
collectgarbage()

if conf.misc.use_display then
    display = require("display")
    display.setup()
    display.cls()
    display.disp_stat("Booting...")
end

local joinCounter = 0
local joinMaxAttempts = 20
tmr.alarm(1, 5000, 1, function()
    local ip = wifi.sta.getip()
    if ip == nil and joinCounter < joinMaxAttempts then
	local msg="Connecting to WiFi Access Point..."
	print(msg)
	if conf.misc.use_display then
	    display.disp_stat(msg)
	end
	joinCounter = joinCounter +1
    else
	if joinCounter == joinMaxAttempts then
	    local msg="Failed to connect to WiFi Access Point"
	    print(msg)
	    if conf.misc.use_display then
		    display.disp_stat(msg)
	    end
	else
	    local msg="Got IP: "..ip
	    print(msg)
	    if conf.misc.use_display then
		    display.disp_stat(msg)
	    end
	    print('heap: ',node.heap())
         -- Uncomment to automatically start everything
            --dofile("telnet.lc")
	    dofile("main3.lc")
	    dofile("button.lc")
	end
	tmr.stop(1)
	joinCounter = nil
	joinMaxAttempts = nil
	collectgarbage()
    end
end)
