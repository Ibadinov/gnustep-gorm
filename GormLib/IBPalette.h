/* IBInspector.h
 *
 * Copyright (C) 2003 Free Software Foundation, Inc.
 *
 * Author:	Gregory John Casamento <greg_casamento@yahoo.com>
 * Date:	2003
 * 
 * This file is part of GNUstep.
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#ifndef INCLUDED_IBPALETTE_H
#define INCLUDED_IBPALETTE_H

#include <Foundation/NSMapTable.h>
#include <Foundation/NSObject.h>

// forward references
@class NSString;
@class NSImage;
@class NSWindow;
@class NSView;

/*
 * Pasteboard types used for DnD when views are dragged out of a palette
 * window into another window in Gorm (or, in the case of IBWindowPboardType
 * onto the desktop).
 */
extern NSString	*IBCellPboardType;
extern NSString	*IBMenuPboardType;
extern NSString	*IBMenuCellPboardType;
extern NSString	*IBObjectPboardType;
extern NSString	*IBViewPboardType;
extern NSString	*IBWindowPboardType;
extern NSString	*IBFormatterPboardType;

/*
 * Pasteboard types used for DnD from images or sounds tab
 * to views or inspector's textfield
 * onto the desktop).
 * NOTE: These are specific to Gorm... */
extern NSString	*GormImagePboardType;
extern NSString	*GormSoundPboardType;

@interface IBPalette : NSObject
{
  NSWindow	*window;
  NSImage	*icon;
}
/*
 * For internal use only - these class methods return the information
 * associated with a particular view.
 */
+ (id) objectForView: (NSView*)aView;
+ (NSString*) typeForView: (NSView*)aView;

/**
 * Associate a particular object and DnD type with a view - so that
 * Gorm knows to initiate a DnD session with the specified object
 * and type rather than an archived copy of the view itsself and
 * the default type (IBViewPboardType).
 */
- (void) associateObject: (id)anObject
		    type: (NSString*)aType
		    with: (NSView*)aView;

/**
 * Releases all the instance variables apart from the window (which is
 * presumed to release itsself when closed) and removes self as an observer
 * of notifications before destroying self.
 */
- (void) dealloc;

/**
 * Method called by Gorm when a new palette has been created and its nib
 * (if any) has been loaded.  Any palette initialisation should be done here.
 */
- (void) finishInstantiate;

/**
 * Return the icon representing the palette.
 */
- (NSImage*) paletteIcon;

/**
 * Return the window containing the views that may be dragged from the
 * palette.
 */
- (NSWindow*) originalWindow;
@end
#endif