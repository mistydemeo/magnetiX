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

#import <Cocoa/Cocoa.h>
#import <QTKit/QTMovie.h>
#import <QTKit/QTDataReference.h>

@interface GameSelectController : NSObject
{
    IBOutlet id picPawn;
    IBOutlet id textPawn;
	IBOutlet id picGuild;
	IBOutlet id picGuildOverlay;
    IBOutlet id textGuild;
	IBOutlet id picJinxter;
    IBOutlet id textJinxter;
	IBOutlet id picCorruption;
	IBOutlet id picCorruptionOverlay;
    IBOutlet id textCorruption;
	IBOutlet id picFish;
	IBOutlet id picFishOverlay;
    IBOutlet id textFish;
	IBOutlet id picMyth;
    IBOutlet id textMyth;
	IBOutlet id picWonderland;
    IBOutlet id textWonderland;
    IBOutlet id textInstall;
    IBOutlet id gameSelectTabView;
	IBOutlet id swapGuildPopUp;
	IBOutlet id swapCorruptionPopUp;
	IBOutlet id swapFishPopUp;
	IBOutlet id windowMenu;
	IBOutlet id magneticController;
	IBOutlet id musicPawn;
	IBOutlet id musicJinxter;
	IBOutlet id musicCorruption;
	IBOutlet id musicFish;
	IBOutlet id musicWonder;
	IBOutlet id installButton;
	IBOutlet id selectGameWindow;
	IBOutlet id magneticWindow;

	NSArray *theGames;
	NSString *uiPath;
	NSString *gamefilesPath;
	NSString *userAppsupportPath;
	NSString *localAppsupportPath;
	NSString *userTrash;
	NSMutableArray *removedTabViewItems;
	
	NSImage *coverPawn;
	NSImage *coverGuild;
	NSImage *coverJinxter;
	NSImage *coverCorruption;
	NSImage *coverFish;
	NSImage *coverMyth;
	NSImage *coverCollection;
	NSImage *coverCollectionFish;
	NSImage *coverCollectionCorruption;
	NSImage *coverCollectionGuild;
	NSImage *coverWonderland;
	
	BOOL isQtSoundPlaying;
}
- (IBAction)swapGuild:(id)sender;
- (IBAction)swapCorruption:(id)sender;
- (IBAction)swapFish:(id)sender;
- (IBAction)toggleMusic:(id)sender;
- (IBAction)start:(id)sender;
- (IBAction)openHelpUrl:(id)sender;
- (IBAction)locateDirectory:(id)sender;
- (NSString *)checkForFile:(NSString *)filename;
- (void)externalStart:(NSString *)filename;
- (void)playQtSound:(QTMovie *)newSound;
- (void)stopQtSound;
- (void)playThemeIfNeeded;
- (void)changeGameSelectionWith:(unichar)character;
- (id)currentlyVisibleGame;

@property (retain) QTMovie *qtSound;
@property (retain) NSString *altInstallPath;

@end