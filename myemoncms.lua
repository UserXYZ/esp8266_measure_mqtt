-- emoncms library - writes data to emoncms
local M

local conf = require("config")

local function send(data)
	local sk=net.createConnection(net.TCP, 0)
    local uri="GET "..conf.emon.path.."?node="..conf.emon.node.."&json="..data..
        "&apikey="..conf.emon.apikey..
        " HTTP/1.1\r\nHost: "..conf.emon.server..
        "\r\nUser-Agent: esp8266\r\nAccept: */*\r\n\r\n"

    if conf.misc.debug then print(uri) end
--print(uri)
print(node.heap())
	sk:on("receive", function(sk, c)
		print("Got "..c)
	end)
    sk:on("sent", function(sk)
        if conf.misc.debug then print("Sent data") end
        print("#")
        sk:close()
        sk=nil
        collectgarbage("collect")
    end)
    sk:on("connection", function(sk)
        if conf.misc.debug then print("Connected") end
        sk:send(uri)
    end )
	sk:connect(80,conf.emon.server)
end

-- export functions
M = { send = send }
return M
