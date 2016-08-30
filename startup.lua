-- start configuration
local conf = require("config")
local wifiConfig = {}
wifiConfig.mode = wifi.STATION
wifiConfig.stationPointConfig = {}

wifi.setmode(wifiConfig.mode)
wifi.sta.config(conf.wlan.ssid, conf.wlan.pwd)
wifiConfig = nil
collectgarbage()

-- print message to console and display, if enabled
function printout(msg, out)
    print(msg)
    if conf.display.use then
	if package.loaded["display2"] == nil then
	    display = require("display2")
	end
	if out == 2 then -- stderr like, status display
	    display.disp_stat(msg)
	elseif out == 1 then -- stdout like, data display
	    display.disp_data(msg)
	else
	    return
	end
	package.loaded["display2"] = nil
	display = nil
	collectgarbage()
    end
end

--set display parameters and initialize if display is in use
if conf.display.use then
    disp = require("display_drv")
print("3")
    if disp.setup() == nil then -- display setup failed
        print("Display setup failed")
        disp = nil
        package.loaded["display_drv"] = nil
        package.loaded["display2"] = nil
        conf.display.use = false
        collectgarbage()
    else -- display initialization ok
	display = require("display2")
    end
end
print("6")
-- clear screen
if conf.display.use then
print("7")
    display.cls(disp)
    display.disp_stat(disp, "Booting...")
end

-- connect to wifi ap
local joinCounter = 0
local joinMaxAttempts = 20
tmr.alarm(1, 5000, tmr.ALARM_AUTO, function()
    local ip = wifi.sta.getip()
    if ip == nil and joinCounter < joinMaxAttempts then
	    printout("Connecting to WiFi Access Point...", 2)
	    joinCounter = joinCounter +1
    else
	    if joinCounter == joinMaxAttempts then
	        printout("Failed to connect to WiFi Access Point", 2)
	    else
	        printout("Got IP: "..ip, 2)
	        print('heap: ', node.heap())
            --dofile("telnet.lc")
            --dofile("main3.lc")
            --dofile("button.lc")
	    end
	    tmr.stop(1)
	    tmr.unregister(1)
	    joinCounter = nil
	    joinMaxAttempts = nil
	    collectgarbage()
    end
end)
