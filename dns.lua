local M = {}

local conf = require("config")

if conf.misc.use_display then
    display = require("display")
end

local function resolveIP(host,cb)
    local conn=net.createConnection(net.TCP, 0)
    conn:dns(tostring(host),function(conn,ip)
        if ip then
            cb(ip)
        else
    	    local msg="DNS query failed for "..host
            print(msg)
            if conf.misc.use_display then
        	    display.disp_stat(msg)
    	    end
            cb(nil)
        end
        conn:close()
        conn = nil
        collectgarbage()
    end)
end
-- export functions
M = { resolveIP = resolveIP }
return M
