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
local serverFiles = {'dns.lua', 'telnet.lua','main3.lua','message3.lua', 'myds3.lua', 'myNtpTime.lua', 'getDST.lua', 'myemoncms.lua', 'button.lua', 'display.lua', 'ds1307.lua'}
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
--set display parameters and initialize if display is in use
if conf.display.use then
    display = require("display")
    if display.setup() == nil then -- display setup failed
        print("Display setup failed")
        display = nil
        package.loaded["display"] = nil
        conf.display.use = false
        collectgarbage()
    end
end
-- clear screen
if conf.display.use then
    display.cls()
    display.disp_stat("Booting...")
--    display = nil
--    package.loaded["display"] = nil
--    collectgarbage()
end
-- connect to wifi ap
local joinCounter = 0
local joinMaxAttempts = 20
tmr.alarm(1, 5000, tmr.ALARM_AUTO, function()
    local ip = wifi.sta.getip()
    if ip == nil and joinCounter < joinMaxAttempts then
	    local msg="Connecting to WiFi Access Point..."
	    print(msg)
	    if conf.display.use then
--            display = require("display")
	        display.disp_stat(msg)
--            display = nil
--            package.loaded["display"] = nil
--            collectgarbage()
	    end
	    joinCounter = joinCounter +1
    else
	    if joinCounter == joinMaxAttempts then
	        local msg="Failed to connect to WiFi Access Point"
	        print(msg)
	        if conf.display.use then
--                display = require("display")
		        display.disp_stat(msg)
--                display = nil
--                package.loaded["display"] = nil
--                collectgarbage()
	        end
	    else
	        local msg="Got IP: "..ip
	        print(msg)
	        if conf.display.use then
--                display = require("display")
		        display.disp_stat(msg)
--                display = nil
--                package.loaded["display"] = nil
--                collectgarbage()
	        end
	        print('heap: ',node.heap())
         -- Uncomment to automatically start everything
--[[
            tmr.alarm(2, 5000, tmr.ALARM_SINGLE, function()
                run = true
                print("Do you want to cancel the startup? Y/N")
                node.input(inp)
                if string.lower(inp) == "y" then
                    print ("Startup cancelled")
                    tmr.stop(2)
                    tmr.stop(1)
                    tmr.unregister(2)
                    tmr.unregister(1)
                end
                else
                    --dofile("telnet.lc")
                    --dofile("main3.lc")
                    --dofile("button.lc")
                    print("start")
            end)
]]--
            --dofile("telnet.lc")
            dofile("main3.lc")
            dofile("button.lc")            
	    end
	    tmr.stop(1)
        tmr.unregister(1)
	    joinCounter = nil
	    joinMaxAttempts = nil
	    collectgarbage()
    end
end)
