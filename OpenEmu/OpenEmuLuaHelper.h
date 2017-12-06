//
//  OpenEmuLuaHelper.h
//  OpenEmu
//
//  Created by Patrick Winchell on 8/25/17.
//
//

#import <Foundation/Foundation.h>

@protocol OpenEmuScriptingHelperDelegate <NSObject>
@required

- (void) setData: (NSData *)data atAddress: (UInt32)address;
- (NSData *) getBytesAtAddress: (UInt32)address length: (UInt) length;
- (void) setColor:(UInt32)color atX:(UInt)x y: (UInt) y;
- (CGSize) scriptScreenSize;
- (void) drawData:(NSData *)data withSize:(CGSize)size;

@end

@protocol OpenEmuScriptingHelper

    - (instancetype) initWithDelegate: (id<OpenEmuScriptingHelperDelegate>)delegate fileURL:(NSURL*)fileURL;

    - (void)onGameLoaded;
    - (void)onStart;
    - (void)onBeforeFrame;
    - (void)onAfterFrame;
    - (void)onGUI;
    - (void)onBeforeSave;
    - (void)onExit;

    @property(readwrite, weak) id<OpenEmuScriptingHelperDelegate> delegate;
@end

@interface OpenEmuLuaHelper : NSObject <OpenEmuScriptingHelper>
@end
