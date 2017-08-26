function OnFrameTick(delegate)
    print(memory.readbyte(0x7E0010))
end


function OnGameLoaded(delegate)
    print(memory.readbyte(0x7E0010))
end
