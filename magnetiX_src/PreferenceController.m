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

#import "PreferenceController.h"
#import "MxTrackSessionSliderCell.h"

@implementation PreferenceController


- (id)init
{
	self = [super initWithWindowNibName:@"Preferences"];
	return self;
}


- (void)windowDidLoad
{
	id window = [self window];
	[window setToolbar:toolbar];
	
	id identifier = [NSString stringWithFormat:@"%li", (long)[[NSUserDefaults standardUserDefaults] integerForKey:@"lastPrefTabOpen"]];
	[toolbar setSelectedItemIdentifier:identifier];
	[tabView selectTabViewItemWithIdentifier:identifier];
	[self resizePanel];
	[window makeFirstResponder:tabView];
	[window setFrameAutosaveName: @"Preferences"];
}


- (void)awakeFromNib
{
	double maxValue = 600;
	NSRect frame;
	
	id screens = [NSScreen screens];
	for (id screen in screens) {
		frame = [screen frame];
		if (frame.size.width > maxValue) { maxValue = frame.size.width; }
	}

	[templateNameTextField setEnabled:NO];
	[templateNameTextField setHidden:YES];

	[maxWidthSlider setMaxValue:maxValue];
	[maxWidthSlider setMinValue:600];
	
	[[maxWidthSlider cell] setTrackingAlertsTarget:self];
	[[charSlider cell] setTrackingAlertsTarget:self];
	[[lineSlider cell] setTrackingAlertsTarget:self];
}


- (void)trackingSessionWillStart:(id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"saveTextPosition" object:nil];
}


- (void)trackingSessionDidEnd:(id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"prefsTrackingSessionDidEnd" object:nil];
}


- (void)windowDidMove:(NSNotification *)aNotification 
{ 
	[[self window] saveFrameUsingName: @"Preferences"];
}


- (void)windowDidResignKey:(NSNotification *)notification
{
	[self endTemplateNaming:self];
}


- (NSDictionary *)currentTemplate
{
	return [arrayController arrangedObjects][[arrayController selectionIndex]];
}


- (IBAction)changeFontButton:(id)sender
{
    NSFontManager *fontManager = [NSFontManager sharedFontManager];
	id template = [self currentTemplate];
	NSFont *gameTextFont = [NSFont fontWithName:template[@"gameFontName"] size:[template[@"gameFontPointSize"] doubleValue]];
	
	if (!gameTextFont) {
		gameTextFont = [NSFont userFontOfSize:12.0];
	}
	
	[fontManager orderFrontFontPanel:self];
	[fontManager setSelectedFont:gameTextFont isMultiple:NO];
	[fontManager setTarget:self];
	
	NSFontPanel *sharedFontPanel = [NSFontPanel sharedFontPanel];
	[sharedFontPanel setDelegate:self];
	[sharedFontPanel setRestorable:NO];
	[sharedFontPanel makeKeyAndOrderFront:self];
}


- (void)setFont:(NSFont *)font
{
	[[NSFontManager sharedFontManager] setSelectedFont:font isMultiple:NO];
}


- (void)changeFont:(id)sender
{
	id template = [self currentTemplate];
	NSFont *gameTextFont = [NSFont fontWithName:template[@"gameFontName"] size:[template[@"gameFontPointSize"] doubleValue]];
    
	NSFont *newFont = [sender convertFont:gameTextFont];
	
	CGFloat pointSize = [newFont pointSize];
	if (pointSize > 70) { // max font size ... larger could break the UI and seems unnecessary
		pointSize = 70;
		newFont = [sender convertFont:newFont toSize:pointSize];
		
		//[[NSFontManager sharedFontManager] setSelectedFont:newFont isMultiple:NO];
		[[NSRunLoop currentRunLoop] performSelector:@selector(setFont:) target:self argument:newFont order:9999 modes:@[NSDefaultRunLoopMode]];
	}
	
	template[@"gameFontName"] = [newFont fontName];
	template[@"gameFontPointSize"] = @(pointSize);
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"fontChanged" object:newFont];
}


- (NSUInteger)validModesForFontPanel:(NSFontPanel *)fontPanel
{
	return (NSFontPanelStandardModesMask ^ NSFontPanelUnderlineEffectModeMask^ NSFontPanelStrikethroughEffectModeMask ^ NSFontPanelTextColorEffectModeMask ^ NSFontPanelDocumentColorEffectModeMask ^ NSFontPanelShadowEffectModeMask);
}


- (NSArrayController *)arrayController
{
	return arrayController;
}


- (IBAction)changeSpacing:(id)sender
{
	[spacingPopoverController setView:spacingView];
	[spacingPopover showRelativeToRect:[spacingButton frame] ofView:gameWindowBox preferredEdge:NSMinYEdge];
}


- (IBAction)closeSpacingPopover:(id)sender
{
	[spacingPopover close];
}


- (IBAction)showHelpText:(id)sender
{
	[helpPopoverController setView:helpText];
	
	NSRect frame = [sender frame];
	NSRect windowFrame = [[sender superview] frame];
	windowFrame.size = [[sender window] frame].size;
	
	windowFrame.origin.y = frame.origin.y;
	windowFrame.size.height = frame.size.height;
	windowFrame.origin.x += 5.0;
	windowFrame.size.width -= 40.0;
	
	[helpPopover showRelativeToRect:windowFrame ofView:[sender superview] preferredEdge:NSMinXEdge];
}


- (IBAction)addTemplate:(id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"addTemplate" object:nil];
	[self editTemplateName:sender];
}


- (IBAction)removeTemplate:(id)sender
{
	NSAlert *theAlert = [NSAlert alertWithMessageText:[NSString stringWithFormat:@"Are you sure you want to delete the template \"%@\"?", [self currentTemplate][@"name"]]
										defaultButton:@"Delete"
									  alternateButton:nil
										  otherButton:@"Cancel"
							informativeTextWithFormat:@""];

	[theAlert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:@selector(removeTemplateAlertDidEnd:returnCode:contextInfo:) contextInfo:nil];
}


- (void)removeTemplateAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(id)contextInfo
{
	if (returnCode == NSAlertDefaultReturn) {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"removeTemplate" object:nil];
	}
}


- (IBAction)editTemplateName:(id)sender
{
	if ([templatesPopupButton isHidden]) {
		[self endTemplateNaming:sender];
		return;
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"templateNameEditingStarted" object:nil];

	[templatesPopupButton setHidden:YES];
		
	NSRect frame = [templatesPopupButton frame];
	frame.origin.x += 2;
	frame.origin.y += 3;
	frame.size.height -= 5;
	frame.size.width -= 5;
	
	[templateNameTextField setFrame:frame];
	[templateNameTextField setEnabled:YES];
	[templateNameTextField setHidden:NO];
	[[self window] makeFirstResponder:templateNameTextField];
}


- (IBAction)endTemplateNaming:(id)sender
{
	if ([templateNameTextField isHidden]) { return; }
	
	[templateNameTextField setHidden:YES];
	[templateNameTextField setEnabled:NO];
	[templatesPopupButton setHidden:NO];

	[[NSNotificationCenter defaultCenter] postNotificationName:@"templateNameEditingEnded" object:nil];
}


- (IBAction)changeTab:(id)sender
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	NSInteger lastPrefTabOpen = [defaults integerForKey:@"lastPrefTabOpen"];
	int newPrefTabToOpen = [[sender itemIdentifier] intValue];
	
	if (lastPrefTabOpen == newPrefTabToOpen) { return; }
	
	[tabView selectTabViewItemWithIdentifier:[NSString stringWithFormat:@"%i", newPrefTabToOpen]];

	[defaults setInteger:newPrefTabToOpen forKey:@"lastPrefTabOpen"];

	//[tabView setHidden:YES];
	[[self window] makeFirstResponder:tabView];
	[self resizePanel];
	//[tabView setHidden:NO];
}


- (void)resizePanel
{
	int identifierOfSelectedTabViewItem = [[[tabView selectedTabViewItem] identifier] intValue];
	NSSize newSize;
	
	if (identifierOfSelectedTabViewItem == 1) {
		newSize = NSMakeSize(296, 467);
	} else {
		newSize = NSMakeSize(296, 313);
	}
	
	id window = [self window];
		
	NSRect newFrame = [window frame];
	
	newFrame.origin.y = newFrame.origin.y + (newFrame.size.height - newSize.height);
	newFrame.size.height = newSize.height;
	newFrame.size.width = newSize.width;
	
	
	[window setFrame:newFrame display:YES animate:YES];
	[window setTitle:[[tabView selectedTabViewItem] label]];
}


- (IBAction)prefSelectTemplate:(id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"templateChanged" object:@([sender indexOfSelectedItem])];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqualToString:@"selectionIndex"]) {
		[templatesPopupButton selectItemAtIndex:[arrayController selectionIndex]];
	}
}


@end
