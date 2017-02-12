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

#import "MXLimiterView.h"
#import "MagneticController.h"

@implementation MXLimiterView


- (void)setFrame:(NSRect)frameRect
{
	MagneticController *controller = (MagneticController *)[[self window] delegate];
	
	frameRect = [[[self window] contentView] frame];

	float newWidth = frameRect.size.width;
	float maxContentWidth = [controller currentContentWidth];
	
	float difference = 0;
	
	if (newWidth > maxContentWidth) {
		difference = (frameRect.size.width - maxContentWidth) / 2;
		frameRect.size.width = maxContentWidth;
		frameRect.origin.x = (float)(int)difference;
	}

	[super setFrame:NSIntegralRect(frameRect)];
	
	[controller updateUI];
}


@end
