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

#import "MXScrollView.h"
#import "MXTextView.h"
#import "MagneticController.h"

@implementation MXScrollView


- (void)awakeFromNib
{
    oldTargetPoint = NSMakePoint(0, 0);
    
    [[self contentView] setPostsBoundsChangedNotifications:YES];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(synchronizedViewContentBoundsDidChange:) name:NSViewBoundsDidChangeNotification object:nil];
}


- (void)setFrame:(NSRect)frameRect
{
	MagneticController *controller = (MagneticController *)[[self window] delegate];
	CGFloat maxWidth = [controller currentContentWidth];

	NSRect frame = [[self window] frame];
	
	frameRect.size.width = ceilf(((frame.size.width - maxWidth) / 2) + maxWidth);
	frameRect.origin.x = frame.size.width - frameRect.size.width;
	
	[super setFrame:frameRect];
}


- (void)updateState
{
	[[self documentView] resetNuller];
	[self updateStateWithout];
}


- (void)updateStateWithout
{
	if (![_timer isValid]) {
		self.timer = [NSTimer timerWithTimeInterval:0.1 target:self selector:@selector(updateStateForReal) userInfo:nil repeats:NO];
		[[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
	}
}


- (void)updateStateForReal
{
	MagneticController *controller = (MagneticController *)[[self window] delegate];
	
	if ([controller isScriptPlaying]) { return; }
	
	id attributes = [[self documentView] attributesForLocation];
	
	NSString *cacheKey = attributes[@"MXImageShown"];
	id status = attributes[@"MXStatusShown"];
	
	[controller mainRestoreStatus:status];
	[controller showImage:cacheKey];
	
	[[self documentView] cleanUpNuller];
}


- (void)synchronizedViewContentBoundsDidChange:(NSNotification *)notification
{
	[self updateStateWithout];
	
	id contentView = [self contentView];
	NSPoint targetPoint = [contentView bounds].origin;
	
	if (targetPoint.y >= [[self documentView] bounds].size.height - [contentView bounds].size.height - 1) {
		[(MagneticController *)[[self window] delegate] disableMore];
	}
    
    if (!NSEqualPoints(oldTargetPoint, targetPoint)) {
        oldTargetPoint = targetPoint;
        [self reflectScrolledClipView:contentView];
    } else {
        oldTargetPoint = targetPoint;
    }
}


- (void)scrollWheel:(NSEvent *)theEvent
{
	if (!self.isScrollingPrevented) {
		[super scrollWheel:theEvent];
	}
}


- (void)scrollToBottom
{
	id magneticTextView = [self documentView];
	[magneticTextView scrollRectToVisible:NSMakeRect(0, NSMaxY([magneticTextView bounds]), 10, 10)];
}


- (void)pageUp:(id)sender
{
	NSRect contentBounds = [[self contentView] bounds];
	
	NSPoint targetPoint = contentBounds.origin;
	targetPoint.y -= (contentBounds.size.height - [[self documentView] gradientHeight] * 1.5);
	
	if (targetPoint.y < 0) {
		targetPoint.y = 0;
	}
	
	[self restrictedScrollToPoint:targetPoint];
}


- (void)pageDown:(id)sender
{
	NSRect contentBounds = [[self contentView] bounds];
	NSRect documentBounds = [[self documentView] bounds];
	
	NSPoint targetPoint = contentBounds.origin;
	targetPoint.y += (contentBounds.size.height - [[self documentView] gradientHeight] * 1.5);
	
	if (targetPoint.y > documentBounds.size.height - contentBounds.size.height) {
		targetPoint.y = documentBounds.size.height - contentBounds.size.height;
	}
	
	[self restrictedScrollToPoint:targetPoint];
}


- (void)scrollToBeginningOfDocument:(id)sender
{
	id magneticTextView = [self documentView];
	NSLayoutManager *lm = [magneticTextView layoutManager];
	
	if (![lm allowsNonContiguousLayout]) {
		
		[self restrictedScrollToPoint:NSZeroPoint];
		
	} else {
	
		[[self contentView] scrollToPoint:NSZeroPoint];
		
	}
}


- (void)nonContiguousScrollToBottomPosition
{
	id magneticTextView = [self documentView];
	NSPoint containerOrigin = [magneticTextView textContainerOrigin];
	
	NSRect paragraphRect = [[magneticTextView layoutManager] boundingRectForGlyphRange:NSMakeRange([[magneticTextView textStorage] length] - 10, 10) inTextContainer:[magneticTextView textContainer]];
	paragraphRect = NSIntegralRect(paragraphRect);
	
	NSPoint testPoint = paragraphRect.origin;
	testPoint.y -= [magneticTextView visibleRect].size.height;
	testPoint.y += paragraphRect.size.height;
	testPoint.y += (2 * containerOrigin.y);
	testPoint.x = 0;
	
	[[self contentView] scrollToPoint:testPoint];
}


- (void)scrollToEndOfDocument:(id)sender
{
	id magneticTextView = [self documentView];
	NSLayoutManager *lm = [magneticTextView layoutManager];
	
	NSRect contentBounds = [[self contentView] bounds];
	NSRect documentBounds = [[self documentView] bounds];
	
	if (![lm allowsNonContiguousLayout]) {
		
		[self restrictedScrollToPoint:NSMakePoint(0, documentBounds.size.height - contentBounds.size.height)];
		
	} else {
		
		// UUUUUGLY ... but the only way I found that works (almost?) reliable with non-contiguous layout when: home-key, change template, end-key
		[self nonContiguousScrollToBottomPosition];
		[NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(nonContiguousScrollToBottomPosition) userInfo:NULL repeats:NO];
		
	}
}


- (void)restrictedScrollToPoint:(NSPoint)point
{
	MagneticController *controller = (MagneticController *)[[self window] delegate];
	[controller setIsImageResizeBlocked:YES];
	
	[NSAnimationContext beginGrouping];
	[[NSAnimationContext currentContext] setCompletionHandler: ^{
		[controller setIsImageResizeBlocked:NO];
		[controller updateUIPossibly]; }];
	[[[self contentView] animator] setBoundsOrigin:point];
	[self flashScrollers];
	[NSAnimationContext endGrouping];
}

@end
