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

- (instancetype) initWithDelegate: (id<OpenEmuLuaHelperDelegate>)delegate;

- (void)onGameLoaded;
- (void)onBeforeFrame;
- (void)onAfterFrame;

@property(readwrite, weak) id<OpenEmuLuaHelperDelegate> delegate;

@end
