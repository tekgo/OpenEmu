--gui.register(function()
--print(memory.readbyte(0x7E0010))
--end)

print("script loaded");

--print(AND(1, 5))
--print(OR(1, 5))
--print(XOR(2, 10))

local function callback()
    print("callback")
end

print(emu)

for k, v in pairs(emu) do
    print(k)
end

--emu.registerafter(callback)

