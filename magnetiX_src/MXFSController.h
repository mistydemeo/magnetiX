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

#import <Foundation/Foundation.h>
#import "MagneticController.h"

@interface MXFSController : NSWindowController

{
	IBOutlet id tableView;
	IBOutlet id loadSaveButton;
	IBOutlet id textView;
	IBOutlet id saveBar;
	IBOutlet id bannerView;
}

- (IBAction)cancel:(id)sender;
- (IBAction)load:(id)sender;
- (IBAction)save:(id)sender;
- (IBAction)trash:(id)sender;

- (void)showSheet;
- (NSString *)previewText;
- (BOOL)isTrashingPossible;
- (void)setGameData:(id)data;
- (BOOL)isLoadSheetOpen;
- (void)updateContent;

@property (retain) NSMutableArray *source;
@property (retain) MagneticController *controller;
@property (assign) BOOL isSaveMode;
@property (retain) id theGameData;
@property (assign) BOOL isSheetOpen;

@end
