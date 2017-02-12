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

#import "MXImageView.h"
#import "MagneticController.h"

@implementation MXImageView


- (void)awakeFromNib
{
	self.originalSize = NSZeroSize;
	maxImageSize = NSZeroSize;
	
	[[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:@"imageSmoothing" options:NSKeyValueObservingOptionNew context:nil];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqual:@"imageSmoothing"]) {
		[self setNeedsDisplay:YES];
	}
}


- (float)maxValue
{
	NSSize imageSize = self.originalSize;
	
	return maxImageSize.height - imageSize.height;
}


- (void)mouseDown:(NSEvent *)theEvent
{
	NSSize imageSize = [[self image] size];
	NSRect bounds = [self bounds];

	NSPoint p = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	if ( p.x > (bounds.size.width / 2) - (imageSize.width / 2) && p.x < (bounds.size.width / 2) + (imageSize.width / 2) ) {
	
		if (p.y < bounds.size.height * 0.25) {
			
			[controller markLastVisibleGlyph];
			
			self.isResizeDrag = YES;
			
			initialLocation = [theEvent locationInWindow];
			maxImageSize = [controller maxImageSize];
			
			oldValue = self.addedPictureSize;
			
			float max = [self maxValue];
			if (oldValue > max || [controller isImageFullSize]) {
				oldValue = max;
			}
			
		} else {
		
			isExportDrag = YES;
			
		}
		
	}
	
	[[self window] disableCursorRects];

	[super mouseDown:theEvent];
}


- (void)dragEnded
{
	self.isResizeDrag = NO;
	self.draggedImages = nil;
	isExportDrag = NO;
	
	initialLocation = NSZeroPoint;
	
	[[self window] enableCursorRects];
	[[self window] invalidateCursorRectsForView:self];
	
	if (self.addedPictureSize < [self maxValue]) {
		[controller makeFullsizeImage:NO];
	} else {
		[controller makeFullsizeImage:YES];
	}
}


- (void)mouseUp:(NSEvent *)theEvent
{
	[self dragEnded];
	
	[super mouseUp:theEvent];
	[self setNeedsDisplay:YES];
}


- (void)draggedImage:(NSImage *)anImage endedAt:(NSPoint)aPoint operation:(NSDragOperation)operation
{
	[self dragEnded];
}


- (void)drawRect:(NSRect)dirtyRect
{
	NSImageInterpolation inter;
	
	if ([[NSUserDefaults standardUserDefaults] integerForKey:@"imageSmoothing"]) {
		inter = NSImageInterpolationDefault;
	} else {
		inter = NSImageInterpolationNone;
	}
	
	[[NSGraphicsContext currentContext] setImageInterpolation:inter];
	
	if (_isResizeDrag) {
		
		[[NSColor colorWithCalibratedWhite:0.5 alpha:0.1] set];
		
		NSRect bounds = [self bounds];
		bounds.origin.x = (bounds.size.width - maxImageSize.width) / 2;
		bounds.size.width = maxImageSize.width;
		
		[NSBezierPath fillRect:NSIntersectionRect(dirtyRect, NSIntegralRect(bounds))];
		
	}

	[super drawRect:dirtyRect];
}


- (void)mouseDragged:(NSEvent *)theEvent
{
	NSRect bounds = [self bounds];
	
	if (isExportDrag) {
		
		/*NSArray *animPics = [controller animPicArray];
		if ([animPics count]) {
			self.draggedImages = [[animPics copy] autorelease];
		} else {*/
			self.draggedImages = @[[[[self image] copy] autorelease]];
		//}
		
		[self dragPromisedFilesOfTypes:@[NSPasteboardTypePNG] fromRect:bounds source:self slideBack:YES event:theEvent];
		
	} else if (_isResizeDrag) {
		
		NSPoint currentLocation = [theEvent locationInWindow];
		float newValue = floorf(oldValue + initialLocation.y - currentLocation.y);
		
		float max = [self maxValue];
		
		if (newValue < 0) {
			
			newValue = 0;
			[[NSCursor resizeDownCursor] set];

		} else if (newValue > max) {
			
			newValue = max;
			[[NSCursor resizeUpCursor] set];
						
		} else {
			
			[[NSCursor resizeUpDownCursor] set];
			
		}
		
		self.addedPictureSize = newValue;
		
		[controller changeFreePictureSize];
		
	}
	
}


- (void)dragImage:(NSImage *)anImage at:(NSPoint)viewLocation offset:(NSSize)initialOffset event:(NSEvent *)event pasteboard:(NSPasteboard *)pboard source:(id)sourceObj slideBack:(BOOL)slideFlag
{
	NSImage *imageWhenDragStarted = self.draggedImages[0];
	NSImage *dragImage = [[NSImage alloc] initWithSize:[imageWhenDragStarted size]];
    
    [dragImage lockFocus];
	[imageWhenDragStarted drawAtPoint:NSZeroPoint fromRect:NSZeroRect operation:NSCompositeCopy fraction:0.7];
    [dragImage unlockFocus];
    [dragImage setScalesWhenResized:NO];
    
	NSPoint p = [self convertPoint:[event locationInWindow] fromView:nil];
	p.x -= [imageWhenDragStarted size].width / 2;
	p.y -= [imageWhenDragStarted size].height / 2;
	
    [super dragImage:dragImage at:p offset:NSZeroSize event:event pasteboard:pboard source:sourceObj slideBack:slideFlag];
    [dragImage release];
}


- (NSString *)pathForNewFileAtDropDestination:(NSURL *)dropDestination
{
	NSString *destPath = [dropDestination path];
	
	NSString *title = [(MagneticController *)[[self window] delegate] imageTitle];
		
	NSString *filename = [NSString stringWithFormat:@"%@.gif", title];
	NSString *path = [destPath stringByAppendingPathComponent:filename];
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
    if (![fileManager fileExistsAtPath:path]) {
		return path;
	}
	
	int i = 1;
	while (i) {
		i ++;
		NSString *filename = [NSString stringWithFormat:@"%@ %i.gif", title, i];
		NSString *path = [destPath stringByAppendingPathComponent:filename];
		if (![fileManager fileExistsAtPath:path]) {
			return path;
		}
	}
	
	return nil;
}


- (NSArray *)namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination
{
	NSString *filePath = [self pathForNewFileAtDropDestination:dropDestination];
	
	NSArray *animPicsSrc = [controller animPicArray]; // anim?
	if ([animPicsSrc count]) {
		self.draggedImages = [[animPicsSrc copy] autorelease];
	}
	
	NSArray *animPics = self.draggedImages;
	
	if ([animPics count] > 1) {
		
		NSURL *fileURL = [NSURL fileURLWithPath:filePath];
		
		NSDictionary *properties = @{@{@0.1f : (NSString *)kCGImagePropertyGIFDelayTime} : (NSString *)kCGImagePropertyGIFDictionary};
		
		CGImageDestinationRef idst = CGImageDestinationCreateWithURL((CFURLRef)fileURL, kUTTypeGIF, [animPics count], nil);
		
		for (int i=0; i<[animPics count]; i++) {
			NSImage *anImage = animPics[i];
			
			CGImageRef imageRef = [anImage CGImageForProposedRect:nil context:nil hints:nil];
			CGImageDestinationAddImage(idst, imageRef, (CFDictionaryRef)(properties));
			
		}
		
		CGImageDestinationFinalize(idst);
		CFRelease(idst);
		
		return @[filePath];
		
	} else {
		
	    NSArray *representations = [animPics[0] representations];
        NSData *bitmapData = [NSBitmapImageRep representationOfImageRepsInArray:representations usingType:NSGIFFileType properties:@{}];
		[bitmapData writeToFile:filePath atomically:YES];
		
		return @[filePath];
	}
	
}


- (NSDragOperation)draggingSession:(NSDraggingSession *)session sourceOperationMaskForDraggingContext:(NSDraggingContext)context
{
	return NSDragOperationCopy;
}


- (void)resetCursorRects
{
	NSSize imageSize = [[self image] size];
	NSRect cRect = [self bounds];
	
	cRect.origin.x = floorf((cRect.size.width - imageSize.width) / 2);

	cRect.size.height = floorf(cRect.size.height * 0.25);
	cRect.size.width = imageSize.width;
	
	NSCursor *cursor;
	
	maxImageSize = [controller maxImageSize];
	float max = [self maxValue];
	
	if (!_addedPictureSize) {
		cursor = [NSCursor resizeDownCursor];
	} else if (_addedPictureSize < max) {
		cursor = [NSCursor resizeUpDownCursor];
	} else {
		cursor = [NSCursor resizeUpCursor];
	}
	
	[self addCursorRect:cRect cursor:cursor];
}


- (BOOL)acceptsFirstMouse:(NSEvent *)event
{
    return YES;
}


- (NSMenu *)menuForEvent:(NSEvent *)theEvent
{
	return imageContextMenu;
}


@end
