//
//  OpenEmuLuaHelper.m
//  OpenEmu
//
//  Created by Patrick Winchell on 8/25/17.
//
//

#import "OpenEmuLuaHelper.h"
#import <LuaCocoa/LuaCocoa.h>

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
    @try
    {
        self.lua = [[LuaCocoa alloc] init];
        lua_State* luaState = [self.lua luaState];
        
        NSLog(@"%@",@"Registering libs");
        [self registerFuncs: luaState];
        
        NSString * directoryPath = [NSString stringWithFormat:@"%@/?.lua", [[fileURL URLByDeletingLastPathComponent] path]];
        
        lua_getglobal(luaState, "package");
        lua_pushstring(luaState, [directoryPath cStringUsingEncoding:NSASCIIStringEncoding]);
        lua_setfield(luaState, -2, "path");
        lua_pop(luaState, 1);
        
        NSLog(@"%@",@"Loading file");
        NSString *tempLuaPath =  fileURL.path; //[[NSBundle mainBundle] pathForResource:@"Foo" ofType:@"lua"];
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
        }
        
        [self onGameLoaded];
    }
    @catch (NSException *exception) {
        NSLog(@"%@",@"Starting Lua Bridge failed");
        self.lua = nil;
    }
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
}

- (void)print: (id)object {
    NSLog(@"%@",object);
}

@end
