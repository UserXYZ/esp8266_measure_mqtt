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

local serverFiles = {'myds2.lua', 'httpserver.lua', 'httpserver-basicauth.lua', 'httpserver-conf.lua', 'base64dec.lua', 'httpserver-request.lua', 'httpserver-static.lua', 'httpserver-header.lua', 'httpserver-error.lua'}
for i, f in ipairs(serverFiles) do compileAndRemoveIfNeeded(f) end

compileAndRemoveIfNeeded = nil
serverFiles = nil
collectgarbage()

-- start configuration
local conf = dofile("httpserver-conf.lc")
local wifiConfig = {}

wifiConfig.mode = wifi.STATION
wifiConfig.stationPointConfig = {}
wifiConfig.stationPointConfig.ssid = conf.wlan.ssid
wifiConfig.stationPointConfig.pwd =  conf.wlan.pwd

wifi.setmode(wifiConfig.mode)
print('set (mode='..wifi.getmode()..')')
print('MAC: ',wifi.sta.getmac())
print('chip: ',node.chipid())
print('heap: ',node.heap())

wifi.sta.config(wifiConfig.stationPointConfig.ssid, wifiConfig.stationPointConfig.pwd)
wifiConfig = nil
collectgarbage()

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
         print('IP: ',ip)
         -- Uncomment to automatically start the server in port 80
         dofile("httpserver.lc")(8008)
      end
      tmr.stop(1)
      joinCounter = nil
      joinMaxAttempts = nil
      collectgarbage()
   end
end)

local temp=require("myds2")
gtab=nil
gtab={}

local delay=conf.misc.wait*1000
if delay < 2000 or delay > 3600000 then
    print("Measuring timeout out of bounds, defaulting to 5s")
    delay=5000
else
    print("Starting measurement every "..conf.misc.wait.." seconds")
end
-- start timer measuring and putting results into global table gtab
tmr.wdclr()
tmr.alarm(6,delay,1,function()
    temp.readT(conf.misc.pin,function(r)
        for k,v in pairs(r) do
            gtab[k]=v
        end
    end)
    coroutine.yield()
end)
collectgarbage()

--[[
temp.readT(4,function(r) for k,v in pairs(r) do gtab[k]=v end end)

tmr.alarm(6,5000,1,function() 
    temp.readT(4,function(r)
        for a,b in pairs(gtab) do
            print(a,b)
        end
    end)
end)
collectgarbage()
tmr.wdclr()

for a,b in pairs(gtab) do
    print(a, string.format("%.3f",b))
end

]]--

