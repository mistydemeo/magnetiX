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

#import "GameSelectController.h"
#import "MXStatusView.h"
#import "MagneticController.h"
#import "MXCoverView.h"
#import <QuartzCore/QuartzCore.h>

@implementation GameSelectController

- (NSString *)checkForFile:(NSString *)filename
{
	NSFileManager *defaultManager = [NSFileManager defaultManager];
	if ([defaultManager fileExistsAtPath: [gamefilesPath stringByAppendingPathComponent:filename]]) {
		return [gamefilesPath stringByAppendingPathComponent:filename]; 
	} else if ([defaultManager fileExistsAtPath: [userAppsupportPath stringByAppendingPathComponent:filename]]) {
		return [userAppsupportPath stringByAppendingPathComponent:filename]; 
	} else if ([defaultManager fileExistsAtPath: [localAppsupportPath stringByAppendingPathComponent:filename]]) {
		return [localAppsupportPath stringByAppendingPathComponent:filename]; 
	} else {
		
		BOOL isDir = NO;
		
		if (![defaultManager fileExistsAtPath: _altInstallPath isDirectory:&isDir] || !isDir) {
			[self updateFileFolderPathFromBookmark];
		}
		
		if ([defaultManager fileExistsAtPath: [_altInstallPath stringByAppendingPathComponent:filename]]) {
			NSRange trashRange = [_altInstallPath rangeOfString:userTrash]; // only use file if its not in the trash!
			NSRange trashesRange = [_altInstallPath rangeOfString:@"/.Trashes/"];
			
			if (trashRange.location != NSNotFound || trashesRange.location != NSNotFound) {
				return nil;
			} else {
				return [_altInstallPath stringByAppendingPathComponent:filename];
			}
		}
		
	}
	
	return nil;
}


- (void)updateFileFolderPathFromBookmark
{
	NSData *bookmarkData = [[NSUserDefaults standardUserDefaults] dataForKey:@"gameFilesBookmarkData"];
	if (bookmarkData) {
		NSURL *URL = [NSURL URLByResolvingBookmarkData:bookmarkData options:NSURLBookmarkResolutionWithoutUI relativeToURL:nil bookmarkDataIsStale:NO error:nil];
		if (URL) {
			self.altInstallPath = [URL path];
		}
	}
}


- (void)awakeFromNib
{
	theGames = [@[@[@"pawn", @"The Pawn", @"mX0"],
					@[@"guild", @"The Guild of Thieves", @"mX1"],
					@[@"jinxter" ,@"Jinxter", @"mX2"],
					@[@"corrupt", @"Corruption", @"mX3"],
					@[@"fish", @"Fish", @"mX4"],
					@[@"myth", @"Myth", @"mX5"],
					@[@"wonder", @"Wonderland", @"mX6", @"wonder"],
					@[@"cguild", @"The Guild of Thieves (MW)", @"mX7", @"coll"],
					@[@"ccorrupt", @"Corruption (MW)", @"mX8", @"coll"],
					@[@"cfish", @"Fish (MW)", @"mX9", @"coll"]] retain];
	
	uiPath = [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/ui/"] retain];	
	gamefilesPath = [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/gamefiles/"] retain];
	userAppsupportPath = [[@"~/Library/Application Support/magnetiX/" stringByExpandingTildeInPath] retain];
	localAppsupportPath = [@"/Library/Application Support/magnetiX/" retain];
	userTrash = [[@"~/.Trash/" stringByExpandingTildeInPath] retain];
	
	removedTabViewItems = [[NSMutableArray alloc] initWithCapacity:1];
	    
	[textPawn setTextContainerInset:NSMakeSize(9,0)];
	[textGuild setTextContainerInset:NSMakeSize(9,0)];
	[textJinxter setTextContainerInset:NSMakeSize(9,0)];
	[textCorruption setTextContainerInset:NSMakeSize(9,0)];
	[textFish setTextContainerInset:NSMakeSize(9,0)];
	[textMyth setTextContainerInset:NSMakeSize(9,0)];
	[textWonderland setTextContainerInset:NSMakeSize(9,0)];
	
	[self updateFileFolderPathFromBookmark];
	
	[self adaptUI];
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(QTMovieDidEnd) name:QTMovieDidEndNotification object:nil];
}


- (IBAction)locateDirectory:(id)sender
{
	[installButton highlight:NO];

	NSOpenPanel *resultPanel  = [NSOpenPanel openPanel];
	[resultPanel setCanChooseFiles:NO];
	[resultPanel setCanChooseDirectories:YES];
	[resultPanel setAllowsMultipleSelection:NO];
	
	[resultPanel beginSheetModalForWindow:selectGameWindow completionHandler:^(NSInteger result) {
        if (NSFileHandlingPanelOKButton == result) {
			
			NSURL *URL = [resultPanel URLs][0];
			NSData *bookmarkData = [URL bookmarkDataWithOptions:NSURLBookmarkCreationMinimalBookmark includingResourceValuesForKeys:nil relativeToURL:nil error:nil];

			if (bookmarkData) {
				[[NSUserDefaults standardUserDefaults] setObject:bookmarkData forKey:@"gameFilesBookmarkData"];
				self.altInstallPath = [URL path];
			
				[gameSelectTabView addTabViewItem: removedTabViewItems[0]];
				[gameSelectTabView addTabViewItem: removedTabViewItems[4]];
				[gameSelectTabView addTabViewItem: removedTabViewItems[1]];
				[gameSelectTabView addTabViewItem: removedTabViewItems[5]];
				[gameSelectTabView addTabViewItem: removedTabViewItems[6]];
				[gameSelectTabView addTabViewItem: removedTabViewItems[2]];
				[gameSelectTabView addTabViewItem: removedTabViewItems[3]];
				
				[removedTabViewItems removeAllObjects];
				
				[self adaptUI];
			}
            
        }
    }];

}


- (NSImage *)coverPawn
{
	if (!coverPawn) {
		coverPawn = [[NSImage imageNamed:@"cover_pawn"] retain];
	}
	return coverPawn;
}
- (NSImage *)coverGuild
{
	if (!coverGuild) {
		coverGuild = [[NSImage imageNamed:@"cover_guild"] retain];
	}
	return coverGuild;
}
- (NSImage *)coverJinxter
{
	if (!coverJinxter) {
		coverJinxter = [[NSImage imageNamed:@"cover_jinxter"] retain];
	}
	return coverJinxter;
}
- (NSImage *)coverCorruption
{
	if (!coverCorruption) {
		coverCorruption = [[NSImage imageNamed:@"cover_corrupt"] retain];
	}
	return coverCorruption;
}
- (NSImage *)coverFish
{
	if (!coverFish) {
		coverFish = [[NSImage imageNamed:@"cover_fish"] retain];
	}
	return coverFish;
}
- (NSImage *)coverMyth
{
	if (!coverMyth) {
		coverMyth = [[NSImage imageNamed:@"cover_myth"] retain];
	}
	return coverMyth;
}
- (NSImage *)coverCollection
{
	if (!coverCollection) {
		coverCollection = [[NSImage imageNamed:@"cover_collection"] retain];
	}
	return coverCollection;
}
- (NSImage *)coverCollectionFish
{
	if (!coverCollectionFish) {
		coverCollectionFish = [[NSImage imageNamed:@"cover_collection_fish"] retain];
	}
	return coverCollectionFish;
}
- (NSImage *)coverCollectionCorruption
{
	if (!coverCollectionCorruption) {
		coverCollectionCorruption = [[NSImage imageNamed:@"cover_collection_corruption"] retain];
	}
	return coverCollectionCorruption;
}
- (NSImage *)coverCollectionGuild
{
	if (!coverCollectionGuild) {
		coverCollectionGuild = [[NSImage imageNamed:@"cover_collection_guild"] retain];
	}
	return coverCollectionGuild;
}
- (NSImage *)coverWonderland
{
	if (!coverWonderland) {
		coverWonderland = [[NSImage imageNamed:@"cover_wonder"] retain];
	}
	return coverWonderland;
}


- (void)adaptUI
{
	NSInteger gameSelected = [[NSUserDefaults standardUserDefaults] integerForKey:@"gameSelected"];

// *** THE PAWN ***

	if (![self checkForFile:@"pawn.mag"]) {
		if (gameSelected == 1) { gameSelected = 20; }
		[removedTabViewItems addObject:[gameSelectTabView tabViewItemAtIndex:[gameSelectTabView indexOfTabViewItemWithIdentifier:@"1"]]];
		[gameSelectTabView removeTabViewItem:[gameSelectTabView tabViewItemAtIndex:[gameSelectTabView indexOfTabViewItemWithIdentifier:@"1"]]];
	} else {
		[picPawn setCover:[self coverPawn]];
		if (![self checkForFile:@"pawn.mp3"]) {
			[musicPawn setHidden:YES];
		}
	}

// *** JINXTER ***

	if (![self checkForFile:@"jinxter.mag"]) {
		if (gameSelected == 3) { gameSelected = 20; }
		[removedTabViewItems addObject:[gameSelectTabView tabViewItemAtIndex:[gameSelectTabView indexOfTabViewItemWithIdentifier:@"3"]]];
		[gameSelectTabView removeTabViewItem:[gameSelectTabView tabViewItemAtIndex:[gameSelectTabView indexOfTabViewItemWithIdentifier:@"3"]]];
	} else {
		[picJinxter setCover:[self coverJinxter]];
		if (![self checkForFile:@"jinxter.mp3"]) {
			[musicJinxter setHidden:YES];
		}
	}

// *** MYTH ***

	if (![self checkForFile:@"myth.mag"]) {
		if (gameSelected == 6) { gameSelected = 20; }
		[removedTabViewItems addObject:[gameSelectTabView tabViewItemAtIndex:[gameSelectTabView indexOfTabViewItemWithIdentifier:@"6"]]];
		[gameSelectTabView removeTabViewItem:[gameSelectTabView tabViewItemAtIndex:[gameSelectTabView indexOfTabViewItemWithIdentifier:@"6"]]];
	} else {
		[picMyth setCover:[self coverMyth]];
	}

// *** WONDERLAND ***

	if (![self checkForFile:@"wonder.mag"]) {
		if (gameSelected == 7) { gameSelected = 20; }
		[removedTabViewItems addObject:[gameSelectTabView tabViewItemAtIndex:[gameSelectTabView indexOfTabViewItemWithIdentifier:@"7"]]];
		[gameSelectTabView removeTabViewItem:[gameSelectTabView tabViewItemAtIndex:[gameSelectTabView indexOfTabViewItemWithIdentifier:@"7"]]];
	} else {
		[picWonderland setCover:[self coverWonderland]];
		if (![self checkForFile:@"wonder.mp3"]) {
			[musicWonder setHidden:YES];
		}
	}

// *** THE GUILD OF THIEVES ***

	if (![self checkForFile:@"guild.mag"] && ![self checkForFile:@"cguild.mag"]) {
		if (gameSelected == 2) { gameSelected = 20; }
		[removedTabViewItems addObject:[gameSelectTabView tabViewItemAtIndex:[gameSelectTabView indexOfTabViewItemWithIdentifier:@"2"]]];
		[gameSelectTabView removeTabViewItem:[gameSelectTabView tabViewItemAtIndex:[gameSelectTabView indexOfTabViewItemWithIdentifier:@"2"]]];
	} else {
		if (![self checkForFile:@"guild.mag"]) {
			[swapGuildPopUp setHidden:YES];
			if (gameSelected == 2) { gameSelected = 8; }
			[self setGuildCollectionCover];
			[[gameSelectTabView tabViewItemAtIndex:[gameSelectTabView indexOfTabViewItemWithIdentifier:@"2"]] setIdentifier:@"8"];
		} else {
			[self setGuildCover];
		}
		
		if (![self checkForFile:@"cguild.mag"]) {
			[swapGuildPopUp setHidden:YES];
		} else {
			if (gameSelected == 8) {
				if ([gameSelectTabView indexOfTabViewItemWithIdentifier:@"8"] == NSNotFound) {
					[self setGuildCollectionCover];
					[[gameSelectTabView tabViewItemAtIndex:[gameSelectTabView indexOfTabViewItemWithIdentifier:@"2"]] setIdentifier:@"8"];
				}
				[gameSelectTabView selectTabViewItemWithIdentifier:@"8"];
				[swapGuildPopUp selectItemAtIndex:1];
			}
		}
	}

// *** CORRUPTION ***

	if (![self checkForFile:@"corrupt.mag"] && ![self checkForFile:@"ccorrupt.mag"]) {
		if (gameSelected == 4) { gameSelected = 20; }
		[removedTabViewItems addObject:[gameSelectTabView tabViewItemAtIndex:[gameSelectTabView indexOfTabViewItemWithIdentifier:@"4"]]];
		[gameSelectTabView removeTabViewItem:[gameSelectTabView tabViewItemAtIndex:[gameSelectTabView indexOfTabViewItemWithIdentifier:@"4"]]];
	} else {
		if (![self checkForFile:@"corrupt.mp3"]) {
			[musicCorruption setHidden:YES];
		}
		
		if (![self checkForFile:@"corrupt.mag"]) {
			[swapCorruptionPopUp setHidden:YES];
			if (gameSelected == 4) { gameSelected = 9; }
			[self setCorruptionCollectionCover];
			[[gameSelectTabView tabViewItemAtIndex:[gameSelectTabView indexOfTabViewItemWithIdentifier:@"4"]] setIdentifier:@"9"];
		} else {
			[self setCorruptionCover];
		}
		
		if (![self checkForFile:@"ccorrupt.mag"]) {
			[swapCorruptionPopUp setHidden:YES];
		} else {
			if (gameSelected == 9) {
				if ([gameSelectTabView indexOfTabViewItemWithIdentifier:@"9"] == NSNotFound) {
					[self setCorruptionCollectionCover];
					[[gameSelectTabView tabViewItemAtIndex:[gameSelectTabView indexOfTabViewItemWithIdentifier:@"4"]] setIdentifier:@"9"];
				}
				[gameSelectTabView selectTabViewItemWithIdentifier:@"9"];
				[swapCorruptionPopUp selectItemAtIndex:1];
			}
		}
	}

// *** FISH! ***

	if (![self checkForFile:@"fish.mag"] && ![self checkForFile:@"cfish.mag"]) {
		if (gameSelected == 5) { gameSelected = 20; }
		[removedTabViewItems addObject:[gameSelectTabView tabViewItemAtIndex:[gameSelectTabView indexOfTabViewItemWithIdentifier:@"5"]]];
		[gameSelectTabView removeTabViewItem:[gameSelectTabView tabViewItemAtIndex:[gameSelectTabView indexOfTabViewItemWithIdentifier:@"5"]]];
	} else {
		if (![self checkForFile:@"fish.mp3"]) {
			[musicFish setHidden:YES];
		}
		
		if (![self checkForFile:@"fish.mag"]) {
			[swapFishPopUp setHidden:YES];
			if (gameSelected == 5) { gameSelected = 10; }
			[self setFishCollectionCover];
			[[gameSelectTabView tabViewItemAtIndex:[gameSelectTabView indexOfTabViewItemWithIdentifier:@"5"]] setIdentifier:@"10"];
		} else {
			[self setFishCover];
		}
		
		if (![self checkForFile:@"cfish.mag"]) {
			[swapFishPopUp setHidden:YES];
		} else {
			if (gameSelected == 10) {
				if ([gameSelectTabView indexOfTabViewItemWithIdentifier:@"10"] == NSNotFound) {
					[self setFishCollectionCover];
					[[gameSelectTabView tabViewItemAtIndex:[gameSelectTabView indexOfTabViewItemWithIdentifier:@"5"]] setIdentifier:@"10"];
				}
				[gameSelectTabView selectTabViewItemWithIdentifier:@"10"];
				[swapFishPopUp selectItemAtIndex:1];
			}
		}
	}


	if (gameSelected && gameSelected < 8) {
		[gameSelectTabView selectTabViewItemWithIdentifier:[NSString stringWithFormat:@"%li", (long)gameSelected]];
	}
	
	if ([[gameSelectTabView tabViewItems] count] > 1) {
		[selectGameWindow setTitle:@"magnetiX - Please select game"];
		[gameSelectTabView removeTabViewItem:[gameSelectTabView tabViewItemAtIndex:[gameSelectTabView indexOfTabViewItemWithIdentifier:@"install"]]];
	} else {
		[selectGameWindow setTitle:@"magnetiX - No game installed!"];
		[textInstall setTextContainerInset:NSMakeSize(55,0)];
	}
}


- (IBAction)swapGuild:(id)sender
{	
	if ([sender indexOfSelectedItem] == 1) {
		[self setGuildCollectionCover];
		[[gameSelectTabView selectedTabViewItem] setIdentifier:@"8"];
		[[NSUserDefaults standardUserDefaults] setInteger:8 forKey:@"gameSelected"];
	} else {
		[self setGuildCover];
		[[gameSelectTabView selectedTabViewItem] setIdentifier:@"2"];
		[[NSUserDefaults standardUserDefaults] setInteger:2 forKey:@"gameSelected"];
	}
}


- (IBAction)swapCorruption:(id)sender
{
	if ([sender indexOfSelectedItem] == 1) {
		[self setCorruptionCollectionCover];
		[[gameSelectTabView selectedTabViewItem] setIdentifier:@"9"];
		[[NSUserDefaults standardUserDefaults] setInteger:9 forKey:@"gameSelected"];
	} else {
		[self setCorruptionCover];
		[self resizeCorruption:-53];
		[[gameSelectTabView selectedTabViewItem] setIdentifier:@"4"];
		[[NSUserDefaults standardUserDefaults] setInteger:4 forKey:@"gameSelected"];
	}
}


- (void)resizeCorruption:(int)moveValue
{
	NSRect guiRect = [picCorruption frame];
	if ((guiRect.size.height == 304 && moveValue > 0 ) || (guiRect.size.height == 357 && moveValue < 0)) {
		[picCorruption setFrameSize:NSMakeSize(guiRect.size.width, guiRect.size.height + moveValue)];
		[picCorruption setFrameOrigin:NSMakePoint(guiRect.origin.x, guiRect.origin.y - moveValue)];
		guiRect = [musicCorruption frame];
		[musicCorruption setFrameOrigin:NSMakePoint(guiRect.origin.x, guiRect.origin.y - moveValue)];
	}
}


- (void)updateCollectionAnim
{
	// stop all
	[[picFishOverlay layer] removeAllAnimations];
	[[picCorruptionOverlay layer] removeAllAnimations];
	[[picGuildOverlay layer] removeAllAnimations];

	
	// start if one is visible
	id subviews = [[[gameSelectTabView selectedTabViewItem] view] subviews];
	
	id view = nil;
	if ([subviews containsObject:picFishOverlay]) {
		view = picFishOverlay;
	} else if ([subviews containsObject:picCorruptionOverlay]) {
		view = picCorruptionOverlay;
	} else if ([subviews containsObject:picGuildOverlay]) {
		view = picGuildOverlay;
	}
	
	if (!view) { return; }
	
	CABasicAnimation *blink = [CABasicAnimation animationWithKeyPath:@"opacity"];
	blink.fromValue = [NSNumber numberWithFloat:0.0];
	blink.toValue = [NSNumber numberWithFloat:1.0];
	blink.duration = 1;
	blink.autoreverses = YES;
	blink.repeatCount = FLT_MAX;
	blink.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
	
	[[view layer] addAnimation:blink forKey:@"blinkAnim"];
}


- (IBAction)swapFish:(id)sender
{
	if ([sender indexOfSelectedItem] == 1) {
		[self setFishCollectionCover];
		[self resizeFish:-114];
		[[gameSelectTabView selectedTabViewItem] setIdentifier:@"10"];
		[[NSUserDefaults standardUserDefaults] setInteger:10 forKey:@"gameSelected"];
	} else {
		[self setFishCover];
		[[gameSelectTabView selectedTabViewItem] setIdentifier:@"5"];
		[[NSUserDefaults standardUserDefaults] setInteger:5 forKey:@"gameSelected"];
	}
}


- (void)setFishCover
{
	[picFish setCover:[self coverFish]];
	[picFishOverlay setCover:nil];
	[self updateCollectionAnim];
}


- (void)setFishCollectionCover
{
	[picFish setCover:[self coverCollection]];
	[picFishOverlay setCover:[self coverCollectionFish]];
	[self updateCollectionAnim];
	
	[self resizeFish:114];
}


- (void)setCorruptionCover
{
	[picCorruption setCover:[self coverCorruption]];
	[picCorruptionOverlay setCover:nil];
	[self updateCollectionAnim];
}


- (void)setCorruptionCollectionCover
{
	[picCorruption setCover:[self coverCollection]];
	[picCorruptionOverlay setCover:[self coverCollectionCorruption]];
	[self updateCollectionAnim];
	
	[self resizeCorruption:53];
}


- (void)setGuildCover
{
	[picGuild setCover:[self coverGuild]];
	[picGuildOverlay setCover:nil];
	[self updateCollectionAnim];
}


- (void)setGuildCollectionCover
{
	[picGuild setCover:[self coverCollection]];
	[picGuildOverlay setCover:[self coverCollectionGuild]];
	[self updateCollectionAnim];
}


- (void)resizeFish:(int)moveValue
{
	NSRect guiRect = [picFish frame];
	if ((guiRect.size.height == 243 && moveValue > 0 ) || (guiRect.size.height == 357 && moveValue < 0)) {
		[picFish setFrameSize:NSMakeSize(guiRect.size.width, guiRect.size.height + moveValue)];
		[picFish setFrameOrigin:NSMakePoint(guiRect.origin.x, guiRect.origin.y - moveValue)];
		guiRect = [musicFish frame];
		[musicFish setFrameOrigin:NSMakePoint(guiRect.origin.x, guiRect.origin.y - moveValue)];
	}
}


- (void)playQtSound:(QTMovie *)newSound
{
	if (isQtSoundPlaying) {
		[self.qtSound stop];
	}
	
	self.qtSound = newSound;
    
	[newSound play];
	isQtSoundPlaying = YES;
}


- (void)stopQtSound
{
	[magneticController setCurrentlyPlayingMidiData:nil];
	
	if (isQtSoundPlaying) {
		[self.qtSound stop];
		isQtSoundPlaying = NO;
	}
}


- (void)QTMovieDidEnd
{
	[magneticController setCurrentlyPlayingMidiData:nil];

	isQtSoundPlaying = NO;
	
	if (![magneticController selectedGame]) {
		[self changeMusicButton:NSOffState];
	}
}


- (void)playTitleMusic:(NSURL *)theUrl
{
	QTMovie *mp3 = [[[QTMovie alloc] initWithURL:theUrl error:nil] autorelease];
	[self playQtSound:mp3];
}


- (IBAction)toggleMusic:(id)sender
{
	int currentGame = [[[gameSelectTabView selectedTabViewItem] identifier] intValue] - 1;
	if (currentGame > 7){ currentGame -= 5; }
	if (!isQtSoundPlaying) {
		[self playTitleMusic:[NSURL fileURLWithPath:[self checkForFile: [theGames[currentGame][0] stringByAppendingString:@".mp3"]]]];
	} else {
		[self.qtSound stop];
		isQtSoundPlaying = NO;
	}
}


- (void)changeMusicButton:(NSInteger)newState
{
	if ([gameSelectTabView indexOfTabViewItemWithIdentifier:@"1"] != NSNotFound) { [musicPawn setState:newState]; }
	if ([gameSelectTabView indexOfTabViewItemWithIdentifier:@"3"] != NSNotFound) { [musicJinxter setState:newState]; }
	if ([gameSelectTabView indexOfTabViewItemWithIdentifier:@"4"] != NSNotFound ||
		[gameSelectTabView indexOfTabViewItemWithIdentifier:@"9"] != NSNotFound) { [musicCorruption setState:newState]; }
	if ([gameSelectTabView indexOfTabViewItemWithIdentifier:@"5"] != NSNotFound ||
		[gameSelectTabView indexOfTabViewItemWithIdentifier:@"10"] != NSNotFound) { [musicFish setState:newState]; }
	if ([gameSelectTabView indexOfTabViewItemWithIdentifier:@"7"] != NSNotFound) { [musicWonder setState:newState]; }
}


- (IBAction)start:(id)sender
{
	if ([magneticController selectedGame]) { // SHOULD not happen ... but could for nine years ... so to be totally sure ... *cough*
		[selectGameWindow orderOut:self];
		[magneticWindow makeKeyAndOrderFront:self];
		return;
	}
	
	if (isQtSoundPlaying) {
		[_qtSound stop];
		isQtSoundPlaying = NO;
		[self changeMusicButton:NSOffState];
	}
	[magneticController startGame:[self currentlyVisibleGame] from:sender];
}


- (id)currentlyVisibleGame
{
	return theGames[[[[gameSelectTabView selectedTabViewItem] identifier] intValue] - 1];
}


- (BOOL)checkForMW:(int)gameToCheck
{
	NSArray *gameSelectTabViewItems = [gameSelectTabView tabViewItems];
	NSEnumerator *f = [gameSelectTabViewItems objectEnumerator];
	id singleItem;
	while ((singleItem = [f nextObject]) != nil) {
		if ([[singleItem identifier] isEqual:[NSString stringWithFormat:@"%i", gameToCheck]]) {
			return TRUE;
		}
	}
	return FALSE;
}


- (void)externalStart:(NSString *)filename
{
	int gameToSelect = 0;
	NSString *gameExtension = [filename pathExtension];
	
	if ([[[gameExtension substringToIndex:2] lowercaseString] isEqual:@"mx"]) {
		gameToSelect = [[gameExtension substringFromIndex:2] intValue] + 1;
	} else { // scripts cannot be correctly assigned -> "normal start"
		[magneticController setExternalLoad:nil];
		[selectGameWindow makeKeyAndOrderFront:self];
		return;
	}
	
	if (gameToSelect > 0 && gameToSelect < 11) {
		if (gameToSelect == 2 && [self checkForFile:@"guild.mag"]) {
			if (![self checkForMW:gameToSelect]) {
				gameToSelect = 0;
				[gameSelectTabView selectTabViewItemWithIdentifier:@"8"];
				[swapGuildPopUp selectItemAtIndex:0];
				[self swapGuild:swapGuildPopUp];
			}
		} else if (gameToSelect == 4 && [self checkForFile:@"corrupt.mag"]) {
			if (![self checkForMW:gameToSelect]) {
				gameToSelect = 0;
				[gameSelectTabView selectTabViewItemWithIdentifier:@"9"];
				[swapCorruptionPopUp selectItemAtIndex:0];
				[self swapCorruption:swapCorruptionPopUp];
			}
		} else if (gameToSelect == 5 && [self checkForFile:@"fish.mag"]) {
			if (![self checkForMW:gameToSelect]) {
				gameToSelect = 0;
				[gameSelectTabView selectTabViewItemWithIdentifier:@"10"];
				[swapFishPopUp selectItemAtIndex:0];
				[self swapFish:swapFishPopUp];
			}
		} else if (gameToSelect == 8 && [self checkForFile:@"cguild.mag"]) {
			if (![self checkForMW:gameToSelect]) {
				gameToSelect = 0;
				[gameSelectTabView selectTabViewItemWithIdentifier:@"2"];
				[swapGuildPopUp selectItemAtIndex:1];
				[self swapGuild:swapGuildPopUp];
			}
		} else if (gameToSelect == 9 && [self checkForFile:@"ccorrupt.mag"]) {
			if (![self checkForMW:gameToSelect]) {
				gameToSelect = 0;
				[gameSelectTabView selectTabViewItemWithIdentifier:@"4"];
				[swapCorruptionPopUp selectItemAtIndex:1];
				[self swapCorruption:swapCorruptionPopUp];
			}
		} else if (gameToSelect == 10 && [self checkForFile:@"cfish.mag"]) {
			if (![self checkForMW:gameToSelect]) {
				gameToSelect = 0;
				[gameSelectTabView selectTabViewItemWithIdentifier:@"5"];
				[swapFishPopUp selectItemAtIndex:1];
				[self swapFish:swapFishPopUp];
			}
		}
		
		if (gameToSelect != 0) {
			
			NSString *identifier = [NSString stringWithFormat:@"%i", gameToSelect];
			if ([gameSelectTabView indexOfTabViewItemWithIdentifier:identifier] != NSNotFound) {
				[gameSelectTabView selectTabViewItemWithIdentifier:[NSString stringWithFormat:identifier, gameToSelect]];
			} else { // corresponding game not installed -> "normal start"
				[magneticController setExternalLoad:nil];
				[selectGameWindow makeKeyAndOrderFront:self];
				return;
			}
			
		}
		
		if ([[[gameSelectTabView selectedTabViewItem] identifier] intValue] > 6) { // is it a magnetic-windows game ?
			[magneticController loadMagneticWindows];
		} else {
			[magneticController loadNONMagneticWindowsWithPath:filename];
		}
		
		[magneticController setIsLoadAtGameStart:YES];
		[self start:nil];
	}
}


- (void)changeGameSelectionWith:(unichar)character
{
	if (character == ' ') {
		
		int identifier = [[[gameSelectTabView selectedTabViewItem] identifier] intValue];
		
		if (identifier == 1) {
			[[musicPawn cell] performClick:self];
		} else if (identifier == 3) {
			[[musicJinxter cell] performClick:self];
		} else if (identifier == 4 || identifier == 9) {
			[[musicCorruption cell] performClick:self];
		} else if (identifier == 5 || identifier == 10) {
			[[musicFish cell] performClick:self];
		} else if (identifier == 7) {
			[[musicWonder cell] performClick:self];
		}
		
	} else if (character == NSLeftArrowFunctionKey) {
		
		[gameSelectTabView selectPreviousTabViewItem:self];
		
	} else if (character == NSRightArrowFunctionKey) {
		
		[gameSelectTabView selectNextTabViewItem:self];
		
	} else {
		
		int identifier = [[[gameSelectTabView selectedTabViewItem] identifier] intValue];
		if (identifier == 2) {
			[swapGuildPopUp selectItemAtIndex:1];
			[self swapGuild:swapGuildPopUp];
		} else if (identifier == 8) {
			[swapGuildPopUp selectItemAtIndex:0];
			[self swapGuild:swapGuildPopUp];
		} else if (identifier == 4) {
			[swapCorruptionPopUp selectItemAtIndex:1];
			[self swapCorruption:swapCorruptionPopUp];
		} else if (identifier == 9) {
			[swapCorruptionPopUp selectItemAtIndex:0];
			[self swapCorruption:swapCorruptionPopUp];
		} else if (identifier == 5) {
			[swapFishPopUp selectItemAtIndex:1];
			[self swapFish:swapFishPopUp];
		} else if (identifier == 10) {
			[swapFishPopUp selectItemAtIndex:0];
			[self swapFish:swapFishPopUp];
		}
		
	}
}


- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{	
	[[NSUserDefaults standardUserDefaults] setInteger:[[tabViewItem identifier] intValue] forKey:@"gameSelected"];
	
	[self stopQtSound];
	[self playThemeIfNeeded];
	[self updateCollectionAnim];
}


- (void)playThemeIfNeeded
{
	if (![magneticController isAppFullyStarted]) { return; }
	
	if (![[NSUserDefaults standardUserDefaults] integerForKey:@"themeAutoplay"]) {
		[self changeMusicButton:NSOffState];
	} else if (![[[gameSelectTabView selectedTabViewItem] identifier] isEqual:@"install"]) {
		[self changeMusicButton:NSOnState];
		int currentGame = [[[gameSelectTabView selectedTabViewItem] identifier] intValue] - 1;
		if (currentGame > 7){ currentGame -= 5; }
		
		NSString *titlePath = [self checkForFile: [theGames[currentGame][0] stringByAppendingString:@".mp3"]];
		if (titlePath) {
			[self playTitleMusic:[NSURL fileURLWithPath:titlePath]];
		}
	}
}


- (IBAction)openHelpUrl:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.maczentrisch.de/magnetiX/help.php"]];
}


- (BOOL)windowShouldClose:(id)sender
{
	NSMenuItem *mi = [windowMenu addItemWithTitle:[selectGameWindow title] action:@selector(makeKeyAndOrderFront:) keyEquivalent:@""];
	[mi setTarget:selectGameWindow];
	[mi setTag:666];
	return YES;
}


- (void)windowDidBecomeMain:(NSNotification *)aNotification
{
	if ([windowMenu indexOfItemWithTag:666] != -1) {
		[windowMenu removeItemAtIndex:[windowMenu indexOfItemWithTag:666]];
	}
}


- (void)windowDidBecomeKey:(NSNotification *)aNotification
{
	NSFontManager *fontManager = [NSFontManager sharedFontManager];
	[[fontManager fontPanel:NO] orderOut:nil];
}


- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)frameSize
{
	NSSize originalWindowSize = NSMakeSize(696.0, 480.0);
	NSSize originalImageViewSize = NSMakeSize(294.0, 344.0);
	
	float imageViewHeight = frameSize.height - (originalWindowSize.height - originalImageViewSize.height);
	float maxImageViewWidth = imageViewHeight / originalImageViewSize.height * originalImageViewSize.width;
	
	float maxWindowWidth = originalWindowSize.width - originalImageViewSize.width + maxImageViewWidth - 19;
	
	if (frameSize.width > maxWindowWidth) {
		frameSize.width = maxWindowWidth;
	}
	
    return frameSize;
}


@end
