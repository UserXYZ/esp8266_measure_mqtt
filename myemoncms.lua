-- emoncms library - writes data to emoncms
local M

conf = dofile("config.lua")

local function send(data)
	local sk=net.createConnection(net.TCP, 0)
    local uri="GET "..conf.emon.path.."?node="..conf.emon.node.."&json="..data..
		"&apikey="..conf.emon.apikey..
        " HTTP/1.1\r\nHost: "..conf.emon.server..
        "\r\nUser-Agent: esp8266\r\nAccept: */*\r\n\r\n"
print(uri)
	sk:on("receive", function(sk, c)
		print("Got "..c)
	end)
    sk:on("sent", function(sk)
        print("Sent data")
        sk:close()
    end)
    sk:on("connection", function(sk)
        print("Connected")
        sk:send(uri)
    end )
	sk:connect(80,conf.emon.server)
end

-- export functions
M = { send = send }
return M

--print(cjson.encode({time=tm, temp=t, pressure=p, alt=al}))
--	sk=net.createConnection(net.TCP, 0)
--    sk:on("receive", function(sck, c) print(c) end )
--    sk:connect(80,"192.168.0.66")
--    sk:send("GET / HTTP/1.1\r\nHost: 192.168.0.66\r\nConnection: keep-alive\r\nAccept: */*\r\n\r\n")
-- curl -s "http://andrea.eunet.rs/emoncms/input/post.json?node=1&json=\{temp:25.0\}&apikey=c4088d0e6554f34c3e0310cc2c227038"
