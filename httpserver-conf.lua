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
conf.misc = misc

return conf
