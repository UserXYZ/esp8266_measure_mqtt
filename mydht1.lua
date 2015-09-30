tmr.wdclr()
tmr.alarm(2,3000,1,function()
    pin = 4
    status,temp,humi,temp_decimal,humi_decimal = dht.read(pin)
    if( status == dht.OK ) then
        print("DHT Temperature:"..temp..";".."Humidity:"..humi)
    elseif( status == dht.ERROR_CHECKSUM ) then
        print( "DHT Checksum error." );
    elseif( status == dht.ERROR_TIMEOUT ) then
        print( "DHT Time out." );
    end
    print()
end)
tmr.stop(2)