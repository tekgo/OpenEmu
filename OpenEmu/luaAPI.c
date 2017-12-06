// luaAPI.c

#include "luaAPI.h"

static const char* luaCallIDStrings [] =
{
    "CALL_BEFOREEMULATION",
    "CALL_AFTEREMULATION",
    "CALL_AFTEREMULATIONGUI",
    "CALL_BEFOREEXIT",
    "CALL_BEFORESAVE",
    "CALL_AFTERLOAD",
    "CALL_ONSTART",
    
    "CALL_HOTKEY_1",
    "CALL_HOTKEY_2",
    "CALL_HOTKEY_3",
    "CALL_HOTKEY_4",
    "CALL_HOTKEY_5",
    "CALL_HOTKEY_6",
    "CALL_HOTKEY_7",
    "CALL_HOTKEY_8",
    "CALL_HOTKEY_9",
    "CALL_HOTKEY_10",
    "CALL_HOTKEY_11",
    "CALL_HOTKEY_12",
    "CALL_HOTKEY_13",
    "CALL_HOTKEY_14",
    "CALL_HOTKEY_15",
    "CALL_HOTKEY_16",
};

static int emu_emulating(lua_State *L) {
    lua_pushboolean(L, 1);
    return 1;
}

static int emu_registerexit(lua_State *L) {
    if (!lua_isnil(L,1))
        luaL_checktype(L, 1, LUA_TFUNCTION);
    lua_settop(L,1);
    lua_getfield(L, LUA_REGISTRYINDEX, luaCallIDStrings[LUACALL_BEFOREEXIT]);
    lua_insert(L,1);
    lua_setfield(L, LUA_REGISTRYINDEX, luaCallIDStrings[LUACALL_BEFOREEXIT]);
    //    StopScriptIfFinished(luaStateToUIDMap[L]);
    return 1;
}

static int emu_registerafter(lua_State *L) {
    if (!lua_isnil(L,1))
        luaL_checktype(L, 1, LUA_TFUNCTION);
    lua_settop(L,1);
    lua_getfield(L, LUA_REGISTRYINDEX, luaCallIDStrings[LUACALL_AFTEREMULATION]);
    lua_insert(L,1);
    lua_setfield(L, LUA_REGISTRYINDEX, luaCallIDStrings[LUACALL_AFTEREMULATION]);
    //    StopScriptIfFinished(luaStateToUIDMap[L]);
    return 1;
}

static int gui_register(lua_State *L) {
    if (!lua_isnil(L,1))
        luaL_checktype(L, 1, LUA_TFUNCTION);
    lua_settop(L,1);
    lua_getfield(L, LUA_REGISTRYINDEX, luaCallIDStrings[LUACALL_AFTEREMULATIONGUI]);
    lua_insert(L,1);
    lua_setfield(L, LUA_REGISTRYINDEX, luaCallIDStrings[LUACALL_AFTEREMULATIONGUI]);
    //    StopScriptIfFinished(luaStateToUIDMap[L]);
    return 1;
}

static int gui_text(lua_State *L) {
    extern int font_height;
    const char *msg;
    int x, y;
    
    x = (int)lua_tointeger(L,1);
    y = (int)lua_tointeger(L,2);
    msg = lua_tostring(L,3);
    
    script_drawText(msg, x, y);
    
    return 1;
}

static int gui_box(lua_State *L) {
    
    int x1 = (int)luaL_checkinteger(L,1); // have to check for errors before deferring
    int y1 = (int)luaL_checkinteger(L,2);
    int x2 = (int)luaL_checkinteger(L,3);
    int y2 = (int)luaL_checkinteger(L,4);
    
    //TODO: Get the color
    
    script_drawBox(x1, y1, x2, y2, 0xffffffff, 0xffffffff);
    
    return 0;
}

static int memory_readbyte(lua_State *L) {
    UInt32 address = (UInt32)lua_tointeger(L,1);
    
    UInt8 value = 0;
    
    const void * dataPtr = script_getBytes(address, 1);
    if (dataPtr != nil) {
        const UInt8 * n = dataPtr;
        value = n[0];
    }
    
    lua_settop(L,0);
    lua_pushinteger(L, value);
    
    return 1;
}

static int memory_readword(lua_State *L) {
    UInt32 address = (UInt32)lua_tointeger(L,1);
    
    UInt16 value = 0;
    
    const void * dataPtr = script_getBytes(address, 2);
    if (dataPtr != nil) {
        const UInt8 * n = dataPtr;
        value = n[0];
        value |= (n[1] << 8);
    }
    
    lua_settop(L,0);
    lua_pushinteger(L, value);
    return 1;
}

static int memory_writebyte(lua_State *L) {
    UInt32 address = (UInt32)lua_tointeger(L,1);
    UInt8 value = (UInt8)(lua_tointeger(L,2) & 0xFF);
    
    script_setBytes(&value, address, sizeof(value));
    return 0;
}

static int memory_writeword(lua_State *L) {
    UInt32 address = (UInt32)lua_tointeger(L,1);
    UInt16 value = (UInt8)(lua_tointeger(L,2) & 0xFF);
    
    script_setBytes(&value, address, sizeof(value));
    return 0;
}

static int print(lua_State *L) {
    
    int n=lua_gettop(L);
    int i;
    for (i=1; i<=n; i++)
    {
        if (i>1) script_print("\t");
        if (lua_isstring(L,i))
            script_print("%s",lua_tostring(L,i));
        else if (lua_isnil(L,i))
            script_print("%s","nil");
        else if (lua_isboolean(L,i))
            script_print("%s",lua_toboolean(L,i) ? "true" : "false");
        else
            script_print("%s:%p",luaL_typename(L,i),lua_topointer(L,i));
    }
    return 0;
}

#define NOT_IMP_LUA(func, feature) \
static int func (lua_State *L) { \
script_print("%@ is not implemented", feature); return 1; }

NOT_IMP_LUA(emu_pause, "emu.pause")
NOT_IMP_LUA(emu_unpause, "emu.unpause")
NOT_IMP_LUA(emu_getframecount, "emu.getframecount")
NOT_IMP_LUA(emu_getlagcount, "emu.getlagcount")
NOT_IMP_LUA(emu_lagged, "emu.lagged")
NOT_IMP_LUA(emu_atframeboundary, "emu.atframeboundary")
NOT_IMP_LUA(emu_registerstart, "emu.registerstart")
NOT_IMP_LUA(emu_persistglobalvariables, "emu.persistglobalvariables")
NOT_IMP_LUA(emu_message, "emu.message")
NOT_IMP_LUA(emu_openscript, "emu.openscript")

NOT_IMP_LUA(gui_line, "gui.line")
NOT_IMP_LUA(gui_pixel, "gui.pixel")
NOT_IMP_LUA(gui_getpixel, "gui.getpixel")
NOT_IMP_LUA(gui_setopacity, "gui.gui_setopacity")
NOT_IMP_LUA(gui_settransparency, "gui.settransparency")
NOT_IMP_LUA(gui_popup, "gui.popup")
NOT_IMP_LUA(gui_parsecolor, "gui.parsecolor")
NOT_IMP_LUA(gui_gdscreenshot, "gui.gdscreenshot")
NOT_IMP_LUA(gui_gdoverlay, "gui.gdoverlay")
NOT_IMP_LUA(gui_savescreenshot, "gui.savescreenshot")
//NOT_IMP_LUA(gui_box, "gui.box")

NOT_IMP_LUA(state_create, "state.create")
NOT_IMP_LUA(state_save, "state.save")
NOT_IMP_LUA(state_load, "state.load")
NOT_IMP_LUA(state_loadscriptdata, "state.loadscriptdata")
NOT_IMP_LUA(state_savescriptdata, "state.savescriptdata")
NOT_IMP_LUA(state_registersave, "state.registersave")
NOT_IMP_LUA(state_registerload, "state.registerload")

NOT_IMP_LUA(memory_readbytesigned, "memory.readbytesigned")
NOT_IMP_LUA(memory_readwordsigned, "memory.readwordsigned")
NOT_IMP_LUA(memory_readdwordsigned, "memory.readdwordsigned")
NOT_IMP_LUA(memory_readdword, "memory.readdword")
NOT_IMP_LUA(memory_readbyterange, "memory.readbyterange")
NOT_IMP_LUA(memory_writedword, "memory.writedword")
NOT_IMP_LUA(memory_getregister, "memory.getregister")
NOT_IMP_LUA(memory_setregister, "memory.setregister")
NOT_IMP_LUA(memory_registerwrite, "memory.registerwrite")
NOT_IMP_LUA(memory_registerread, "memory.registerread")
NOT_IMP_LUA(memory_registerexec, "memory.registerexec")

NOT_IMP_LUA(apu_readbyte, "apu.readbyte")
NOT_IMP_LUA(apu_readbytesigned, "apu.readbytesigned")
NOT_IMP_LUA(apu_readword, "apu.readword")
NOT_IMP_LUA(apu_readwordsigned, "apu.readwordsigned")
NOT_IMP_LUA(apu_readdword, "apu.readdword")
NOT_IMP_LUA(apu_readdwordsigned, "apu.readdwordsigned")
NOT_IMP_LUA(apu_readbyterange, "apu.readbyterange")
NOT_IMP_LUA(apu_writebyte, "apu.writebyt")
NOT_IMP_LUA(apu_writeword, "apu.writeword")
NOT_IMP_LUA(apu_writedword, "apu.writedword")

NOT_IMP_LUA(joy_get, "joy_get")
NOT_IMP_LUA(joy_getdown, "joy_getdown")
NOT_IMP_LUA(joy_getup, "joy_getup")
NOT_IMP_LUA(joy_set, "joy_set")
NOT_IMP_LUA(joy_gettype, "joy_gettype")
NOT_IMP_LUA(joy_settype, "joy_settype")

NOT_IMP_LUA(input_get, "input_get")
NOT_IMP_LUA(input_getdown, "input_get")
NOT_IMP_LUA(input_getup, "input_getup")
NOT_IMP_LUA(input_registerhotkey, "input_registerhotkey")
NOT_IMP_LUA(input_popup, "input_popup")

NOT_IMP_LUA(movie_isactive, "movie_isactive")
NOT_IMP_LUA(movie_isrecording, "movie_isrecording")
NOT_IMP_LUA(movie_isplaying, "movie_isplaying")
NOT_IMP_LUA(movie_getmode, "movie_getmode")
NOT_IMP_LUA(movie_getlength, "movie_getlength")
NOT_IMP_LUA(movie_getname, "movie_getname")
NOT_IMP_LUA(movie_rerecordcount, "movie_rerecordcount")
NOT_IMP_LUA(movie_setrerecordcount, "movie_setrerecordcount")
NOT_IMP_LUA(emu_rerecordcounting, "emu_rerecordcounting")
NOT_IMP_LUA(movie_getreadonly, "movie_getreadonly")
NOT_IMP_LUA(movie_setreadonly, "movie_setreadonly")
NOT_IMP_LUA(movie_play, "movie_play")
NOT_IMP_LUA(movie_replay, "movie_replay")
NOT_IMP_LUA(movie_close, "movie_close")

/// LuaBitOp starts here
// the following bit operations are ported from LuaBitOp 1.0.12
// because it can handle the sign bit (bit 31) correctly.

/*
 ** Lua BitOp -- a bit operations library for Lua 5.1/5.2.
 ** http://bitop.luajit.org/
 **
 ** Copyright (C) 2008-2012 Mike Pall. All rights reserved.
 **
 ** Permission is hereby granted, free of charge, to any person obtaining
 ** a copy of this software and associated documentation files (the
 ** "Software"), to deal in the Software without restriction, including
 ** without limitation the rights to use, copy, modify, merge, publish,
 ** distribute, sublicense, and/or sell copies of the Software, and to
 ** permit persons to whom the Software is furnished to do so, subject to
 ** the following conditions:
 **
 ** The above copyright notice and this permission notice shall be
 ** included in all copies or substantial portions of the Software.
 **
 ** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 ** EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 ** MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 ** IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 ** CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 ** TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 ** SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 **
 ** [ MIT license: http://www.opensource.org/licenses/mit-license.php ]
 */

typedef int32_t SBits;
typedef uint32_t UBits;

typedef union {
    lua_Number n;
#ifdef LNUM_DOUBLE
    uint64_t b;
#else
    UBits b;
#endif
} BitNum;

/* Convert argument to bit type. */
static UBits barg(lua_State *L, int idx)
{
    BitNum bn;
    UBits b;
#if LUA_VERSION_NUM < 502
    bn.n = lua_tonumber(L, idx);
#else
    bn.n = luaL_checknumber(L, idx);
#endif
#if defined(LNUM_DOUBLE)
    bn.n += 6755399441055744.0;  /* 2^52+2^51 */
#ifdef SWAPPED_DOUBLE
    b = (UBits)(bn.b >> 32);
#else
    b = (UBits)bn.b;
#endif
#elif defined(LUA_NUMBER_INT) || defined(LUA_NUMBER_LONG) || \
defined(LUA_NUMBER_LONGLONG) || defined(LUA_NUMBER_LONG_LONG) || \
defined(LUA_NUMBER_LLONG)
    if (sizeof(UBits) == sizeof(lua_Number))
        b = bn.b;
    else
        b = (UBits)(SBits)bn.n;
#elif defined(LNUM_FLOAT)
#error "A 'float' lua_Number type is incompatible with this library"
#else
#error "Unknown number type, check LUA_NUMBER_* in luaconf.h"
#endif
#if LUA_VERSION_NUM < 502
    if (b == 0 && !lua_isnumber(L, idx)) {
        luaL_typerror(L, idx, "number");
    }
#endif
    return b;
}

/* Return bit type. */
#define BRET(b)  lua_pushnumber(L, (lua_Number)(SBits)(b)); return 1;

static int bit_tobit(lua_State *L) {
    BRET(barg(L, 1))
}

static int bit_bnot(lua_State *L) {
    BRET(~barg(L, 1))
}

#define BIT_OP(func, opr) \
static int func (lua_State *L) { int i; UBits b = barg(L, 1); \
for (i = lua_gettop(L); i > 1; i--) b opr barg(L, i); BRET(b) }
BIT_OP(bit_band, &=)
BIT_OP(bit_bor, |=)
BIT_OP(bit_bxor, ^=)

#define bshl(b, n)  (b << n)
#define bshr(b, n)  (b >> n)
#define bsar(b, n)  ((SBits)b >> n)
#define brol(b, n)  ((b << n) | (b >> (32-n)))
#define bror(b, n)  ((b << (32-n)) | (b >> n))
#define BIT_SH(func, fn) \
static int func (lua_State *L) { \
UBits b = barg(L, 1); UBits n = barg(L, 2) & 31; BRET(fn(b, n)) }
BIT_SH(bit_lshift, bshl)
BIT_SH(bit_rshift, bshr)
BIT_SH(bit_arshift, bsar)
BIT_SH(bit_rol, brol)
BIT_SH(bit_ror, bror)

static int bit_bswap (lua_State *L)
{
    UBits b = barg(L, 1);
    b = (b >> 24) | ((b >> 8) & 0xff00) | ((b & 0xff00) << 8) | (b << 24);
    BRET(b)
}

static int bit_tohex (lua_State *L)
{
    UBits b = barg(L, 1);
    SBits n = lua_isnone(L, 2) ? 8 : (SBits)barg(L, 2);
    const char *hexdigits = "0123456789abcdef";
    char buf[8];
    int i;
    if (n < 0) { n = -n; hexdigits = "0123456789ABCDEF"; }
    if (n > 8) n = 8;
    for (i = (int)n; --i >= 0; ) { buf[i] = hexdigits[b & 15]; b >>= 4; }
    lua_pushlstring(L, buf, (size_t)n);
    return 1;
}

/// LuaBitOp ends here

static int bitshift (lua_State *L)
{
    int shift = (int)luaL_checkinteger(L,2);
    if (shift < 0) {
        lua_pushinteger(L, -shift);
        lua_replace(L, 2);
        return bit_lshift(L);
    }
    else
        return bit_rshift(L);
}

static int bitbit (lua_State *L)
{
    int rv = 0;
    int numArgs = lua_gettop(L);
    for(int i = 1; i <= numArgs; i++) {
        int where = (int)luaL_checkinteger(L,i);
        if (where >= 0 && where < 32)
            rv |= (1 << where);
    }
    lua_settop(L,0);
    BRET(rv);
}

void CallRegisteredLuaFunctions(enum LuaCallID calltype, lua_State* L) {
    const char* idstring = luaCallIDStrings[calltype];
    
    lua_getfield(L, LUA_REGISTRYINDEX, idstring);
    
    if (lua_isfunction(L, -1))
    {
        int errorcode = lua_pcall(L, 0, 0, 0);
        if (errorcode)
            script_print("%@ %d", "error", errorcode);
    }
    else
    {
        lua_pop(L, 1);
    }
}

void RegisterLuaFuncs(lua_State* L) {
    
    const luaL_reg emulib[] =
    {
        {"pause", emu_pause},
        {"unpause", emu_unpause},
        {"framecount", emu_getframecount},
        {"lagcount", emu_getlagcount},
        {"lagged", emu_lagged},
        {"emulating", emu_emulating},
        {"atframeboundary", emu_atframeboundary},
        {"registerafter", emu_registerafter},
        {"registerstart", emu_registerstart},
        {"registerexit", emu_registerexit},
        {"persistglobalvariables", emu_persistglobalvariables},
        {"message", emu_message},
        {"print", print}, // sure, why not
        {"openscript", emu_openscript},
        {NULL,NULL},
    };
    
    const luaL_reg guilib[] =
    {
        {"register", gui_register},
        {"text", gui_text},
        {"line", gui_line},
        {"pixel", gui_pixel},
        {"getpixel", gui_getpixel},
        {"opacity", gui_setopacity},
        {"transparency", gui_settransparency},
        {"popup", gui_popup},
        {"parsecolor", gui_parsecolor},
        {"gdscreenshot", gui_gdscreenshot},
        {"gdoverlay", gui_gdoverlay},
        {"savescreenshot", gui_savescreenshot},
        // alternative names
        {"drawtext", gui_text},
        {"drawbox", gui_box},
        {"drawline", gui_line},
        {"drawpixel", gui_pixel},
        {"setpixel", gui_pixel},
        {"writepixel", gui_pixel},
        {"readpixel", gui_getpixel},
        {"rect", gui_box},
        {"drawrect", gui_box},
        {"drawimage", gui_gdoverlay},
        {"image", gui_gdoverlay},
        {NULL,NULL},
    };
    
    const luaL_reg statelib[] =
    {
        {"create", state_create},
        {"save", state_save},
        {"load", state_load},
        {"loadscriptdata", state_loadscriptdata},
        {"savescriptdata", state_savescriptdata},
        {"registersave", state_registersave},
        {"registerload", state_registerload},
        {NULL,NULL},
    };
    
    const luaL_reg memorylib[] =
    {
        {"readbyte", memory_readbyte},
        {"readbytesigned", memory_readbytesigned},
        {"readword", memory_readword},
        {"readwordsigned", memory_readwordsigned},
        {"readdword", memory_readdword},
        {"readdwordsigned", memory_readdwordsigned},
        {"readbyterange", memory_readbyterange},
        {"writebyte", memory_writebyte},
        {"writeword", memory_writeword},
        {"writedword", memory_writedword},
        {"getregister", memory_getregister},
        {"setregister", memory_setregister},
        // alternate naming scheme for word and double-word and unsigned
        {"readbyteunsigned", memory_readbyte},
        {"readwordunsigned", memory_readword},
        {"readdwordunsigned", memory_readdword},
        {"readshort", memory_readword},
        {"readshortunsigned", memory_readword},
        {"readshortsigned", memory_readwordsigned},
        {"readlong", memory_readdword},
        {"readlongunsigned", memory_readdword},
        {"readlongsigned", memory_readdwordsigned},
        {"writeshort", memory_writeword},
        {"writelong", memory_writedword},
        // memory hooks
        {"registerwrite", memory_registerwrite},
        {"registerread", memory_registerread},
        {"registerexec", memory_registerexec},
        // alternate names
        {"register", memory_registerwrite},
        {"registerrun", memory_registerexec},
        {"registerexecute", memory_registerexec},
        {NULL,NULL},
    };
    
    const luaL_reg apulib[] =
    {
        {"readbyte", apu_readbyte},
        {"readbytesigned", apu_readbytesigned},
        {"readword", apu_readword},
        {"readwordsigned", apu_readwordsigned},
        {"readdword", apu_readdword},
        {"readdwordsigned", apu_readdwordsigned},
        {"readbyterange", apu_readbyterange},
        {"writebyte", apu_writebyte},
        {"writeword", apu_writeword},
        {"writedword", apu_writedword},
        // alternate naming scheme for word and double-word and unsigned
        {"readbyteunsigned", apu_readbyte},
        {"readwordunsigned", apu_readword},
        {"readdwordunsigned", apu_readdword},
        {"readshort", apu_readword},
        {"readshortunsigned", apu_readword},
        {"readshortsigned", apu_readwordsigned},
        {"readlong", apu_readdword},
        {"readlongunsigned", apu_readdword},
        {"readlongsigned", apu_readdwordsigned},
        {"writeshort", apu_writeword},
        {"writelong", apu_writedword},
        {NULL,NULL},
    };
    
    const luaL_reg joylib[] =
    {
        {"get", joy_get},
        {"getdown", joy_getdown},
        {"getup", joy_getup},
        {"set", joy_set},
        {"gettype", joy_gettype},
        {"settype", joy_settype},
        // alternative names
        {"read", joy_get},
        {"write", joy_set},
        {"readdown", joy_getdown},
        {"readup", joy_getup},
        {NULL,NULL},
    };
    
    const luaL_reg inputlib[] =
    {
        {"get", input_get},
        {"getdown", input_getdown},
        {"getup", input_getup},
        {"registerhotkey", input_registerhotkey},
        {"popup", input_popup},
        // alternative names
        {"read", input_get},
        {"readdown", input_getdown},
        {"readup", input_getup},
        {NULL,NULL},
    };
    
    const luaL_reg movielib[] =
    {
        {"active", movie_isactive},
        {"recording", movie_isrecording},
        {"playing", movie_isplaying},
        {"mode", movie_getmode},
        
        {"length", movie_getlength},
        {"name", movie_getname},
        {"rerecordcount", movie_rerecordcount},
        {"setrerecordcount", movie_setrerecordcount},
        
        {"rerecordcounting", emu_rerecordcounting},
        {"readonly", movie_getreadonly},
        {"setreadonly", movie_setreadonly},
        {"framecount", emu_getframecount}, // for those familiar with other emulators that have movie.framecount() instead of emulatorname.framecount()
        
        {"play", movie_play},
        {"replay", movie_replay},
        {"stop", movie_close},
        
        // alternative names
        {"open", movie_play},
        {"close", movie_close},
        {"getname", movie_getname},
        {"playback", movie_play},
        {"getreadonly", movie_getreadonly},
        {NULL,NULL},
    };
    
    const luaL_reg bit_funcs[] =
    {
        { "tobit",    bit_tobit },
        { "bnot",    bit_bnot },
        { "band",    bit_band },
        { "bor",    bit_bor },
        { "bxor",    bit_bxor },
        { "lshift",    bit_lshift },
        { "rshift",    bit_rshift },
        { "arshift",    bit_arshift },
        { "rol",    bit_rol },
        { "ror",    bit_ror },
        { "bswap",    bit_bswap },
        { "tohex",    bit_tohex },
        {NULL,NULL},
    };
    
    luaL_openlibs(L);
    
    luaL_register(L, "emu", emulib);
    luaL_register(L, "gui", guilib);
    luaL_register(L, "savestate", statelib);
    luaL_register(L, "memory", memorylib);
    luaL_register(L, "apu", apulib);
    luaL_register(L, "joypad", joylib); // for game input
    luaL_register(L, "input", inputlib); // for user input
    luaL_register(L, "movie", movielib);
    luaL_register(L, "bit", bit_funcs); // LuaBitOp library
    
    lua_settop(L, 0);
    
    lua_register(L, "print", print);
    
    // old bit operation functions
    lua_register(L, "AND", bit_band);
    lua_register(L, "OR", bit_bor);
    lua_register(L, "XOR", bit_bxor);
    lua_register(L, "SHIFT", bitshift);
    lua_register(L, "BIT", bitbit);
}
