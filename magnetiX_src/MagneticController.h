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

@class PreferenceController;
@class MXFSController;
@class MXScrollView;
@class MXTextView;

typedef OSStatus (*CallBackType)(int);

@interface MagneticController : NSObject
{
    IBOutlet MXTextView *magneticTextView;
	IBOutlet MXScrollView *magneticScrollView;
    IBOutlet NSWindow *magneticWindow;
    IBOutlet NSWindow *selectGameWindow;
    IBOutlet id imageView;
    IBOutlet NSTextField *statusTextLeft;
    IBOutlet NSTextField *statusTextRight;
    IBOutlet NSMenuItem *lastCommandMenuItem;
    IBOutlet NSMenuItem *nextCommandMenuItem;
    IBOutlet NSTabView *gameSelectTabView;
    IBOutlet id hintPanel;
    IBOutlet NSOutlineView *hintOutlineView;
    IBOutlet id gameSelectController;
    IBOutlet id hintDataSource;
    IBOutlet id limiterView;
	IBOutlet NSArrayController *arrayController;
    IBOutlet id viewMenu;

	PreferenceController *preferenceController;
	MXFSController *fileSelectionController;
	float borderValue;
	NSArray *selectedGame;
	NSPipe *orderPipe;
	int currentImageSize;
	int invalidatedCursorRectsWithImageSize;
	bool quitInProgress;
	bool closeInProgress;
	NSMutableArray *orderBuffer;
	NSMutableArray *orderHistory;
	NSMutableIndexSet *ordersForScript;
	NSMutableArray *uglyRanges;
	NSUInteger currentOrder;
	int animMode;
	int currentAnimFrame;
	NSMutableArray *animPicArray;
	NSTimer *animTimer;
	int loadWithProgress;
	bool isMagneticWindows;
	float stringHeight;
	NSUInteger theGlyphIndex;
	BOOL glyphType;
	float glyphOverlap;
	NSTimeInterval lastFontChange;
	NSRange workaroundRange;
	BOOL isFullscreenStatusChanging;
	BOOL isTemplateChanging;
	BOOL hasGraphics;
	NSLock *loadSaveMWLock;
	BOOL isPawnLoadException;
	BOOL isFishTerminalException;
	BOOL isStartingGameComplete;
	NSUInteger imageRangeLocation;
	NSUInteger newImageToSave;
	NSUInteger statusRangeLocation;
	BOOL isJumpingBlocked;
	BOOL isUpdateMissing;
	SEL missingPrefsUpdate;
}
- (IBAction)showPreferencePanel:(id)sender;
- (IBAction)openScript:(id)sender;
- (IBAction)saveAsScript:(id)sender;
- (IBAction)openFile:(id)sender;
- (IBAction)saveFile:(id)sender;
- (IBAction)trashFile:(id)sender;
- (IBAction)lastCommand:(id)sender;
- (IBAction)nextCommand:(id)sender;
- (IBAction)undoCommand:(id)sender;
- (IBAction)showHints:(id)sender;
- (IBAction)quickSelectTemplate:(id)sender;
- (IBAction)updateUse8BitGraphics:(id)sender;

- (void)startGame:(NSArray *)aGame from:(id)sender;
- (void)changeFreePictureSize;
- (NSSize)maxImageSize;
- (void)markLastVisibleGlyph;
- (void)loadNONMagneticWindowsWithPath:(NSString *)path;
- (void)loadMagneticWindows;
- (void)disableMore;
- (BOOL)scrollMore;
- (NSMutableArray *)animPicArray;
- (void)enterOrderString:(NSString *)order;
- (void)enterQuickAnswerWithString:(NSString *)answer;
- (void)updateUI;
- (void)updateUIPossibly;
- (NSArray *)selectedGame;
- (void)makeFullsizeImage:(BOOL)newValue;
- (BOOL)isImageFullSize;
- (NSUInteger)theGlyphIndex;
- (void)mainRestoreStatus:(NSString *)text;
- (void)showImage:(NSString *)cacheKey;
- (NSString *)imageTitle;
- (NSString *)previewText;
- (NSString *)savedGamesFolderForCurrentGame;
- (void)saveSheetClosedWithSaving:(BOOL)isSaving;
- (void)loadSheetClosedWithLoading:(NSString *)path;
- (CGFloat)currentContentWidth;
- (NSImage *)currentImage;

@property (retain) NSString *externalLoad;
@property (retain) NSString *customHintPath;
@property (retain) NSMutableArray *templatesArray;
@property (retain) NSMutableDictionary *currentTemplate;
@property (retain) NSFont *gameTextFont;
@property (retain) NSDictionary *userAttributes;
@property (retain) NSDictionary *gameAttributes;
@property (retain) NSDictionary *textFieldAttributes;
@property (assign) BOOL isAppFullyStarted;
@property (assign) int quickAnswerType;
@property (assign) BOOL isScriptPlaying;
@property (assign) BOOL isLoadAtGameStart;
@property (assign) BOOL hideNextOrder;
@property (assign) BOOL isImageResizeBlocked;
@property (retain) NSString *currentlyShownStatus;
@property (retain) NSString *latestStatus;
@property (retain) NSString *lastSavedImage;
@property (retain) NSImage *currentPreview;
@property (retain) NSString *currentlyShownImage;
@property (retain) NSImage *animBaseImage;
@property (retain) NSDictionary *cropDic;
@property (retain) NSDictionary *colCorDic;
@property (retain) NSData *mwSaveGameData;
@property (retain) NSValue *mwLoadGameValue;
@property (retain) NSData *currentlyPlayingMidiData;
@property (assign) BOOL isColorTimerStarted;
@property (assign) BOOL isFontTimerStarted;
@property (assign) BOOL use8BitGraphics;

@end
