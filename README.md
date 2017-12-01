# This is a test to get Lua scripting integrated into the open emu SNES-9x core. Code is not properly attributed at this time.

This contains a binary of [luaCocoa](https://github.com/mugginsoft/luacocoa), here is its license:

	LuaCocoa is under the MIT license:

	Copyright (C) 2009-2010 PlayControl Software, LLC. 
	Eric Wing <ewing . public @ playcontrol.net>

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
	THE SOFTWARE.


	Additional LuaCocoa Contributors:
	Jonathan Mitchell


	LuaCocoa uses or contains other code which is under their respective licenses:

	Lua is under the MIT license. (Roberto Ierusalimschy, Waldemar Celes, Luiz Henrique de Figueiredo, PUC-Rio)
	http://www.lua.org

	LNUM patch is under the MIT license. (Asko Kauppi)
	http://luaforge.net/projects/lnum/

	LPeg is under the MIT license. (Roberto Ierusalimschy, PUC-Rio)
	http://www.inf.puc-rio.br/~roberto/lpeg/lpeg.html

	Leg is under the MIT license. (Humberto Saraiva Nazareno dos Anjos)
	http://leg.luaforge.net/

	Objective-Lua is under the MIT license. (David Given)
	http://www.cowlark.com/objective-lua/



	Some code was copied/inspired from the following projects:

	JSCocoa is under the MIT license. (Patrick Geiller)
	http://inexdo.com/JSCocoa

	PyObjC is under the MIT license. (Ronald Oussoren, Bill Bumgarner, Steve Majewski, Lele Gaifax, et.al.)
	http://pyobjc.sourceforge.net/license.html

OpenEmu
=======

![alt text](http://openemu.org/img/intro-md.png "OpenEmu Screenshot")

OpenEmu is an open source project to bring game emulation to OS X as a first
class citizen, leveraging modern OS X technologies such as Cocoa, Core
Animation and Quartz, and 3rd party libraries like Sparkle for auto-updating.
OpenEmu is based on a modular architecture, allowing for game-engine plugins,
this means OpenEmu can support a host of different emulation engines and
back-ends while retaining a familiar OS X native front-end.

Currently OpenEmu can load the following game engines as plugins:

* Atari 2600 ([Stella](http://sourceforge.net/projects/stella/))
* Atari 5200 ([Atari800](http://sourceforge.net/projects/atari800/))
* Atari 7800 ([ProSystem](https://github.com/raz0red/wii7800))
* Atari Lynx ([Mednafen](http://mednafen.sourceforge.net/))
* ColecoVision ([CrabEmu](http://crabemu.sourceforge.net/))
* Famicom Disk System ([Nestopia](http://nestopia.sourceforge.net/))
* Game Boy / Game Boy Color ([Gambatte](https://github.com/sinamas/gambatte))
* Game Boy Advance ([VBA-M](http://sourceforge.net/projects/vbam/))
* Game Gear ([CrabEmu](http://crabemu.sourceforge.net/), [TwoMbit](http://sourceforge.net/projects/twombit/))
* Intellivision ([Bliss](https://github.com/jeremiah-sypult/BlissEmu))
* NeoGeo Pocket ([NeoPop](http://neopop.emuxhaven.net/))
* Nintendo (NES) / Famicom ([FCEUX](http://sourceforge.net/projects/fceultra/), [Nestopia](http://nestopia.sourceforge.net/))
* Nintendo DS ([DeSmuME](http://desmume.org/))
* Nintendo 64 ([Mupen64Plus](https://github.com/mupen64plus))
* Odyssey²/Videopac+ ([O2EM](http://sourceforge.net/projects/o2em/))
* PC-FX ([Mednafen](http://mednafen.sourceforge.net/))
* SG-1000 ([CrabEmu](http://crabemu.sourceforge.net/))
* Sega 32X ([picodrive](https://github.com/notaz/picodrive))
* Sega CD / Mega CD ([Genesis Plus](https://github.com/ekeeke/Genesis-Plus-GX))
* Sega Genesis / Mega Drive ([Genesis Plus](https://github.com/ekeeke/Genesis-Plus-GX))
* Sega Master System ([CrabEmu](http://crabemu.sourceforge.net/), [TwoMbit](http://sourceforge.net/projects/twombit/))
* Sony PlayStation ([Mednafen](http://mednafen.sourceforge.net/))
* Sony PSP ([PPSSPP](https://github.com/hrydgard/ppsspp))
* Super Nintendo (SNES) ([Higan](http://byuu.org/), [Snes9x](https://github.com/snes9xgit/snes9x))
* TurboGrafx-16/PC Engine ([Mednafen](http://mednafen.sourceforge.net/))
* TurboGrafx-CD/PCE-CD ([Mednafen](http://mednafen.sourceforge.net/))
* Virtual Boy ([Mednafen](http://mednafen.sourceforge.net/))
* Vectrex ([VecXGL](http://jum.pdroms.de/emulators/emul.html))
* WonderSwan ([Mednafen](http://mednafen.sourceforge.net/))

Minimum Requirements
--------------------

OS X 10.11 El Capitan
