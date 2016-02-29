local M = {}

function setup()
    local cs  = 8 -- GPIO15, pull-down 10k to GND
    local dc  = 1 -- GPIO5
    local res = 0 -- GPIO16
    spi.setup(1, spi.MASTER, spi.CPOL_LOW, spi.CPHA_LOW, 8, 8)
    disp = u8g.pcd8544_84x48_hw_spi(cs, dc, res)
--    disp:setFont(u8g.font_6x10)
--    disp:setFontRefHeightExtendedText()
--    disp:setFontPosTop()
    disp:setDefaultForegroundColor()
end

local function cls()
    disp:firstPage()
    repeat
    until disp:nextPage() == false
    tmr.delay(100000)
end

local function draw_lines(cols)

end

local function draw_string(text)

end

--[[
print("write text")
disp:firstPage()
repeat
    rows=math.ceil(disp:getHeight()/disp:getFontLineSpacing())
--    cols=math.ceil(disp:getWidth()/disp:getStrWidth("Hello"))
    local x=0
    local y=0
    for i=1,rows-1,1
    do
        disp:drawStr( x, y, "Hello!")
        x=x+10
        y=y+disp:getFontLineSpacing()
    end
until disp:nextPage() == false
tmr.delay(100000)
tmr.wdclr()
]]--

-- Return module table
M = {
    setup = setup,
    cls = cls,
    draw_lines = draw_lines,
    draw_string = draw_string
}
return M
