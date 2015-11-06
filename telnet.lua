function telnetSrv()
   sv=net.createServer(net.TCP, 180)
   sv:listen(2323, function(conn)
      function s_output(str)
         if (conn~=nil) then conn:send(str) end
      end
      print("Wifi console connected.")
      node.output(s_output,1)
      s_output("esp8266>");
      
      conn:on("receive", function(conn, pl) 
         node.input(pl) 
         if (conn==nil)    then 
            print("conn is nil.") 
         end
      end)
      conn:on("disconnection",function(conn) 
         node.output(nil) 
      end)
   end)
end

telnetSrv()
