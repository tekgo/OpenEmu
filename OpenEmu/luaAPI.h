// luaAPI.h

#ifndef luaAPI_h
#define luaAPI_h

#import <LuaCocoa/lua.h>
#import <LuaCocoa/luaconf.h>
#import <LuaCocoa/lauxlib.h>
#import <LuaCocoa/lualib.h>
#import "LuaHelperHeaders.h"
#include <stdio.h>

enum LuaCallID
{
    LUACALL_BEFOREEMULATION,
    LUACALL_AFTEREMULATION,
    LUACALL_AFTEREMULATIONGUI,
    LUACALL_BEFOREEXIT,
    LUACALL_BEFORESAVE,
    LUACALL_AFTERLOAD,
    LUACALL_ONSTART,
    
    LUACALL_SCRIPT_HOTKEY_1,
    LUACALL_SCRIPT_HOTKEY_2,
    LUACALL_SCRIPT_HOTKEY_3,
    LUACALL_SCRIPT_HOTKEY_4,
    LUACALL_SCRIPT_HOTKEY_5,
    LUACALL_SCRIPT_HOTKEY_6,
    LUACALL_SCRIPT_HOTKEY_7,
    LUACALL_SCRIPT_HOTKEY_8,
    LUACALL_SCRIPT_HOTKEY_9,
    LUACALL_SCRIPT_HOTKEY_10,
    LUACALL_SCRIPT_HOTKEY_11,
    LUACALL_SCRIPT_HOTKEY_12,
    LUACALL_SCRIPT_HOTKEY_13,
    LUACALL_SCRIPT_HOTKEY_14,
    LUACALL_SCRIPT_HOTKEY_15,
    LUACALL_SCRIPT_HOTKEY_16,
    
    LUACALL_COUNT
};

void CallRegisteredLuaFunctions(enum LuaCallID calltype, lua_State* L);
void RegisterLuaFuncs(lua_State* L);

/// Scripting API

extern const void * script_getBytes(UInt32 address, UInt32 length);
extern void script_setBytes(const void * bytes, UInt32 address, UInt32 length);
extern void script_setPixel(UInt32 color, int x, int y);
extern void script_drawBox(int x1, int y1, int x2, int y2, UInt32 fill, UInt32 outline);
extern void script_drawText(const char *msg, int x, int y);
extern int script_print(const char * __restrict format, ...);

#endif /* luaAPI_h */
