//
//  OpenEmuLuaHelper.m
//  OpenEmu
//
//  Created by Patrick Winchell on 8/25/17.
//
//

#import "OpenEmuLuaHelper.h"
#import <LuaCocoa/LuaCocoa.h>

@implementation OpenEmuLuaHelper
{
    LuaCocoa *lua;
}

OpenEmuLuaHelper * helperRef;

- (instancetype) initWithDelegate: (id<OpenEmuLuaHelperDelegate>)delegate
{
    self = [super init];
    if (self) {
        self.delegate = delegate;
        [self setupLuaBridge];
    }
    return self;
}

- (void)setupLuaBridge
{
    NSLog(@"%@",@"Starting Lua Bridge");
    @try
    {
        lua = [[LuaCocoa alloc] init];
        lua_State* luaState = [lua luaState];
        
        NSString *tempLuaPath = [[NSBundle mainBundle] pathForResource:@"Foo" ofType:@"lua"];
        int err = luaL_loadfile(luaState, [tempLuaPath fileSystemRepresentation]);
        if (err)
        {
            NSLog(@"luaL_loadfile failed: %s", lua_tostring(luaState, -1));
            lua_pop(luaState, 1); /* pop error message from stack */
            lua = nil;
        }
        err = lua_pcall(luaState, 0, 0, 0);
        if (err)
        {
            NSLog(@"luaL_loadfile failed: %s", lua_tostring(luaState, -1));
            lua_pop(luaState, 1); /* pop error message from stack */
            lua = nil;
        }
        
        [self registerFuncs:luaState];
        
        [self onGameLoaded];
    }
    @catch (NSException *exception) {
        NSLog(@"%@",@"Starting Lua Bridge failed");
        lua = nil;
    }
}

-(void)onGameLoaded {
    [lua pcallLuaFunction:"OnGameLoaded" withSignature:"@", self];
}

-(void)onBeforeFrame {
    [lua pcallLuaFunction:"OnFrameTick" withSignature:"@", self];
}

-(void)onAfterFrame {
//    [lua pcallLuaFunction:"OnFrameTick" withSignature:"@", self];
}

static int emu_emulating(lua_State *L) {
    lua_pushboolean(L, 1);
    return 1;
}

static int emu_registerexit(lua_State *L) {
    // TODO
    return 1;
}

static int gui_register(lua_State *L) {
    // TODO
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
