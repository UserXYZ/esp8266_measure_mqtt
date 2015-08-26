mqtt_client = {}

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

-- debug test
broker="broker.mqttdashboard.com"
port = 1883
clientid="MYesp8266"
topic="/MYtest"

function mqtt_client.msgSend(m,topic, msg)
    m:publish(topic, msg, 0, 0, function(conn) print("data sent") end)
end

function mqtt_client.stop(m)
    m:on("offline", function(con) end)
    m:close()
end

function mqtt_client.setup()
    print("setup start")
    m = mqtt.Client(clientid, 120, user, pwd)
--      m:on("connect", function(conn) print ("reconnected to broker") end)
--      m:on("offline", function(conn) print ("gone offline") end)
    m:lwt("/lwt", clientid.." died", 0, 0)

    m:on("offline", function(con)
        print ("reconnecting to "..broker)
        tmr.wdclr()
        tmr.alarm(3, 5000, 0, function()
            m:connect(broker, port, secure, function() tmr.stop(3) end )
        end)
    end)

    m:on("message", function(conn, topic, data)
        if data ~= nil then
            print(topic..":"..data)
        end
    end)

    tmr.alarm(2, 1000, 1, function()
        if wifi.sta.status() == 5 then
            tmr.stop(2)
            tmr.wdclr()
            m:connect(broker, 1883, 0, function(conn)
                print("connected")
                m:subscribe(topic,0, function(conn)
                    mqtt_client.msgSend(m,topic, "test by "..clientid)
                end)
            end)
        end
    end)
    print("setup end")
    return(m)
end

return mqtt_client
--print(cjson.encode({key="value"}))