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

#import "MXFSController.h"
#import "MXFSBannerView.h"

@implementation MXFSController


- (id)init
{
	self = [super initWithWindowNibName:@"FileSelection"];
	self.source = [[[NSMutableArray alloc] init] autorelease];
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(selectionChanged:) name:NSTableViewSelectionDidChangeNotification object:nil];
	[nc addObserver:self selector:@selector(save:) name:@"saveBarImageDoubleClicked" object:nil];
	[nc addObserver:self selector:@selector(refreshTableView) name:NSCurrentLocaleDidChangeNotification object:nil];
	[nc addObserver:self selector:@selector(refreshTableView) name:NSSystemTimeZoneDidChangeNotification object:nil];
	
	return self;
}


- (void)refreshTableView
{
	if (![self.window isVisible]) return;
	
	[tableView setNeedsDisplay:YES];
}


- (void)awakeFromNib
{
	[tableView setTarget:self];
	[tableView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleNone];
	[self.window setContentBorderThickness:48.0 forEdge:NSMinYEdge];
	
	[[textView enclosingScrollView] setScrollerKnobStyle:NSScrollerKnobStyleLight];
	[[tableView enclosingScrollView] setScrollerKnobStyle:NSScrollerKnobStyleLight];
	
	[self showSheet];
}


- (void)setGameData:(id)data
{
	if (![data isEqualTo:self.theGameData]) {
		self.theGameData = data;
		[tableView deselectAll:self];
		[tableView scrollToBeginningOfDocument:self];
	}
}


- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [self.source count];
}


- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	id row = self.source[rowIndex];
	
	id identifier = [aTableColumn identifier];
	id object = row[identifier];
	
	if (object == [NSNull null]) {
				
		if ([identifier isEqualToString:@"preview"]) {
		
			NSImage *previewPic = [self previewPicAtBundlePath:row[@"path"]];
			
			row[identifier] = previewPic;
			return previewPic;
			
		} else { // title
		
			NSString *previewText = [self previewTextAtBundlePath:row[@"path"]];
			
			row[identifier] = previewText;
			return previewText;
			
		}
	}
	
	return object;
}


// cellExpansions are "broken" before Mavericks (no line breaks AND white text on yellow bg) in this case ... so std. toolTips as a viable alternative
- (BOOL)tableView:(NSTableView *)tableView shouldShowCellExpansionForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_8) {
		return NO;
	}
	
	return YES;
}


- (NSString *)tableView:(NSTableView *)aTableView toolTipForCell:(NSCell *)aCell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)row mouseLocation:(NSPoint)mouseLocation
{
	if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_8) {
		if ([[aTableColumn identifier] isEqualToString:@"title"]) {
			return self.source[row][@"title"];
		}
	}
	
	return nil;
}


- (void)selectionChanged:(NSNotification *)note
{
	if (!self.isSaveMode) {
	
		NSInteger selectedRow = [tableView selectedRow];
		if (selectedRow >= 0) {
			
			if (![self.source[selectedRow][@"path"] length]) {
				[tableView deselectAll:self];
				return;
			}
			
			[loadSaveButton setEnabled:YES];
		} else {
			[loadSaveButton setEnabled:NO];
		}
		
	} else {
	
		[loadSaveButton setEnabled:YES];
		
	}
}


- (void)setMainButtonTitle:(NSString *)title
{
	[loadSaveButton setTitle:title];
	[loadSaveButton sizeToFit];
	NSRect buttonFrame = [loadSaveButton frame];
	buttonFrame.size.width += 20;
	
	NSRect windowFrame = [self.window frame];
	
	buttonFrame.origin.x = windowFrame.size.width - buttonFrame.size.width - 12;
	
	[loadSaveButton setFrame:buttonFrame];
}


- (void)showSheet
{
	if (!loadSaveButton) {
		[self openSheet];
		return;
	}
	
	if (self.isSaveMode) {
		[self showSaveSheet];
	} else {
		[self showLoadSheet];
	}
}


- (void)showLoadSheet
{
	[bannerView setBannerText:@"Load Game"];
	[bannerView setNeedsDisplay:YES];
	
	if (![saveBar isHidden]) {
		[saveBar setHidden:YES];
		
		id scrollView = [tableView enclosingScrollView];
		NSRect frame = [scrollView frame];
		frame.size.height += ([saveBar frame].size.height);
		[scrollView setFrame:frame];
	}
	
	[tableView setDoubleAction:@selector(load:)];
	
	self.isSaveMode = NO;
	[self setMainButtonTitle:@"Load"];
	[loadSaveButton setAction:@selector(load:)];
	[self showFiles];
}


- (void)showSaveSheet
{
	[bannerView setBannerText:@"Save Game"];
	[bannerView setNeedsDisplay:YES];
	
	if ([saveBar isHidden]) {
		id scrollView = [tableView enclosingScrollView];
		NSRect frame = [scrollView frame];
		frame.size.height -= ([saveBar frame].size.height);
		[scrollView setFrame:frame];
		
		[saveBar setHidden:NO];
	}
	
	[tableView setDoubleAction:nil];
	
	[textView setHidden:NO];
	
	self.isSaveMode = YES;
	[self setMainButtonTitle:@"Save"];
	[loadSaveButton setAction:@selector(save:)];
	
	[self.window makeFirstResponder:tableView];

	[tableView scrollToBeginningOfDocument:self];
	
	[self showFiles];
}


- (BOOL)textView:(NSTextView *)aTextView doCommandBySelector:(SEL)aSelector
{
    if (aSelector == @selector(insertTab:)) {
        [[aTextView window] selectNextKeyView:nil];
        return YES;
    } else if (aSelector == @selector(insertBacktab:)) {
        [[aTextView window] selectPreviousKeyView:nil];
        return YES;
    }
	
    return NO;
}


- (void)openSheet
{
	if (self.isSheetOpen) return;
	
	self.isSheetOpen = YES;
	
	[NSApp beginSheet: [self window]
	   modalForWindow: [NSApp mainWindow]
		modalDelegate: self
	   didEndSelector: @selector(sheetDidEnd:returnCode:contextInfo:)
		  contextInfo: nil];
}


- (void)updateContent
{
	if (self.isSheetOpen) { [self showFiles]; }
}


- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
{
	self.isSheetOpen = NO;
}


- (BOOL)isLoadSheetOpen
{
	if (self.isSheetOpen && !self.isSaveMode) {
		return YES;
	}
	
	return NO;
}


- (NSImage *)previewPicAtBundlePath:(NSString *)path
{
	if (self.controller.use8BitGraphics && [self.theGameData count] < 4) {
		NSData *data = [NSData dataWithContentsOfFile:[path stringByAppendingPathComponent:@"/currentData"]];
		if (data) {
			NSDictionary *dataDic = [NSUnarchiver unarchiveObjectWithData:data];
			
			NSString *path = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:[NSString stringWithFormat:@"/gamefiles/8bit/%@/%@.gif", self.theGameData[0], dataDic[@"currentlyShownImage"]]];
			NSImage *eightBitImage = [[[NSImage alloc] initWithContentsOfFile:path] autorelease];
			if (eightBitImage) {
				return eightBitImage;
			}
		}
	}
	
	
	NSImage *previewPic = [[[NSImage alloc] initWithContentsOfFile:[path stringByAppendingPathComponent:@"/previewPic.tif"]] autorelease];
	
	if (!previewPic) {
		previewPic = [[NSWorkspace sharedWorkspace] iconForFile:path];
		[previewPic setSize:NSMakeSize(145, 145)];
	}
	
	if (!previewPic) {
		previewPic = [[[NSImage alloc] initWithSize:NSMakeSize(1, 1)] autorelease];
	}
	
	return previewPic;
}


- (NSString *)previewTextAtBundlePath:(NSString *)path
{
	NSString *previewText = [[[NSString alloc] initWithContentsOfFile:[path stringByAppendingPathComponent:@"/previewText.txt"] encoding:NSUTF8StringEncoding error:nil] autorelease];
	
	if (!previewText) {
		previewText = [[path lastPathComponent] stringByDeletingPathExtension];
	}
	
	if (!previewText) {
		previewText = @"";
	}
	
	return previewText;
}


- (void)preloadLastestPreviewData
{
	id theSource = self.source;
	NSUInteger maxCount = 100;
	if (self.controller.use8BitGraphics && [self.theGameData count] < 4) {
		maxCount = 40;
	}
	
	NSUInteger sourceCount = [theSource count];
	
	if (sourceCount < maxCount) {
		maxCount = sourceCount;
	}
	
	for (int i = 0; i < maxCount; i++) {
		id row = theSource[i];
		
		NSString *path = row[@"path"];
		row[@"preview"] = [self previewPicAtBundlePath:path];
		row[@"title"] = [self previewTextAtBundlePath:path];

	}
}


- (void)showFiles
{
	NSString *path = [self.controller savedGamesFolderForCurrentGame];
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	NSArray *dirFiles = [fileManager contentsOfDirectoryAtPath:path error:nil];
	NSString *pred = [NSString stringWithFormat:@"self ENDSWITH '.%@'", self.theGameData[2]];
	NSArray *gameFiles = [dirFiles filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:pred]];
	
	[self.source removeAllObjects];
	
	int fileNr = 0;
	
	for (id filePath in gameFiles) {
		
		NSString *bundlePath = [path stringByAppendingPathComponent:filePath];
		
		NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:bundlePath error:nil];
		NSDate *modDate = [fileAttributes objectForKey:NSFileModificationDate];
		
		[self.source addObject:[[@{@"preview" : [NSNull null], @"title" : [NSNull null], @"date" : modDate, @"path" : bundlePath} mutableCopy] autorelease]];
		
		fileNr ++;
	}
	
	NSSortDescriptor *theDesc1 = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
	[self.source sortUsingDescriptors:@[theDesc1]];
	[theDesc1 release];
	
	[self preloadLastestPreviewData];
	
	if (self.isSaveMode) {
		id attributes = @{NSForegroundColorAttributeName: [NSColor whiteColor], NSFontAttributeName: [NSFont systemFontOfSize:13]};
		NSAttributedString *string = [[NSAttributedString alloc] initWithString:[self.controller previewText] attributes:attributes];
		[[textView textStorage] setAttributedString:string];
		[string release];
		[textView setTypingAttributes:attributes];
	} else {
		if (![self.source count]) {
			[self addEmptyRow];
		}
	}
	
	[tableView reloadData];
	
	if (self.isSaveMode) {
		[tableView deselectAll:nil];
	}
	
	[self selectionChanged:nil];
	
	[self openSheet];
}


- (void)addEmptyRow
{
	NSString *emptyText = [NSString stringWithFormat:@"No saved games for \"%@\", yet!\n\n( Old saved game files can still be used by double clicking them or by dragging them on the App icon in the Dock. )", self.theGameData[1]];
	[self.source addObject:@{@"preview" : [NSApp applicationIconImage], @"title" : emptyText, @"date" : @"", @"path" : @""}];

}


- (IBAction)cancel:(id)sender
{
	[NSApp endSheet:[self window]];
	[[self window] orderOut:self];
	
	if (self.isSaveMode) {
		[self.controller saveSheetClosedWithSaving:NO];
	} else {
		[self.controller loadSheetClosedWithLoading:nil];
	}
}


- (IBAction)load:(id)sender
{
	NSInteger selectedRow = [tableView selectedRow];
	if (selectedRow < 0) return;
	
	NSString *path = self.source[selectedRow][@"path"];
	if (![path length]) return;
	
	[NSApp endSheet:[self window]];
	[[self window] orderOut:self];
	
	[self.controller loadSheetClosedWithLoading:path];
}


- (NSString *)previewText
{
	return [[textView textStorage] string];
}


- (IBAction)save:(id)sender
{
	id object = @{@"preview" : [self.controller currentImage], @"title" : [self previewText], @"date" : @"", @"path" : @""};
	
	[textView setHidden:YES];
	[tableView deselectAll:self];
	[tableView scrollToBeginningOfDocument:self];
	
	[NSAnimationContext beginGrouping];
	[[NSAnimationContext currentContext] setCompletionHandler: ^{
		
		[NSApp endSheet:[self window]];
		[[self window] orderOut:self];
		
		[self.controller saveSheetClosedWithSaving:YES];
		
	}];
	
	[[NSAnimationContext currentContext] setDuration:0.75];
	
	[tableView beginUpdates];
	
	[self.source insertObject:object atIndex:0];
	[tableView insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:0] withAnimation:NSTableViewAnimationSlideLeft];
	
	[tableView endUpdates];
	
	[NSAnimationContext endGrouping];
}


- (BOOL)isTrashingPossible
{
	if ([tableView selectedRow] < 0 || ![[self window] isVisible]) return NO;
	
	return YES;
}


- (IBAction)trash:(id)sender
{
	if (![self isTrashingPossible]) return;

	NSInteger selectedRow = [tableView selectedRow];

	NSString *delPath = self.source[selectedRow][@"path"];
	NSURL *delURL = [NSURL fileURLWithPath:delPath isDirectory:NO];
	
	[[NSWorkspace sharedWorkspace] recycleURLs:@[delURL] completionHandler:^(NSDictionary *newURLs, NSError *error) {
	
		if (error == nil) {
			
			NSSound *sound = [NSSound soundNamed:@"trashing"];
			[sound play];
			
			[NSAnimationContext beginGrouping];
			[[NSAnimationContext currentContext] setCompletionHandler: ^{
				
				NSUInteger count = [self.source count];
				
				if (selectedRow < count) {
				
					[tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow] byExtendingSelection:NO];
					
				} else if (count) {
				
					[tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:count - 1] byExtendingSelection:NO];
					
				} else {
				
					[self addEmptyRow];
					[tableView reloadData];
					
				}
				
			}];
			
			[[NSAnimationContext currentContext] setDuration:0.5];
			
			[tableView beginUpdates];
			
			[self.source removeObjectAtIndex:selectedRow];
			[tableView removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:selectedRow] withAnimation:NSTableViewAnimationSlideRight];
			
			[tableView endUpdates];
			
			[NSAnimationContext endGrouping];
		}
		
	}];
	
}


@end
