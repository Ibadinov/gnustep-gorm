/* GormMatrixEditor.h - Editor for matrices.
 *
 * Copyright (C) 2002 Free Software Foundation, Inc.
 *
 * Author:	Pierre-Yves Rivaille
 * Date:	Aug 2002
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
#ifndef	INCLUDED_GormMatrixEditor_h
#define	INCLUDED_GormMatrixEditor_h

#include "GormViewWithSubviewsEditor.h"

@interface GormMatrixEditor : GormViewWithSubviewsEditor
{
  NSCell* selected;
  int selectedRow;
  int selectedCol;
}
@end

#endif
