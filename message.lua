conf = dofile("httpserver-conf.lc")
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
broker="test.mosquitto.org"
port = 1883

local function init()
-- init mqtt client with keepalive timer 120sec
    m = mqtt.Client(clientid, 120, user, pwd)
-- setup Last Will and Testament (optional)
-- Broker will publish a message with qos = 0, retain = 0, data = "offline"
-- to topic "/lwt" if client don't send keepalive packet
    m:on("connect", function(conn) print ("reconnected to broker") end)
    m:on("offline", function(conn) print ("gone offline") end)
    m:lwt("/lwt", clientid.." died", 0, 0)
end

local function msgSend(topic, message)
-- publish a message with data = hello, QoS = 0, retain = 0
    m:publish(topic,msg, 0, 0, function(conn) print("data sent") end)
end

local function msgRecv(client)
-- on publish message receive event
    client:on("message", function(conn, topic, data)
        print(topic .. ":" )
        if data ~= nil then
            print(data)
        end
    end)
end

--init()
-- for secure: m:connect("192.168.11.118", 1880, 1)
m = mqtt.Client(clientid, 120, user, pwd)
m:connect(broker, port, secure, function(conn) print("connected to "..broker) end)
msgSend("/test","test message")
-- subscribe topic with qos = 0
-- m:subscribe("/topic",0, function(conn) print("subscribe success") end)
m:close()
-- you can call m:connect again

--print(cjson.encode({key="value"}))
