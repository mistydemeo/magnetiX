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

#import "MXTextView.h"
#import "MagneticController.h"

@implementation MXTextView


- (void)awakeFromNib
{
	lastMouseDownStatusGlyph = -1;
	isMouseDownStatus = NO;
	[self resetNuller];
}


- (NSMenu *)menuForEvent:(NSEvent *)theEvent
{
	NSMenu *cMenu = [super menuForEvent:theEvent];
	for (id item in [cMenu itemArray]) {
		if ([item hasSubmenu] && ![[item title] isEqualToString:@"Speech"]) {
			[cMenu removeItem:item];
		}
	}
	
	NSRange selectedRange = [self selectedRange];
	
	if (selectedRange.length > 1) {
		return cMenu;
	}
	
	if (selectedRange.length == 1) {
		NSString *string = [[[self textStorage] string] substringWithRange:selectedRange];
		if (![string isEqualToString:@" "]) {
			return cMenu;
		}
	}
	
	id lastItem = [[cMenu itemArray] lastObject];
	if ([lastItem isSeparatorItem]) {
		[cMenu removeItem:lastItem];
	}
	
	return cMenu;
}

	
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	SEL action = [menuItem action];
	
	if (action == @selector(cut:) || action == @selector(paste:)) {
	
		if ([self selectedRange].location < [self editRange].location) {
			return NO;
		}

	}
	
	return [super validateMenuItem:menuItem];
}

	
- (void)setFrame:(NSRect)frameRect
{
	CGFloat ccw = [controller currentContentWidth];
	if (ccw > 0) {
		frameRect.size.width = ccw;
	}
	[super setFrame:frameRect];
	
	NSScrollView *sv = [self enclosingScrollView];
	if (frameRect.size.height <= [sv frame].size.height) {
		[controller disableMore];
	}
}


- (NSDictionary *)selectedTextAttributes
{
	return nil;
}


- (NSDictionary *)typingAttributes
{
	return [controller userAttributes];
}


- (void)setSelectedRanges:(NSArray *)ranges affinity:(NSSelectionAffinity)affinity stillSelecting:(BOOL)stillSelectingFlag
{
	if ([ranges count] > 0) {

		NSRange newRange;

		NSRange editRange = [self editRange];
		NSRange theRange = [ranges[0] rangeValue];
				
		if (theRange.length < 1 && theRange.location < editRange.location) {
			
			newRange = NSMakeRange(editRange.location, 0);
			
		} else {
		
			NSRange intersection = NSIntersectionRange(editRange, theRange);
			if (intersection.length <= 0) {
				newRange = theRange;
			} else {
				newRange = intersection;
			}
			
		}
		
		ranges = @[[NSValue valueWithRange:newRange]];
	}
	
	
	NSRange range;
	NSTextStorage *textStorage = self.textStorage;
	NSColor *color = [super selectedTextAttributes][NSBackgroundColorAttributeName];
	
	if (color) {
		for (NSValue *value in self.selectedRanges) {
			range = value.rangeValue;
			if (range.location == NSNotFound || range.length == 0 || [textStorage length] < range.location + range.length) { continue; }
			
			[[self layoutManager] removeTemporaryAttribute:NSBackgroundColorAttributeName forCharacterRange:range];
		}
		
		for (NSValue *value in ranges) {
			range = value.rangeValue;
			if (range.location == NSNotFound || range.length == 0 || [textStorage length] < range.location + range.length) { continue; }
			
			[[self layoutManager] addTemporaryAttribute:NSBackgroundColorAttributeName value:color forCharacterRange:range];
		}
	}
	
	[super setSelectedRanges:ranges affinity:affinity stillSelecting:stillSelectingFlag];
	
	[self setNeedsDisplay:YES];
}


- (NSArray *)readablePasteboardTypes
{
    return @[NSPasteboardTypeString];
}


- (NSRange)editRange
{
	NSTextStorage *storage = [self textStorage];
	NSUInteger length = [storage length];
	
	NSRange range = NSMakeRange(0, 0);
	
	if (!length) { return range; }
	
	id value = [storage attribute:@"MXUserEntry" atIndex:length - 1 longestEffectiveRange:&range inRange:NSMakeRange(0, length)];
		
	if (range.location == 0 || !value) { return NSMakeRange(length, 0); }
	
	return range;
}


- (NSString *)inlineOrderString
{
	return [[[self textStorage] attributedSubstringFromRange:[self editRange]] string];
}


- (void)insertNewline:(id)sender
{
	NSString *order = [self inlineOrderString];
	if ([order length] < 1) { return; }
	self.isTypingAllowed = NO;
	[controller enterOrderString:[self inlineOrderString]];
}


- (void)replaceOrder:(NSString *)order
{
	NSTextStorage *storage = [self textStorage];
		
	NSRange editRange = [self editRange];
	[storage replaceCharactersInRange:editRange withString:order];
	[storage setAttributes:self.typingAttributes range:NSMakeRange(editRange.location, [order length])];
}


- (BOOL)textView:(NSTextView *)aTextView shouldChangeTextInRange:(NSRange)affectedCharRange replacementString:(NSString *)replacementString
{
	if (!self.isTypingAllowed) { return NO; }
	
	if ([controller isScriptPlaying]) { return NO; }
	
	NSRange editRange = [self editRange];

	if ([replacementString isEqualToString:@""]) {
		
		if (affectedCharRange.location < editRange.location) {
			NSRange newRange = NSMakeRange(editRange.location, affectedCharRange.length - (editRange.location - affectedCharRange.location));
			[[self textStorage] replaceCharactersInRange:newRange withString:@""];
			return NO;
		}
		
	}
	
	if ([replacementString rangeOfString:@"\n"].location != NSNotFound) { // prevent alt+enter
		return NO;
	}

	if (affectedCharRange.location < editRange.location) { return NO; }
		
	if (controller.quickAnswerType && [replacementString length] && [@"#undo" rangeOfString:replacementString].location != editRange.length) {
		[controller enterQuickAnswerWithString:replacementString];
		return NO;
	}
	
	[self checkBeforeType];
	
	return YES;
}


- (NSString *)checkString
{
	NSTextStorage *storage = [self textStorage];
	if ([storage length] < 2) { return @""; }
	
	NSRange editRange = [self editRange];
	if (editRange.location < 2) { return @""; }
	
	return [[storage attributedSubstringFromRange:NSMakeRange(editRange.location - 3, 3)] string];
}


- (void)keyDown:(NSEvent *)theEvent
{
	if (![controller scrollMore]) {
		
		NSString *characters = [theEvent characters];
		if ([characters length]) {
			unichar character = [characters characterAtIndex:0];
			
			switch (character) {
				case NSPageUpFunctionKey:
					[[self enclosingScrollView] pageUp:self];
					return;
				case NSPageDownFunctionKey:
					[[self enclosingScrollView] pageDown:self];
					return;
				default:
					break;
			}
		}
		
		NSRange editRange = [self editRange];
		
		if ([self selectedRange].location < editRange.location) {
			[self setSelectedRange:NSMakeRange([[self textStorage] length], 0)];
		}
		
		if ([characters length] && [characters characterAtIndex:0] == NSTabCharacter) { return; }
		
		[super keyDown:theEvent];
		
	}
}


- (void)moveUp:(id)sender {}
- (void)moveDown:(id)sender {}
- (void)moveToEndOfDocument:(id)sender {}
- (void)moveToBeginningOfDocument:(id)sender {}

- (void)scrollToBeginningOfDocument:(id)sender
{
	[[self enclosingScrollView] scrollToBeginningOfDocument:self];
}
- (void)scrollToEndOfDocument:(id)sender
{
	[[self enclosingScrollView] scrollToEndOfDocument:self];
}


- (NSArray *)acceptableDragTypes
{
    return nil;
}


- (CGFloat)scrollPosition
{
	return [[[self enclosingScrollView] contentView] bounds].origin.y;
}


- (NSUInteger)lastVisibleGlyph
{
    NSLayoutManager *layoutManager = [self layoutManager];
	NSTextContainer *textContainer = [self textContainer];
	
	NSRect visibleRect = [self visibleRect];
	
	//if (visibleRect.origin.y <= 50) { return 1; }
	
	NSPoint point = NSMakePoint(0, visibleRect.origin.y + visibleRect.size.height);
	
	CGFloat sP = [self scrollPosition];
	if (sP < 0) {
		point.y += (-sP);
	}
	
	NSPoint containerOrigin = [self textContainerOrigin];
	
    point.y -= containerOrigin.y;
	
	NSUInteger glyphIndex = [layoutManager glyphIndexForPoint:point inTextContainer:textContainer];
	
	return glyphIndex;
}


- (void)checkBeforeType
{
	id scrollView = [self enclosingScrollView];
	NSRect svFrame = [scrollView frame];
	NSRect frame = [self frame];
	
	if ([self scrollPosition] < frame.size.height - svFrame.size.height) {
		
		[self scrollToEndOfDocument:self];
		
	} else if (isMouseDownStatus) {
		
		[controller mainRestoreStatus:nil];
		[controller showImage:nil];
		
		isMouseDownStatus = NO;
		lastMouseDownStatusGlyph = -1;
		
	}
}
	

- (id)attributesForLocation
{
	NSTextStorage *storage = [self textStorage];
	NSUInteger length = [storage length];
	
	if (!length) { return nil; }
	
	NSUInteger val;
	CGFloat sP = [self scrollPosition];
		
	if (lastMouseDownStatusGlyph >= 0) {
		
		val = lastMouseDownStatusGlyph;
		lastMouseDownStatusGlyph = -1;
		lastTopPositionGlyph = -1;
		
	} else if (lastTopPositionGlyph >= 0 && sP < self.testTempLocation) {
		
		val = lastTopPositionGlyph;
		if (sP < 0) { sP = 0; }
		self.testTempLocation = sP + 1;
		
	} else {
		
		val = [self lastVisibleGlyph];
		isMouseDownStatus = NO;
		lastTopPositionGlyph = -1;
		
	}
	
	self.testTempGlyph = val;
	
	if (val >= length) {
		val = length - 1;
	}
	
	return [storage attributesAtIndex:val effectiveRange:NULL];
}

	
/*	its possible that the top-most "reachable" image is less high than the following one. that could result in UI jumping back and forth,
	because resizing to the smaller image would force-change the text-position at the "trigger" and thus possibly change the image again ...
	so all this "Nuller"-BS is a quick'n'dirty workaround for this problem ... i have a hard time understanding all this myself, now :-)  */

	
- (void)cleanUpNuller
{
	if ([self scrollPosition] < self.testTempLocation) {
		lastTopPositionGlyph = self.testTempGlyph;
	} else {
		lastTopPositionGlyph = -1;
		self.testTempLocation = 1;
	}
}
	

- (void)resetNuller
{
	lastTopPositionGlyph = -1;
	self.testTempGlyph = -1;
	self.testTempLocation = 1;
}


- (void)mouseDown:(NSEvent *)theEvent
{
	if ([theEvent modifierFlags] & NSCommandKeyMask) {
			
		NSPoint event_location = [theEvent locationInWindow];
		NSPoint local_point = [self convertPoint:event_location fromView:nil];
		
		NSPoint containerOrigin = [self textContainerOrigin];
		local_point.y -= containerOrigin.y;
		
		NSUInteger glyphIndex = [[self layoutManager] glyphIndexForPoint:local_point inTextContainer:[self textContainer]];
		id attributes = [[self textStorage] attributesAtIndex:glyphIndex effectiveRange:NULL];
		
		NSString *cacheKey = attributes[@"MXImageShown"];
		id status = attributes[@"MXStatusShown"];
		
		lastMouseDownStatusGlyph = glyphIndex;
		
		[controller mainRestoreStatus:status];
		[controller showImage:cacheKey];
		
		isMouseDownStatus = YES;
		
	}
	
	[super mouseDown:theEvent];
}


- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
			
	NSRect visibleRect = [self visibleRect];
	NSRect gradFrame = visibleRect;
	
	int height = self.gradientHeight;
	gradFrame.size.height = height;
	
	NSPoint targetPoint = visibleRect.origin;
	
	float topValue;
	float botValue;
	
	float gradFadeHeight = 30.0;
	
	float from = 20;
	float to = from + gradFadeHeight;
	
	if (targetPoint.y <= from) { topValue = 0.0; }
	else if (targetPoint.y >= to) { topValue = 1.0; }
	else {
		topValue = (targetPoint.y - from) * (1.0f / (to - from));
	}
	
	to = [self bounds].size.height - visibleRect.size.height;
	from = to - gradFadeHeight;
	
	if (targetPoint.y <= from) { botValue = 0.0; }
	else if (targetPoint.y >= to) { botValue = 1.0; }
	else {
		botValue = (targetPoint.y - from) * (1.0f / (to - from));
	}
	 
	botValue = 1 - botValue;
	
	//NSColor *endColor = [[NSColor redColor] colorWithAlphaComponent:0];
	NSColor *endColor = [self.backgroundColor colorWithAlphaComponent:0];

	//NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:[[NSColor redColor] colorWithAlphaComponent:topValue] endingColor:endColor];
	NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:[self.backgroundColor colorWithAlphaComponent:topValue] endingColor:endColor];
	
	[gradient drawInRect:gradFrame angle:90.0];
	gradFrame.size.height /= 2;
	[gradient drawInRect:gradFrame angle:90.0];
	
	[gradient release];
	
	//gradient = [[NSGradient alloc] initWithStartingColor:[[NSColor redColor] colorWithAlphaComponent:botValue] endingColor:endColor];
	gradient = [[NSGradient alloc] initWithStartingColor:[self.backgroundColor colorWithAlphaComponent:botValue] endingColor:endColor];
	
	gradFrame.size.height = height;
	gradFrame.origin.y += visibleRect.size.height - height;
	
	[gradient drawInRect:gradFrame angle:-90.0];
	gradFrame.size.height /= 2;
	gradFrame.origin.y += gradFrame.size.height;
	[gradient drawInRect:gradFrame angle:-90.0];
	
	[gradient release];
}


+ (BOOL)isCompatibleWithResponsiveScrolling
{
	return NO;
}


@end
