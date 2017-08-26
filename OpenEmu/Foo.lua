gui.register(function()
print(memory.readbyte(0x7E0010))
end)

print("script loaded");

local info = debug.getinfo(1,'S');
print(info.source);
