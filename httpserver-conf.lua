-- httpserver-conf.lua
-- Part of nodemcu-httpserver, contains static configuration for httpserver.
-- Author: Sam Dieck
local conf = {}

-- Basic Authentication Conf
local auth = {}
auth.enabled = true
-- auth.enabled = false
auth.realm = "NodeMCU http server"
-- displayed in the login dialog users get
auth.user = "admin"
auth.password = "admin"
conf.auth = auth

local wlan = {}
-- wifi config etc
wlan.ssid="Confuzed"
wlan.pwd="StaTeBriga123"
conf.wlan = wlan

local misc = {}
-- debugging
misc.debug = false
-- measuring rate in seconds, decimal value allowed
misc.wait = 5
-- pin on which the sensors are connected
misc.pin = 4
conf.misc = misc

local mqtt = {}
mqtt.clientid = "Confuzed_home"
mqtt.secure = true
mqtt.user = "guest"
mqtt.password = "guest"
--mqtt.broker = "broker.mqttdashboard.com"
mqtt.broker = "mqtt.thingstud.io"
mqtt.port = 9001
mqtt.topic = "/Confuzed/home"
mqtt.rtopic = "/Confuzed/home/todo"
mqtt.delay = 10
conf.mqtt = mqtt

return conf
