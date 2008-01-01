/* GormDocumentController.m
 *
 * This class is a subclass of the NSDocumentController
 *
 * Copyright (C) 2006 Free Software Foundation, Inc.
 *
 * Author:      Gregory John Casamento <greg_casamento@yahoo.com>
 * Date:        2006
 *
 * This file is part of GNUstep.
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 USA.
 */

#include <GormCore/GormWrapperLoader.h>
#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include <GormCore/GormPalettesManager.h>
#include <GormCore/GormClassManager.h>
#include <GormCore/GormImage.h>
#include <GormCore/GormSound.h>
#include <GormCore/GormPrivate.h>
#include <GormCore/NSView+GormExtensions.h>
#include <GormCore/GormFunctions.h>

@interface GormGormWrapperLoader : GormWrapperLoader
{
  NSMutableArray *_repairLog;
  id message;
  id textField;
  id panel;
}
@end

@implementation GormGormWrapperLoader
+ (NSString *) type
{
  return @"GSGormFileType";
}

- (id) init
{
  if((self = [super init]) != nil)
    {
      _repairLog = [[NSMutableArray alloc] init];
    }
  return self;
}

- (void) dealloc
{
  RELEASE(_repairLog);
  [super dealloc];
}

- (void) _openMessagePanel: (NSString *) msg
{
  NSEnumerator *en = [_repairLog objectEnumerator];
  id m = nil;

  if([NSBundle loadNibNamed: @"GormInconsistenciesPanel"
	       owner: self] == NO)
    {
      NSLog(@"Failed to open message panel...");
    }
  else
    {
      [message setStringValue: msg];
      
      while((m = [en nextObject]) != nil)
	{
	  [textField insertText: m];
	}

      [panel orderFront: self];
    }
}

/** 
 * The sole purpose of this method is to clean up .gorm files from older
 * versions of Gorm which might have some dangling references.   This method
 * may be added to as time goes on to make sure that it's possible 
 * to repair old .gorm files.
 */
- (void) _repairFile
{
  NSEnumerator *en = [[[document nameTable] allKeys] objectEnumerator];
  NSString *key = nil;
  int errorCount = 0;
  NSString *errorMsg = nil;
  NSArray *connections = [document allConnectors];
  id con = nil;

  NSRunAlertPanel(_(@"Warning"), 
		  _(@"You are running with 'GormRepairFileOnLoad' set to YES."),
		  nil, nil, nil);

  /**
   * Iterate over all objects in nameTable.
   */
  [document deactivateEditors];
  while((key = [en nextObject]) != nil)
  {
    id obj = [[document nameTable] objectForKey: key];

    /*
     * Take care of any dangling menus...
     */
    if([obj isKindOfClass: [NSMenu class]] && ![key isEqual: @"NSMenu"])
      {
	id sm = [obj supermenu];
	if(sm == nil)
	  {
	    NSArray *menus = findAll(obj);
	    [_repairLog addObject: 
			  [NSString stringWithFormat: @"ERROR ==> Found and removed a dangling menu %@, %@.\n",
				    obj,[document nameForObject: obj]]];
	    [document detachObjects: menus];
	    [document detachObject: obj];
	    
	    // Since the menu is a top level object, it is not retained by
	    // anything else.  When it was unarchived it was autoreleased, and
	    // the detach also does a release.  Unfortunately, this causes a
	    // crash, so this extra retain is only here to stave off the 
	    // release, so the autorelease can release the menu when it should.
	    RETAIN(obj); // extra retain to stave off autorelease...
	    errorCount++;
	  }
      }

    /*
     * Take care of any dangling menu items...
     */
    if([obj isKindOfClass: [NSMenuItem class]])
      {
	id m = [obj menu];
	if(m == nil)
	  {
	    id sm = [obj submenu];

	    [_repairLog addObject:
			  [NSString stringWithFormat: @"ERROR ==> Found and removed a dangling menu item %@, %@.\n",
				    obj,[document nameForObject: obj]]];
	    [document detachObject: obj];

	    // if there are any submenus, detach those as well.
	    if(sm != nil)
	      {
		NSArray *menus = findAll(sm);
		[document detachObjects: menus];
	      }
	    errorCount++;
	  }
      }

    /*
     * If there is a view which is not associated with a name, give it one...
     */
    if([obj isKindOfClass: [NSWindow class]])
      {
	NSArray *allViews = allSubviews([obj contentView]);
	NSEnumerator *ven = [allViews objectEnumerator];
	id v = nil;
	
	while((v = [ven nextObject]) != nil)
	  {
	    NSString *name = nil;
	    if((name = [document nameForObject: v]) == nil)
	      {
		[document attachObject: v toParent: [v superview]];
		name = [document nameForObject: v];
		[_repairLog addObject: 
			      [NSString stringWithFormat: 
					  @"ERROR ==> Found view %@ without an associated name, adding to the nametable as %@\n", 
					v, name]];
		if([v respondsToSelector: @selector(stringValue)])
		  {
		    [_repairLog addObject: [NSString stringWithFormat: @"INFO: View string value is %@\n",[v stringValue]]];
		  }
		errorCount++;
	      }
	    [_repairLog addObject: [NSString stringWithFormat: @"INFO: Checking view %@ with name %@\n", v, name]];
	  }
      }
  }
  [document reactivateEditors];
  
  /**
   * Iterate over all connections...  remove connections with nil sources.
   */
  en = [connections objectEnumerator];
  while((con = [en nextObject]) != nil)
    {
      if([con isKindOfClass: [NSNibConnector class]])
	{
	  if([con source] == nil)
	    {
	      [_repairLog addObject: 
			    [NSString stringWithFormat: @"ERROR ==> Removing bad connector with nil source: %@\n",con]];
	      [document removeConnector: con];
	      errorCount++;
	    }
	}
    }
  
  // report the number of errors...
  if(errorCount > 0)
    {
      errorMsg = [NSString stringWithFormat: @"%d inconsistencies were found, please save the file.",errorCount]; 
      [self _openMessagePanel: errorMsg];
    }
}

/**
 * Private method.  Determines if the document contains an instance of a given
 * class or one of it's subclasses.
 */
- (BOOL) _containsKindOfClass: (Class)cls
{
  NSEnumerator *en = [[document nameTable] objectEnumerator];
  id obj = nil;
  while((obj = [en nextObject]) != nil)
    {
      if([obj isKindOfClass: cls])
	{
	  return YES;
	}
    }
  return NO;
}

- (BOOL) loadFileWrapper: (NSFileWrapper *)wrapper withDocument: (GormDocument *) doc
{
  NS_DURING
    {
      NSData		        *data = nil;
      NSData                    *classes = nil;
      NSUnarchiver		*u = nil;
      NSEnumerator		*enumerator = nil;
      id <IBConnectors>	         con = nil;
      NSString                  *ownerClass, *key = nil;
      BOOL                       repairFile = [[NSUserDefaults standardUserDefaults] 
						boolForKey: @"GormRepairFileOnLoad"];
      GormPalettesManager       *palettesManager = [(id<Gorm>)NSApp palettesManager];
      NSDictionary              *substituteClasses = [palettesManager substituteClasses];
      NSEnumerator              *en = [substituteClasses keyEnumerator];
      NSString                  *subClassName = nil;
      unsigned int           	version = NSNotFound;
      NSDictionary              *fileWrappers = nil;

      if ([super loadFileWrapper: wrapper withDocument: doc])
	{
	  GormClassManager *classManager = [document classManager];

	  key = nil;
	  fileWrappers = [wrapper fileWrappers];

	  enumerator = [fileWrappers keyEnumerator];
	  while((key = [enumerator nextObject]) != nil)
	    {
	      NSFileWrapper *fw = [fileWrappers objectForKey: key];
	      if([fw isRegularFile])
		{
		  NSData *fileData = [fw regularFileContents];
		  if([key isEqual: @"objects.gorm"])
		    {
		      data = fileData;
		    }
		  else if([key isEqual: @"data.info"])
		    {
		      [document setInfoData: fileData];
		    }
		  else if([key isEqual: @"data.classes"])
		    {
		      classes = fileData;
		      
		      // load the custom classes...
		      if (![classManager loadCustomClassesWithData: classes]) 
			{
			  NSRunAlertPanel(_(@"Problem Loading"), 
					  _(@"Could not open the associated classes file.\n"
					    @"You won't be able to edit connections on custom classes"), 
					  _(@"OK"), nil, nil);
			}
		    }
		}
	    }
	  
	  // check the data...
	  // NOTE: If info isn't present, then it's an older archive which
	  //  doesn't contain that file.
	  if (data == nil || classes == nil)
	    {
	      return NO;
	    }
	  
	  /*
	   * Create an unarchiver, and use it to unarchive the gorm file while
	   * handling class replacement so that standard objects understood
	   * by the gui library are converted to their Gorm internal equivalents.
	   */
	  u = [[NSUnarchiver alloc] initForReadingWithData: data];
	  
	  /*
	   * Special internal classes
	   */ 
	  [u decodeClassName: @"GSNibItem" 
	     asClassName: @"GormObjectProxy"];
	  [u decodeClassName: @"GSCustomView" 
	     asClassName: @"GormCustomView"];
	  
	  /*
	   * Substitute any classes specified by the palettes...
	   */
	  while((subClassName = [en nextObject]) != nil)
	    {
	      NSString *realClassName = [substituteClasses objectForKey: subClassName];
	      [u decodeClassName: realClassName 
		 asClassName: subClassName];
	    }
	  
	  // turn off custom classes.
	  [GSClassSwapper setIsInInterfaceBuilder: YES]; 
	  GSNibContainer *container = [u decodeObject];
	  if (container == nil || [container isKindOfClass: [GSNibContainer class]] == NO)
	    {
	      return NO;
	    }
	  // turn on custom classes.
	  [GSClassSwapper setIsInInterfaceBuilder: NO]; 
	  
	  /*
	   * Retrieve the custom class data and refresh the classes view...
	   */
	  [classManager setCustomClassMap: 
			  [NSMutableDictionary dictionaryWithDictionary: 
						 [container customClasses]]];
	  
	  //
	  // Get all of the visible objects...
	  //
	  NSArray *visible = [container visibleWindows];
	  id visObj = nil;
	  enumerator = [visible objectEnumerator];
	  while((visObj = [enumerator nextObject]) != nil)
	    {
	      [document setObject: visObj isVisibleAtLaunch: YES];
	    }
	  
	  //
	  // Get all of the deferred objects...
	  //
	  NSArray *deferred = [container deferredWindows];
	  id defObj = nil;
	  enumerator = [deferred objectEnumerator];
	  while((defObj = [enumerator nextObject]) != nil)
	    {
	      [document setObject: defObj isDeferred: YES];
	    }
	  
	  /*
	   * In the newly loaded nib container, we change all the connectors
	   * to hold the objects rather than their names (using our own dummy
	   * object as the 'NSOwner'.
	   */
	  GormFilesOwner *filesOwner = [document filesOwner];
	  GormFirstResponder *firstResponder = [document firstResponder];
	  ownerClass = [[container nameTable] objectForKey: @"NSOwner"];
	  if (ownerClass)
	    {
	      [filesOwner setClassName: ownerClass];
	    }
	  // [[container nameTable] removeObjectForKey: @"NSOwner"];
	  // [[container nameTable] removeObjectForKey: @"NSFirst"];
	  [[container nameTable] setObject: filesOwner forKey: @"NSOwner"];
	  [[container nameTable] setObject: firstResponder forKey: @"NSFirst"];

	  //
	  // Add entries...
	  //
	  [[document nameTable] addEntriesFromDictionary: [container nameTable]];
	  
	  //
	  // Add top level items...
	  //
	  NSArray *objs = [[container topLevelObjects] allObjects];
	  [[document topLevelObjects] addObjectsFromArray: objs];
					
	  //
	  // Add connections
	  //
	  NSMutableArray *connections = [document connections];
	  [connections addObjectsFromArray: [container connections]];

	  /* Iterate over the contents of nameTable and create the connections */
	  NSDictionary *nt = [document nameTable];
	  enumerator = [connections objectEnumerator];
	  while ((con = [enumerator nextObject]) != nil)
	    {
	      NSString  *name;
	      id        obj;
	      
	      name = (NSString*)[con source];
	      obj = [nt objectForKey: name];
	      [con setSource: obj];
	      name = (NSString*)[con destination];
	      obj = [nt objectForKey: name];
	      [con setDestination: obj];
	    }
	  
	  /*
	   * If the GSNibContainer version is 0, we need to add the top level objects
	   * to the list so that they can be properly processed.
	   */
	  version = [u versionForClassName: NSStringFromClass([GSNibContainer class])];
	  if(version == 0)
	    {
	      id obj;
	      NSEnumerator *en = [nt objectEnumerator];
	      
	      // get all of the GSNibItem subclasses which could be top level objects
	      while((obj = [en nextObject]) != nil)
		{
		  if([obj isKindOfClass: [GSNibItem class]] &&
		     [obj isKindOfClass: [GSCustomView class]] == NO)
		    {
		      [[container topLevelObjects] addObject: obj];
		    }
		}
	      [document setOlderArchive: YES];
	    }
	  else if(version == 1)
	    {
	      // nothing else, just mark it as older...
	      [document setOlderArchive: YES];
	    }
	  
	  /*
	   * If the GSWindowTemplate version is 0, we need to let Gorm know that this is
	   * an older archive.  Also, if the window template is not in the archive we know
	   * it was made by an older version of Gorm.
	   */
	  version = [u versionForClassName: NSStringFromClass([GSWindowTemplate class])];
	  if(version == NSNotFound && [self _containsKindOfClass: [NSWindow class]])
	    {
	      [document setOlderArchive: YES];
	    }

	  /* 
	   * Rebuild the mapping from object to name for the nameTable... 
	   */
	  [document rebuildObjToNameMapping];
	  
	  /*
	   * repair the .gorm file, if needed.
	   */
	  if(repairFile)
	    {
	      [self _repairFile];
	    }
	  
	  NSDebugLog(@"nameTable = %@",[container nameTable]);
	  
	  // awaken all elements after the load is completed.
	  enumerator = [nt keyEnumerator];
	  while ((key = [enumerator nextObject]) != nil)
	    {
	      id o = [nt objectForKey: key];
	      if ([o respondsToSelector: @selector(awakeFromDocument:)])
		{
		  [o awakeFromDocument: document];
		}
	    }
	  
	  // document opened...
	  [document setDocumentOpen: YES];
	  
	  // release the unarchiver..
	  RELEASE(u);
	}
      else
	{
	  return NO;
	}
    }
  NS_HANDLER
    {
      NSRunAlertPanel(_(@"Problem Loading"), 
		      [NSString stringWithFormat: @"Failed to load file.  Exception: %@",[localException reason]], 
		      _(@"OK"), nil, nil);
      return NO; 
    }
  NS_ENDHANDLER;

  // if we made it here, then it was a success....
  return YES;
}
@end
