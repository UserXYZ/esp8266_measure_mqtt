local modname = ...
local M = {}
_G[modname] = M

local tmr = tmr
local mqtt = mqtt
local wifi = wifi
local print = print
local dofile = dofile
-- Limited to local environment
setfenv(1,M)

local conf = dofile("httpserver-conf.lc")
clientid = conf.mqtt.clientid
user = conf.mqtt.user
pwd = conf.mqtt.password
broker = conf.mqtt.broker
port = conf.mqtt.port
topic = conf.mqtt.topic
secure = conf.mqtt.secure
if conf.mqtt.secure then
    secure = 1
else
    secure = 0
end

local function msgSend(m,topic, msg)
    m:publish(topic, msg, 0, 0, function(m) print("data sent") end)
end

local function stop(m)
    m:on("offline", function(m) end)
    m:close()
end

local function setup()
    print("setup start")
    m = mqtt.Client(clientid, 120, user, pwd)
    m:lwt("/lwt", clientid.." died", 0, 0)

    m:on("offline", function(m)
        print ("reconnecting to "..broker)
        tmr.wdclr()
        tmr.alarm(3, 5000, 0, function()
            m:connect(broker, port, secure, function() tmr.stop(3) end )
        end)
    end)

    m:on("message", function(m, topic, data)
        if data ~= nil then
            print(topic..":"..data)
        end
    end)

    tmr.alarm(2, 1000, 1, function()
        if wifi.sta.status() == 5 then
            tmr.stop(2)
            tmr.wdclr()
            m:connect(broker, 1883, 0, function(m)
                print("connected")
                m:subscribe(topic,0, function(m)
                    msgSend(m,topic, "init by "..clientid)
                end)
            end)
        end
    end)
    print("setup end")
    return(m)
end

-- Return module table
  -- expose
  M = {
    setup = setup,
    stop = stop,
    msgSend = msgSend,
  }
return M
--print(cjson.encode({key="value"}))
