local modname = ...
local M = {}
_G[modname] = M

local tmr = tmr
local mqtt = mqtt
local wifi = wifi
--local print = print
-- Limited to local environment
setfenv(1,M)

local conf = require("config")
local secure = conf.mqtt.secure
if conf.mqtt.secure then
    secure = 1
else
    secure = 0
end

local function msgSend(m, topic, msg)
	local t=""
    if topic == "" or topic == nil then t = conf.mqtt.topic end
    m:publish(t, msg, 0, 0, function(m)
        if conf.misc.debug then
            print("mqtt data sent")
        else
            print("*")
        end
    end)
end
-- received message, do something with it (control gpio or whatever)
local function msgRecv(rtopic, data)
    print(rtopic..":"..data)
end

local function setup()
    if conf.misc.debug then print("setup start") end
    m = mqtt.Client(conf.mqtt.clientid, 120, conf.mqtt.user, conf.mqtt.password)
    m:lwt("/lwt", conf.mqtt.clientid.." died", 0, 0)
-- if we go offline
    m:on("offline", function(m)
        print ("reconnecting to "..conf.mqtt.broker..":"..conf.mqtt.port)
        tmr.wdclr()
        tmr.alarm(1, 5000, 1, function()
			if wifi.sta.status() == 5 then
				m:connect(conf.mqtt.broker, conf.mqtt.port, secure, function(m)	tmr.stop(1)	end)
			end
        end)
    end)
-- handle received message
	local rtopic=conf.mqtt.rtopic
    m:on("message", function(m, rtopic, data)
        if data ~= nil then
            msgRecv(rtopic, data)
        end
    end)
-- connect to broker and subscribe
    tmr.wdclr()
    tmr.alarm(1, 1000, 1, function()
        if wifi.sta.status() == 5 then
            tmr.stop(1)
            m:connect(conf.mqtt.broker, conf.mqtt.port, secure, function(m)
                print("connected to "..conf.mqtt.broker..":"..conf.mqtt.port)
                m:subscribe(conf.mqtt.rtopic, 0, function(m)
					msgSend(m, conf.mqtt.rtopic, conf.mqtt.clientid.." waiting for command")
                end)
            end)
        end
    end)
    if conf.misc.debug then print("setup end") end
    return(m)
end
-- Return module table
M = {
	setup = setup,
	msgSend = msgSend
}
return M
