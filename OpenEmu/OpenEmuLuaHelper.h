//
//  OpenEmuLuaHelper.h
//  OpenEmu
//
//  Created by Patrick Winchell on 8/25/17.
//
//

#import <Foundation/Foundation.h>

@protocol OpenEmuLuaHelperDelegate <NSObject>
@required

- (void) setData: (NSData *)data atAddress: (UInt32)address;
- (NSData *) getBytesAtAddress: (UInt32)address length: (UInt) length;

@end

@interface OpenEmuLuaHelper : NSObject

- (instancetype) initWithDelegate: (id<OpenEmuLuaHelperDelegate>)delegate fileURL:(NSURL*)fileURL;

-(void)onGameLoaded;

- (void)onStart;
- (void)onBeforeFrame;
- (void)onAfterFrame;
- (void)onGUI;
- (void)onBeforeSave;
- (void)onExit;

@property(readwrite, weak) id<OpenEmuLuaHelperDelegate> delegate;

@end
