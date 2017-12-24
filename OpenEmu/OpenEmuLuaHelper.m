//
//  OpenEmuLuaHelper.m
//  OpenEmu
//
//  Created by Patrick Winchell on 8/25/17.
//
//

#import "OpenEmuLuaHelper.h"
#import <LuaCocoa/LuaCocoa.h>
#import "luaAPI.h"

@interface OpenEmuLuaHelper ()

@property (readwrite, strong) LuaCocoa *lua;
@property (assign) uint32 *screenBuffer;
@property (assign) CGSize screenSize;
@property (assign) int bufferLength;

@end

@implementation OpenEmuLuaHelper

@synthesize delegate;

OpenEmuLuaHelper * helperRef;

- (instancetype) initWithDelegate: (id<OpenEmuScriptingHelperDelegate>)delegate fileURL:(NSURL*)fileURL
{
    self = [super init];
    if (self) {
        self.delegate = delegate;
        [self setupLuaBridgeWithFileURL: fileURL];
    }
    return self;
}

- (void)registerFuncs: (lua_State*)state {
    helperRef = self;
    
    RegisterLuaFuncs(state);
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

-(void)onGameLoaded {
    CallRegisteredLuaFunctions(LUACALL_AFTERLOAD, [[self lua] luaState]);
}

-(void)onStart {
    CallRegisteredLuaFunctions(LUACALL_ONSTART, [[self lua] luaState]);
}

-(void)onBeforeFrame {
    CallRegisteredLuaFunctions(LUACALL_BEFOREEMULATION, [[self lua] luaState]);
}

-(void)onAfterFrame {
    CallRegisteredLuaFunctions(LUACALL_AFTEREMULATION, [[self lua] luaState]);
}

- (void)onGUI {
    
    if (self.screenBuffer == nil) {
        CGSize screenSize = [self.delegate scriptScreenSize];
        if (CGSizeEqualToSize(screenSize, CGSizeZero)) {
            return;
        }
        int bufferLength = sizeof(UInt32) * (int)screenSize.width * (int)screenSize.height;
        self.bufferLength = bufferLength;
        self.screenBuffer = malloc(bufferLength);
        self.screenSize = screenSize;
    }

    CallRegisteredLuaFunctions(LUACALL_AFTEREMULATIONGUI, [[self lua] luaState]);
    
    NSData * screenData = [NSData dataWithBytes: self.screenBuffer length: self.bufferLength];
    
    [self.delegate drawData: screenData withSize: self.screenSize];
    
    memset(self.screenBuffer, 0, self.bufferLength);
}

- (void)onBeforeSave {
    CallRegisteredLuaFunctions(LUACALL_BEFORESAVE, [[self lua] luaState]);
}

- (void)onExit {
    CallRegisteredLuaFunctions(LUACALL_BEFOREEXIT, [[self lua] luaState]);
}

- (void)drawText: (NSString*)msg atX:(int)x atY:(int)y
{
    [self drawBox:CGRectMake(x - 1, y - 1, [msg length] * 4 + 1, 9) fill: 0x000000FF outline: 0x000000FF];
    
    int offsetX = x;
    
    for (int i = 0; i < [msg length]; i++) {
        unichar c = [msg characterAtIndex:i];
        
        int charIdx = (c-32)*7*4;
        if (charIdx < sizeof(Small_Font_Data) && charIdx >= 0) {
            const unsigned char* Cur_Glyph = (const unsigned char*)&Small_Font_Data + charIdx;
            for (int cy = 0; cy < 8 ; cy++) {
                unsigned int glyphLine = *((unsigned int*)Cur_Glyph + cy);
                for (int cx = 0; cx < 3; cx++) {
                    if (cx + offsetX < self.screenSize.width && (y + cy) < self.screenSize.height) {
                        int shift = cx << 3;
                        int mask = 0xFF << shift;
                        int intensity = (glyphLine & mask) >> shift;
                        
                        if (intensity) {
                            int idx = (cx + offsetX) + (y + cy) * (int)self.screenSize.width;
                            self.screenBuffer[idx] = 0xFFFFFFFF;
                        }
                    }
                }
            }
        }
        offsetX += 4;
    }
}

- (void)drawBox: (CGRect)box fill:(UInt32)fill outline:(UInt32) outline
{
    int x1 = box.origin.x;
    int x2 = box.origin.x + box.size.width;
    int y1 = box.origin.y;
    int y2 = box.origin.y + box.size.height;
    
    for (int x = x1; x < x2; x++) {
        for (int y = y1; y < y2; y++) {
            if (x >= 0 && y >= 0 && x < self.screenSize.width && y < self.screenSize.width) {
                int idx = x + y * (int)self.screenSize.width;
                self.screenBuffer[idx] = fill;
            }
        }
    }
}

- (void)setPixelColor:(UInt32) color x:(int)x y:(int)y
{
    if ((self.screenBuffer != nil) && (x >= 0) && (y >= 0) && (x < self.screenSize.width) && (y < self.screenSize.width)) {
        int idx = x + y * (int)self.screenSize.width;
        self.screenBuffer[idx] = color;
    }
}

- (void)dealloc
{
    [self onExit];
    free(self.screenBuffer);
}

const void * script_getBytes(UInt32 address, UInt32 length) {
    NSData * data = [helperRef.delegate getBytesAtAddress: address length:length];
    if (data.length == length) {
        const void * bytes = [data bytes];
        return bytes;
    }
    return nil;
}

void script_setBytes(const void * bytes, UInt32 address, UInt32 length) {
    NSData * data = [NSData dataWithBytes:bytes length: length];
    [helperRef.delegate setData:data atAddress: address];
}

void script_setPixel(UInt32 color, int x, int y) {
    [helperRef setPixelColor:color x:x y:y];
}

void script_drawBox(int x1, int y1, int x2, int y2, UInt32 fill, UInt32 outline) {
    [helperRef drawBox: CGRectMake(x1, y1, x2 - x1, y2 - y1) fill:fill outline:outline];
}

void script_drawText(const char *msg, int x, int y) {
    [helperRef drawText: [NSString stringWithUTF8String:msg] atX:x atY:y];
}

int script_print(const char * __restrict format, ...)
{
    va_list args;
    va_start(args,format);
    NSLogv([NSString stringWithUTF8String:format], args) ;
    va_end(args);
    return 1;
}

@end
