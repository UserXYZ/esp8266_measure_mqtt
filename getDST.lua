-- http://api.timezonedb.com/?zone=America/Toronto&format=json&key=0ZDSLL4QJS5I

local M = {}

local conf = require("config")

local function getDST(cb)
    local offset=nil
    local host="api.timezonedb.com"
    local q="/?zone="..conf.misc.zone.."&format=json&key="..conf.misc.timezonedb_key
    local conn=net.createConnection(net.TCP, 0)

    if not zone then cb(nil) end

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
        conn:close()
        conn=nil
        collectgarbage()
        cb(offset)
        end
    end)

    conn:dns(tostring(host),function(conn,ip)
        if ip then
            conn:connect(80,tostring(ip))
        else
            conn:close()
            conn=nil
            collectgarbage()
            print("DNS can't resolve DST server"..host)
            cb(nil)
        end
    end)
end

M = { getDST = getDST }
return M
