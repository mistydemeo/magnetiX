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

#import "MXFSBannerView.h"

@implementation MXFSBannerView


- (void)drawRect:(NSRect)dirtyRect
{
	NSRect bounds = [self bounds];
	
	NSColor *goldColor = [NSColor colorWithDeviceRed:0.58 green:0.54 blue:0.38 alpha:1.0];
	
	[goldColor set];
	NSRect current = bounds;
	current.size.height = 3.0;
	current.origin.y = 26;
	NSRectFill(current);
	
	if (!self.bannerText) return;
	
	NSDictionary *attributes = @{ NSFontAttributeName : [NSFont fontWithName:@"Palatino-Roman" size:20.0], NSForegroundColorAttributeName : goldColor };
	NSSize stringSize = [self.bannerText sizeWithAttributes:attributes];
			
	current = bounds;
	current.origin.y += 10.0;
	current.size.height -= 20.0;
	current.origin.x = floorf(current.size.width / 2 - (stringSize.width / 2 + 20));
	current.size.width = stringSize.width + 40;
	
	NSRectFill(current);
	
	[[NSColor whiteColor] set];
	
	NSRectFill(NSInsetRect(current, 3.0, 3.0));
	
	[self.bannerText drawAtPoint:NSMakePoint(current.origin.x + 20, current.origin.y + 5) withAttributes:attributes];
}


@end
