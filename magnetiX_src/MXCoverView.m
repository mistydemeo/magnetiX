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

#import "MXCoverView.h"

@implementation MXCoverView


- (void)drawRect:(NSRect)rect
{
	[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh]; // dont know if THIS is necessary ... just using drawRect changes the rendering and improves the quality, especially when small
	[super drawRect:rect];
}


- (void)setCover:(NSImage *)cover
{
	NSImageRep *rep = [cover representations][0];
	originalSize = NSMakeSize(rep.pixelsWide, rep.pixelsHigh);
	
	if (originalSize.width > 550) {
		originalSize.width /= 4;
		originalSize.height /= 4;
	} else {
		originalSize.width /= 2;
		originalSize.height /= 2;
	}
	
	[self setImage:cover];
	
	[self resizeImageToViewWidth:[self frame].size.width];
}


- (void)resizeImageToViewWidth:(float)width
{
	float originalViewWidth = 294.0;
	
	float newCoverWitdh = width / originalViewWidth * originalSize.width;
	float newCoverHeight = width / originalViewWidth * originalSize.height;
	
	[[self image] setSize:NSMakeSize(floorf(newCoverWitdh), floorf(newCoverHeight))];
	
	if (associatedMusicButton) {
		NSRect frame = [associatedMusicButton frame];
		frame.origin.y = [[self superview] frame].size.height - floorf(newCoverHeight) - 60;
		frame.origin.x = floorf((width - newCoverWitdh) / 2) + 18;
		[associatedMusicButton setFrame:frame];
		[associatedMusicButton setNeedsDisplay:YES];
	}
}


- (void)setFrame:(NSRect)frameRect
{	
	[self resizeImageToViewWidth:frameRect.size.width];
	[super setFrame:frameRect];
    [self setNeedsDisplay:YES]; // X.11b1
}


@end
