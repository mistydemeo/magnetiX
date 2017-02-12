/****************************************************************************\
*
* magnetiX - Magnetic Scrolls Interpreter - Mac OS X port
*
* Written by Jan-Sebastian Schliemann <magnetiX@maczentrisch.de>
*
*
* the original Magnetic was:
*
* Written by Niclas Karlsson <nkarlsso@abo.fi>,
*            David Kinder <davidk.kinder@virgin.net>,
*            Stefan Meier <Stefan.Meier@if-legends.org> and
*            Paul David Doherty <pdd@if-legends.org>
*
* Copyright (C) 1997-2008  Niclas Karlsson
*
*
*
*     This program is free software; you can redistribute it and/or modify
*     it under the terms of the GNU General Public License as published by
*     the Free Software Foundation; either version 2 of the License, or
*     (at your option) any later version.
*
*     This program is distributed in the hope that it will be useful,
*     but WITHOUT ANY WARRANTY; without even the implied warranty of
*     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*     GNU General Public License for more details.
*
*     You should have received a copy of the GNU General Public License
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111, USA.
*
\*****************************************************************************/
#import "MXStatusView.h"
#import "GameSelectController.h"
#import "MagneticController.h"
#import "PreferenceController.h"
#import "MXFSController.h"
#import "MXHintsDataSource.h"
#import "MXScrollView.h"
#import "MXScroller.h"
#import "MXTextView.h"
#import "MXImageView.h"
#import "NSArray+mutableCopyWithMutableSubarrays.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include "defs.h"
#import <QuartzCore/QuartzCore.h>

static MagneticController *sharedController;
char buffer[1000], statbuffer[80], xpos = 0, statbufpos = 0, ms_gfx_enabled, filename[256], *gameSuffix = "";
int bufpos = 0, exHint = 0;
int workaroundTextHide = 0;
int workaroundTextHideMW = 0;
int workaroundTextType = 0;
BOOL isSavePackaged = NO;
NSUInteger uglyLocation = 0;
BOOL isJumpingBlocked = NO;
BOOL isUpdateMissing = NO;

@implementation MagneticController


+ (MagneticController *)sharedController
{
    return sharedController;
}


- (id)init
{
    self = [super init];
	
    sharedController = self;
	quitInProgress = NO;
	isFullscreenStatusChanging = NO;
    self.isAppFullyStarted = NO;
	
	orderPipe = [[NSPipe pipe] retain];
	
	orderBuffer = [[NSMutableArray alloc] initWithCapacity:1];
	orderHistory = [[NSMutableArray alloc] initWithCapacity:1];
	ordersForScript = [[NSMutableIndexSet alloc] init];
	uglyRanges = [[NSMutableArray alloc] initWithCapacity:1];
	animPicArray = [[NSMutableArray alloc] initWithCapacity:1];
		
	currentOrder = -1;
	currentImageSize = 0;
	borderValue = 22;
	lastFontChange = 0;
	theGlyphIndex = 0;
	glyphType = NO;
	isTemplateChanging = NO;
	self.isScriptPlaying = NO;
	hasGraphics = YES;
	invalidatedCursorRectsWithImageSize = -1;
	
	loadSaveMWLock = [[NSLock alloc] init];
	
	NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
	defaultValues[@"themeAutoplay"] = @1; // 0 = OFF, 1 = ON
	defaultValues[@"wonderlandMusic"] = @1; // 0 = OFF, 1 = ON
	defaultValues[@"disableRandomEventsAlert"] = @0;
	defaultValues[@"gameSelected"] = @1;
	defaultValues[@"templateSelected"] = @0;
	defaultValues[@"isFullscreen"] = @0;
	defaultValues[@"lastPrefTabOpen"] = @1;
	defaultValues[@"imageSmoothing"] = @1;
	defaultValues[@"imageOptimizations"] = @1;
	defaultValues[@"useIngameFileManagement"] = @1;
	defaultValues[@"nonContiguousLayout"] = @0;

	NSMutableArray *templateArray = [[NSMutableArray alloc] init];
	NSMutableDictionary *template = nil;
	
	template = [[NSMutableDictionary alloc] init];
	
	template[@"id"] = @0;
	template[@"name"] = @"Dark, Classic";
	template[@"colorBackground"] = [NSColor colorWithCalibratedRed:0.0704716 green:0.0704716 blue:0.0704716 alpha:1];
	template[@"colorTextGame"] = [NSColor colorWithCalibratedRed:0.973399 green:0.933342 blue:0.845653 alpha:1];
	template[@"colorTextUser"] = [NSColor colorWithDeviceRed:0.9 green:0.5 blue:0.5 alpha:1];
	template[@"displayPicture"] = @3; // 0 = OFF, 1 = normal, 2 = double, 3 = custom ... 1 and 2 are GONE, now ... old values will be converted ... 8 will be used as 3 with 8 bit graphics on
	template[@"use8BitGraphics"] = @0;
	template[@"isPictureFullsize"] = @0;
	template[@"displayAnim"] = @2; // 0 = OFF, 1 = single, 2 = loop, (3 = default, GONE)
	template[@"addedPictureSize"] = @150;
	template[@"maxContentWidth"] = @850;
	template[@"hasCustomSpacing"] = @0;
	template[@"characterSpacing"] = @0;
	template[@"lineSpacing"] = @0;
	template[@"gameFontName"] = @"TimesNewRomanPSMT";
	template[@"gameFontPointSize"] = @18;

	[templateArray addObject:template];
	
	[template release];
	
	template = [[NSMutableDictionary alloc] init];
	
	template[@"id"] = @1;
	template[@"name"] = @"Dark, Sixtyfour";
	template[@"colorBackground"] = [NSColor colorWithCalibratedRed:0.0704716 green:0.0704716 blue:0.0704716 alpha:1];
	template[@"colorTextGame"] = [NSColor colorWithDeviceRed:0.654902 green:1 blue:0.619608 alpha:1];
	template[@"colorTextUser"] = [NSColor colorWithCalibratedRed:0.0160292 green:0.815894 blue:0.216447 alpha:1];
	template[@"displayPicture"] = @3;
	template[@"use8BitGraphics"] = @1;
	template[@"isPictureFullsize"] = @0;
	template[@"displayAnim"] = @2;
	template[@"addedPictureSize"] = @0;
	template[@"maxContentWidth"] = @750;
	template[@"hasCustomSpacing"] = @0;
	template[@"characterSpacing"] = @0;
	template[@"lineSpacing"] = @0;
	template[@"gameFontName"] = @"Palatino-Roman";
	template[@"gameFontPointSize"] = @18;
	
	[templateArray addObject:template];
	
	[template release];
	
	template = [[NSMutableDictionary alloc] init];
	
	template[@"id"] = @2;
	template[@"name"] = @"Magnetic Bright";
	template[@"colorBackground"] = [NSColor colorWithCalibratedRed:0.973399 green:0.957452 blue:0.912021 alpha:1];
	template[@"colorTextGame"] = [NSColor colorWithCalibratedRed:0.188119 green:0.180377 blue:0.163431 alpha:1];
	template[@"colorTextUser"] = [NSColor colorWithCalibratedRed:0.655066 green:0 blue:0.10077 alpha:1];
	template[@"displayPicture"] = @3;
	template[@"use8BitGraphics"] = @0;
	template[@"isPictureFullsize"] = @1;
	template[@"displayAnim"] = @2;
	template[@"addedPictureSize"] = @0;
	template[@"maxContentWidth"] = @1000;
	template[@"hasCustomSpacing"] = @1;
	template[@"characterSpacing"] = @0;
	template[@"lineSpacing"] = @2;
	template[@"gameFontName"] = @"Optima-Regular";
	template[@"gameFontPointSize"] = @18;
	
	[templateArray addObject:template];
	
	[template release];
		
	NSData *templatesData = [NSArchiver archivedDataWithRootObject:templateArray];
	defaultValues[@"templatesData"] = templatesData;
	
	[templateArray release];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults registerDefaults:defaultValues];
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(changedFont:) name:@"fontChanged" object:nil];
	[nc addObserver:self selector:@selector(removeTemplate:) name:@"removeTemplate" object:nil];
	[nc addObserver:self selector:@selector(addTemplate:) name:@"addTemplate" object:nil];
	[nc addObserver:self selector:@selector(markLastVisibleGlyph) name:@"saveTextPosition" object:nil];
	[nc addObserver:self selector:@selector(prefChangedTemplate:) name:@"templateChanged" object:nil];
	[nc addObserver:self selector:@selector(firePossiblyMissingSelector) name:@"prefsTrackingSessionDidEnd" object:nil];
	[nc addObserver:self selector:@selector(enableViewMenu) name:@"templateNameEditingEnded" object:nil];
	[nc addObserver:self selector:@selector(disableViewMenu) name:@"templateNameEditingStarted" object:nil];
	
	[defaults addObserver:self forKeyPath:@"wonderlandMusic" options:NSKeyValueObservingOptionOld context:nil];
	[defaults addObserver:self forKeyPath:@"imageOptimizations" options:NSKeyValueObservingOptionOld context:nil];
	[defaults addObserver:self forKeyPath:@"nonContiguousLayout" options:NSKeyValueObservingOptionOld context:nil];
	
	// the rects define pixel counts that will be cropped (values used a la CSS: top, right, bottom, left) ... these dark lines look *BAD* when large on lighter backgrounds
	//, @"xxxx" : [NSValue valueWithRect:NSMakeRect(0, 0, 0, 0)]
	NSDictionary *pawn = @{@"1" : [NSValue valueWithRect:NSMakeRect(0, 0, 0, 1)], @"11" : [NSValue valueWithRect:NSMakeRect(0, 0, 0, 1)]};
	NSDictionary *guild = @{@"8" : [NSValue valueWithRect:NSMakeRect(0, 0, 0, 1)], @"21" : [NSValue valueWithRect:NSMakeRect(0, 2, 0, 1)]};
	NSDictionary *jinxter = @{@"3" : [NSValue valueWithRect:NSMakeRect(0, 1, 0, 0)], @"15" : [NSValue valueWithRect:NSMakeRect(0, 1, 0, 0)], @"18" : [NSValue valueWithRect:NSMakeRect(1, 1, 0, 1)], @"21" : [NSValue valueWithRect:NSMakeRect(0, 0, 1, 0)], @"24" : [NSValue valueWithRect:NSMakeRect(0, 2, 0, 0)], @"25" : [NSValue valueWithRect:NSMakeRect(0, 0, 0, 1)], @"27" : [NSValue valueWithRect:NSMakeRect(1, 0, 1, 0)], @"28" : [NSValue valueWithRect:NSMakeRect(0, 1, 1, 0)]};
	
	NSDictionary *corrupt = @{@"0" : [NSValue valueWithRect:NSMakeRect(0, 1, 0, 1)], @"1" : [NSValue valueWithRect:NSMakeRect(0, 2, 0, 0)], @"2" : [NSValue valueWithRect:NSMakeRect(0, 0, 1, 0)], @"6" : [NSValue valueWithRect:NSMakeRect(0, 0, 1, 0)], @"13" : [NSValue valueWithRect:NSMakeRect(0, 0, 1, 0)], @"21" : [NSValue valueWithRect:NSMakeRect(0, 0, 2, 0)], @"22" : [NSValue valueWithRect:NSMakeRect(0, 1, 0, 0)]};
	
	NSDictionary *fish = @{@"0" : [NSValue valueWithRect:NSMakeRect(0, 0, 0, 1)], @"20" : [NSValue valueWithRect:NSMakeRect(0, 1, 0, 0)], @"24" : [NSValue valueWithRect:NSMakeRect(0, 1, 1, 0)]};
	NSDictionary *myth = @{@"0" : [NSValue valueWithRect:NSMakeRect(0, 0, 1, 0)]};
	NSDictionary *cguild = @{@"gbilli" : [NSValue valueWithRect:NSMakeRect(0, 0, 1, 0)], @"ghill" : [NSValue valueWithRect:NSMakeRect(0, 1, 1, 1)], @"gshrin" : [NSValue valueWithRect:NSMakeRect(0, 1, 0, 0)], @"goutba" : [NSValue valueWithRect:NSMakeRect(0, 1, 0, 0)]};
	NSDictionary *ccorrupt = @{@"crevo" : [NSValue valueWithRect:NSMakeRect(0, 0, 1, 0)], @"cstart" : [NSValue valueWithRect:NSMakeRect(0, 1, 0, 0)], @"cpart" : [NSValue valueWithRect:NSMakeRect(0, 0, 0, 1)]};
	NSDictionary *cfish = @{@"fabbey" : [NSValue valueWithRect:NSMakeRect(0, 0, 0, 1)], @"fbatt" : [NSValue valueWithRect:NSMakeRect(0, 0, 1, 0)], @"fdino" : [NSValue valueWithRect:NSMakeRect(0, 1, 0, 0)], @"flab" : [NSValue valueWithRect:NSMakeRect(0, 1, 0, 0)], @"fmixer" : [NSValue valueWithRect:NSMakeRect(0, 1, 0, 0)], @"fplaza" : [NSValue valueWithRect:NSMakeRect(1, 1, 1, 1)], @"fproj" : [NSValue valueWithRect:NSMakeRect(0, 1, 0, 0)]};
	
	NSDictionary *wonder = @{@"bumble" : [NSValue valueWithRect:NSMakeRect(0, 0, 0, 1)], @"cedge" : [NSValue valueWithRect:NSMakeRect(0, 0, 1, 0)], @"dland" : [NSValue valueWithRect:NSMakeRect(0, 1, 0, 0)], @"frog" : [NSValue valueWithRect:NSMakeRect(0, 0, 1, 0)], @"grthal" : [NSValue valueWithRect:NSMakeRect(0, 1, 0, 0)], @"house" : [NSValue valueWithRect:NSMakeRect(0, 0, 0, 1)], @"madkit" : [NSValue valueWithRect:NSMakeRect(0, 0, 1, 0)], @"rbrige" : [NSValue valueWithRect:NSMakeRect(0, 1, 0, 1)], @"waiter" : [NSValue valueWithRect:NSMakeRect(0, 1, 0, 1)], @"jury1" : [NSValue valueWithRect:NSMakeRect(0, 0, 1, 0)]};
	
	self.cropDic = @{ @"pawn" : pawn, @"guild" : guild, @"jinxter" : jinxter, @"corrupt" : corrupt, @"fish" : fish, @"myth" : myth, @"cguild" : cguild, @"ccorrupt" : ccorrupt, @"cfish" : cfish, @"wonder" : wonder };
	
	cguild = @{
			   @"gantec" : @{@"saturation" : @(1.100000), @"brightness" : @(0.000000), @"contrast" : @(1.084000)},
			   @"gmacaw" : @{@"saturation" : @(1.100000), @"brightness" : @(0.000000), @"contrast" : @(1.030000)},
			   @"ghotho" : @{@"saturation" : @(1.100000), @"brightness" : @(-0.073000), @"contrast" : @(1.062000)},
			   @"gfores" : @{@"saturation" : @(1.200000), @"brightness" : @(-0.025000), @"contrast" : @(1.169000)},
			   @"gintem" : @{@"saturation" : @(1.120000), @"brightness" : @(-0.024000), @"contrast" : @(1.130000)},
			   @"gorgan" : @{@"saturation" : @(1.100000), @"brightness" : @(0.000000), @"contrast" : @(1.150000)},
			   @"gboats" : @{@"saturation" : @(1.271000), @"brightness" : @(0.000000), @"contrast" : @(1.152000)},
			   @"gsump" : @{@"saturation" : @(1.206000), @"brightness" : @(-0.001750), @"contrast" : @(1.101000)},
			   @"gstair" : @{@"saturation" : @(1.100000), @"brightness" : @(0.000000), @"contrast" : @(1.139000)},
			   @"gcoalr" : @{@"saturation" : @(1.200000), @"brightness" : @(-0.174000), @"contrast" : @(1.599000)},
			   @"gcastl" : @{@"saturation" : @(1.100000), @"brightness" : @(0.000000), @"contrast" : @(1.137000)},
			   @"gtempl" : @{@"saturation" : @(1.100000), @"brightness" : @(0.000000), @"contrast" : @(1.073000)},
			   @"gwfiel" : @{@"saturation" : @(1.100000), @"brightness" : @(0.000000), @"contrast" : @(1.240000)},
			   @"std" : @{@"saturation" : @(1.100000), @"brightness" : @(0.000000), @"contrast" : @(1.040000)}
			   };
	
	guild = @{
			  @"10" : @{@"saturation" : @(1.100000), @"brightness" : @(0.000000), @"contrast" : @(1.240312)},
			  @"9" : @{@"saturation" : @(1.100000), @"brightness" : @(0.000000), @"contrast" : @(1.084437)},
			  @"15" : @{@"saturation" : @(1.100000), @"brightness" : @(0.000000), @"contrast" : @(1.137063)},
			  @"11" : @{@"saturation" : @(1.271312), @"brightness" : @(0.000000), @"contrast" : @(1.151562)},
			  @"12" : @{@"saturation" : @(1.200000), @"brightness" : @(-0.173625), @"contrast" : @(1.599000)},
			  @"6" : @{@"saturation" : @(1.100000), @"brightness" : @(-0.073500), @"contrast" : @(1.061750)},
			  @"28" : @{@"saturation" : @(1.100000), @"brightness" : @(0.000000), @"contrast" : @(1.150000)},
			  @"13" : @{@"saturation" : @(1.100000), @"brightness" : @(0.000000), @"contrast" : @(1.138625)},
			  @"18" : @{@"saturation" : @(1.200000), @"brightness" : @(-0.025500), @"contrast" : @(1.169062)},
			  @"8" : @{@"saturation" : @(1.120000), @"brightness" : @(-0.023937), @"contrast" : @(1.150000)},
			  @"14" : @{@"saturation" : @(1.100000), @"brightness" : @(0.000000), @"contrast" : @(1.073063)},
			  @"std" : @{@"saturation" : @(1.100000), @"brightness" : @(0.000000), @"contrast" : @(1.040000)},
			  @"25" : @{@"saturation" : @(1.205750), @"brightness" : @(0.015313), @"contrast" : @(1.081875)}
			  };
	
	myth = @{
			 @"std" : @{@"saturation" : @(1.020000), @"brightness" : @(0.000000), @"contrast" : @(1.030000)}
			 };
	
	wonder = @{
			   @"walgdn" : @{@"saturation" : @(1.155687), @"brightness" : @(0.000000), @"contrast" : @(1.107188)},
			   @"dunge" : @{@"saturation" : @(1.100000), @"brightness" : @(0.000000), @"contrast" : @(1.033937)},
			   @"dormou" : @{@"saturation" : @(1.180000), @"brightness" : @(0.000000), @"contrast" : @(1.095312)},
			   @"music" : @{@"saturation" : @(1.100000), @"brightness" : @(0.000000), @"contrast" : @(1.033375)},
			   @"limb" : @{@"saturation" : @(1.100000), @"brightness" : @(0.000000), @"contrast" : @(1.032375)},
			   @"wood3" : @{@"saturation" : @(1.100000), @"brightness" : @(0.000000), @"contrast" : @(1.029750)},
			   @"std" : @{@"saturation" : @(1.100000), @"brightness" : @(0.000000), @"contrast" : @(1.000000)}
			   };
	
	jinxter = @{
				@"10" : @{@"saturation" : @(1.150000), @"brightness" : @(-0.112750), @"contrast" : @(1.077188)},
				@"2" : @{@"saturation" : @(1.150000), @"brightness" : @(-0.021875), @"contrast" : @(1.200000)},
				@"21" : @{@"saturation" : @(1.150000), @"brightness" : @(0.000000), @"contrast" : @(1.137625)},
				@"11" : @{@"saturation" : @(1.150000), @"brightness" : @(0.000000), @"contrast" : @(1.196437)},
				@"16" : @{@"saturation" : @(1.150000), @"brightness" : @(0.000000), @"contrast" : @(1.122125)},
				@"27" : @{@"saturation" : @(1.150000), @"brightness" : @(0.016313), @"contrast" : @(1.040000)},
				@"5" : @{@"saturation" : @(1.150000), @"brightness" : @(0.000000), @"contrast" : @(1.130375)},
				@"12" : @{@"saturation" : @(1.150000), @"brightness" : @(0.000000), @"contrast" : @(1.168062)},
				@"17" : @{@"saturation" : @(1.150000), @"brightness" : @(0.000000), @"contrast" : @(1.195938)},
				@"28" : @{@"saturation" : @(1.191250), @"brightness" : @(-0.036875), @"contrast" : @(1.073063)},
				@"0" : @{@"saturation" : @(1.150000), @"brightness" : @(-0.020375), @"contrast" : @(1.205188)},
				@"std" : @{@"saturation" : @(1.150000), @"brightness" : @(0.000000), @"contrast" : @(1.040000)},
				@"25" : @{@"saturation" : @(1.150000), @"brightness" : @(-0.027062), @"contrast" : @(1.106625)}
				};
	
	corrupt = @{
				@"std" : @{@"saturation" : @(1.150000), @"brightness" : @(0.000000), @"contrast" : @(1.000000)},
				@"4" : @{@"saturation" : @(1.150000), @"brightness" : @(0.000000), @"contrast" : @(1.019750)}
				};
	
	ccorrupt = @{
				 @"ccasin" : @{@"saturation" : @(1.150000), @"brightness" : @(0.000000), @"contrast" : @(1.020000)},
				 @"cstart" : @{@"saturation" : @(1.000000), @"brightness" : @(0.000000), @"contrast" : @(1.000000)},
				 @"cocorr" : @{@"saturation" : @(1.150000), @"brightness" : @(0.000000), @"contrast" : @(1.024625)},
				 @"std" : @{@"saturation" : @(1.150000), @"brightness" : @(0.000000), @"contrast" : @(1.000000)}
				 };
	
	cfish = @{
			  @"std" : @{@"saturation" : @(1.150000), @"brightness" : @(0.000000), @"contrast" : @(1.000000)},
			  @"fcorr" : @{@"saturation" : @(1.150000), @"brightness" : @(0.000000), @"contrast" : @(1.150000)},
			  @"frec" : @{@"saturation" : @(1.150000), @"brightness" : @(0.000000), @"contrast" : @(1.054000)}
			  };
	
	pawn = @{
			 @"14" : @{@"saturation" : @(1.316313), @"brightness" : @(0.000000), @"contrast" : @(1.040000)},
			 @"13" : @{@"saturation" : @(1.669875), @"brightness" : @(0.000000), @"contrast" : @(1.040000)},
			 @"21" : @{@"saturation" : @(1.100000), @"brightness" : @(-0.048062), @"contrast" : @(1.040000)},
			 @"12" : @{@"saturation" : @(1.100000), @"brightness" : @(0.000000), @"contrast" : @(1.081875)},
			 @"18" : @{@"saturation" : @(1.224500), @"brightness" : @(-0.038750), @"contrast" : @(1.071687)},
			 @"std" : @{@"saturation" : @(1.100000), @"brightness" : @(0.000000), @"contrast" : @(1.040000)}
			 };
	
	fish = @{
			 @"std" : @{@"saturation" : @(1.150000), @"brightness" : @(0.000000), @"contrast" : @(1.000000)}, 
			 @"11" : @{@"saturation" : @(1.150000), @"brightness" : @(0.000000), @"contrast" : @(1.150000)}, 
			 @"21" : @{@"saturation" : @(1.150000), @"brightness" : @(0.000000), @"contrast" : @(1.053563)}
			 };
	
	self.colCorDic = @{ @"pawn" : pawn, @"guild" : guild, @"jinxter" : jinxter, @"corrupt" : corrupt, @"fish" : fish, @"myth" : myth, @"cguild" : cguild, @"ccorrupt" : ccorrupt, @"cfish" : cfish, @"wonder" : wonder };

    return self;
}


- (NSString *)imageTitle
{
	NSString *image = self.currentlyShownImage;
	if (!image) { image = self.lastSavedImage; }
	return [NSString stringWithFormat:@"%@ | %@", selectedGame[1], image];
}


- (void)updateTextAttributes
{
	id template = self.currentTemplate;

	NSColor *colorTextUser = template[@"colorTextUser"];
	NSColor *colorTextGame = template[@"colorTextGame"];
	
	if ([template[@"hasCustomSpacing"] boolValue]) {
		
		NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
		[style setLineSpacing:[template[@"lineSpacing"] floatValue]];
		
		self.userAttributes = @{NSForegroundColorAttributeName: colorTextUser,
							   NSFontAttributeName: self.gameTextFont,
							   NSKernAttributeName: @([template[@"characterSpacing"] floatValue]),
							   NSParagraphStyleAttributeName: style,
							   @"MXUserEntry": @"1"};
		
		self.gameAttributes = @{NSForegroundColorAttributeName: colorTextGame,
							   NSFontAttributeName: self.gameTextFont,
							   NSKernAttributeName: @([template[@"characterSpacing"] floatValue]),
							   NSParagraphStyleAttributeName: style};
		
		[style release];
		
		self.textFieldAttributes = @{NSForegroundColorAttributeName: colorTextUser,
									 NSFontAttributeName: self.gameTextFont,
									 NSKernAttributeName: @([template[@"characterSpacing"] floatValue])};
		
	} else {
	
		self.userAttributes = @{NSForegroundColorAttributeName: colorTextUser,
							   NSFontAttributeName: self.gameTextFont,
							   @"MXUserEntry": @"1"};
		
		self.gameAttributes = @{NSForegroundColorAttributeName: colorTextGame,
							   NSFontAttributeName: self.gameTextFont};
		
		self.textFieldAttributes = @{NSForegroundColorAttributeName: colorTextUser,
									 NSFontAttributeName: self.gameTextFont};
	}
	
	[magneticTextView setSelectedTextAttributes:@{NSBackgroundColorAttributeName: [colorTextGame colorWithAlphaComponent:0.3]}];
	
	id scroller = [magneticScrollView verticalScroller];
	if ([scroller scrollerStyle] != NSScrollerStyleOverlay) {
		[scroller setNeedsDisplay:YES];
	}
}


- (void)changeDisplayAnim
{
	id template = self.currentTemplate;
	animMode = [template[@"displayAnim"] intValue];
	
	if (![template[@"displayPicture"] intValue]) {
		animMode = 0;
	}
	
	if (animMode) {
		[self possiblyContinueAnim];
	}
}


- (void)changeMaxContentWidth
{
	[limiterView setFrame:NSZeroRect];
    [magneticWindow invalidateCursorRectsForView:imageView];
}


- (void)removeTemplate:(NSNotification *)note
{
	isTemplateChanging = YES;
	
	NSUInteger selectionIndex = [arrayController selectionIndex];
	
	id templates = [arrayController arrangedObjects];
	NSUInteger templateCount = [templates count];
	
	if (templateCount > selectionIndex + 1) {
		arrayController.selectionIndex = selectionIndex + 1;
	} else {
		arrayController.selectionIndex = selectionIndex - 1;
	}
		
	if (templateCount < 3) {
		preferenceController.canRemove = NO;
	} else {
		preferenceController.canRemove = YES;
	}
	
	[arrayController removeObjectAtArrangedObjectIndex:selectionIndex];
	
	isTemplateChanging = NO;
	[self updateUI];
	[self saveTemplates];
}


- (void)selectTemplateObjectWithId:(NSUInteger)tid
{
	id objects = [arrayController arrangedObjects];
	int i = 0;
	for (id object in objects) {
		if ([object[@"id"] intValue] == tid) {
			arrayController.selectionIndex = i;
			return;
		}
		i ++;
	}
}


- (void)addTemplate:(NSNotification *)note
{
	isTemplateChanging = YES;
	
	NSMutableIndexSet *iset = [[NSMutableIndexSet alloc] init];
	for (id temp in _templatesArray) {
		[iset addIndex:[temp[@"id"] intValue]];
	}
	 
	int i=0;
	 
	while ([iset containsIndex:i]) {
		i++;
	}
	 
	[iset release];
	 
	NSMutableDictionary *template = [self.currentTemplate mutableCopy];
	template[@"id"] = @(i);
	
	NSString *oldName = template[@"name"];
	
	if (! ([oldName length] > 5 && [[oldName substringFromIndex:[oldName length] - 5] isEqualToString:@" copy"]) ) {
		template[@"name"] = [NSString stringWithFormat:@"%@ copy", oldName];

	}
	 
	[arrayController addObject:template];
	 
	[template release];
	
	[self selectTemplateObjectWithId:i];
	
	preferenceController.canRemove = YES;
	
	isTemplateChanging = NO;
	[self updateUI];
	[self saveTemplates];
}


- (NSSize)freeScaledImageSize
{
	NSSize originalSize = [imageView originalSize];
	
	if (NSEqualSizes(originalSize, NSZeroSize)) { return NSZeroSize; }
	
	float originalViewHeight = originalSize.height;
	
	BOOL updateNeeded = NO;
	
	float addHeightToView = [(MXImageView *)imageView addedPictureSize];
	if (![imageView isResizeDrag] && [self isImageFullSize]) {
		addHeightToView = 100000;
		updateNeeded = YES;
	}
	
	float addHeightToImage = addHeightToView * (originalSize.height / originalViewHeight);
	
	NSSize newSize = NSMakeSize(originalSize.width + (addHeightToImage / originalSize.height * originalSize.width) , originalSize.height + addHeightToImage);
		
	newSize.width = floorf(newSize.width);
	newSize.height = floorf(newSize.height);
	
	NSSize maxSize = [self maxImageSize];
	if (newSize.width > maxSize.width || newSize.height > maxSize.height) {
		if (updateNeeded) { [imageView setAddedPictureSize:maxSize.height - originalSize.height]; }
		return maxSize;
	}
	
	if (updateNeeded) { [imageView setAddedPictureSize:newSize.height - originalSize.height]; }
	return newSize;
}


- (void)makeFullsizeImage:(BOOL)newValue;
{
	(self.currentTemplate)[@"isPictureFullsize"] = @(newValue);
	[self saveTemplates];
}


- (BOOL)isImageFullSize
{
	return [(self.currentTemplate)[@"isPictureFullsize"] boolValue];
}


- (NSSize)maxImageSize
{
	NSSize imageViewSize = [imageView bounds].size;
	
	float maxImageWidth = imageViewSize.width;
	float maxImageHeight = maxImageWidth / 240 * 149; // based on the Pawn-first-image ratio
	
	float textViewMax = 200; // texview + borders
	float maxImageViewHeight = [[magneticWindow contentView] frame].size.height - [statusTextLeft frame].size.height - borderValue - textViewMax;

	if (maxImageHeight > maxImageViewHeight) {
		maxImageHeight = maxImageViewHeight;
		maxImageWidth = maxImageHeight / 149 * 240;
	}
	
	NSSize originalSize = [imageView originalSize];
	
	float newWidth = originalSize.width / originalSize.height * maxImageHeight;
	if (newWidth > maxImageWidth) {
		maxImageHeight = originalSize.height / originalSize.width * maxImageWidth;
	} else {
		maxImageWidth = newWidth;
	}

	return NSMakeSize(floorf(maxImageWidth), floorf(maxImageHeight));
}


- (void)clearGlyphIndex
{
	theGlyphIndex = NSUIntegerMax;
	glyphType = NO;
}


- (void)markLastVisibleGlyph
{
    NSLayoutManager *layoutManager = [magneticTextView layoutManager];
	NSTextContainer *textContainer = [magneticTextView textContainer];
	
	NSRect visibleRect = [magneticTextView visibleRect];
	
	NSPoint point = NSMakePoint(0, visibleRect.origin.y + visibleRect.size.height);
	
	NSPoint containerOrigin = [magneticTextView textContainerOrigin];
	
    point.y -= containerOrigin.y;
	
	NSUInteger glyphIndex = [layoutManager glyphIndexForPoint:point inTextContainer:textContainer];
	
	NSRect paragraphRect = [layoutManager boundingRectForGlyphRange:NSMakeRange(glyphIndex, 1) inTextContainer:textContainer];
	paragraphRect = NSIntegralRect(paragraphRect);
	
	glyphOverlap = -((visibleRect.origin.y + visibleRect.size.height) - paragraphRect.origin.y - paragraphRect.size.height);
	if (glyphOverlap < -(2 * containerOrigin.y)) { glyphOverlap = -(2 * containerOrigin.y); }
		
	theGlyphIndex = glyphIndex;
	glyphType = YES;
}


- (NSUInteger)theGlyphIndex
{
	return theGlyphIndex;
}


- (void)markLastGlyph
{
	theGlyphIndex = [[magneticTextView textStorage] length];
	glyphType = NO;
}


- (void)updateUIPossibly
{
	if (!isUpdateMissing) { return; }
	//isJumpingBlocked = YES;
	[self markLastVisibleGlyph];
	[self updateUI];
	//isJumpingBlocked = NO;
	isUpdateMissing = NO;
}


- (void)updateUI
{
	if (isTemplateChanging) { return; } // its called ONCE after all the changes are made
	
	NSRect contentViewFrame = [[magneticWindow contentView] frame];
	
	NSRect statusTextLeftFrame = [statusTextLeft frame];
	statusTextLeftFrame.size.height = stringHeight + 5;
	statusTextLeftFrame.origin.y = contentViewFrame.size.height - 12 - statusTextLeftFrame.size.height;
	
	NSRect statusTextRightFrame = [statusTextRight frame];
	statusTextRightFrame.size.height = stringHeight + 5;
	statusTextRightFrame.origin.y = contentViewFrame.size.height - 12 - statusTextRightFrame.size.height;

	if (!isMagneticWindows) {
		[statusTextLeft setFrame:statusTextLeftFrame];
		[statusTextRight setFrame:statusTextRightFrame];
		[statusTextLeft setHidden:NO];
		[statusTextRight setHidden:NO];
	} else {
		statusTextRightFrame.origin.y += (statusTextRightFrame.size.height - 5);
		[statusTextLeft setHidden:YES];
		[statusTextRight setHidden:YES];
	}
	
	NSRect imageViewRect = [imageView frame];
	
	float imageViewMarginTop = 10.0;
	float imageViewMarginBottom = 15.0;
	
	NSSize newSize = [self freeScaledImageSize];
	
	imageViewRect.size.height = newSize.height;
				
	[[imageView image] setSize:newSize];
			
	imageViewRect.origin.y = statusTextRightFrame.origin.y - imageViewRect.size.height;

	if (!currentImageSize) {
		
		[imageView setHidden:YES];
		
	} else {
		
		[imageView setHidden:NO];
		
		imageViewRect.origin.y -= imageViewMarginTop;
		
		[imageView setFrame:imageViewRect];
		[imageView setNeedsDisplay:YES];
		
	}

	
	float newBorder = borderValue;
	[magneticWindow setContentBorderThickness:newBorder forEdge:NSMinYEdge];
		
	NSRect magneticScrollViewRect = [magneticScrollView frame];
	magneticScrollViewRect.origin.y = newBorder;
	
	if (currentImageSize) {
		newBorder += imageViewMarginBottom;
	} else {
		if (isMagneticWindows) {
			newBorder -= imageViewMarginTop + 7;
		} else {
			newBorder += imageViewMarginBottom;
		}
	}
	
	magneticScrollViewRect.size.height = imageViewRect.origin.y - newBorder;
	
	int gradHeight = ceilf(stringHeight * 3);
	if (gradHeight > 50) { gradHeight = 50; }
	[magneticTextView setGradientHeight:gradHeight];
	
	[magneticScrollView setFrame:magneticScrollViewRect];
	
	[self jumpToGlyph];
}


- (void)changedFont:(NSNotification *)note
{
	self.gameTextFont = [note object];
	
	if ([self isLivePrefsUpdatingAllowed]) {
		[self changeFontForReal];
	} else {
		if (!self.isFontTimerStarted) {
			[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(changeFontForReal) userInfo:NULL repeats:NO];
			self.isFontTimerStarted = YES;
		}
	}
}


- (void)changeFontForReal
{
	NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
	if (now - lastFontChange > 1) {
		[self markLastVisibleGlyph];
	}
	lastFontChange = now;
	
	[self saveTemplates];
	[self updateFont];

	[self updateUI];
	
	if ([[magneticScrollView contentView] bounds].origin.y <= 0) {
		[magneticScrollView updateState];
	}
	
	self.isFontTimerStarted = NO;
}


- (void)updateStringHeight
{
	NSString *testString = @"String";
	NSDictionary *attributes = [[NSDictionary alloc] initWithObjectsAndKeys:self.gameTextFont, NSFontAttributeName, nil];
	stringHeight = roundf([testString sizeWithAttributes:attributes].height);
	[attributes release];
}


- (void)updateFont
{
	[self updateTextAttributes];
	
	[[magneticTextView textStorage] setFont:self.gameTextFont];
	[magneticTextView setNeedsDisplay:YES];
	
	[self refreshStatusAttributes];
	
	[self updateStringHeight];
}


- (void)changeColorBackground
{
	[self updateColorBackground];
	
	[magneticTextView setSelectedRanges:[magneticTextView selectedRanges]];
	
	[[magneticWindow contentView] setNeedsDisplay:YES];
}


- (void)updateColorBackground
{
	NSColor *color = (self.currentTemplate)[@"colorBackground"];
    
	if ([[color colorUsingColorSpaceName:@"NSCalibratedRGBColorSpace"] brightnessComponent] < 0.5) {
		[magneticScrollView setScrollerKnobStyle:NSScrollerKnobStyleLight];
	} else {
		[magneticScrollView setScrollerKnobStyle:NSScrollerKnobStyleDark];
	}
	
	[[magneticWindow contentView] setBackgroundColor:color];
	[magneticTextView setBackgroundColor:color];
    [magneticScrollView setBackgroundColor:color];
}


- (void)changeColorTextBothAndSpacing
{
	[self updateTextAttributes];
	[self refreshStatusAttributes];
	
	[self changeTextAttributesType:3 andSpacing:YES];
	
	[magneticTextView setSelectedRanges:[magneticTextView selectedRanges]];
}


- (void)changeColorTextBoth
{
	[self updateTextAttributes];
	[self refreshStatusAttributes];
	
	[self changeTextAttributesType:3 andSpacing:NO];
	
	[magneticTextView setSelectedRanges:[magneticTextView selectedRanges]];
}


- (void)changeColorTextGame
{
	[self updateTextAttributes];
	[self refreshStatusAttributes];

	[self changeTextAttributesType:2 andSpacing:NO];
	
	[magneticTextView setSelectedRanges:[magneticTextView selectedRanges]];
	
	self.isColorTimerStarted = NO;
}


- (void)changeColorTextUser
{
	[self updateTextAttributes];
	
	[self changeTextAttributesType:1 andSpacing:NO];
	
	[magneticTextView setSelectedRanges:[magneticTextView selectedRanges]];

	self.isColorTimerStarted = NO;
}


- (void)changeTextAttributesType:(int)textType andSpacing:(BOOL)changeSpacing
{
	NSDictionary *newUserAtts = self.userAttributes;
	NSDictionary *newGameAtts = self.gameAttributes;
	
	NSTextStorage *storage = [magneticTextView textStorage];
	NSUInteger length = [storage length];
	
	[magneticTextView setInsertionPointColor:newUserAtts[NSForegroundColorAttributeName]];
	
	if (!length) { return; } // color-changes before starting a game?
	
	NSRange range = NSMakeRange (0, 0);
	NSUInteger loc = 0;
	
	[storage beginEditing];
	
	while (loc < length) {
		
		NSRange range2 = NSMakeRange (loc, length - loc);
		
		if ([storage attribute:@"MXUserEntry" atIndex:loc longestEffectiveRange:&range inRange:range2]) {
			if (textType != 2) {
				[storage addAttributes:newUserAtts range:range];
			}
		} else if (textType != 1) {
			[storage addAttributes:newGameAtts range:range];
		}

		loc = range.location + range.length;
	}
	
	if (changeSpacing) {
		[self updateSpacing];
	}
	
	[storage endEditing];
}


- (void)updateSpacing
{
	id template = self.currentTemplate;
	
	NSTextStorage *storage = [magneticTextView textStorage];
	
	if ([template[@"hasCustomSpacing"] boolValue]) {
		
		NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
		[style setLineSpacing:[template[@"lineSpacing"] floatValue]];
		
		NSDictionary *newAtts = @{NSKernAttributeName: @([template[@"characterSpacing"] floatValue]),
								  NSParagraphStyleAttributeName: style};
		
		[style release];
		
		[storage addAttributes:newAtts range:NSMakeRange(0, [storage length])];
		
	} else {
		
		[storage removeAttribute:NSKernAttributeName range:NSMakeRange(0, [storage length])];
		[storage removeAttribute:NSParagraphStyleAttributeName range:NSMakeRange(0, [storage length])];
		
	}
}


- (void)changeCustomSpacing
{
	[self updateTextAttributes];
	[self refreshStatusAttributes];
	
	NSTextStorage *storage = [magneticTextView textStorage];
	[storage beginEditing];
	[self updateSpacing];
	[storage endEditing];

	[self updateUI];
	
	if ([[magneticScrollView contentView] bounds].origin.y <= 0) {
		[magneticScrollView updateState];
	}
}



- (NSMutableDictionary *)refreshCurrentTemplate
{
	NSArray *array = [arrayController arrangedObjects];
	if (![array count]) { self.currentTemplate = nil; }
	self.currentTemplate = array[[arrayController selectionIndex]];
	
	return self.currentTemplate;
}


- (void)saveTemplates
{
	NSData *templatesData = [NSArchiver archivedDataWithRootObject:self.templatesArray];
	[[NSUserDefaults standardUserDefaults] setObject:templatesData forKey:@"templatesData"];
}


- (void)updateLayoutType
{
	[[magneticTextView layoutManager] setAllowsNonContiguousLayout:[[NSUserDefaults standardUserDefaults] boolForKey:@"nonContiguousLayout"]];
}


- (void)awakeFromNib
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	[self updateLayoutType];
	[magneticTextView setEditable:YES];
	[magneticTextView setDelegate:magneticTextView];
	
	NSData *tData = [defaults objectForKey:@"templatesData"];
	NSArray *tArray = [NSUnarchiver unarchiveObjectWithData:tData];
	//NSLog(@"prefs = %@", tArray);
	self.templatesArray = [[tArray mutableCopy] autorelease];
	[self selectTemplateObjectWithId:[defaults integerForKey:@"templateSelected"]];
	
	NSSortDescriptor *theDesc = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(localizedStandardCompare:)];
	[arrayController setSortDescriptors:@[theDesc]];
	[theDesc release];

	[magneticTextView setTextContainerInset:NSMakeSize(0, 40)];
	
	[magneticWindow setContentBorderThickness:22.0 forEdge:NSMinYEdge];
	
	[self changeMaxContentWidth];
	[self changeTemplate];
	
	[magneticScrollView bind:@"isScrollingPrevented" toObject:imageView withKeyPath:@"isResizeDrag" options:nil];
	
	[lastCommandMenuItem setKeyEquivalent:[NSString stringWithFormat:@"%C", (unsigned short)NSUpArrowFunctionKey]];
	[nextCommandMenuItem setKeyEquivalent:[NSString stringWithFormat:@"%C", (unsigned short)NSDownArrowFunctionKey]];
	
	[viewMenu setAutoenablesItems:NO];
	
	[arrayController addObserver:self forKeyPath:@"selectionIndex" options:NSKeyValueObservingOptionNew context:nil];
	[arrayController addObserver:self forKeyPath:@"selection.colorBackground" options:NSKeyValueObservingOptionNew context:nil];
	[arrayController addObserver:self forKeyPath:@"selection.colorTextGame" options:NSKeyValueObservingOptionNew context:nil];
	[arrayController addObserver:self forKeyPath:@"selection.colorTextUser" options:NSKeyValueObservingOptionNew context:nil];
	[arrayController addObserver:self forKeyPath:@"selection.maxContentWidth" options:NSKeyValueObservingOptionNew context:nil];
	[arrayController addObserver:self forKeyPath:@"selection.hasCustomSpacing" options:NSKeyValueObservingOptionNew context:nil];
	[arrayController addObserver:self forKeyPath:@"selection.characterSpacing" options:NSKeyValueObservingOptionNew context:nil];
	[arrayController addObserver:self forKeyPath:@"selection.lineSpacing" options:NSKeyValueObservingOptionNew context:nil];
	[arrayController addObserver:self forKeyPath:@"selection.displayPicture" options:NSKeyValueObservingOptionNew context:nil];
	[arrayController addObserver:self forKeyPath:@"selection.use8BitGraphics" options:NSKeyValueObservingOptionNew context:nil];
	[arrayController addObserver:self forKeyPath:@"selection.displayAnim" options:NSKeyValueObservingOptionNew context:nil];
	[arrayController addObserver:self forKeyPath:@"selection.name" options:NSKeyValueObservingOptionNew context:nil];
}


- (BOOL)isLivePrefsUpdatingAllowed
{
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"nonContiguousLayout"] || [[magneticTextView textStorage] length] < 100000) {
		return YES;
	}
	
	return NO;
}


- (void)firePossiblyMissingSelector
{
	if (missingPrefsUpdate) {
		[self performSelector:missingPrefsUpdate];
		missingPrefsUpdate = nil;
	}
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{	
	if ([keyPath isEqualToString:@"selectionIndex"]) {
		
		id template = [self refreshCurrentTemplate];
		
		if ([[NSUserDefaults standardUserDefaults] integerForKey:@"templateSelected"] == [template[@"id"] intValue]) { // prevents multiple updates e.g. when adding new template
			return;
		}
		
		[preferenceController endTemplateNaming:self];
		[self markLastVisibleGlyph];
		[self changeTemplate];
	} else if (isTemplateChanging) {
		return;
	} else if ([keyPath isEqualToString:@"selection.colorBackground"]) {
		[self saveTemplates];
		[self changeColorBackground];
	} else if ([keyPath isEqualToString:@"selection.colorTextGame"]) {
		[self saveTemplates];
		
		if ([self isLivePrefsUpdatingAllowed]) {
			[self changeColorTextGame];
		} else {
			if (!self.isColorTimerStarted) {
				[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(changeColorTextGame) userInfo:NULL repeats:NO];
				self.isColorTimerStarted = YES;
			}
		}
		
	} else if ([keyPath isEqualToString:@"selection.colorTextUser"]) {
		[self saveTemplates];
		
		if ([self isLivePrefsUpdatingAllowed]) {
			[self changeColorTextUser];
		} else {
			if (!self.isColorTimerStarted) {
				[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(changeColorTextUser) userInfo:NULL repeats:NO];
				self.isColorTimerStarted = YES;
			}
		}
		
	} else if ([keyPath isEqualToString:@"selection.maxContentWidth"]) {
		[self saveTemplates];
		
		if ([self isLivePrefsUpdatingAllowed]) {
			[self changeMaxContentWidth];
		} else {
			missingPrefsUpdate = @selector(changeMaxContentWidth);
		}
		
	} else if ([keyPath isEqualToString:@"selection.characterSpacing"] || [keyPath isEqualToString:@"selection.lineSpacing"]) {
		[self saveTemplates];
		
		if ([self isLivePrefsUpdatingAllowed]) {
			[self changeCustomSpacing];
		} else {
			missingPrefsUpdate = @selector(changeCustomSpacing);
		}
		
	} else if ([keyPath isEqualToString:@"selection.hasCustomSpacing"]) {
		[self markLastVisibleGlyph];
		[self saveTemplates];
		[self changeCustomSpacing];
	} else if ([keyPath isEqualToString:@"selection.displayPicture"] || [keyPath isEqualToString:@"selection.use8BitGraphics"]) {
		[self saveTemplates];
		[self markLastVisibleGlyph];
		[self changeDisplayPicture];
	} else if ([keyPath isEqualToString:@"selection.displayAnim"]) {
		[self saveTemplates];
		[self changeDisplayAnim];
	} else if ([keyPath isEqualToString:@"selection.name"]) {
		[preferenceController endTemplateNaming:self];
	} else if ([keyPath isEqualToString:@"wonderlandMusic"]) {
		if (![[NSUserDefaults standardUserDefaults] integerForKey:@"wonderlandMusic"] && selectedGame) { [gameSelectController stopQtSound]; }
	} else if ([keyPath isEqualToString:@"imageOptimizations"]) {
		[self updateImage];
	} else if ([keyPath isEqualToString:@"nonContiguousLayout"]) {
		[self updateLayoutType];
	}
}


- (void)enableViewMenu
{
	for (NSMenuItem *item in [viewMenu itemArray]) {
		[item setEnabled:YES];
	}
}


- (void)disableViewMenu
{
	for (NSMenuItem *item in [viewMenu itemArray]) {
		[item setEnabled:NO];
	}
}


- (void)updateViewMenu
{
	[viewMenu removeAllItems];
	id templates = [arrayController arrangedObjects];
	NSUInteger selectionIndex = [arrayController selectionIndex];

	int i = 0;
	for (id template in templates) {
		NSString *equiv = nil;
		
		if (i < 9) {
			equiv = [NSString stringWithFormat:@"%i", i + 1];
		} else if (i == 9) {
			equiv = @"0";
		} else {
			equiv = @"";
		}

		NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:template[@"name"] action:@selector(quickSelectTemplate:) keyEquivalent:equiv];
		[item setTag:i];
		
		if (i == selectionIndex) {
			[item setState:NSOnState];
		}
		
		[viewMenu addItem:item];
		[item release];
		
		i++;
	}
	
	[self enableViewMenu];
}


- (void)changeToTemplateWithIndex:(int)index
{
	if (index == arrayController.selectionIndex) { return; }
	
	isTemplateChanging = YES;
	arrayController.selectionIndex = index;
	isTemplateChanging = NO;
	[magneticTextView resetNuller];
	[self updateUI];
}


- (IBAction)quickSelectTemplate:(id)sender
{
	[self changeToTemplateWithIndex:(int)[sender tag]];
}


- (void)prefChangedTemplate:(NSNotification *)note
{
	[self changeToTemplateWithIndex:[[note object] intValue]];
}


- (void)changeTemplate
{
	id template = [self refreshCurrentTemplate];
	
	[[NSUserDefaults standardUserDefaults] setInteger:[template[@"id"] intValue] forKey:@"templateSelected"];
	
	NSFont *gameFont = [NSFont fontWithName:template[@"gameFontName"] size:[template[@"gameFontPointSize"] doubleValue]];
	
	if (!gameFont) {
		gameFont = [NSFont userFontOfSize:12.0];
	}
	
	// possible "-updateUI"s in the following sections will NOT be executed (because of "isTemplateChanging = YES") ... there is ONE call after all this
	
	self.gameTextFont = gameFont;
	[self updateStringHeight];
		
	[self updateColorBackground];
	[self changeColorTextBothAndSpacing];

	[self changeMaxContentWidth];
	
	[self updateDisplayPicture];
	[self changeDisplayAnim];
	
	[[magneticWindow contentView] setNeedsDisplay:YES];
	
	[self updateViewMenu];
}


- (void)changeTextAtImport
{
	[self changeColorTextBoth];
}


- (void)changeFreePictureSize
{
	[self markLastVisibleGlyph];
	(self.currentTemplate)[@"addedPictureSize"] = @([imageView addedPictureSize]);
	[self saveTemplates];
	[self updateUI];
	
	if ([[magneticScrollView contentView] bounds].origin.y <= 0) {
		[magneticScrollView updateState];
	}
}


- (void)changeDisplayPicture
{
	[self updateDisplayPicture];
	[self changeDisplayAnim];
	[self updateUI];
}


- (IBAction)updateUse8BitGraphics:(id)sender
{
	if ([self.currentTemplate[@"use8BitGraphics"] boolValue]) {
		(self.currentTemplate)[@"use8BitGraphics"] = @NO;
	} else {
		(self.currentTemplate)[@"use8BitGraphics"] = @YES;
	}
}


- (void)updateDisplayPicture
{
	id template = self.currentTemplate;
	
	if (isMagneticWindows && hasGraphics && currentImageSize == 0) {
	
		currentImageSize = [template[@"displayPicture"] intValue];
		
		if (currentImageSize != 0 && [self orderPossible]) {
			[self addHiddenOrder:@"Graphics off"];
			[self addHiddenOrder:@"Graphics on"];
		}
	
	} else {
	
		currentImageSize = [template[@"displayPicture"] intValue];
	
	}
	
	if ([self.currentTemplate[@"use8BitGraphics"] boolValue]) {
		if (!self.use8BitGraphics) {
			self.use8BitGraphics = YES;
			[self updateImage];
			[fileSelectionController updateContent];
		}
	} else {
		if (self.use8BitGraphics) {
			self.use8BitGraphics = NO;
			[self updateImage];
			[fileSelectionController updateContent];
		}
	}
	
	if (currentImageSize == 1) { // x1 and x2 are gone ... converting old settings
		(self.currentTemplate)[@"displayPicture"] = @3;
		(self.currentTemplate)[@"addedPictureSize"] = @0;
		(self.currentTemplate)[@"isPictureFullsize"] = @0;
		[self saveTemplates];
		currentImageSize = 3;
	} else if (currentImageSize == 2) {
		(self.currentTemplate)[@"displayPicture"] = @3;
		(self.currentTemplate)[@"addedPictureSize"] = @150;
		(self.currentTemplate)[@"isPictureFullsize"] = @0;
		[self saveTemplates];
		currentImageSize = 3;
	} else if (currentImageSize > 3) {
		currentImageSize = 3;
	}
	
	if (!hasGraphics) { currentImageSize = 0; }
	
	if (currentImageSize) {
		[imageView setAddedPictureSize:[template[@"addedPictureSize"] floatValue]];
	} else {
		[imageView setAddedPictureSize:0.0];
	}
	
	[self togglePicSize];
}


- (void)togglePicSize
{
	[self togglePicSize:0];
}


- (void)togglePicSize:(int)picNumber
{
	NSSize newSize;
	
	if ([animPicArray count]) {
		
		if (currentImageSize) {
			
			NSImage *currentImage = [animPicArray[picNumber] copy];
			[imageView setImage:currentImage];
			newSize = [currentImage size];
			[currentImage release];
			
		} else {
			
			newSize = NSZeroSize;
			
		}
		
	} else {
		
		newSize = NSZeroSize;
		
	}
	
	BOOL isImageResizeBlocked = self.isImageResizeBlocked;
	
	if (!NSEqualSizes(newSize, [imageView originalSize]) && !isImageResizeBlocked) {
		[imageView setOriginalSize:newSize];
		[self updateUI];
		
		[magneticWindow invalidateCursorRectsForView:imageView];
		
	} else {
		
		if (isImageResizeBlocked) {
			isUpdateMissing = YES;
			[imageView setOriginalSize:newSize];
		}
		
		[[imageView image] setSize:[self freeScaledImageSize]];
		[imageView setNeedsDisplay:YES];
		
		if (isTemplateChanging || invalidatedCursorRectsWithImageSize != currentImageSize) {
			[magneticWindow invalidateCursorRectsForView:imageView];
			invalidatedCursorRectsWithImageSize = currentImageSize;
		}
		
	}
}

	
- (void)enterQuickAnswerWithString:(NSString *)answer
{
	NSString *order = [[answer uppercaseString] substringToIndex:1];
	
	if (self.quickAnswerType == 1 && ![order isEqualToString:@"Q"] && ![order isEqualToString:@"R"] && ![order isEqualToString:@"L"]) {
		order = @"R";
	} else if (self.quickAnswerType == 2 && ![order isEqualToString:@"Q"] && ![order isEqualToString:@"R"]) {
		order = @"R";
	} else if (self.quickAnswerType == 3 && ![order isEqualToString:@"Y"] && ![order isEqualToString:@"N"]) {
		order = @"N";
	}
	
	[self enterOrderString:order];
}


- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	SEL action = [menuItem action];
	BOOL isSheetOpen = [self isAlertOpen];
	
	if (action == @selector(lastCommand:)) {
		if ([orderHistory count] == 0 || currentOrder == 0 || isSheetOpen || self.quickAnswerType || ![magneticTextView isTypingAllowed]) return NO;
		else return YES;
	} else if (action == @selector(nextCommand:)) {
		if ([orderHistory count] < 2 || currentOrder == [orderHistory count] - 1 || currentOrder == -1 || isSheetOpen || self.quickAnswerType || ![magneticTextView isTypingAllowed]) return NO;
		else return YES;
	} else if (action == @selector(undoCommand:)) {
		if ([orderHistory count] == 0 || ![self undoPossible]) return NO;
		else return YES;
	} else if (action == @selector(openScript:)) {
		if (![selectedGame count] || isSheetOpen) return NO;
		else return YES;
	} else if (action == @selector(saveAsScript:)) {
		if (![selectedGame count] || [ordersForScript count] == 0 || isSheetOpen) return NO;
		else return YES;
	} else if (action == @selector(openFile:)) {
		if (isSheetOpen) return NO;
		return YES;
	} else if (action == @selector(saveFile:)) {
		if (![selectedGame count] || [orderHistory count] == 0 || ![magneticWindow isDocumentEdited] || isSheetOpen) return NO;
		else return YES;
	} else if (action == @selector(showHints:)) {
		if (![selectedGame count] || isSheetOpen) return NO;
		else return YES;
	} else if (action == @selector(trashFile:)) {
		if (fileSelectionController && [fileSelectionController isTrashingPossible]) return YES;
		else return NO;
	} else if (action == @selector(updateUse8BitGraphics:)) {
		if (self.use8BitGraphics) {
			[menuItem setState:NSOnState];
		} else {
			[menuItem setState:NSOffState];
		}
		if (isMagneticWindows) {
			return NO;
		} else {
			return YES;
		}
	} else return YES;
}


- (IBAction)lastCommand:(id)sender
{
	if (currentOrder == -1) { currentOrder = [orderHistory count]; }
	
	if (currentOrder == 1 && [orderHistory count] == 1) {
		
		[magneticTextView replaceOrder:orderHistory[0]];
		
	} else if (currentOrder > 0) {
		currentOrder --;
		
		[magneticTextView replaceOrder:orderHistory[currentOrder]];

	}
}


- (IBAction)nextCommand:(id)sender
{
	if (currentOrder == -1) { currentOrder = [orderHistory count]; }
	
	if (currentOrder < [orderHistory count] - 1) {
		currentOrder ++;
		
		[magneticTextView replaceOrder:orderHistory[currentOrder]];

	}
}


- (IBAction)undoCommand:(id)sender
{
	[self clearGlyphIndex];
	[self addSilencedOrder:@"#undo"];
}


- (IBAction)showPreferencePanel:(id)sender
{
	BOOL isFirstTime = NO;
	if (!preferenceController) {
		preferenceController = [[PreferenceController alloc] init];
		isFirstTime = YES;
	}
	
	[preferenceController showWindow:self];
	
	if (isFirstTime) {
		
		NSArrayController *nac = [preferenceController arrayController];
		
		NSSortDescriptor *theDesc = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(localizedStandardCompare:)];
		[nac setSortDescriptors:@[theDesc]];
		[theDesc release];
		
		[nac addObserver:preferenceController forKeyPath:@"selectionIndex" options:NSKeyValueObservingOptionNew context:nil];
		
		[nac bind:@"contentArray" toObject:arrayController withKeyPath:@"arrangedObjects" options:nil];
		
		[nac setSelectionIndex:[arrayController selectionIndex]];
		
		[arrayController bind:@"selectionIndex" toObject:nac withKeyPath:@"selectionIndex" options:nil];
		[nac bind:@"selectionIndex" toObject:arrayController withKeyPath:@"selectionIndex" options:nil];
		
		if ([[arrayController arrangedObjects] count] < 2) {
			preferenceController.canRemove = NO;
		} else {
			preferenceController.canRemove = YES;
		}
	}
}


- (void)mainNoUserProgressAfterLoadNSave
{
	[magneticWindow setDocumentEdited:NO];
}


- (void)mainNoUserProgress
{
	[magneticWindow setDocumentEdited:NO];
	[ordersForScript removeAllIndexes];
}


- (void)noUserProgress
{
	[self performSelectorOnMainThread:@selector(mainNoUserProgress) withObject:NULL waitUntilDone:YES];
}


void noUserProgressAfterLoadNSave(void)
{
    NSAutoreleasePool *localPool;
    localPool = [[NSAutoreleasePool alloc] init];  
    [[MagneticController sharedController] mainNoUserProgressAfterLoadNSave];
    [localPool release];
}



- (void)enableMore
{
	[magneticTextView setIsMore:YES];
	[magneticTextView setEditable:NO];
}



- (void)disableMore
{
	if (![magneticTextView isMore]) {
		return;
	}
	
	[magneticTextView setIsMore:NO];
	[magneticTextView setEditable:YES];
	[self updateFirstResponder];
}



- (BOOL)scrollMore
{
	if ([magneticTextView isMore]) {
		[magneticScrollView pageDown:self];
		return YES;
	}
	
	return NO;
}


- (void)jumpToGlyph
{
	if (isJumpingBlocked) { return; }
	if (theGlyphIndex == NSUIntegerMax || self.isScriptPlaying) {
		
		// whats going one here? ... this DOUBLE-scroll-solution was necessary to make sure its scrolled down correctly in EVERY case ... hmmm ... whatever ...
		
		[magneticTextView scrollRangeToVisible:NSMakeRange([[magneticTextView string] length], 0)];
		
		id clipView = [magneticScrollView contentView];
		
		NSRect contentBounds = [clipView bounds];
		NSRect documentBounds = [[magneticScrollView documentView] bounds];
			
		NSPoint targetPoint = NSZeroPoint;
		targetPoint.y = documentBounds.size.height - contentBounds.size.height;
			
		[clipView scrollToPoint:targetPoint];
		
	} else if (glyphType) {
		[self scrollFixingBottom];
	} else {
		[self scrollFixingTop];
	}
}


- (void)scrollFixingBottom
{
	NSRect paragraphRect = [[magneticTextView layoutManager] boundingRectForGlyphRange:NSMakeRange(theGlyphIndex, 1) inTextContainer:[magneticTextView textContainer]];
	paragraphRect = NSIntegralRect(paragraphRect);

	NSPoint testPoint = paragraphRect.origin;
	testPoint.y -= [magneticTextView visibleRect].size.height - paragraphRect.size.height + glyphOverlap;
	if (testPoint.y < 0) { testPoint.y = 0; }
	testPoint.x = 0;
	
	[[magneticScrollView contentView] scrollToPoint:testPoint];
}


- (void)scrollFixingTop
{
	NSRect paragraphRect = [[magneticTextView layoutManager] boundingRectForGlyphRange:NSMakeRange(theGlyphIndex, 1) inTextContainer:[magneticTextView textContainer]];
	paragraphRect = NSIntegralRect(paragraphRect);

	NSPoint testPoint = paragraphRect.origin;
	testPoint.x = 0;
	
	NSPoint containerOrigin = [magneticTextView textContainerOrigin];
	testPoint.y += containerOrigin.y;
	
	NSRect bounds = [magneticTextView bounds];
	NSRect visibleRect = [magneticTextView visibleRect];
	
	if (testPoint.y == containerOrigin.y) { // no scrolling on gamestart
		testPoint.y = 0;
	} else {
		testPoint.y -= ceilf([magneticTextView gradientHeight] / 2);
	}
	
	if (testPoint.y > bounds.size.height - visibleRect.size.height) {
		testPoint.y = bounds.size.height - visibleRect.size.height;
	}
	else if (testPoint.y + visibleRect.size.height < bounds.size.height) {
		[self enableMore];
	}
		
	[[magneticScrollView contentView] scrollToPoint:testPoint];
}


- (void)changeTextAndScroll:(NSString *)text
{
	[self performSelectorOnMainThread:@selector(mainChangeTextAndScroll:) withObject:text waitUntilDone:YES];
}


- (void)mainChangeTextAndScroll:(NSString *)text
{
	[self clearGlyphIndex];
	[self mainChangeText:text];
}


- (void)changeText:(NSString *)text
{
	[self performSelectorOnMainThread:@selector(mainChangeText:) withObject:text waitUntilDone:YES];
}


- (void)mainChangeText:(NSString *)text
{
	if (![text length] || self.hideNextOrder) { return; }
	
	if ([[magneticTextView textStorage] length] == 0) {
		if ([text characterAtIndex:0] == '\n' || [text isEqualToString:@" \n"]) {
			return;
		}
	}
	
	if (([text isEqualToString:@">"] || [text isEqualToString:@"]"]) && workaroundTextType == 2) { [self mainCompleteUglyRange]; }
	
	NSMutableAttributedString *output = [[NSMutableAttributedString alloc] initWithString:text];
	[output addAttributes:self.gameAttributes range:NSMakeRange(0, [text length])];
	
    [[magneticTextView textStorage] appendAttributedString:output];
	[self jumpToGlyph];
	[magneticTextView setNeedsDisplay:YES];
	
	[output release];

	if ([text rangeOfString:@"Magnetic Scrolls Ltd."].location != NSNotFound || [text rangeOfString:@"(C) Magnetic Scrolls 19"].location != NSNotFound) { // check for restart - i found no other way to do this
		
		if (!self.isScriptPlaying) {
			[self mainNoUserProgress];
		}
		
		if (theGlyphIndex > 0 && theGlyphIndex < NSUIntegerMax) { // its NOT the first game launch but an "ingame restart"			
			id textStorage = [magneticTextView textStorage];
			[textStorage replaceCharactersInRange:NSMakeRange(0, theGlyphIndex + 1) withString:@""];
			
			while ([[textStorage string] characterAtIndex:0] == '\n' || [[textStorage string] characterAtIndex:0] == ' ') {
				[textStorage replaceCharactersInRange:NSMakeRange(0, 1) withString:@""];
			}
			
			if (!self.isScriptPlaying) {
				[orderHistory removeAllObjects];
				[ordersForScript removeAllIndexes];
				
				theGlyphIndex = 0;
				
				[uglyRanges removeAllObjects];
				[self clearImageHistory];
			}
			
		}
		
		if (isMagneticWindows) {
            [gameSelectController stopQtSound];
			[orderBuffer insertObject:@"Graphics on" atIndex:0];
			[self transferOrder];
		}
	}
	
	if ([text rangeOfString:@"The Prawn - Copyright (c) 1985"].location != NSNotFound) {
		isFishTerminalException = YES;
	}
	
	if ([text rangeOfString:@"[Previous turn undone.]"].location != NSNotFound) {
		[ordersForScript removeIndex:[ordersForScript lastIndex]];
	}
	
	isPawnLoadException = NO;
	
	if ([text rangeOfString:@"(q/r/l)"].location != NSNotFound) {
		isPawnLoadException = YES;
		self.quickAnswerType = 1;
	} else if ([text rangeOfString:@"(q/r)"].location != NSNotFound) {
		self.quickAnswerType = 2;
	} else if ([text rangeOfString:@"(y/n)"].location != NSNotFound || [text rangeOfString:@"Yes or No?"].location != NSNotFound) {
		self.quickAnswerType = 3;
	} else {
		self.quickAnswerType = 0;
	}
}


OSStatus changeText(CFStringRef message)
{
    NSAutoreleasePool *localPool;
    localPool = [[NSAutoreleasePool alloc] init];
    [[MagneticController sharedController] changeText:(NSString *)message];
	CFRelease(message);
    [localPool release];
    return noErr;
}


- (NSString *)cleanedStatusString:(NSString *)string
{
	string = [string stringByReplacingOccurrencesOfString:@"  " withString:@" "];
	NSArray *statusParts = [[string componentsSeparatedByString:@"\n"][0] componentsSeparatedByString:@"\t"];
	NSCharacterSet *cSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	return [NSString stringWithFormat:@"%@\t%@", [statusParts[0] stringByTrimmingCharactersInSet:cSet], [statusParts[1] stringByTrimmingCharactersInSet:cSet]];
}


- (void)changeStatus:(NSString *)text
{
	[self performSelectorOnMainThread:@selector(mainChangeStatus:) withObject:[self cleanedStatusString:text] waitUntilDone:YES];
}


- (void)saveStatus
{
	NSString *text = [NSString stringWithFormat:@"%@\t%@", [statusTextLeft stringValue], [statusTextRight stringValue]];
	
	NSUInteger length = [[[magneticTextView textStorage] string] length];
	NSRange statusRange = NSMakeRange(statusRangeLocation, length  - statusRangeLocation);
	statusRangeLocation = length;
	
	if (!self.latestStatus) { self.latestStatus = text; }
	[[magneticTextView textStorage] addAttribute:@"MXStatusShown" value:self.latestStatus range:statusRange];
	
	self.currentlyShownStatus = text;
	self.latestStatus = text;
}


- (void)mainChangeStatus:(NSString *)text
{
	if (workaroundTextHide > 50 || isMagneticWindows) { return; }
	
	NSUInteger length = [[[magneticTextView textStorage] string] length];
	NSRange statusRange = NSMakeRange(statusRangeLocation, length  - statusRangeLocation);
	statusRangeLocation = length;
	
	if (!self.latestStatus) { self.latestStatus = text; }
	[[magneticTextView textStorage] addAttribute:@"MXStatusShown" value:self.latestStatus range:statusRange];
		
	[self changeStatusWithText:text];
	
	self.currentlyShownStatus = text;
	self.latestStatus = text;
}


- (void)mainRestoreStatus:(NSString *)text
{
	if (workaroundTextHide > 50 || isMagneticWindows) { return; }

	if (!text) { text = self.latestStatus; }
	if (!text || [text isEqualToString:self.currentlyShownStatus]) { return; }
		
	[self changeStatusWithText:text];
	
	self.currentlyShownStatus = text;
}


- (void)changeStatusWithText:(NSString *)text
{
	NSArray *statusParts = [text componentsSeparatedByString:@"\t"];
	
	NSMutableAttributedString *output1 = [[NSMutableAttributedString alloc] initWithString:statusParts[0]];
	[output1 addAttributes:self.gameAttributes range:NSMakeRange(0, [output1 length])];
	[output1 removeAttribute:NSParagraphStyleAttributeName range:NSMakeRange(0, [output1 length])];
	
	NSMutableAttributedString *output2 = [[NSMutableAttributedString alloc] initWithString:statusParts[1]];
	[output2 addAttributes:self.gameAttributes range:NSMakeRange(0, [output2 length])];
	[output2 removeAttribute:NSParagraphStyleAttributeName range:NSMakeRange(0, [output2 length])];
	
	NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
	[style setAlignment:NSRightTextAlignment];
	[output2 addAttribute:NSParagraphStyleAttributeName value:style range:NSMakeRange(0, [output2 length])];
	[style release];
	
	[statusTextLeft setAttributedStringValue:output1];
	[statusTextRight setAttributedStringValue:output2];
	
	[output1 release];
	[output2 release];
}


- (void)refreshStatusAttributes
{
	self.currentlyShownStatus = nil;
	[self mainRestoreStatus:[NSString stringWithFormat:@"%@\t%@", [statusTextLeft stringValue], [statusTextRight stringValue]]];
}


OSStatus changeStatus(CFStringRef message)
{
    NSAutoreleasePool *localPool;
    localPool = [[NSAutoreleasePool alloc] init];        
    [[MagneticController sharedController] changeStatus:(NSString *)message];
	CFRelease(message);
    [localPool release];
    return noErr;
}


- (void)startGame:(NSArray *)aGame from:(id)sender;
{
	isStartingGameComplete = NO;
	self.isScriptPlaying = NO;
	[self disableMore];

	selectedGame = [[NSArray alloc] initWithArray:aGame];
		
	if ([selectedGame count] == 4) {
		isMagneticWindows = YES;
		if (self.isLoadAtGameStart) { workaroundTextHideMW = 100; }
	} else {
		isMagneticWindows = NO;
		if (self.isLoadAtGameStart) { workaroundTextHide = 100; }
	}
	
	[magneticWindow setTitle:[@"magnetiX - " stringByAppendingString:selectedGame[1]]];
	
	[magneticWindow makeKeyAndOrderFront:self];
			
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	if ([defaults boolForKey:@"isFullscreen"] && !(([magneticWindow styleMask] & NSFullScreenWindowMask) == NSFullScreenWindowMask)) {
		[magneticWindow toggleFullScreen:self];
		return; // completeStartingGame in windowDidEnterFullscreen
	}

	[self completeStartingGame];
}


- (NSArray *)selectedGame
{
	return selectedGame;
}


- (void)completeStartingGame
{
	if (self.isAppFullyStarted) { // double clicking a saved-game to start the app made problems on lion, otherwise
		if ([selectGameWindow isMiniaturized]) {
			[selectGameWindow orderBack:self];
		}
    	[selectGameWindow orderOut:nil];
    }

	if (self.isLoadAtGameStart) {
		[self clearGlyphIndex];
		self.isLoadAtGameStart = NO;
	} else {
		[self markLastGlyph];
	}
	
	[self updateUI];
	
    [self updateFirstResponder];

	isStartingGameComplete = YES;
	
	[NSThread detachNewThreadSelector:@selector(threadStart) toTarget:self withObject:NULL];
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.isAppFullyStarted = YES;
    
    if ([magneticWindow isKeyWindow]) {
        [selectGameWindow orderOut:self];
    } else {
        [selectGameWindow makeKeyAndOrderFront:self]; // X.11b1
		[gameSelectController playThemeIfNeeded];
	}
}


- (int)loadGame:(unsigned char *)ptr ofSize:(unsigned short)size
{
	NSData *beforeLoad = [NSData dataWithBytes:ptr length:size];
	NSValue *theValue = [NSValue valueWithPointer:ptr];
	
	[self performSelectorOnMainThread:@selector(mainLoadGame:) withObject:theValue waitUntilDone:YES];
	[loadSaveMWLock lock];
	[loadSaveMWLock unlock];

	NSData *afterLoad = [NSData dataWithBytes:ptr length:size];
	if ([beforeLoad isEqualToData:afterLoad]) {
		return 1; // load NOT successful
	} else {
		[self mainNoUserProgressAfterLoadNSave];
        [gameSelectController stopQtSound];
		return 0; // load succcessful
	}
}


- (void)showLoadWithProgressPanel
{
	NSAlert *theAlert = [NSAlert alertWithMessageText:@"Unsaved Progress!"
										defaultButton:@"Load New Game"
									  alternateButton:nil
										  otherButton:@"Cancel"
							informativeTextWithFormat:@"Do you want to load another game and dismiss your current progress?"];
	
	[theAlert beginSheetModalForWindow:magneticWindow modalDelegate:self didEndSelector:@selector(progressAlertDidEnd:returnCode:contextInfo:) contextInfo:nil];
	
	[NSApp runModalForWindow:[theAlert window]];
}


- (void)progressAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(id)contextInfo
{
	if (returnCode == NSAlertDefaultReturn) {
		loadWithProgress = 1;
	}
	
	[NSApp stopModal];
}


- (void)mainLoadGame:(NSValue *)theValue
{
	[loadSaveMWLock lock];
	
	if ([magneticWindow isDocumentEdited]) {
		[self showLoadWithProgressPanel];
	}
	
	if (![magneticWindow isDocumentEdited] || loadWithProgress) {
		
		unsigned char *ptr = [theValue pointerValue];
		loadWithProgress = 0;
		
		if (self.externalLoad) {
			
			if (![self completedMWLoadToPtr:ptr fromPath:self.externalLoad]) {
				[self MWloadError];
			}
			
			self.externalLoad = nil;
			[loadSaveMWLock unlock];
			
		} else {
			
			if ([[NSUserDefaults standardUserDefaults] boolForKey:@"useIngameFileManagement"]) {
				self.mwLoadGameValue = theValue;
				[self openLoadSheet];
				return;
			}
			
			NSOpenPanel *openPanel = [NSOpenPanel openPanel];
			[openPanel setAllowedFileTypes:@[selectedGame[2]]];
			[openPanel beginSheetModalForWindow:[NSApp mainWindow] completionHandler:^(NSInteger result) {
				
				if (NSFileHandlingPanelOKButton == result) {
					
					if (![self completedMWLoadToPtr:ptr fromPath:[[openPanel URL] path]]) {
						[self MWloadError];
					}
					
				} else {
					
					[self clearPromptAfterCancelingSaveOrLoad];
					
				}
				
				[loadSaveMWLock unlock];
				
			}];

		}
		
	} else {
		
		[self clearPromptAfterCancelingSaveOrLoad];
		[loadSaveMWLock unlock];
		
	}
}


- (void)MWloadError
{
	uglyLocation = [[[magneticTextView textStorage] string] length] - [magneticTextView editRange].length;
	[[MagneticController sharedController] processOrder:@"Load\n"];
	workaroundTextType = 2;
}


- (void)loadSheetClosedWithLoading:(NSString *)path
{
	if (![selectedGame count]) {
		
		self.externalLoad = path;
		[gameSelectController externalStart:self.externalLoad];
		
	} else if (isMagneticWindows) {
	
		if (path) {
			
			if (![self completedMWLoadToPtr:[self.mwLoadGameValue pointerValue] fromPath:path]) {
				[self MWloadError];
			}
						
		} else {
			
			[self clearPromptAfterCancelingSaveOrLoad];
			
		}
		
		self.mwLoadGameValue = nil;
		[loadSaveMWLock unlock];
		
	} else {
	
		if (path) {
			
			[self loadNONMagneticWindowsWithPath:path];
			
		} else {

			[self clearPromptAfterCancelingSaveOrLoad];
			
		}
		
	}
}


- (BOOL)completedMWLoadToPtr:(unsigned char *)ptr fromPath:(NSString *)path
{
	NSString *subPath1 = [path stringByAppendingPathComponent:@"saveGame"];
	NSString *subPath2 = [path stringByAppendingPathComponent:@"currentData"];
	NSString *loadPath = nil;
	
	if ([[NSWorkspace sharedWorkspace] isFilePackageAtPath:path]) {
		
		NSFileManager *fileManager = [NSFileManager defaultManager];
		
		if (![fileManager fileExistsAtPath:subPath1] || ![fileManager fileExistsAtPath:subPath2]) {
			workaroundTextHideMW = 0;
			return NO;
		}
		
		[self mainLoadMiscDataAtPackagePath:path];
		isSavePackaged = YES;
		
		loadPath = subPath1;
		
	} else {
		
		[self fileConverted:path];
		isSavePackaged = NO;
		workaroundTextHideMW = 0;
		
		loadPath = path;
	}
	
	NSData *loadData = [NSData dataWithContentsOfFile:loadPath];
	if (!loadData) { return NO; }
	[loadData getBytes:ptr];
	return YES;
}


OSStatus loadGame(unsigned char *ptr, unsigned short size)
{
    NSAutoreleasePool *localPool;
    localPool = [[NSAutoreleasePool alloc] init];  
    int saveReturn = [[MagneticController sharedController] loadGame:ptr ofSize:size];
    [localPool release];
    return saveReturn;
}


void loadMiscData(type8s *name)
{
    NSAutoreleasePool *localPool = [[NSAutoreleasePool alloc] init];
	
	NSString *path = [NSString stringWithUTF8String:name];
    [[MagneticController sharedController] loadMiscDataAtPackagePath:path];

    [localPool release];
}


type8 ms_load_file(type8s *name, type8 *ptr, type16 size)
{
	FILE *fh;
	int loadReturn;

	if (name) { // standard games
		if (!(fh=fopen(name,"rb"))) {
			return 1;
		}
		if (fread(ptr,1,size,fh) != size) {
			return 1;
		}
		fclose(fh);
		
		loadMiscData(name);
		noUserProgressAfterLoadNSave();
		loadReturn = 0;
	} else {
		loadReturn = loadGame(ptr, size);
	}
	return loadReturn;
}


- (void)saveGame:(NSData *)saveGame
{
	[self performSelectorOnMainThread:@selector(mainSaveGame:) withObject:saveGame waitUntilDone:YES];
	[loadSaveMWLock lock];
	[loadSaveMWLock unlock];
}


- (void)mainSaveGame:(NSData *)saveGame
{
	[loadSaveMWLock lock];
	
	self.mwSaveGameData = saveGame;
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"useIngameFileManagement"]) {
		[self openSaveSheet];
		return;
	}
	
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	[savePanel setAllowedFileTypes:@[selectedGame[2]]];
	[savePanel setNameFieldStringValue:selectedGame[1]];
	[savePanel beginSheetModalForWindow:[NSApp mainWindow] completionHandler:^(NSInteger result) {
		
		if (NSFileHandlingPanelOKButton == result) {
			
			NSString *path = [[savePanel URL] path];
			[self finishMWSavingAtPath:path];

		} else {
			
			[self clearPromptAfterCancelingSaveOrLoad];
			
		}
		
		quitInProgress = NO;
		closeInProgress = NO;
		[loadSaveMWLock unlock];
		
	}];
}


- (void)finishMWSavingAtPath:(NSString *)path
{
	NSString *name = [path lastPathComponent];
	
	if ([self saveMiscDataToPackagePath:path]) {
		path = [path stringByAppendingPathComponent:@"saveGame"];
	}
	
	BOOL success = [self.mwSaveGameData writeToFile:path atomically:YES];
	self.mwSaveGameData = nil;

	if (success) {
		
		currentOrder = -1;
		[self mainNoUserProgressAfterLoadNSave];
		
		workaroundTextHideMW = 0;
		workaroundTextType = 2;
		
		[self processSaveOrder];
		[self changeText:[NSString stringWithFormat:@"\nSaving: %@\n", name]];
		
		[loadSaveMWLock unlock];
		
		if (quitInProgress) {
			[NSApp terminate:nil];
		}
		if (closeInProgress) {
			[self addSilencedOrder:@"quit"];
			[self addSilencedOrder:@"q"];
			[self addSilencedOrder:@"y"];
		}
		
		return;
		
	} else {
		
		workaroundTextHideMW = 0;
		workaroundTextType = 2;
		
		[self processSaveOrder];
		[self changeText:[NSString stringWithFormat:@"\nSaving: %@\n", name]];
		[self changeText:@"Sorry, there was a problem with the save.\n"];
		[magneticTextView setIsTypingAllowed:YES];
		
	}
		
	quitInProgress = NO;
	closeInProgress = NO;
	[loadSaveMWLock unlock];
}


- (NSString *)savedGamesFolderForCurrentGame
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
	
	NSString *game = selectedGame[0];
	if (!game) {
		game = [gameSelectController currentlyVisibleGame][0];
	}
	
	NSString *savedGamePath = [basePath stringByAppendingPathComponent:[NSString stringWithFormat:@"magnetiX/savedGames/%@/", game]];
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if (![fileManager fileExistsAtPath:savedGamePath isDirectory:NULL]) {
        [fileManager createDirectoryAtPath:savedGamePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
	
    return savedGamePath;
}


- (NSString *)nowString
{
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[dateFormatter setDateFormat:@"YYYY-MM-dd HH-mm-ss"];
	return [dateFormatter stringFromDate:[NSDate date]];
}


- (void)trashFile:(id)sender
{
	if (fileSelectionController) {
		[fileSelectionController trash:sender];
	}
}


- (void)openSaveSheet
{
	[self openFileSheetWithSaveMode:YES];
}

- (void)openLoadSheet
{
	[self openFileSheetWithSaveMode:NO];
}


- (void)openFileSheetWithSaveMode:(BOOL)isSaveMode
{
	if (!fileSelectionController) {
		fileSelectionController = [[MXFSController alloc] init];
		[fileSelectionController setController:self];
	}
	
	id game = selectedGame;
	if (!game) {
		game = [gameSelectController currentlyVisibleGame];
		if (![selectGameWindow isVisible] || ![selectGameWindow isMainWindow]) {
			[selectGameWindow makeKeyAndOrderFront:self];
		}
	} else {
		if (![magneticWindow isVisible] || ![magneticWindow isMainWindow]) {
			[magneticWindow makeKeyAndOrderFront:self];
		}
	}
		
	[fileSelectionController setIsSaveMode:isSaveMode];
	[fileSelectionController setGameData:game];
	[fileSelectionController showSheet];
}


- (void)saveSheetClosedWithSaving:(BOOL)isSaving
{
	if (isMagneticWindows) {
	
		if (isSaving) {
			
			NSString *path = [[[self savedGamesFolderForCurrentGame] stringByAppendingPathComponent:[self nowString]] stringByAppendingPathExtension:selectedGame[2]];
			[self finishMWSavingAtPath:path];
			return;
			
		} else {
			
			[self clearPromptAfterCancelingSaveOrLoad];
			quitInProgress = NO;
			closeInProgress = NO;
			[loadSaveMWLock unlock];
			return;
			
		}
		
	} else {

		if (isSaving) {
			
			NSString *path = [[[self savedGamesFolderForCurrentGame] stringByAppendingPathComponent:[self nowString]] stringByAppendingPathExtension:selectedGame[2]];
			
			if ([self saveMiscDataToPackagePath:path]) {
				path = [path stringByAppendingPathComponent:@"saveGame"];
				isSavePackaged = YES;
			} else {
				isSavePackaged = NO;
			}
			
			[self addHiddenOrder:@"Save#"];
			[self addHiddenOrder:path];
			[self addHiddenOrder:@"Y"];
			
		} else {
			
			quitInProgress = NO;
			closeInProgress = NO;
			
			[self clearPromptAfterCancelingSaveOrLoad];
			return;
			
		}
		
	}
}


OSStatus saveGame(unsigned char *ptr, unsigned short size)
{
    NSAutoreleasePool *localPool;
    localPool = [[NSAutoreleasePool alloc] init];  
	NSData *saveData = [NSData dataWithBytes:ptr length:size];      
    [[MagneticController sharedController] saveGame:saveData];
    [localPool release];
    return noErr;
}


type8 ms_save_file(type8s *name, type8 *ptr, type16 size)
{
	FILE *fh;

	if (name) { // standard games
		if (!(fh = fopen(name,"wb"))) {
			[[MagneticController sharedController] nonMWGameSaved:NO];
			return 1;
		}
		if (fwrite(ptr,1,size,fh) != size) {
			fclose(fh);
			[[MagneticController sharedController] nonMWGameSaved:NO];
			return 1;
		}
		[[MagneticController sharedController] nonMWGameSaved:YES];
		fclose(fh);
	} else { // magnetic windows games
		saveGame(ptr, size);
	}
	return 0;
}


void script_write(type8 c)
{
	return;
}


void transcript_write(type8 c)
{
	return;
}


void ms_statuschar(type8 c)
{
	statbuffer[statbufpos++] = c;
	if (c == 0x0a){
		changeStatus(CFStringCreateWithBytes(NULL, (UInt8 *)statbuffer, statbufpos--, + kCFStringEncodingMacRoman, 0));
		statbufpos = 0;
	}
}


void ms_flush(void)
{
	if (!bufpos) {
		return;
	}
	
	if (workaroundTextHide) {
		
		if (workaroundTextHide == 5) {
			NSAutoreleasePool *localPool = [[NSAutoreleasePool alloc] init];
			if (workaroundTextType == 1) {
				[[MagneticController sharedController] changeText:@"\nLoading: "];
			} else {
				[[MagneticController sharedController] changeText:@"\nSaving: "];
			}
			[localPool release];
		}
		
		workaroundTextHide --;

		CFStringRef order = CFStringCreateWithBytes(NULL, (UInt8 *)buffer, bufpos--, + kCFStringEncodingUTF8, 0);
		if ([(NSString *)order isEqualToString:@">"] || [(NSString *)order isEqualToString:@"]"]) {
			workaroundTextHide = 0;
		}
		CFRelease(order);
		
		bufpos = 0;
		return;
	}
	
	if (workaroundTextHideMW) {
		workaroundTextHideMW --;

		CFStringRef order = CFStringCreateWithBytes(NULL, (UInt8 *)buffer, bufpos--, + kCFStringEncodingUTF8, 0);
		if ([(NSString *)order isEqualToString:@">"]) {
			workaroundTextHideMW = 0;
		}
		CFRelease(order);
		
		bufpos = 0;
		return;
	}
	
	changeText(CFStringCreateWithBytes(NULL, (UInt8 *)buffer, bufpos--, + kCFStringEncodingUTF8, 0));
	bufpos = 0;
}


void ms_putchar(type8 c)
{
	buffer[bufpos++] = c;
	if (c == '\b') {
		bufpos--; bufpos--;
	}
	if ((c == 0x0a) || (bufpos >= 999)) {
		ms_flush();
	}
}


- (void)enterOrderString:(NSString *)order
{
	if (![order isEqual:@""]) {
		
		[self markLastGlyph];
		[self addOrder:order checkingContent:YES hidingFromScript:NO];
		
	}
	currentOrder = -1;
}


- (void)oderDoneNextOne
{
	NSTextStorage *storage = [magneticTextView textStorage];
	NSString *string = [storage string];
	if ([string length] && [string characterAtIndex:[string length] - 1] != ' ') {
		
		NSMutableAttributedString *output = [[NSMutableAttributedString alloc] initWithString:@" "];
		[output addAttributes:self.gameAttributes range:NSMakeRange(0, 1)];
		[storage appendAttributedString:output];
		[output release];
		
	}
	
	self.hideNextOrder = NO;
	
	if ([orderBuffer count]) {
		[self transferOrder];
	} else {
		[magneticTextView setIsTypingAllowed:YES];
	}
}


- (void)transferOrder
{
	if ([orderBuffer count]) {
		isFishTerminalException = NO;
		[[orderPipe fileHandleForWriting] writeData:[[orderBuffer[0] stringByAppendingString:@"\n"] dataUsingEncoding:NSUTF8StringEncoding]];
		[orderBuffer removeObjectAtIndex:0];
	}
	
	if (![orderBuffer count] && self.isScriptPlaying) {
		self.isScriptPlaying = NO;
		[self clearGlyphIndex];
	}
}


- (void)addOrder:(NSString *)theOrder
{
	[self addOrder:theOrder checkingContent:NO hidingFromScript:NO];
}


- (void)addSilencedOrder:(NSString *)theOrder
{
	[self addOrder:theOrder checkingContent:NO hidingFromScript:YES];
}


- (void)addOrder:(NSString *)theOrder checkingContent:(BOOL)check hidingFromScript:(BOOL)isSilent;
{
	NSString *clearOrder;
	NSString *lowercaseOrder = [theOrder lowercaseString];
	
	BOOL isOrderPossible = [self orderPossible];
	isFishTerminalException = NO;
	
	if (check && isOrderPossible) {
		
		if ([theOrder isEqualToString:@"Load#"]) { theOrder = @"Load# "; } // "internally reserved" ... just to be sure
		else if ([theOrder isEqualToString:@"L#"]) { theOrder = @"L# "; }
		else if ([theOrder isEqualToString:@"Save#"]) { theOrder = @"Save# "; }
		
		NSString *checkString = [lowercaseOrder stringByAppendingString:@"          "];
		if ([[checkString substringToIndex:8] isEqual:@"graphic "] || [[checkString substringToIndex:9] isEqual:@"graphics "]) {
			[self clearGlyphIndex];
			[self userText:theOrder];
			[self changeText:@"\n*** Please use the Preferences to change graphic options. ***\n> "];
			[magneticTextView setIsTypingAllowed:YES];
			return;
		} else if ([[checkString substringToIndex:5] isEqual:@"save "]) {
			if (!isMagneticWindows) {
				[self saveFile:self];
				return;
			} else {
				[self addHiddenOrder:@"Save#"];
				return;
			}
		} else if ([[checkString substringToIndex:5] isEqual:@"load "] || [[checkString substringToIndex:8] isEqual:@"restore "]) {
			if (!isMagneticWindows) {
				[self openFile:self];
				return;
			} else {
				[self addHiddenOrder:@"Load#"];
				[self addHiddenOrder:@"Graphics off"];
				[self addHiddenOrder:@"Graphics on"];
				return;
			}
		} else if ([[checkString substringToIndex:6] isEqual:@"#undo "]) {
			isSilent = YES;
		} else if ([[checkString substringToIndex:5] isEqual:@"hint "] || [[checkString substringToIndex:6] isEqual:@"hints "]) {
			isSilent = YES;
			if (self.customHintPath) {
				[self clearGlyphIndex];
				[self userText:theOrder];
				[self changeText:@"\n> "];
				[magneticTextView setIsTypingAllowed:YES];
				[self performSelectorOnMainThread:@selector(mainOpenCustomHints) withObject:nil waitUntilDone:YES];
				return;
			}
		} else {
			[magneticWindow setDocumentEdited:YES];
		}
	}
	
	if (check && !isOrderPossible && isPawnLoadException) {
		if ([[lowercaseOrder substringToIndex:1] isEqual:@"l"]) {
			[self openFile:self];
			return;
		}
	}
	
	if ([theOrder length] > 256) {
		clearOrder = [theOrder substringToIndex:255];
	} else {
		clearOrder = theOrder;
	}
	
	[orderHistory addObject:clearOrder];
	if (!isSilent) {
		[ordersForScript addIndex:[orderHistory count] - 1];	
	}
	
	[orderBuffer addObject:clearOrder];
	
	[self transferOrder];
}


- (void)addHiddenOrder:(NSString *)order
{
	[orderBuffer addObject:order];
	[self transferOrder];
}


- (BOOL)orderPossible
{
	if ([selectedGame count]) {
		NSString *checkString = [magneticTextView checkString];
		if (([checkString isEqual:@"\n> "] || [checkString isEqual:@"\n] "]) && (![self isAlertOpen] || quitInProgress) && !isFishTerminalException && !self.isScriptPlaying) { // ']' is necessary for the pawn "debug mode"
			return YES;
		}
	}
	
	return NO;
}


- (BOOL)undoPossible
{
	if ([selectedGame count]) {
		if ((![self isAlertOpen] || quitInProgress) && !self.isScriptPlaying) {
			return YES;
		}
	}
	
	return NO;
}


- (void)answerFirstAlert
{
	NSBeep();
	
	[self clearGlyphIndex];
	[self jumpToGlyph];
	
	NSBeginAlertSheet(@"This is currently not possible!", @"OK", nil, nil, magneticWindow, self, @selector(endAnswerFirstAlert:returnCode:contextInfo:), NULL, NULL, @"Please answer the game question(s) first, and/or play up to the next \"standard\" prompt. Then try again.");
}


- (void)endAnswerFirstAlert:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
}


- (BOOL)windowShouldClose:(id)sender
{
	if (![self orderPossible]) {
		[self answerFirstAlert];
	} else {
		if ([magneticWindow isDocumentEdited]) {
			NSBeginAlertSheet(@"Unsaved Progress!", @"Save", @"Don't Save", @"Cancel", magneticWindow, self, @selector(endCloseSheet:returnCode:contextInfo:), NULL, NULL, @"Do you want to save your progress before leaving this game?");
		} else {
			[orderBuffer removeAllObjects];
			[self addOrder:@"quit"];
			[self addOrder:@"q"];
			[self addOrder:@"y"];
		}
	}
	return NO;
}


- (void)endCloseSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	switch (returnCode) {
		case NSAlertAlternateReturn:
			[self mainNoUserProgress];
			[orderBuffer removeAllObjects];
		break;
		case NSAlertDefaultReturn:
			[orderBuffer removeAllObjects];
			[sheet orderOut:nil];
			closeInProgress = YES;
			[self saveFile:nil];
		break;
	}
	
	if (![magneticWindow isDocumentEdited]) {
		[self addOrder:@"quit"];
		[self addOrder:@"q"];
		[self addOrder:@"y"];
	}
}


- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag
{
	if (selectedGame) {
		[magneticWindow makeKeyAndOrderFront:self];
		if ([selectGameWindow isVisible]) { // should not happen ... but i HAD it happen.
			[selectGameWindow orderOut:self];
		} else if ([selectGameWindow isMiniaturized]) {
			[selectGameWindow orderBack:self];
			[selectGameWindow orderOut:self];
		}
	} else {
		[selectGameWindow makeKeyAndOrderFront:self];
		if ([magneticWindow isVisible]) {
			[magneticWindow orderOut:self];
		} else if ([magneticWindow isMiniaturized]) {
			[magneticWindow orderBack:self];
			[magneticWindow orderOut:self];
		}
	}
	
    return NO;
}


- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	if ([magneticWindow isDocumentEdited]) {
		NSBeginAlertSheet(@"Unsaved Progress!", @"Save", @"Don't Save", @"Cancel", magneticWindow, self, @selector(endQuitSheet:returnCode:contextInfo:), NULL, NULL, @"Do you want to save your progress before leaving this game?");
		return NSTerminateLater;
	} else {
		return NSTerminateNow;
	}
}


- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	[[orderPipe fileHandleForWriting] closeFile];
    
	if ([NSColorPanel sharedColorPanelExists]) {
		NSColorPanel *panel = [NSColorPanel sharedColorPanel];
		[panel setRestorable:NO];
	}
	
	if (preferenceController) {
		[preferenceController endTemplateNaming:self];
	}
}


- (void)endQuitSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	switch (returnCode) {
		case NSAlertAlternateReturn:
			[self mainNoUserProgress];
		break;
		case NSAlertDefaultReturn:
			quitInProgress = YES;

			if (![self orderPossible]) {
				quitInProgress = NO;
				[sheet orderOut:nil];
				[self answerFirstAlert];
			} else {
				[orderBuffer removeAllObjects];
				[sheet orderOut:nil];
				[self saveFile:nil];
			}
		break;
	}
	
	if (![magneticWindow isDocumentEdited] && !quitInProgress) { // don't save
		[NSApp replyToApplicationShouldTerminate:YES];
	} else { // cancel or save
		[NSApp replyToApplicationShouldTerminate:NO];
	}
}


- (void)userText:(NSString *)text
{
	[self performSelectorOnMainThread:@selector(mainUserText:) withObject:text waitUntilDone:YES];
}


- (void)mainUserText:(NSString *)theOrder
{
	if (self.hideNextOrder) { return; }
	[magneticTextView replaceOrder:[theOrder stringByAppendingString:@"\n"]];
}


- (void)mainProcessOrder:(NSString *)order
{
	if ([order isEqual:@"quit"] && quitInProgress) {
		[NSApp terminate:nil];
	} else if ([order isEqual:@"Graphics on"] || [order isEqual:@"Graphics off"]) {
		self.hideNextOrder = YES;
	}
	[self mainUserText:order];
	//[orderHistory addObject:order];
}


- (void)processSaveOrder
{
	[self performSelectorOnMainThread:@selector(mainProcessSaveOrder) withObject:nil waitUntilDone:YES];
}


- (void)mainProcessSaveOrder
{	
	uglyLocation = [[[magneticTextView textStorage] string] length] - [magneticTextView editRange].length;
	[self mainProcessOrder:@"Save"];
}


- (void)completeUglyRange
{
	[self performSelectorOnMainThread:@selector(mainCompleteUglyRange) withObject:nil waitUntilDone:YES];
}


- (void)mainCompleteUglyRange
{
	workaroundTextType = 0;
	NSUInteger length = [[[magneticTextView textStorage] string] length] - uglyLocation;
	[uglyRanges addObject:[NSValue valueWithRange:NSMakeRange(uglyLocation, length + 2)]];
}


- (void)processOrder:(NSString *)order
{
	[self performSelectorOnMainThread:@selector(mainProcessOrder:) withObject:order waitUntilDone:YES];
}


OSStatus processOrder(CFStringRef order)
{
	if (workaroundTextHide) {
		
		if (workaroundTextHide == 4) {
			NSAutoreleasePool *localPool = [[NSAutoreleasePool alloc] init];
			
			NSString *name = nil;
			if (isSavePackaged) {
				name = [[(NSString *)order stringByDeletingLastPathComponent] lastPathComponent];
			} else {
				name = [(NSString *)order lastPathComponent];
			}
			
			[[MagneticController sharedController] changeText:[NSString stringWithFormat:@"\"%@\".", name]];
			[localPool release];
		}
		
		workaroundTextHide --;
		
		CFRelease(order);
		return noErr;
	}
	
	if (workaroundTextHideMW) {
		workaroundTextHideMW --;

		CFRelease(order);
		return noErr;
	}
	
    NSAutoreleasePool *localPool = [[NSAutoreleasePool alloc] init];
    
	if ([(NSString *)order isEqualToString:@"L#"]) {
		
		workaroundTextType = 1;
		
		if (isSavePackaged) {
			workaroundTextHide = 10;
		} else {
			workaroundTextHide = 6;
			[[MagneticController sharedController] processOrder:@"L"];
		}
		
	} else if ([(NSString *)order isEqualToString:@"Load#"]) {
		
		if (ms_is_magwin()) {
			workaroundTextHideMW = 10;
			CFRelease(order);
			return noErr;
		} else {
			
			if (isSavePackaged) {
				workaroundTextHide = 10;
			} else {
				workaroundTextHide = 6;
				[[MagneticController sharedController] processOrder:@"Load"];
			}
			
			workaroundTextType = 1;
		}
				
	} else if ([(NSString *)order isEqualToString:@"Save#"]) {
		
		if (ms_is_magwin()) {
			workaroundTextHideMW = 10;
			CFRelease(order);
			return noErr;
		} else {
			workaroundTextHide = 6;
		}
		
		workaroundTextType = 2;
		[[MagneticController sharedController] processSaveOrder];
		
	} else {
		
		[[MagneticController sharedController] processOrder:(NSString *)order];
		
	}
	
	CFRelease(order);
    [localPool release];
	return noErr;
}


- (void)nextOrder
{
	[self performSelectorOnMainThread:@selector(oderDoneNextOne) withObject:NULL waitUntilDone:YES];
}


OSStatus nextOrder()
{
    NSAutoreleasePool *localPool;
    localPool = [[NSAutoreleasePool alloc] init];        
    [[MagneticController sharedController] nextOrder];
    [localPool release];
	return noErr;
}


type8 ms_getchar(type8 trans)
{
	static type8s buf[256];
	static type16 pos = 0;
	static BOOL seedInProgress = NO;
	int c;
	type8 i;

	if (!pos) {
		i = 0;
		nextOrder();
		while (1) {
			c = getchar();
			if (c == '\n' || c == EOF || i == 255) {
				break;
			}
			buf[i++] = c;
		}
		
		buf[i] = '\n';
		
		processOrder(CFStringCreateWithBytes(NULL, (UInt8 *)buf, i--, + kCFStringEncodingUTF8, 0));
		i++;
		
		buf[i] = '\0';
		
		if (strcmp(buf, "#undo") == 0) {
			buf[0] = 0;
			i = 1;
		}
		if (strcmp(buf, "Load#") == 0 || strcmp(buf, "L#") == 0 || strcmp(buf, "Save#") == 0) {
			i --;
		}

		if (seedInProgress) {
			seedInProgress = NO;
			buf[i] = 0;
			if (strtol(buf, NULL, 0)) {	
				ms_seed((unsigned int)strtol(buf, NULL, 0));
				i = 0;
				buf[i] = '\n';
				if (ms_is_magwin()) {
					[[MagneticController sharedController] changeTextAndScroll:@"\n>"];
				}
			}
		}
		if (strcmp(buf, "#seed") == 0) {
			seedInProgress = YES;
			i = 0;
			buf[i] = '\n';
			if (ms_is_magwin()) {
				[[MagneticController sharedController] changeTextAndScroll:@"\n>"];
			}
		}
						
		buf[i] = '\n';
	}
	
	if ((c = buf[pos++]) == '\n' || !c) {
		pos = 0;
	}
	
	return (type8)c;
}


type16 red[16], green[16], blue[16];

- (void)changeImage:(NSNumber *)imageNr
{
	if ((workaroundTextHide > 50 || workaroundTextHideMW > 50) && isSavePackaged) { return; } // when launching magnetiX with a "new" game file -> no image necessary at the beginning
	
	if (isMagneticWindows) { // blocks the first image direcly after a MW-load (with hidden "Graphics Off", "Graphics On"). This could result in another image than the one it was saved on.
		if (imageRangeLocation == [[[magneticTextView textStorage] string] length]) {
			return;
		}
	}
		
	NSString *key = nil;
	
	if (ms_is_magwin()) {
		key = [NSString stringWithUTF8String:anim_name([imageNr intValue])];
	} else {
		key = [NSString stringWithFormat:@"%i", [imageNr intValue]];
	}
	
	if (![self imageForCacheKey:key]) { return; }
		
	if (self.animBaseImage) {
		
		[self nextAnimFrameForKey:key];
		
		if (!animMode) { // animation is "off" ... so just show first frame
			[self togglePicSize:0];
			[self saveNewImageWithKey:key];
		} else {
			[self mainShowAnim];
			[self saveNewImageWithKey:key];
		}
		
	} else {
				
		[self togglePicSize:0];
		[self saveNewImageWithKey:key];
		
	}
	
}


- (BOOL)imageForCacheKey:(NSString *)key
{
	//if ([key isEqualToString:@"4"]) { key = @"23"; } else if ([key isEqualToString:@"23"]) { key = @"4"; } // pawn image-size-debug
	
	if (!key || [key isEqualToString:@"nopic"]) { return NO; }
	
	if (animTimer) {
		[animTimer invalidate];
		animTimer = NULL;
	}
	
	self.animBaseImage = nil;
	[animPicArray removeAllObjects];
	currentAnimFrame = 0;

	
	if (self.use8BitGraphics && !isMagneticWindows) {
		
		NSString *path = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:[NSString stringWithFormat:@"/gamefiles/8bit/%@/%@.gif", selectedGame[0], key]];
		
		NSImage *eightBitImage = [[[NSImage alloc] initWithContentsOfFile:path] autorelease];
		if (eightBitImage) {
			[animPicArray addObject:eightBitImage];
		}
		
	}
	
	
	type16 w = 0, h = 0, pal[16];
	type8 *raw = 0, i, is_anim = 0;
	long a;
	
	if (!isMagneticWindows) {
		raw = ms_extract1((type8)[key intValue],&w,&h,pal);
	} else {
		raw = ms_extract2((type8s*)[key cStringUsingEncoding:NSASCIIStringEncoding],&w,&h,pal,&is_anim);
	}
	
	NSBitmapImageRep *colRep = [[[NSBitmapImageRep alloc] initWithBitmapDataPlanes: NULL
																		pixelsWide: w
																		pixelsHigh: h
																	 bitsPerSample: 8
																   samplesPerPixel: 3
																		  hasAlpha: NO
																		  isPlanar: NO
																	colorSpaceName: NSCalibratedRGBColorSpace
																	   bytesPerRow: 3 * w
																	  bitsPerPixel: 24
								 ] autorelease];
	
	unsigned char *colData = [colRep bitmapData];
	
	for (i = 0; i < 16; i++) {
		red[i] = (pal[i]&0x0F00)>>7;
		green[i] = (pal[i]&0x00F0)>>3;
		blue[i]= (pal[i]&0x000F)<<1;
	}
	
	int corector = 18;
	if (![[NSUserDefaults standardUserDefaults] boolForKey:@"imageOptimizations"]) {
		corector = 15;
	}
	
	for (a = 0; a < w*h; a++) {
		*colData++ = red[raw[a]]*corector;
		*colData++ = green[raw[a]]*corector;
		*colData++ = blue[raw[a]]*corector;
	}
	
	NSImage *scanImage = [[NSImage alloc] initWithSize:NSZeroSize];
	[scanImage addRepresentation:colRep];
	
	if (is_anim) {
		self.animBaseImage = scanImage;
	} else {
		
		NSImage *cleanedImage = [self cleanedImageFromImage:scanImage withKey:key];
		if (![animPicArray count]) {
			[animPicArray addObject:cleanedImage];
		} else { // 8 bit is on, but 16 bit will be use for saved game previews
			self.currentPreview = cleanedImage;
		}
	}
	
	[scanImage release];
	
	if ([selectedGame[0] isEqualToString:@"wonder"]) {
		[self checkMusicForKey:key];
	}
	
	return YES;
}


- (BOOL)nextAnimFrameForKey:(NSString *)key
{	
	NSBitmapImageRep *srcImageRep;
	NSImage *animImage;
	struct ms_position * positions;
	type16 count, s;
	type8 frames_left;
	
	unsigned char *colData;
	type16 w, h;
	
	frames_left = ms_animate(&positions, &count);
	
	if (!frames_left || ms_anim_is_repeating()) {
		self.animBaseImage = nil;
		return NO;
	}
	
	NSImage *baseImage = self.animBaseImage;
	if (!baseImage) { return NO; }
	
	NSSize imageSize = [baseImage size];
	w = imageSize.width;
	h = imageSize.height;
	
	srcImageRep = [NSBitmapImageRep imageRepWithData:[baseImage TIFFRepresentation]];
	
	for (s=0; s<count; s++) {
		
		if (positions[s].number>-1) {
			type8	*bitmap;
			type8	*mask;
			type16	frame_width, frame_height;
			int sx = 0, sy = 0, xCorrector = 0, frame_current = 0, mask_current = 0, mask_width = 0, mask_rest = 0, frame_line_check = 0, positionXTemp = 0, frameWidthTemp = 0;
			CFBitVectorRef maskVector = NULL;
			
			int corector = 18;
			if (![[NSUserDefaults standardUserDefaults] boolForKey:@"imageOptimizations"]) {
				corector = 15;
			}
			
			bitmap = ms_get_anim_frame (positions[s].number, &frame_width, &frame_height, &mask);
			
			if (mask != NULL) {
				mask_width = ((((frame_width - 1) / 8) + 2) & (~1)) * 8;
				mask_rest = mask_width - frame_width;
				maskVector = CFBitVectorCreate (NULL, mask, mask_width * frame_height - mask_rest);
			}
			colData = [srcImageRep bitmapData];
			
			if (positions[s].x < 0) {
				xCorrector = -(positions[s].x);
				frame_current = xCorrector;
				mask_current = xCorrector;
			}
			if (positions[s].x + frame_width > w) {
				if (positions[s].x < 1) {
					positionXTemp = 0;
					frameWidthTemp = frame_width + positions[s].x;
				}
				else {
					positionXTemp = positions[s].x;
					frameWidthTemp = frame_width;
				}
				xCorrector += frameWidthTemp - (w - positionXTemp);
			}
			if (positions[s].y < 0) {
				frame_current += -(positions[s].y) * frame_width;
				mask_current  += -(positions[s].y) * frame_width;
			}
			for (sy=0; sy<h; sy++) {
				for (sx=0; sx<w; sx++) {
					if ( (sx>=positions[s].x && sx<positions[s].x + frame_width) && (sy>=positions[s].y && sy<positions[s].y + frame_height) ) {
						if (mask != NULL) {
							if (!CFBitVectorGetBitAtIndex (maskVector, mask_current)) {
								*colData++ = red[bitmap[frame_current]]*corector;
								*colData++ = green[bitmap[frame_current]]*corector;
								*colData++ = blue[bitmap[frame_current]]*corector;
							} else {
								colData += 3;
							}
						} else {
							*colData++ = red[bitmap[frame_current]]*corector;
							*colData++ = green[bitmap[frame_current]]*corector;
							*colData++ = blue[bitmap[frame_current]]*corector;
						}
						frame_current++; frame_line_check = 1; mask_current++;
					} else {
						colData += 3;
					}
				}
				if (frame_line_check){
					frame_current += xCorrector;  mask_current += xCorrector + mask_rest; frame_line_check = 0;
				}
			}
			if (maskVector) {
				CFRelease(maskVector);
				maskVector = NULL;
			}
		}
		
	}

	animImage = [[NSImage alloc] initWithSize:NSZeroSize];
	[animImage addRepresentation:srcImageRep];
	
	[animPicArray addObject:[self cleanedImageFromImage:animImage withKey:key]];
	
	[animImage release];
	
	return YES;
}


- (void)completeAnim
{
	while (self.animBaseImage) {
		[self nextAnimFrameForKey:self.currentlyShownImage];
	}
}


- (void)saveNewImageWithKey:(NSString *)key
{
	if ([animPicArray count]) {
		if (! (self.use8BitGraphics && !isMagneticWindows) ) {
			self.currentPreview = animPicArray[0];
		}
	}
	
	if (!self.lastSavedImage) {
		self.lastSavedImage = key;
		return;
	}
	
	NSTextStorage *ts = [magneticTextView textStorage];
	NSRange imageLocationRange = NSMakeRange(imageRangeLocation, [[ts string] length] - imageRangeLocation);
	imageRangeLocation = imageLocationRange.location + imageLocationRange.length;
	
	[ts addAttributes:@{@"MXImageShown": self.lastSavedImage} range:imageLocationRange];
		
	self.lastSavedImage = key;
	self.currentlyShownImage = key;
}


- (void)updateImage
{
	NSString *image = self.currentlyShownImage;
	if (!image) { image = self.lastSavedImage; }
	
	self.currentlyShownImage = nil;
	
	[self showImage:image];
}


- (void)windowDidChangeBackingProperties:(NSNotification *)note
{
	if ([selectedGame count]) {
		[self updateImage];
	}
}


- (void)showImage:(NSString *)cacheKey
{
	if (!cacheKey && !self.currentlyShownImage) { return; }
	if ([self.currentlyShownImage isEqualToString:cacheKey]  || (!cacheKey && [self.currentlyShownImage isEqualToString:self.lastSavedImage])) { return; }
	
	if (!cacheKey) { cacheKey = self.lastSavedImage; }
		
	if (![self imageForCacheKey:cacheKey]) { return; }
	
	BOOL isAnimRestored = NO;
	
	if (self.animBaseImage) {
		if ([self nextAnimFrameForKey:cacheKey] && animMode) {
			isAnimRestored = YES;
		}
	}
	
	if (![animPicArray count]) { return; }
		
	id clipView = [magneticScrollView contentView];

	CGFloat oldHeight = [magneticScrollView frame].size.height;
	NSPoint scrollPoint = [clipView bounds].origin;
	
	self.currentlyShownImage = cacheKey;
	
	isJumpingBlocked = YES;
	[self togglePicSize:0];
	isJumpingBlocked = NO;
		
	CGFloat newHeight = [magneticScrollView frame].size.height;
	
	if (self.isImageResizeBlocked || oldHeight == newHeight) {
		if (isAnimRestored) { [[NSRunLoop currentRunLoop] performSelector:@selector(mainShowAnim) target:self argument:nil order:9999 modes:@[NSDefaultRunLoopMode]]; }
		return;
	}
	
	if (oldHeight < newHeight && scrollPoint.y < newHeight - oldHeight) {
		NSInteger var = scrollPoint.y;
		if (var < 1) { var = 1; }
		[magneticTextView setTestTempLocation:var];
	}
	
	scrollPoint.y += (oldHeight - newHeight);
	
	if (scrollPoint.y > [magneticTextView bounds].size.height - [clipView bounds].size.height) {
		scrollPoint.y = [magneticTextView bounds].size.height - [clipView bounds].size.height;
	} else if (scrollPoint.y < 0) {
		scrollPoint.y = 0;
	}
		
	[clipView scrollToPoint:scrollPoint];
	
	if (isAnimRestored) { [[NSRunLoop currentRunLoop] performSelector:@selector(mainShowAnim) target:self argument:nil order:9999 modes:@[NSDefaultRunLoopMode]]; }
}


- (NSImage *)cleanedImageFromImage:(NSImage *)image withKey:(NSString *)key
{
	if (![[NSUserDefaults standardUserDefaults] boolForKey:@"imageOptimizations"]) {
		return image;
	}
	
	NSString *game = selectedGame[0];

	id needeDic = self.cropDic[game];
	NSValue *cropValues = needeDic[key];
	
	id corDic = self.colCorDic[game];
	id corValues = corDic[key];
	if (!corValues) {
		corValues = corDic[@"std"];
	}
	
	NSSize dstSize = [image size];
	NSRect dstRect = NSZeroRect;
	dstRect.size = dstSize;
	
	if (cropValues) {
		
		NSRect rect = [cropValues rectValue];

		dstSize.width -= (rect.origin.y + rect.size.height);
		dstSize.height -= (rect.origin.x + rect.size.width);
		
		dstRect.origin.x = rect.size.height;
		dstRect.origin.y = rect.size.width;
		
	}

	NSImage *croppedImage = [[NSImage alloc] initWithSize:dstSize];
	[croppedImage lockFocus];
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationNone];
	[image drawAtPoint:NSZeroPoint fromRect:dstRect operation:NSCompositeCopy fraction:1];
    [croppedImage unlockFocus];
	
	CIImage *ciImage = [[[CIImage alloc] initWithData:[croppedImage TIFFRepresentation]] autorelease];
	
	[croppedImage release];
	
	if ([magneticWindow backingScaleFactor] > 1) {
		ciImage = [ciImage imageByApplyingTransform:CGAffineTransformMakeScale(0.5, 0.5)];
	}
	
	CIFilter *filter = [CIFilter filterWithName:@"CIColorControls"];
	[filter setDefaults];
    [filter setValue:corValues[@"saturation"] forKey:@"inputSaturation"];
    [filter setValue:corValues[@"brightness"] forKey:@"inputBrightness"];
    [filter setValue:corValues[@"contrast"] forKey:@"inputContrast"];
	[filter setValue:ciImage forKey:@"inputImage"];
	
	CIImage *ciFilteredImage = [filter valueForKey:@"outputImage"];
	
	NSCIImageRep *rep = [NSCIImageRep imageRepWithCIImage:ciFilteredImage];
	NSImage *nsFilteredImage = [[NSImage alloc] initWithSize:rep.size];
	[nsFilteredImage addRepresentation:rep];
	
	NSImage *unscaledImage = [self deRetinaUpscaleImage:[nsFilteredImage autorelease]];
		
	NSImage *finalImage = [[NSImage alloc] initWithSize:NSZeroSize];
	[finalImage addRepresentation:[NSBitmapImageRep imageRepWithData:[unscaledImage TIFFRepresentation]]];
	
	if ([magneticWindow backingScaleFactor] > 1) {
		// makes sure that the images are displayed at the same size in relation to window size, e.g. when moving the window from a retina to a non-retina display ... WITHOUT actually resizing the image, again.
		// so export or preview size is still 1:1 pixel size in every case
		NSSize size = [finalImage size];
		[finalImage setSize:NSMakeSize(size.width * 2, size.height * 2)];
	}
	
	return [finalImage autorelease];
}


- (NSImage *)deRetinaUpscaleImage:(NSImage *)image
{
	if ([magneticWindow backingScaleFactor] > 1) {

		NSSize size = [image size];
		size.width *= 0.5;
		size.height *= 0.5;
		
		NSImage *ret = [[NSImage alloc] initWithSize:size];
		[ret lockFocus];
		NSAffineTransform *transform = [NSAffineTransform transform];
		[transform scaleBy:0.5];
		[transform concat];
		[image drawAtPoint:NSZeroPoint fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0];
		[ret unlockFocus];
		
		return [ret autorelease];

	} else {
		
		return image;
		
	}
}


- (void)possiblyContinueAnim
{
	if (animTimer) {
		[animTimer invalidate];
		animTimer = NULL;
	}
	
	NSUInteger count = [animPicArray count];
	
	if (count > 1 || self.animBaseImage) {
		if (currentAnimFrame >= count) { currentAnimFrame = 0; }
		animTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(animationNextFrame) userInfo:NULL repeats:YES];
	}
}


- (void)mainShowAnim
{
	currentAnimFrame = 0;
	if (animTimer) {
		[animTimer invalidate];
		animTimer = NULL;
	}
	animTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(animationNextFrame) userInfo:NULL repeats:YES];
}


- (void)animationNextFrame
{
    if (!selectedGame) { return; }
    
	if (self.animBaseImage) {
		[self nextAnimFrameForKey:self.currentlyShownImage];
	}
	
	if (![animPicArray count]) {
		[animTimer invalidate];
		animTimer = NULL;
		return;
	}
	if (currentAnimFrame > [animPicArray count] - 1) { currentAnimFrame = 0; }
	
	[self togglePicSize:currentAnimFrame];
	[imageView display];
	
	currentAnimFrame ++;
	
	if (currentAnimFrame > [animPicArray count] - 1) {
		if (animMode == 1) {
			[animTimer invalidate];
			animTimer = NULL;
		}
		currentAnimFrame = 0;
	} else if (!animMode) {
		[animTimer invalidate];
		animTimer = NULL;
	}
}


OSStatus changeImage(type32 imageNr)
{
    NSAutoreleasePool *localPool;
    localPool = [[NSAutoreleasePool alloc] init];        
    //[[MagneticController sharedController] changeImage:(type32)imageNr];
	[[MagneticController sharedController] performSelectorOnMainThread:@selector(changeImage:) withObject:@(imageNr) waitUntilDone:YES];
    [localPool release];
    return noErr;
}


void ms_showpic(type32 c,type8 mode)
{
	if (mode) {
		changeImage(c);
	}
}


void ms_fatal(type8s *txt)
{
	exit(1);
}


- (void)reopenHintsPanel
{
	[hintPanel makeKeyAndOrderFront:self];
}


- (void)showHintPanelWithData:(NSMutableArray *)hintData
{
	[hintDataSource setHintArray:hintData];
	[hintOutlineView reloadData];
	[hintOutlineView expandItem:[hintOutlineView itemAtRow:0]];
	
	if (![hintPanel isVisible]) {
		id scrollView = [hintOutlineView enclosingScrollView];
		[scrollView setFrame:[scrollView frame]]; // makes sure the column width is adjusted even with "empty" prefs
	}
	
	[hintPanel makeKeyAndOrderFront:self];
}


static char *hint_content (struct ms_hint hints[], type16 node, int number)
{
	int index, count;
	assert (hints != NULL);

	for (count = 0, index = 0; count < number; index++) {
		if (hints[node].content[index] == '\0') {
			count++;
		}
	}
	return (char *)hints[node].content + index;
}


void add_hint (struct ms_hint *hints2, NSMutableArray *dst, NSString *subName)
{
	int i;
	int currentHint = exHint;
	NSMutableArray *subData = [NSMutableArray array];
	
	[subData addObject:subName];
	
	for (i=0; i < hints2[currentHint].elcount; i++) {
		if (hints2[currentHint].nodetype == 1) {
			exHint ++;
			add_hint (hints2, subData, [NSString stringWithCString:hint_content(hints2, currentHint ,i) encoding:NSISOLatin1StringEncoding]);
		} else {
			NSMutableArray *hintArray = [NSMutableArray array];
			[hintArray addObject:[NSString stringWithFormat:@"HINT %i",i+1]];
			[hintArray addObject:[NSString stringWithCString:hint_content(hints2, currentHint ,i) encoding:NSISOLatin1StringEncoding]];
			[subData addObject:hintArray];
		}
	}
	
	[dst addObject:subData];
}


- (void)mainOpenCustomHints
{
	if (!exHint) {
		exHint ++;
		NSMutableArray *data = [[NSArray arrayWithContentsOfFile:self.customHintPath] mutableCopyWithMutableSubarrays];
		[self showHintPanelWithData:data];
		[data release];
	} else {
		[self reopenHintsPanel];
	}
}


- (void)openHints:(struct ms_hint *)hints2
{
	if (!exHint) {
		int i = 1;
		NSMutableArray *mainData = [NSMutableArray array];
		add_hint (hints2, mainData, @" ");

		if ([selectedGame[0] isEqual:@"cfish"]){ i = 2; }
		else if ([selectedGame[0] isEqual:@"cguild"]){ i = 3; }

		mainData[0][i][0] = selectedGame[1];
		[self performSelectorOnMainThread:@selector(showHintPanelWithData:) withObject:mainData[0][i] waitUntilDone:YES];
	} else {
		[self performSelectorOnMainThread:@selector(reopenHintsPanel) withObject:nil waitUntilDone:YES];
	}
}


OSStatus openHints(struct ms_hint *hints2)
{
    NSAutoreleasePool *localPool;
    localPool = [[NSAutoreleasePool alloc] init];        
    [[MagneticController sharedController] openHints:hints2];
    [localPool release];
    return noErr;
}


- (IBAction)showHints:(id)sender
{
	if (![self orderPossible]) {
		[self answerFirstAlert];
		return;
	}
	
	[self clearGlyphIndex];
	[self addOrder:@"Hints" checkingContent:YES hidingFromScript:YES];
}


type8 ms_showhints(struct ms_hint * hints)
{
	openHints(hints);
	return 1;
}


- (void)tempDisableGraphics
{
	hasGraphics = NO;
	[self updateDisplayPicture];
	[self updateUI];
}


- (void)threadStart
{
    NSAutoreleasePool *localPool;
    localPool = [[NSAutoreleasePool alloc] init];        

	dup2([[orderPipe fileHandleForReading] fileDescriptor], 0);
	
	NSString *gfxPath = [gameSelectController checkForFile: [selectedGame[0] stringByAppendingString:@".gfx"]];
	NSString *magPath = [gameSelectController checkForFile: [selectedGame[0] stringByAppendingString:@".mag"]];
	NSString *hntPath = nil;
	NSString *sndPath = nil;

	if (isMagneticWindows) {
		hntPath = [gameSelectController checkForFile: [selectedGame[3] stringByAppendingString:@".hnt"]];
		if ([selectedGame[0] isEqual:@"wonder"]) {
			sndPath = [gameSelectController checkForFile:@"wonder.snd"];
		}
		self.customHintPath = nil;
	} else {
		hntPath = NULL;
		self.customHintPath = [gameSelectController checkForFile: [selectedGame[0] stringByAppendingString:@"_hnt.plist"]];
	}
	
	if (!gfxPath) {
		[self performSelectorOnMainThread:@selector(tempDisableGraphics) withObject:nil waitUntilDone:YES];
	}
	
	mainemu((char *)[magPath UTF8String], (char *)[gfxPath UTF8String], (char *)[hntPath UTF8String], (char *)[sndPath UTF8String], (char *)[selectedGame[2] UTF8String]);
	
    [localPool release];
}


- (void)showRandomEventsAlertPanel
{
	NSAlert *theAlert = [NSAlert alertWithMessageText:@"Random Events!"
										defaultButton:@"OK"
									  alternateButton:nil
										  otherButton:nil
							informativeTextWithFormat:@"Due to some random events in these games playing back a script might not result in the game situation you expect.\nThis can be avoided by seeding the random event generator at the beginning of the gaming session you want to save - Please look in the magnetiX help for instructions."];
	
	[theAlert setShowsSuppressionButton:YES];
	
	[theAlert beginSheetModalForWindow:magneticWindow modalDelegate:self didEndSelector:@selector(randomEventsAlertDidEnd:returnCode:contextInfo:) contextInfo:nil];
	
	[NSApp runModalForWindow:[theAlert window]];
	
}


- (void)randomEventsAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(id)contextInfo
{
	if ([[alert suppressionButton] state] == NSOnState) {
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"disableRandomEventsAlert"];
	}
	
	[NSApp stopModal];
}


- (IBAction)saveAsScript:(id)sender
{
	if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"disableRandomEventsAlert"] intValue] != 1) {
		[self showRandomEventsAlertPanel];
	}
	
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	[savePanel setAllowedFileTypes:@[@"rec"]];
	[savePanel setNameFieldStringValue:selectedGame[1]];
	[savePanel beginSheetModalForWindow:[NSApp mainWindow] completionHandler:^(NSInteger result) {
		
		if (NSFileHandlingPanelOKButton == result) {
			
			NSArray *scriptOrders = [orderHistory objectsAtIndexes:ordersForScript];
			
			NSMutableString *theScript = [[NSMutableString alloc] init];
				
			for (id singleOrder in scriptOrders) {
				[theScript appendString:singleOrder];
				[theScript appendString:@"\n"];
			}
			
			[theScript writeToFile:[[savePanel URL] path] atomically:YES encoding:NSISOLatin1StringEncoding error:nil];
			[theScript release];
			
		}
		
	}];
	
}


- (IBAction)openScript:(id)sender
{
	if (![self orderPossible]) {
		[self answerFirstAlert];
	} else {
		
		NSOpenPanel *openPanel = [NSOpenPanel openPanel];
		[openPanel setAllowedFileTypes:@[@"rec"]];
		[openPanel beginSheetModalForWindow:[NSApp mainWindow] completionHandler:^(NSInteger result) {
			
			if (NSFileHandlingPanelOKButton == result) {
				
				[self runScript:[[openPanel URL] path]];
				if ([orderBuffer count]) {
					[self transferOrder];
				}
				
			}
			
		}];
		
	}
}


- (void)runScript:(NSString *)scriptPath
{
	[self clearGlyphIndex];
	
	NSMutableString *scriptData = [[NSString stringWithContentsOfFile:scriptPath encoding:NSISOLatin1StringEncoding error:nil] mutableCopy];

	[scriptData replaceOccurrencesOfString:@"\r\n" withString:@"\n" options:0 range:NSMakeRange(0, [scriptData length])];
	[scriptData replaceOccurrencesOfString:@"\r" withString:@"\n" options:0 range:NSMakeRange(0, [scriptData length])];

	NSArray *singleOrders = [scriptData componentsSeparatedByString:@"\n"];
    [scriptData release];
    
	BOOL hasOrders = NO;
	
	NSEnumerator *f = [singleOrders objectEnumerator];
	id singleOrder;
	while ((singleOrder = [f nextObject]) != nil) {
		if ( ![singleOrder isEqual:@""] &&
			 ![[[[singleOrder stringByAppendingString:@"          "] lowercaseString] substringToIndex:8] isEqual:@"graphic "] &&
			 ![[[[singleOrder stringByAppendingString:@"          "] lowercaseString] substringToIndex:9] isEqual:@"graphics "] )
		{
			if (!hasOrders) {
				hasOrders = YES;
				[magneticWindow setDocumentEdited:YES];
				self.isScriptPlaying = YES;
			}
			[orderBuffer addObject:singleOrder];
			[orderHistory addObject:singleOrder];
			[ordersForScript addIndex:[orderHistory count] - 1];
		}
	}
	currentOrder = -1;
}


- (BOOL)setBundleBit:(BOOL)flag forFile:(NSString *)path
{
    FSRef fileRef;
    OSErr error = FSPathMakeRef((UInt8 *)[path fileSystemRepresentation], &fileRef, NULL);
	
    FSCatalogInfo fileInfo;
    if (!error)
    {
    	error = FSGetCatalogInfo(&fileRef, kFSCatInfoFinderInfo, &fileInfo, NULL, NULL, NULL);
    }
	
    if (!error)
    {
    	FolderInfo *finderInfo = (FolderInfo *)fileInfo.finderInfo;
    	if (flag) {
    		finderInfo->finderFlags |= kHasBundle;
    	}
    	else {
    		finderInfo->finderFlags &= ~kHasBundle;
    	}
		
    	error = FSSetCatalogInfo(&fileRef, kFSCatInfoFinderInfo, &fileInfo);
    }
	
    if (error) {
    	return NO;
    }
	
	return YES;
}


- (NSString *)addStatusTextToPreviewText:(NSString *)pt
{
	NSString *firstLine = [pt componentsSeparatedByString:@"\n"][0];
	
	NSArray *statusParts = [self.latestStatus componentsSeparatedByString:@"\t"];
	NSString *leftStatus = statusParts[0];
	
	if ([firstLine length] >= [leftStatus length]) {
		NSString *textStart = [[firstLine substringToIndex:[leftStatus length]] lowercaseString];
		
		if ([textStart isEqualToString:[leftStatus lowercaseString]]) {
			
			if ([firstLine length] + 1 < [pt length]) {
				pt = [pt substringFromIndex:[firstLine length] + 1];
			} else {
				pt = @"";
			}
			
		}
		
	}
	
	return [NSString stringWithFormat:@"%@ (%@)\n%@", [leftStatus capitalizedString], statusParts[1], pt];
}


- (NSString *)previewText
{
	NSTextStorage *storageCopy = [[magneticTextView textStorage] mutableCopy];
	
	for (NSInteger i = [uglyRanges count] - 1; i >= 0; i--) { // remove all texts resulting from save-operations ... no need to have these on load
		[storageCopy deleteCharactersInRange:[uglyRanges[i] rangeValue]];
	}
	
	NSUInteger length = [storageCopy length];
	NSRange range = NSMakeRange(0, 0);

	while (range.length < 4) {
		
		id value = [storageCopy attribute:@"MXUserEntry" atIndex:length - 1 longestEffectiveRange:&range inRange:NSMakeRange(0, length)];
		
		if (value) {
			[storageCopy deleteCharactersInRange:range];
			length -= range.length;
			[storageCopy attribute:@"MXUserEntry" atIndex:length - 1 longestEffectiveRange:&range inRange:NSMakeRange(0, length)];
		}
		
		length -= range.length;
	}
	
	NSString *previewTextWithCrap = [[storageCopy string] substringWithRange:range];
	[storageCopy release];
	
	int from = 1;
	if (range.location == 0) from = 0;
	
	NSString *prevText = [previewTextWithCrap substringFromIndex:from];
	
	if ([prevText length] >= 4) { prevText = [prevText substringToIndex:[prevText length] - 3]; }
	
	if (!isMagneticWindows) {
		prevText = [self addStatusTextToPreviewText:prevText];
	}
	
	return prevText;
}


- (BOOL)saveMiscDataToPackagePath:(NSString *)path
{
	NSFileManager *defaultManager = [NSFileManager defaultManager];
	
	if (![[NSWorkspace sharedWorkspace] isFilePackageAtPath:path]) {
		
		if (![defaultManager createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:nil]) {
			
			NSData *data = [NSData dataWithContentsOfFile:path];
			if (!data) { return NO; }
			if (![defaultManager removeItemAtPath:path error:nil]) { return NO; }
			if (![defaultManager createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:nil]) {
				[data writeToFile:path atomically:NO];
				return NO;
			}
			
			[data writeToFile:[path stringByAppendingPathComponent:@"saveGame"] atomically:NO];

		}
		
		[self setBundleBit:YES forFile:path];
	}
	
	if (![defaultManager isWritableFileAtPath:path]) { return NO; } // otherwise it would write to a save-package that was protected in finder
	
	[self saveStatus];
	[self saveNewImageWithKey:self.lastSavedImage];
	
	NSTextStorage *storageCopy = [[magneticTextView textStorage] mutableCopy];
	
	for (NSInteger i = [uglyRanges count] - 1; i >= 0; i--) { // remove all texts resulting from save-operations ... no need to have these on load
		[storageCopy deleteCharactersInRange:[uglyRanges[i] rangeValue]];
	}
	
	NSDictionary *dataDic = @{@"statusLeft" : [statusTextLeft stringValue],
							  @"statusRight" : [statusTextRight stringValue],
							  @"textStorage" : storageCopy,
							  @"orderHistory" : orderHistory,
							  @"ordersForScript" : ordersForScript,
							  @"currentlyShownImage" : self.currentlyShownImage
							  };
	
	NSData *data = [NSArchiver archivedDataWithRootObject:dataDic];
	[data writeToFile:[path stringByAppendingPathComponent:@"currentData"] atomically:NO];
	
	[[self.currentPreview TIFFRepresentationUsingCompression:NSTIFFCompressionLZW factor:0] writeToFile:[path stringByAppendingPathComponent:@"previewPic.tif"] atomically:NO];
	
	NSString *prevText = nil;
	if (fileSelectionController) {
		prevText = [fileSelectionController previewText];
	} else {
		prevText = [self previewText];
	}
	
	[prevText writeToFile:[path stringByAppendingPathComponent:@"previewText.txt"] atomically:NO encoding:NSUTF8StringEncoding error:nil];
	
	[storageCopy release];
	
	return YES;
}



- (IBAction)saveFile:(id)sender
{
	if (![self orderPossible]) {
		[self answerFirstAlert];
	} else {
		
		[self clearGlyphIndex];
		[self jumpToGlyph];
		
		if (isMagneticWindows) {
			[self addHiddenOrder:@"Save#"];
			return;
		} else {
			
			if ([[NSUserDefaults standardUserDefaults] boolForKey:@"useIngameFileManagement"]) {
				[self openSaveSheet];
				return;
			}
			
			NSSavePanel *savePanel = [NSSavePanel savePanel];
			[savePanel setAllowedFileTypes:@[selectedGame[2]]];
			[savePanel setNameFieldStringValue:selectedGame[1]];
			[savePanel beginSheetModalForWindow:[NSApp mainWindow] completionHandler:^(NSInteger result) {
				
				if (NSFileHandlingPanelOKButton == result) {
					
					NSString *path = [[savePanel URL] path];
					
					if ([self saveMiscDataToPackagePath:path]) {
						path = [path stringByAppendingPathComponent:@"saveGame"];
						isSavePackaged = YES;
					} else {
						isSavePackaged = NO;
					}
					
					[self addHiddenOrder:@"Save#"];
					[self addHiddenOrder:path];
					[self addHiddenOrder:@"Y"];
					
				} else {
					
					quitInProgress = NO;
					closeInProgress = NO;
					
					[self clearPromptAfterCancelingSaveOrLoad];
					
				}
				
			}];

		}
	}
}


- (void)nonMWGameSaved:(BOOL)hadSuccess
{
	[self performSelectorOnMainThread:@selector(mainNonMWGameSaved:) withObject:@(hadSuccess) waitUntilDone:NO];
}


- (void)mainNonMWGameSaved:(NSNumber *)hadSuccess
{
	if ([hadSuccess boolValue]) {
	
		currentOrder = -1;
		[self mainNoUserProgressAfterLoadNSave];
		
		if (quitInProgress) {
			[self addOrder:@"quit"];
		}
		if (closeInProgress) {
			[self addSilencedOrder:@"quit"];
			[self addSilencedOrder:@"q"];
			[self addSilencedOrder:@"y"];
		}
		
	} else {
	
		quitInProgress = NO;
		closeInProgress = NO;
		
	}
}


- (void)loadMiscDataAtPackagePath:(NSString *)path
{
	[self performSelectorOnMainThread:@selector(mainCheckLoadMiscDataAtPackagePath:) withObject:path waitUntilDone:YES];
}


- (void)fileConverted:(NSString *)path
{
	[orderHistory removeAllObjects];
	[ordersForScript removeAllIndexes];
	[uglyRanges removeAllObjects];
	
	isPawnLoadException = NO;
	self.quickAnswerType = 0;
	
	[magneticTextView setString:@""];
	[self mainChangeText:[NSString stringWithFormat:@"Loading: %@\n( Converted old saved game ... Progress recording enabled. )\n\n", [path lastPathComponent]]];
	
	imageRangeLocation = [[[magneticTextView textStorage] string] length];
	statusRangeLocation = imageRangeLocation;
}


- (void)mainCheckLoadMiscDataAtPackagePath:(NSString *)path
{
	NSString *subPath = [path stringByDeletingLastPathComponent];
	
	if (![[NSWorkspace sharedWorkspace] isFilePackageAtPath:subPath]) {
		[self fileConverted:path];
		return;
	}
	
	[self mainLoadMiscDataAtPackagePath:subPath];
}


- (void)mainLoadMiscDataAtPackagePath:(NSString *)path
{
	[self clearGlyphIndex];
	
	NSData *data = [NSData dataWithContentsOfFile:[path stringByAppendingPathComponent:@"currentData"]];
	if (data) {
		NSDictionary *dataDic = [NSUnarchiver unarchiveObjectWithData:data];
		
		NSString *text = [NSString stringWithFormat:@"%@\t%@", dataDic[@"statusLeft"], dataDic[@"statusRight"]];
		self.latestStatus = text;
		[self changeStatusWithText:text];
		self.currentlyShownStatus = text;
		self.latestStatus = text;
		
		id attString = dataDic[@"textStorage"];
		[[magneticTextView textStorage] setAttributedString:attString];
						
		imageRangeLocation = [attString length];
		statusRangeLocation = imageRangeLocation;
		
		self.currentlyShownImage = nil;
		[self showImage:dataDic[@"currentlyShownImage"]];
		self.lastSavedImage = self.currentlyShownImage;
		
		if ([animPicArray count]) {
			if (! (self.use8BitGraphics && !isMagneticWindows) ) {
				self.currentPreview = animPicArray[0];
			}
		}
				
		[orderHistory removeAllObjects];
		[orderHistory addObjectsFromArray:dataDic[@"orderHistory"]];
		
		[ordersForScript removeAllIndexes];
		[ordersForScript addIndexes:dataDic[@"ordersForScript"]];
		
		//[self changeTemplate];
		[self changeTextAtImport];
	}
	
	[self jumpToGlyph];
	
	[uglyRanges removeAllObjects];
	isPawnLoadException = NO;
	self.quickAnswerType = 0;
	
	[self clearPromptAfterCancelingSaveOrLoad];
	imageRangeLocation = [[[magneticTextView textStorage] string] length];
	statusRangeLocation = imageRangeLocation;
}



- (void)loadNONMagneticWindowsWithPath:(NSString *)path
{
	NSString *subPath1 = [path stringByAppendingPathComponent:@"saveGame"];
	NSString *subPath2 = [path stringByAppendingPathComponent:@"currentData"];
	NSString *loadPath = nil;
	
	if ([[NSWorkspace sharedWorkspace] isFilePackageAtPath:path]) {
		isSavePackaged = YES;
		
		NSFileManager *fileManager = [NSFileManager defaultManager];

		if (![fileManager fileExistsAtPath:subPath1] || ![fileManager fileExistsAtPath:subPath2]) {
		
			uglyLocation = [[[magneticTextView textStorage] string] length] - [magneticTextView editRange].length;
			
			workaroundTextHide = 0;
			
			[[MagneticController sharedController] processOrder:@"Load"];
			[self changeText:@"\nSorry, there was a problem with the load.\n> "];
			[magneticTextView setIsTypingAllowed:YES];
			[self clearGlyphIndex];
			[self jumpToGlyph];
			self.externalLoad = nil;
			[self completeUglyRange];
			
			return;
			
		}
		
		loadPath = subPath1;
		
	} else {
		isSavePackaged = NO;
		loadPath = path;
	}
	
	self.externalLoad = nil;

	[self clearGlyphIndex];
	
	if (isPawnLoadException) {
		[self addHiddenOrder:@"L#"];
	} else {
		[self addHiddenOrder:@"Load#"];
	}
	[self addHiddenOrder:loadPath];
	[self addHiddenOrder:@"Y"];
	currentOrder = -1;
}


- (void)loadMagneticWindows
{
	if (self.externalLoad) {
		if ([[NSWorkspace sharedWorkspace] isFilePackageAtPath:self.externalLoad]) {
			isSavePackaged = YES;
		} else {
			isSavePackaged = NO;
		}
	}
	
	[self clearGlyphIndex];
	
	[self addHiddenOrder:@"Load#"];
	[self addHiddenOrder:@"Graphics off"];
	[self addHiddenOrder:@"Graphics on"];
}


- (IBAction)openFile:(id)sender
{	
	if ([selectedGame count] && ![self orderPossible] && !isPawnLoadException) {
		[self answerFirstAlert];
	} else {
		if (isMagneticWindows) {
			[self loadMagneticWindows];
			return;
		} else {
			if ([magneticWindow isDocumentEdited]) {
				[self showLoadWithProgressPanel];
			}
			
			if (![magneticWindow isDocumentEdited] || loadWithProgress) {
				loadWithProgress = 0;

				if (self.externalLoad) {
					[self loadNONMagneticWindowsWithPath:self.externalLoad];
				} else {
					
					if ([[NSUserDefaults standardUserDefaults] boolForKey:@"useIngameFileManagement"]) {
						[self openLoadSheet];
						return;
					}
					
					NSArray *types = nil;
					if ([selectedGame count]) {
						types = @[selectedGame[2]];
					} else {
						types = @[@"mX0", @"mX1", @"mX2", @"mX3", @"mX4", @"mX5", @"mX6", @"mX7", @"mX8", @"mX9"];
					}
					
					NSOpenPanel *openPanel = [NSOpenPanel openPanel];
					[openPanel setAllowedFileTypes:types];
					[openPanel beginSheetModalForWindow:[NSApp mainWindow] completionHandler:^(NSInteger result) {
						
						if (NSFileHandlingPanelOKButton == result) {
							
							if (![selectedGame count]) {
								
								self.externalLoad = [[openPanel URL] path];
								[gameSelectController externalStart:self.externalLoad];
								
							} else {
								
								[self loadNONMagneticWindowsWithPath:[[openPanel URL] path]];
								
							}
							
						} else {
							
							[self clearPromptAfterCancelingSaveOrLoad];
							
						}
						
					}];
					
				}
				
			} else {
				
				[self clearPromptAfterCancelingSaveOrLoad];
				
			}
		}
	}
}


- (void)backToGameSelection
{
	[self performSelectorOnMainThread:@selector(mainBackToGameSelection) withObject:nil waitUntilDone:YES];
}


- (void)clearImageHistory
{
	imageRangeLocation = 0;
	self.lastSavedImage = nil;
	self.currentlyShownImage = 0;
	newImageToSave = 0;
	
	self.currentlyShownStatus = nil;
	self.latestStatus = nil;
	statusRangeLocation = 0;
}


- (void)mainBackToGameSelection
{
    [selectedGame release];
    selectedGame = NULL;
    
    if (animTimer) {
        [animTimer invalidate];
        animTimer = NULL;
    }
	
	[gameSelectController stopQtSound];
	[self mainNoUserProgress];
	
	[self disableMore];
	theGlyphIndex = 0;
	glyphType = NO;
	self.isScriptPlaying = NO;
	[magneticTextView setIsTypingAllowed:NO];
	
	[magneticTextView setString:@""];

	//[[visibleScroller documentView] setFrame:NSZeroRect]; // prevents cases where overlay scrollers stay visible on next game start
	//[[magneticScrollView contentView] scrollToPoint:NSZeroPoint];
	
	[magneticWindow orderOut:nil];
	[selectGameWindow makeKeyAndOrderFront:nil];
	
	self.animBaseImage = nil;
	self.currentPreview = nil;
	
	NSImage *emptyImage = [[NSImage alloc] initWithSize:NSMakeSize(0, 0)];
	[imageView setImage:emptyImage];
	[emptyImage release];
	[animPicArray removeAllObjects];
	
	[orderHistory removeAllObjects];
	[ordersForScript removeAllIndexes];
	[statusTextLeft setStringValue:@""];
    [statusTextRight setStringValue:@""];
	[uglyRanges removeAllObjects];
	
	[self clearImageHistory];
	
	closeInProgress = NO;
	isMagneticWindows = NO;
	
	if (exHint) { // do we need to clean up mw-hints?
		[hintPanel close];
		exHint = 0;
		[hintDataSource releaseHintArray];
		[hintOutlineView reloadData];
	}
	
	if (!hasGraphics) {
		hasGraphics = YES;
		[self updateDisplayPicture];
	}
}


OSStatus backToGameSelection(void)
{
    NSAutoreleasePool *localPool;
    localPool = [[NSAutoreleasePool alloc] init];        
    [[MagneticController sharedController] backToGameSelection];
    [localPool release];
    return noErr;
}


int mainemu(char *magPath, char *gfxPath, char *hntPath, char *sndPath, char *newSuffix)
{
	type8s running, *gamename = 0, *gfxname = 0, *hintname = 0, *sndname = 0;
	gamename = magPath;
    gfxname = gfxPath;
	hintname = hntPath;
	sndname = sndPath;
	gameSuffix = newSuffix;
	ms_gfx_enabled = ms_init(gamename, gfxname, hintname, sndname);
	ms_gfx_enabled--;
	running = 1;
	while (running) {
		running = ms_rungame();
	}
	backToGameSelection();
	ms_freemem();
	return 0;
}


- (void)checkMusicForKey:(NSString *)key
{
	if (![[NSUserDefaults standardUserDefaults] integerForKey:@"wonderlandMusic"]) { return; }
	
	NSDictionary *names = @{ @"music" : @"t-mus", @"catter" : @"t-cat", @"dormou" : @"t-madt", @"croque" : @"t-croq", @"court" : @"t-crt", @"enthal" : @"t-pal" };
	
	NSString *name = names[key];
	
	if (!name) { return; }
		
	type32 length = 0;
	type16 tempo = 0;

	type8* midi = sound_extract((type8s*)[name cStringUsingEncoding:NSASCIIStringEncoding], &length, &tempo);
	if (midi != NULL) {
		[self playMidi:midi ofLength:length withTempo:tempo];
	}
}


- (void)playMidi:(unsigned char *)midi_data ofLength:(unsigned long)length withTempo:(unsigned short)tempo
{
	NSData *midiData = [NSData dataWithBytes:midi_data length:length];
	[self performSelectorOnMainThread:@selector(playMidiData:) withObject:midiData waitUntilDone:NO];
}


- (void)playMidiData:(NSData *)data
{
	if (![[NSUserDefaults standardUserDefaults] integerForKey:@"wonderlandMusic"] || [data isEqualToData:self.currentlyPlayingMidiData]) { return; }
	
	QTDataReference *dataRef = [QTDataReference dataReferenceWithReferenceToData:data name:@".midi" MIMEType:@"audio/midi"];
	NSError *error = nil;
	QTMovie *midi = [[[QTMovie alloc] initWithDataReference:dataRef error:&error] autorelease];
	if (error) {
		[gameSelectController stopQtSound];
	} else {
		self.currentlyPlayingMidiData = data;
		[gameSelectController playQtSound:midi];
	}
}


void playMidi(unsigned char *midi_data, unsigned long length, unsigned short tempo)
{
    NSAutoreleasePool *localPool;
    localPool = [[NSAutoreleasePool alloc] init];
    [[MagneticController sharedController] playMidi:midi_data ofLength:length withTempo:tempo];
    [localPool release];
}


void ms_playmusic(type8 *midi_data, type32 length, type16 tempo)
{
	playMidi(midi_data, length, tempo);
}


- (void)windowDidBecomeKey:(NSNotification *)aNotification
{
	NSFontManager *fontManager = [NSFontManager sharedFontManager];
	[[fontManager fontPanel:NO] orderOut:nil];
}


- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames
{
	BOOL isLoadSheetOpen = [fileSelectionController isLoadSheetOpen];
	
	if (([magneticWindow attachedSheet] || [selectGameWindow attachedSheet]) && !isLoadSheetOpen) {
		[NSApp replyToOpenOrPrint:NSApplicationDelegateReplyCancel];
		return;
	}
	
	if ([magneticWindow isMiniaturized]) {
		[magneticWindow makeKeyAndOrderFront:self];
	} else if ([selectGameWindow isMiniaturized]) {
		[selectGameWindow makeKeyAndOrderFront:self];
	}
	
	NSString *mainPath = filenames[0];
	
	NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:mainPath error:nil];
	NSString *fileType = fileAttributes[NSFileType];
	if ([fileType isEqual:NSFileTypeDirectory] && ![[NSWorkspace sharedWorkspace] isFilePackageAtPath:mainPath]) { // prevent "force-drag"-error (alt+cmd)
		[NSApp replyToOpenOrPrint:NSApplicationDelegateReplyCancel];
		return;
	}
	
	if ([selectedGame count]) { // a game is running ... try to load saved game
		
		if ([selectedGame[2] isEqual:[mainPath pathExtension]]) { // correct saved game for the game currently running ... load it, or progress-warning
			
			if (isLoadSheetOpen) {
				[fileSelectionController cancel:self];
			}
			
			self.externalLoad = mainPath;
			[self openFile:NULL];
			
		} else if ([[mainPath pathExtension]isEqual:@"rec"]) { // its a script - try to run it
			
			if (![self orderPossible]) {
				[self answerFirstAlert];
			} else {
				[self runScript:mainPath];
				if ([orderBuffer count]) {
					[self transferOrder];
				}
			}
			
		}
		/*else // saved game for another game than the one currently running ... do nothing, or give wrong-game-alert
		{

		}*/
	} else { // NO game is running ... try to start game
		
		if (isLoadSheetOpen) {
			[fileSelectionController cancel:self];
		}
		
		self.externalLoad = mainPath;
		[gameSelectController externalStart:mainPath];
		
	}
	
	[NSApp replyToOpenOrPrint:NSApplicationDelegateReplySuccess];
}


- (void)windowWillStartLiveResize:(NSNotification *)notification
{
	[self markLastVisibleGlyph];
}


- (void)windowDidEndLiveResize:(NSNotification *)notification
{
	// [self jumpToGlyph];
	[magneticTextView resetNuller];
	[[NSRunLoop currentRunLoop] performSelector:@selector(jumpToGlyph) target:self argument:nil order:9999 modes:@[NSDefaultRunLoopMode]];
}


- (void)windowWillEnterFullScreen:(NSNotification *)notification
{
	[self markLastVisibleGlyph];
	isFullscreenStatusChanging = YES;

	borderValue = 0;
	
	[self updateUI];
}


- (void)windowDidEnterFullScreen:(NSNotification *)notification
{
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"isFullscreen"];
	isFullscreenStatusChanging = NO;
	
	if (!isStartingGameComplete) {
		[self completeStartingGame];
	}
}


- (void)windowWillExitFullScreen:(NSNotification *)notification
{
	[self markLastVisibleGlyph];
	isFullscreenStatusChanging = YES;

	borderValue = 22;
	
	[self updateUI];
}


- (void)windowDidExitFullScreen:(NSNotification *)notification
{
	[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"isFullscreen"];
	isFullscreenStatusChanging = NO;
}


- (void)updateFirstResponder
{
	[magneticWindow makeFirstResponder:magneticTextView];
	[magneticTextView setSelectedRange:NSMakeRange([[magneticTextView textStorage] length], 0)];
}


- (NSMutableArray *)animPicArray;
{
	[self completeAnim]; // this is (only) used from GIF-export ... so the anim needs to be completely generated here
	return animPicArray;
}


- (BOOL)isAlertOpen
{
	if ([magneticWindow attachedSheet] || [selectGameWindow attachedSheet]) {
		return YES;
	} else {
		return NO;
	}
}


- (void)clearPromptAfterCancelingSaveOrLoad
{
	NSString *lowercaseOrder = [[magneticTextView inlineOrderString] lowercaseString];
	if (![lowercaseOrder length]) { return; }
	NSString *checkString = [lowercaseOrder stringByAppendingString:@"          "];
	
	if ([[checkString substringToIndex:5] isEqual:@"save "] || [[checkString substringToIndex:5] isEqual:@"load "] || [[checkString substringToIndex:8] isEqual:@"restore "]) {
		[magneticTextView replaceOrder:@""];
	}
	
	[magneticTextView setIsTypingAllowed:YES];
}


- (CGFloat)currentContentWidth
{
	NSRect frameRect = [[magneticWindow contentView] frame];
	
	float newWidth = frameRect.size.width;
	float maxContentWidth = ceilf([[self currentTemplate][@"maxContentWidth"] floatValue]);
	if (!maxContentWidth) { maxContentWidth = 10000; }
	
	if (maxContentWidth > newWidth - 32) {
		maxContentWidth = newWidth - 32;
	}
	
	return maxContentWidth;
}


- (NSImage *)currentImage
{
	return [imageView image];
}


@end
