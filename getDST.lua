-- http://api.timezonedb.com/?zone=America/Toronto&format=json&key=0ZDSLL4QJS5I

local M = {}

local conf = require("config")

if conf.misc.use_display then
    display = require("display")
end

local function getDST(cb)
    if conf.misc.zone == "" then cb("No defined time zone in your config file!") end

    local offset=nil
    local host="api.timezonedb.com"
    local q="/?zone="..conf.misc.zone.."&format=json&key="..conf.misc.timezonedb_key
    local conn=net.createConnection(net.TCP, 0)

    conn:on("connection",function(conn, payload)
	    conn:send("GET "..q.." HTTP/1.1\r\n"..
                      "Host: "..host.."\r\n"..
                      "Accept: */*\r\n"..
                      "User-Agent: Mozilla/4.0 (compatible; esp8266 Lua;)"..
                      "\r\n\r\n")
    end)

    conn:on("receive", function(conn, payload)
-- parse response
        if payload then
--print("payload="..payload)
            local i,j=string.find(payload,"{.*}")
            if i and j then
                local l=string.sub(payload,i,j)
                local t=cjson.decode(l)
                if t["status"] == "OK" then
                    offset=t["gmtOffset"]/3600
                end
            end
        end
        conn:close()
        conn=nil
        collectgarbage()
        cb(offset)
    end)

    conn:dns(tostring(host),function(conn,ip)
        if ip then
            conn:connect(80,tostring(ip))
        else
            conn:close()
            conn=nil
            collectgarbage()
            local msg="DNS can't resolve DST server"..host
            if conf.misc.use_display then
        	    display.disp_stat(msg)
    	    end
            cb(msg)
        end
    end)
end

M = { getDST = getDST }
return M
