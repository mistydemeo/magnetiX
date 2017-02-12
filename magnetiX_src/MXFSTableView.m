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

#import "MXFSTableView.h"
#import "MXFSController.h"

@implementation MXFSTableView


- (NSMenu *)menuForEvent:(NSEvent *)theEvent
{
	NSPoint eventLocation = [theEvent locationInWindow];
	NSPoint localPoint = [self convertPoint:eventLocation fromView:nil];
		
	NSInteger index = [self rowAtPoint:localPoint];
	
	if (index >= 0) {
		if (index != [self selectedRow]) {
			[self selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
		}
		
		return self.menu;
	}
	
	return nil;
}


- (void)drawRow:(NSInteger)row clipRect:(NSRect)clipRect
{
	id controller = [self dataSource];

    NSColor *bgColor = nil;
	
    if ([controller isSaveMode]) {
        bgColor = [NSColor colorWithCalibratedWhite:0.25 alpha:1];
    } else {
        bgColor = [NSColor colorWithDeviceRed:0.13 green:0.16 blue:0.58 alpha:1.0];
    }
	
    NSIndexSet *selectedRowIndexes = [self selectedRowIndexes];
    if ([selectedRowIndexes containsIndex:row])  {
		[bgColor setFill];
		NSRect rowRect = [self rectOfRow:row];
		NSRectFill(rowRect);
		
		if (![controller isSaveMode]) {
			[[NSColor colorWithDeviceRed:0.58 green:0.54 blue:0.38 alpha:1.0] set];
			NSRect accentRect = rowRect;
			accentRect.size.height = 1;
			NSRectFill(accentRect);
			accentRect.origin.y += (rowRect.size.height - 1);
			NSRectFill(accentRect);
		}
		
		
    }
	
    [super drawRow:row clipRect:clipRect];
}


@end
