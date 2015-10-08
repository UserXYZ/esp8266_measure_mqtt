-- retrieve the current time from Google
-- tested on NodeMCU 0.9.5 build 20150108
--[[
local moduleName = ... 
local M = {}
_G[moduleName] = M
]]--
local M

local function getTime(tz,host,cb)
    local time = {}
    local conn=net.createConnection(net.TCP, 0) 
    if tz < -12 or tz > 12 or not tz then return nil end
    
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
        local h=string.sub(gt,1,2)
        local m=string.sub(gt,4,5)
        local s=string.sub(gt,7,8)
        h=h+tz
        if (h+tz) > 23 then h=24-h+tz end
        if (h+tz)< 0 then h=24+h+tz end
--        time=h..":"..m..":"..s
        time={h,m,s}
        collectgarbage("collect")
        conn:close()
        cb(time)
    end)
    
    conn:connect(80,host)
end

M = {
        getTime = getTime
    }

return M
