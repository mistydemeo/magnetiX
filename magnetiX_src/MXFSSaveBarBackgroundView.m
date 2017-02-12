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

#import "MXFSSaveBarBackgroundView.h"

@implementation MXFSSaveBarBackgroundView

- (void)drawRect:(NSRect)rect
{
	NSRect shadowRect = [self bounds];
	shadowRect.origin.y += 10;
	shadowRect.origin.x -= 10;
	shadowRect.size.height -= 10;
	shadowRect.size.width += 20;
	
	[NSGraphicsContext saveGraphicsState];
	
	NSShadow *smallShadow = [[NSShadow alloc] init];
	[smallShadow setShadowOffset:NSMakeSize(5.0, -5.0)];
	[smallShadow setShadowBlurRadius:4];
	[smallShadow setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.3]];
	[smallShadow set];
	[smallShadow release];
	
	[[NSColor colorWithDeviceRed:0.13 green:0.16 blue:0.58 alpha:1.0] set];
	[NSBezierPath fillRect:shadowRect];
	
	[NSGraphicsContext restoreGraphicsState];
	
	shadowRect.origin.y += (shadowRect.size.height - 3);
	shadowRect.size.height = 3.0;
	
	[[NSColor colorWithCalibratedWhite:1.0 alpha:0.2] set];
	[NSBezierPath fillRect:shadowRect];
	
	//[super drawRect:[self bounds]];
}


- (void)mouseDown:(NSEvent *)theEvent
{
	[self clearTable];
	[super mouseDown:theEvent];
}


- (void)clearTable
{
	[tableView deselectAll:self];
}


@end
