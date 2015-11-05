-- prepare files
local compileAndRemoveIfNeeded = function(f)
   if file.open(f) then
      file.close()
      print('Compiling:', f)
      node.compile(f)
      file.remove(f)
      collectgarbage("collect")
   end
end
-- main()
--local serverFiles = {'message2.lua', 'myds3.lua', 'base64dec.lua', 'bmp085.lua', 'myNetTime.lua', 'myemoncms.lua', 'httpserver.lua', 'httpserver-basicauth.lua', 'httpserver-request.lua', 'httpserver-static.lua', 'httpserver-header.lua', 'httpserver-error.lua'}
local serverFiles = {'main.lua','message2.lua', 'myds3.lua', 'base64dec.lua', 'bmp085.lua', 'myNetTime.lua', 'myemoncms.lua'}
for i, f in ipairs(serverFiles) do
    compileAndRemoveIfNeeded(f)
end

compileAndRemoveIfNeeded = nil
serverFiles = nil
collectgarbage("collect")
-- start configuration
conf = require("config")
local wifiConfig = {}
wifiConfig.mode = wifi.STATION
wifiConfig.stationPointConfig = {}

wifi.setmode(wifiConfig.mode)
print('set (mode='..wifi.getmode()..')')
print('MAC: ',wifi.sta.getmac())
print('heap: ',node.heap())

wifi.sta.config(conf.wlan.ssid, conf.wlan.pwd)
wifiConfig = nil
collectgarbage("collect")

local joinCounter = 0
local joinMaxAttempts = 20
tmr.alarm(1, 5000, 1, function()
   local ip = wifi.sta.getip()
   if ip == nil and joinCounter < joinMaxAttempts then
      print('Connecting to WiFi Access Point ...')
      joinCounter = joinCounter +1
   else
      if joinCounter == joinMaxAttempts then
         print('Failed to connect to WiFi Access Point.')
      else
         print('Got IP: ',ip)
         -- Uncomment to automatically start the server in port 80
         --dofile("httpserver.lc")(8008)
      end
      tmr.stop(1)
      joinCounter = nil
      joinMaxAttempts = nil
      collectgarbage("collect")
   end
end)

dofile("main.lc")

collectgarbage("collect")
