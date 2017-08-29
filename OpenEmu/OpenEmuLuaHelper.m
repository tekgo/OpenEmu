//
//  OpenEmuLuaHelper.m
//  OpenEmu
//
//  Created by Patrick Winchell on 8/25/17.
//
//

#import "OpenEmuLuaHelper.h"
#import <LuaCocoa/LuaCocoa.h>
#import <LuaCocoa/lua.h>
#import <LuaCocoa/luaconf.h>

@interface OpenEmuLuaHelper ()

@property(readwrite, strong) LuaCocoa *lua;

@end

@implementation OpenEmuLuaHelper

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

OpenEmuLuaHelper * helperRef;

- (instancetype) initWithDelegate: (id<OpenEmuLuaHelperDelegate>)delegate fileURL:(NSURL*)fileURL
{
    self = [super init];
    if (self) {
        self.delegate = delegate;
        [self setupLuaBridgeWithFileURL: fileURL];
    }
    return self;
}

- (void)setupLuaBridgeWithFileURL:(NSURL*)fileURL
{
    NSLog(@"%@",@"Starting Lua Bridge");
    
    NSString * oldCWD = [[NSFileManager defaultManager] currentDirectoryPath];
    NSString * cwd = [[fileURL URLByDeletingLastPathComponent] path];
    
    [[NSFileManager defaultManager] changeCurrentDirectoryPath: cwd];
    
    NSString * packagePath = [NSString stringWithFormat:@"%@/?.lua", cwd];
    NSString * packagecPath = [NSString stringWithFormat:@"%@/?.dylib;%@/?.so", cwd, cwd];
    
    @try
    {
        self.lua = [[LuaCocoa alloc] init];
        lua_State* luaState = [self.lua luaState];
        
        NSLog(@"%@",@"Registering libs");
        [self registerFuncs: luaState];
        
        lua_getglobal(luaState, "package");
        lua_pushstring(luaState, [packagePath cStringUsingEncoding:NSASCIIStringEncoding]);
        lua_setfield(luaState, -2, "path");
        lua_pop(luaState, 1);
        
        lua_getglobal(luaState, "package");
        lua_pushstring(luaState, [packagecPath cStringUsingEncoding:NSASCIIStringEncoding]);
        lua_setfield(luaState, -2, "cpath");
        lua_pop(luaState, 1);
        
        NSLog(@"%@",@"Loading file");
        NSString *tempLuaPath =  fileURL.path;
        
        int err = luaL_loadfile(luaState, [tempLuaPath fileSystemRepresentation]);
        if (err)
        {
            NSLog(@"luaL_loadfile failed: %s", lua_tostring(luaState, -1));
            lua_pop(luaState, 1); /* pop error message from stack */
            self.lua = nil;
        }
        err = lua_pcall(luaState, 0, 0, 0);
        if (err)
        {
            NSLog(@"luaL_loadfile failed: %s", lua_tostring(luaState, -1));
            lua_pop(luaState, 1); /* pop error message from stack */
            self.lua = nil;
            return;
        }
        
        [self onGameLoaded];
    }
    @catch (NSException *exception) {
        NSLog(@"%@",@"Starting Lua Bridge failed");
        self.lua = nil;
    }
    
    [[NSFileManager defaultManager] changeCurrentDirectoryPath: oldCWD];
}

void CallRegisteredLuaFunctions(enum LuaCallID calltype);

-(void)onGameLoaded {
    [self.lua pcallLuaFunction:"OnGameLoaded" withSignature:"@", self];
    CallRegisteredLuaFunctions(LUACALL_AFTERLOAD);
}

-(void)onStart {
    CallRegisteredLuaFunctions(LUACALL_ONSTART);
}

-(void)onBeforeFrame {
//    [self.lua pcallLuaFunction:"OnFrameTick" withSignature:"@", self];
    CallRegisteredLuaFunctions(LUACALL_BEFOREEMULATION);
}

-(void)onAfterFrame {
//    [lua pcallLuaFunction:"OnFrameTick" withSignature:"@", self];
    CallRegisteredLuaFunctions(LUACALL_AFTEREMULATION);
}

- (void)onGUI {
    CallRegisteredLuaFunctions(LUACALL_AFTEREMULATIONGUI);
}

- (void)onBeforeSave {
    CallRegisteredLuaFunctions(LUACALL_BEFORESAVE);
}

- (void)onExit {
    CallRegisteredLuaFunctions(LUACALL_BEFOREEXIT);
}

void CallRegisteredLuaFunctions(enum LuaCallID calltype) {
    assert((unsigned int)calltype < (unsigned int)LUACALL_COUNT);
    const char* idstring = luaCallIDStrings[calltype];
    
        lua_State* L = [[helperRef lua] luaState];
    
        lua_getfield(L, LUA_REGISTRYINDEX, idstring);
        
        if (lua_isfunction(L, -1))
        {
            int errorcode = lua_pcall(L, 0, 0, 0);
            if (errorcode)
                NSLog(@"%@", @"error");
        }
        else
        {
            lua_pop(L, 1);
        }
}

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
    // TODO
    return 1;
}

static int memory_readbyte(lua_State *L) {
    UInt32 address = (UInt32)lua_tointeger(L,1);
    
    UInt8 value = 0;
    
    NSData * data = [helperRef.delegate getBytesAtAddress: address length:1];
    if ([data length] > 0) {
        const UInt8 * n = [data bytes];
        value = n[0];
    }
    
    NSLog(@"Reading address: %x value: %u data: %@", address, value, data);
    
    lua_settop(L,0);
    lua_pushinteger(L, value);
    
    return 1;
}

static int memory_readword(lua_State *L) {
    UInt32 address = (UInt32)lua_tointeger(L,1);
    
    UInt16 value = 0;
    
    NSData * data = [helperRef.delegate getBytesAtAddress: address length:2];
    if ([data length] > 1) {
        const UInt8 * n = [data bytes];
        value = n[0];
        value |= (n[1] << 8);
    }
    
    lua_settop(L,0);
    lua_pushinteger(L, value);
    return 1;
}

static int memory_writebyte(lua_State *L) {
    UInt32 address = (UInt32)lua_tointeger(L,1);
    uint8 value = (uint8)(lua_tointeger(L,2) & 0xFF);
    
    NSData * data = [NSData dataWithBytes:&value length: sizeof(value)];
    [helperRef.delegate setData:data atAddress: address];
    return 0;
}

static int memory_writeword(lua_State *L) {
    UInt32 address = (UInt32)lua_tointeger(L,1);
    uint16 value = (uint8)(lua_tointeger(L,2) & 0xFF);
    
    NSData * data = [NSData dataWithBytes:&value length: sizeof(value)];
    [helperRef.delegate setData:data atAddress: address];
    return 0;
}

int printfX(const char * __restrict format, ...);

int printfX(const char * __restrict format, ...)
{
    va_list args;
    va_start(args,format);
    NSLogv([NSString stringWithUTF8String:format], args) ;
    va_end(args);
    return 1;
}


static int print(lua_State *L) {
    
    int n=lua_gettop(L);
    int i;
    for (i=1; i<=n; i++)
    {
        if (i>1) printfX("\t");
        if (lua_isstring(L,i))
            printfX("%s",lua_tostring(L,i));
        else if (lua_isnil(L,i))
            printfX("%s","nil");
        else if (lua_isboolean(L,i))
            printfX("%s",lua_toboolean(L,i) ? "true" : "false");
        else
            printfX("%s:%p",luaL_typename(L,i),lua_topointer(L,i));
    }
    return 0;
}

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

//DEFINE_LUA_FUNCTION(bit_tobit, "x") { BRET(barg(L, 1)) }
//DEFINE_LUA_FUNCTION(bit_bnot, "x") { BRET(~barg(L, 1)) }

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

static const struct luaL_Reg bit_funcs[] = {
    { "tobit",	bit_tobit },
    { "bnot",	bit_bnot },
    { "band",	bit_band },
    { "bor",	bit_bor },
    { "bxor",	bit_bxor },
    { "lshift",	bit_lshift },
    { "rshift",	bit_rshift },
    { "arshift",	bit_arshift },
    { "rol",	bit_rol },
    { "ror",	bit_ror },
    { "bswap",	bit_bswap },
    { "tohex",	bit_tohex },
    { NULL, NULL }
};

// LuaBitOp ends here

static int bitshift (lua_State *L)
{
    int shift = luaL_checkinteger(L,2);
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
        int where = luaL_checkinteger(L,i);
        if (where >= 0 && where < 32)
            rv |= (1 << where);
    }
    lua_settop(L,0);
    BRET(rv);
}

- (void)registerFuncs: (lua_State*)state {
    helperRef = self;
    
    const luaL_reg emulib[] =
    {
        {"emulating", emu_emulating},
        {"registerexit", emu_registerexit},
        {NULL,NULL},
    };
    
    const luaL_reg guilib[] =
    {
        {"register", gui_register},
        {"text", gui_text},
        {NULL,NULL},
    };
    
    const luaL_reg statelib[] =
    {
        {NULL,NULL},
    };
    
    const luaL_reg memorylib[] =
    {
        {"readbyte", memory_readbyte},
        {"readword", memory_readword},
        {"writebyte", memory_writebyte},
        {"writeword", memory_writeword},
        {NULL,NULL},
    };
    
    const luaL_reg apulib[] =
    {
        {NULL,NULL},
    };
    
    const luaL_reg joylib[] =
    {
        {NULL,NULL},
    };
    
    const luaL_reg inputlib[] =
    {
        {NULL,NULL},
    };
    
    const luaL_reg movielib[] =
    {
        {NULL,NULL},
    };
    
    const luaL_reg bit_funcs[] =
    {
        { "tobit",	bit_tobit },
        { "bnot",	bit_bnot },
        { "band",	bit_band },
        { "bor",	bit_bor },
        { "bxor",	bit_bxor },
        { "lshift",	bit_lshift },
        { "rshift",	bit_rshift },
        { "arshift",	bit_arshift },
        { "rol",	bit_rol },
        { "ror",	bit_ror },
        { "bswap",	bit_bswap },
        { "tohex",	bit_tohex },
        {NULL,NULL},
    };
    
    luaL_openlibs(state);
    
    luaL_register(state, "emu", emulib);
    luaL_register(state, "gui", guilib);
    luaL_register(state, "savestate", statelib);
    luaL_register(state, "memory", memorylib);
    luaL_register(state, "apu", apulib);
    luaL_register(state, "joypad", joylib); // for game input
    luaL_register(state, "input", inputlib); // for user input
    luaL_register(state, "movie", movielib);
    luaL_register(state, "bit", bit_funcs); // LuaBitOp library
    
    lua_settop(state, 0);
    
    lua_register(state, "print", print);
    
    // old bit operation functions
    lua_register(state, "AND", bit_band);
    lua_register(state, "OR", bit_bor);
    lua_register(state, "XOR", bit_bxor);
    lua_register(state, "SHIFT", bitshift);
    lua_register(state, "BIT", bitbit);
}

- (void)print: (id)object {
    NSLog(@"%@",object);
}

@end
