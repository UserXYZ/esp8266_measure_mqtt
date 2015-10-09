--[[
local moduleName = ... 
local M = {}
_G[moduleName] = M
]]--
local M

local function getTime(tz,host,cb)
    local time = {}
    local ipaddr
    local conn=net.createConnection(net.TCP, 0)
        
    if tz < -12 or tz > 12 or not tz then cb(nil) end
    
    conn:on("connection",function(conn, payload)
            conn:send("HEAD / HTTP/1.1\r\n".. 
                      "Host: "..host.."\r\n"..
                      "Accept: */*\r\n"..
                      "User-Agent: Mozilla/4.0 (compatible; esp8266 Lua;)"..
                      "\r\n\r\n") 
    end)
    
    conn:on("receive", function(conn, payload)
        local gt=string.sub(payload,string.find(payload,"Date: ")+23,
            string.find(payload,"Date: ")+31)
        local h=string.sub(gt,1,2)+tz
        local m=string.sub(gt,4,5)
        local s=string.sub(gt,7,8)
        if h > 23 then h=24-h+tz end
        if h < 0 then h=24+h+tz end
--        time=h..":"..m..":"..s
        time={h,m,s}
        conn:close()
        conn=nil
        collectgarbage("collect")
        cb(time)
    end)

    conn:dns(tostring(host),function(conn,ip)
        if ip then
            ipaddr=tostring(ip)
            conn:connect(80,ipaddr)
        else
            conn:close()
            conn=nil
            collectgarbage("collect")
            print("DNS can't resolve "..host)
            cb(nil)
        end
    end)
end

M = { getTime = getTime }

return M
