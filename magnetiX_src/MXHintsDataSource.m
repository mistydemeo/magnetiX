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

#import "MXHintsDataSource.h"

@implementation MXHintsDataSource

void add_entry (id src, NSMutableArray *dst)
{
	unsigned i;
	id tempSrc;
	
	if ([src isKindOfClass:[NSArray class]]) {
		tempSrc = src[0];
		[src removeObjectAtIndex:0];
	} else {
		tempSrc = src;
	}
	
	NSMutableDictionary *entry = [NSMutableDictionary dictionaryWithObjectsAndKeys:tempSrc, @"object", nil];
	
	if ([src isKindOfClass:[NSArray class]]) {
		NSMutableArray *children = [NSMutableArray array];
		for (i = 0; i != [src count]; ++i) {
			add_entry(src[i], children);
			entry[@"children"] = children;
		}
	}
	
	[dst addObject:entry];
}


- (void)setHintArray:(NSMutableArray *)hintData
{
	hintArray = [[NSMutableArray alloc] init];
	add_entry(hintData, hintArray);
}


- (void)releaseHintArray
{
	[hintArray release];
	hintArray = NULL;
}


- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	NSArray *array = item ? item[@"children"] : hintArray;
	return array ? [array count] : 0;
}


- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	return item[@"children"] != nil;
}


- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item
{
	NSArray *array = item ? item[@"children"] : hintArray;
	return array[index];
}


- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	return item[[tableColumn identifier]];
}


- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item
{
	NSString *string = item[@"object"];
	
	id column = [outlineView tableColumns][0];
	
	id dcell = [column dataCellForRow:[outlineView rowForItem:item]];
	
	[dcell setStringValue:string];
	
	float newCellWidth = [column width] - ([outlineView indentationPerLevel] * ([outlineView levelForItem:item] + 1));
	
	NSSize cellsize = [dcell cellSize];
	cellsize.height = 100000000.0;
	cellsize.width = newCellWidth;
	
	NSRect bounds;
	bounds.origin = NSZeroPoint;
	bounds.size = cellsize;
	
	[dcell setWraps:YES];
	cellsize = [dcell cellSizeForBounds:bounds];
	
	return cellsize.height;
}


- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
	return NO;
}


@end
