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

#import "MXScroller.h"

@implementation MXScroller


+ (BOOL)isCompatibleWithOverlayScrollers
{
	return self == [MXScroller class];
}


- (void)drawKnob
{	
	if ([self scrollerStyle] == NSScrollerStyleOverlay) {
		[super drawKnob];
		return;
	}
	
	NSRect knobRect = [self rectForPart:NSScrollerKnob];
	knobRect.size.width = 8.0;
	knobRect.size.height -= 2.0;
	knobRect.origin.x += 4.0;
	knobRect.origin.y += 1.0;
	
	NSColor *color = [self knobColor];
	
	CGFloat alpha = 0.3;
	
	if ((floor(NSAppKitVersionNumber) >= NSAppKitVersionNumber10_8)) {
		
		NSRect globalRect = NSZeroRect;
		globalRect.origin = [NSEvent mouseLocation];
		NSPoint windowLocation = [[self window] convertRectFromScreen:globalRect].origin;
		NSPoint viewLocation = [self convertPoint:windowLocation fromView:nil];
		
		if (NSPointInRect(viewLocation, [self bounds]) || self.isTrackingKnob) {
			alpha = 0.6;
		}
		
	}
	
	[[color colorWithAlphaComponent:alpha] set];
	
	NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:knobRect xRadius:4.0 yRadius:4.0];
	[path fill];
}


- (void)drawKnobSlotInRect:(NSRect)slotRect highlight:(BOOL)flag
{
	if ([self scrollerStyle] == NSScrollerStyleOverlay) {
		[super drawKnobSlotInRect:slotRect highlight:flag];
		return;
	}
	
	[[self backgroundColor] setFill];
	[[[self outlineColor] colorWithAlphaComponent:0.3] setStroke];
	
	[NSBezierPath fillRect:slotRect];
	
	slotRect.size.width += 5.0;
	slotRect.size.height += 5.0;
	slotRect.origin.x += 0.5;
	slotRect.origin.y -= 2.5;
	
	[NSBezierPath strokeRect:slotRect];
}


- (void)trackKnob:(NSEvent *)theEvent
{
	self.isTrackingKnob = YES;
	[super trackKnob:theEvent];
	self.isTrackingKnob = NO;
}


- (NSColor *)backgroundColor
{
	return [NSColor clearColor];
}

- (NSColor *)outlineColor
{
	return [NSColor whiteColor];
}

- (NSColor *)knobColor
{
	return [NSColor whiteColor];
}


@end
