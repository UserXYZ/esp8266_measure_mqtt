return function (connection, args)
    dofile("myds3.lua")
    connection:send("HTTP/1.0 200 OK\r\nContent-Type: text/html\r\nCache-Control: private, no-store\r\n\r\n")
    connection:send("<html><head><body><title>T</title></head><body>OK</body></html>\n")
--    coroutine.yield()
--    setup(4)
--    local tbl={}
--    tbl=readT(4)
--    print(#tbl)
--	readT(4,function(r) for k,v in pairs(r) do print(k,v) end end)
--    coroutine.yield()
end
