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
secure = conf.mqtt.secure
if conf.mqtt.secure then
    secure = 1
else
    secure = 0
end

local function checkTopic(topic)
    local t=""
    if topic == "" or topic == nil then
        t = conf.mqtt.topic
    else
        t = topic
    end
    return(t)
end

local function msgSend(m, topic, msg)
    t = checkTopic(topic)
    m:publish(t, msg, 0, 0, function(m)
        if conf.misc.debug then
            print("mqtt data sent")
        else
            print("*")
        end
    end)
end

local function msgSendJson(m, topic, tab)
	local a,b, val
	for a,b in pairs(tab)
	do
        val = string.format("%.3f",b)
		msg = cjson.encode({a=b})
	end
    t = checkTopic(topic)
    m:publish(t, msg, 0, 0, function(m)
        if conf.misc.debug then
			print("mqtt data sent")
        else
            print("+")
        end
    end)
end

-- received message, do something with it (control gpio or whatever)
local function msgRecv(topic, data)
    print(topic..":"..data)
end

local function stop(m)
    m:on("offline", function(m) print("quitting now") end)
    m:close()
end

local function setup()
    if conf.misc.debug then print("setup start") end
    m = mqtt.Client(clientid, 120, user, pwd)
    m:lwt("/lwt", clientid.." died", 0, 0)

    m:on("offline", function(m)
        print ("reconnecting to "..broker)
        tmr.wdclr()
        tmr.alarm(3, 5000, 0, function()
            m:connect(broker, port, secure, function() tmr.stop(3) end )
        end)
    end)
-- handle received message    
    if rtopic == "" or rtopic == nil then
        rtopic = conf.mqtt.rtopic
    end
    m:on("message", function(m, rtopic, data)
        if data ~= nil then
            msgRecv(rtopic, data)
        end
    end)
-- connect to broker and subscribe
    tmr.alarm(2, 1000, 1, function()
        if wifi.sta.status() == 5 then
            tmr.stop(2)
            tmr.wdclr()
            m:connect(broker, port, 0, function(m)
                print("connected")
                t = checkTopic(topic)
                m:subscribe(t,0, function(m)
                    msgSend(m,t, "init by "..clientid)
                end)
            end)
        end
    end)
    if conf.misc.debug then print("setup end") end
    return(m)
end

-- Return module table
  -- expose
  M = {
    setup = setup,
    stop = stop,
    msgSend = msgSend,
    msgSendJson = msgSendJson
  }
return M
