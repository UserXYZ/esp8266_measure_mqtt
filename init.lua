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

local serverFiles = {'message2.lua', 'myds3.lua', 'httpserver.lua', 'httpserver-basicauth.lua', 'httpserver-conf.lua', 'base64dec.lua', 'httpserver-request.lua', 'httpserver-static.lua', 'httpserver-header.lua', 'httpserver-error.lua'}
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
         --dofile("httpserver.lc")(8008)
      end
      tmr.stop(1)
      joinCounter = nil
      joinMaxAttempts = nil
      collectgarbage()
   end
end)

-- start timer measuring and putting results into global table gtab
local function startTemp()
    local temp=require("myds3")
    gtab=nil
    gtab={}

    local delay=conf.misc.wait*1000
    if delay < 2000 or delay > 3600000 then
        print("Measuring timeout out of bounds, defaulting to 5s")
        delay=5000
    else
        print("Starting measurement every "..conf.misc.wait.." second(s)")
    end

    tmr.wdclr()
    tmr.alarm(6, delay,1,function()
        temp.readT(conf.misc.pin,function(r)
            for k,v in pairs(r) do
                gtab[k]=v
            end
        end)
    end)
end
-- start sending mqtt data
local function startMQTT()

    local f=require("message2")
    local val=""

    local mdelay=conf.mqtt.delay*1000
    if mdelay < 5000 or mdelay > 3600000 then
        print("MQTT delay out of bounds, defaulting to 10s")
        mdelay=10000
    else
        print("Starting sending MQTT data every "..conf.mqtt.delay.." second(s)")
    end
-- start sending with default topic for now
    local client=f.setup()
    tmr.wdclr()
    tmr.alarm(5,mdelay,1,function() for a,b in pairs(gtab) do
            val=string.format("%.3f",b)
            f.msgSend(client, conf.mqtt.topic, cjson.encode({temp=val}))
        end
    end)
end
-- main()
-- start or not
local abort = false
print("Do you want to cancel startup in 5 seconds? Y/N [N]")
uart.on("data", 1, function(data)
    if string.upper(data)=='Y' then
        uart.on("data")
        print("Cancelling startup...")
        abort = true
    elseif string.upper(data)=='N' then
        uart.on("data")
        print("OK, starting")
        abort = false
    else
        print("Wrong input, starting anyway")
        uart.on("data")
        abort = false
    end
end,0)

tmr.wdclr()
tmr.alarm(3,1000,1,function()
    if wifi.sta.status() == 5 then
        if abort == false then
            startTemp()
            tmr.delay(2000)
            startMQTT()
            print("Started...")
            tmr.stop(3)
        end
    end
end)
collectgarbage()
