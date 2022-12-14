/*
 * Copyright 2015, 2016, 2018 Jonathan K. Bullard. All rights reserved.
 *
 *  This file is part of Tunnelblick.
 *
 *  Tunnelblick is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License version 2
 *  as published by the Free Software Foundation.
 *
 *  Tunnelblick is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program (see the file COPYING included with this
 *  distribution); if not, write to the Free Software Foundation, Inc.,
 *  59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *  or see http://www.gnu.org/licenses/.
 */

#import <Quartz/Quartz.h>

#import "helper.h"
#import "sharedRoutines.h"

#import "MenuController.h"
#import "TBUserDefaults.h"
#import "UIHelper.h"

extern MenuController * gMC;
extern TBUserDefaults * gTbDefaults;

@implementation UIHelper

+(NSString *) appendRTLIfRTLLanguage: (NSString *) string {
    
    if (  [gMC languageAtLaunchWasRTL]  ) {
        return [string stringByAppendingString: @"-RTL"];
    }
    
    return string;
}

+(unsigned int) detailsWindowsViewIndexFromPreferencesWithCount: (unsigned int) count {
    
    // "count" is the [toolbarIdentifiers count]
	
	unsigned int ix = (  [UIHelper languageAtLaunchWasRTL]
					   ? [gTbDefaults unsignedIntForKey: @"detailsWindowViewIndex" default: count - 1 min: 2 max: count - 1]
					   : [gTbDefaults unsignedIntForKey: @"detailsWindowViewIndex" default: 0         min: 0 max: count - 3]);
	return ix;
}

+(BOOL) languageAtLaunchWasRTL {
    
    return [gMC languageAtLaunchWasRTL];
}

+(NSString *) imgTagForImageName: (NSString *) imageName
                           width: (NSInteger)  width
                          height: (NSInteger)  height {
    
    NSURL * url = [[NSBundle mainBundle] URLForImageResource: imageName];
    NSString * tag = [NSString stringWithFormat: @"<img src=\"%@\" width=\"%ld\" height=\"%ld\">",
                      [url absoluteString], (long)width, (long)height];
    return tag;
}


+(void) makeAllAsWideAsWidest: (NSArray *) list
						shift: (BOOL)      shift {
	
	// Changes the width of a set of buttons so they are all as wide as the widest one.
	//
	// If "shift" is TRUE, shifts each button as needed to keep it flush right
	
	// Find the width of the largest button
	CGFloat largestWidth = -1.0;
	NSEnumerator * e = [list objectEnumerator];
	NSButton * button;
	while (  (button = [e nextObject])  ) {
		CGFloat thisWidth = [button frame].size.width;
		if (  thisWidth > largestWidth  ) {
			largestWidth = thisWidth;
		}
	}
	
	// Adjust the buttons
	if (  largestWidth != -1.0  ) {
		e = [list objectEnumerator];
		while (  (button = [e nextObject])  ) {
			CGFloat thisWidth = [button frame].size.width;
			CGFloat change = thisWidth - largestWidth;
			if (  change != 0.0) {
				NSRect frame = [button frame];
				frame.size.width = frame.size.width - change;
				[button setFrame: frame];
				if (  shift  ) {
					[UIHelper shiftControl: button by: change reverse: YES];
				}
			}
		}
	}
}

+(CGFloat) setTitle: (NSString *) newTitle
		  ofControl: (id)         theControl
	    frameHolder: (id)         frameHolder
			  shift: (BOOL)       shift
			 narrow: (BOOL)       narrow
			 enable: (BOOL)       enable {
	
    // Sets up UI elements that are flush right or flush left and need to be resized.
    //
    // Optionally sets the title of a control, then adjusts its size, optionally shifts it right or left to keep
    // the right or left edge of the control in the same place, and then sets it enabled or disabled.
    //
    // If 'newTitle' is given, setTitle is performed on 'theControl'.
    // All sizing activity is performed on 'frameHolder'.
    // For an NSButton, 'theControl' and 'frameHolder' will be the same.
    // For text, 'theControl' will be an NSTextFieldCell and 'frameholder' will be an NSTextField
    //
    // If 'newTitle' is nil, the title is not set, but everything else is done. (Used for pop-down buttons.)
    //
    // An element that is flush right in an LTR language is flush left in an RTL language, so the 'shift'
    // argument is usually either [UIHelper languageAtLaunchWasRTL] or its logical inverse.
    // This is, 'shift' is TRUE for something that is flush right in an LTR language, or flush left in an RTL language.
    //
    // If 'narrow' is true, then the control is allowed to become narrower. (Set FALSE for "OK" buttons and other small buttons.)
    //
    // Returns the change in size of the control (positive if the control got larger, negative if it got smaller).
    
    if (   ( ! theControl )
		|| ( ! frameHolder )  ) {
        NSLog(@"setTitle:ofControl:shift:setEnabled: control and/or frameControl is nil; title is '%@'", newTitle);
        [gMC terminateBecause: terminatingBecauseOfError];
        return 0.0; // Make static analyzer happy
    }
    
    CGFloat widthChange = 0.0;
    
    NSRect oldFrame = [frameHolder frame];
    
    if (  newTitle  ) {
        [theControl setTitle: newTitle];
    }
    
    [frameHolder sizeToFit];
    
    NSRect newFrame = [frameHolder frame];
    if (  ! narrow  ) {
        if (  newFrame.size.width < oldFrame.size.width  ) {
            newFrame.size.width = oldFrame.size.width;
            [frameHolder setFrame: newFrame];
        }
    }
    
    widthChange = newFrame.size.width - oldFrame.size.width;    // + if control got bigger, - if got smaller
    
    if (  shift  ) {
        newFrame.origin.x = newFrame.origin.x - widthChange;    // shift control left if got bigger, right if got smaller
        [frameHolder setFrame:newFrame];
    }
    
    [theControl setEnabled: enable];
    
    return widthChange;
}

+(CGFloat) setTitle: (NSString *) newTitle
          ofControl: (id)         theControl
              shift: (BOOL)       shift
             narrow: (BOOL)       narrow
             enable: (BOOL)       enable {
    
    return [UIHelper setTitle: newTitle ofControl: theControl frameHolder: theControl shift: shift narrow: narrow enable: enable];
}

+(void) shiftControl: (id)      theControl
                  by: (CGFloat) amount
             reverse: (BOOL)    reverse {
    
    // Optionally shifts a control right (if amount is negative) or left (if amount is positive)
    // If "reverse" is TRUE, moves in the opposite direction
    
    if (  ! theControl  ) {
        NSLog(@"shift:control:by: control is nil");
        [gMC terminateBecause: terminatingBecauseOfError];
        return; // Make static analyzer happy
    }
    
    if (  reverse  ) {
        amount = - amount;
    }
    
    NSRect newFrame = [theControl frame];
    newFrame.origin.x = newFrame.origin.x - amount;
    [theControl setFrame:newFrame];
}

+(void) performOnMainThreadDictionary: (NSDictionary *) dict {
	
	SEL selector = NSSelectorFromString([dict objectForKey: @"selectorName"]);
	id  target   = [dict objectForKey: @"target"];
	id  object   = [dict objectForKey: @"object"];
	[target performSelectorOnMainThread: selector withObject: object waitUntilDone: NO];
}

+(void) performSelectorName: (NSString *) selectorName
					 target: (id)         target
				 withObject: (NSObject *) object
	 onMainThreadAfterDelay: (NSTimeInterval) delay {
	
	if (   ( ! selectorName )
		|| ( ! target )  ) {
		NSLog(@"Error: performSelectorName: %@ target: %@ withObject: %@ onMainThreadAfterDelay %f",
			  selectorName, target, object, delay);
		[gMC terminateBecause: terminatingBecauseOfError];
		return;
	}
	
	if (  ! object  ) {
		object = [NSNull null];
	}
	
	NSDictionary * dict = [NSDictionary dictionaryWithObjectsAndKeys:
						   selectorName, @"selectorName",
						   target,		 @"target",
						   object,       @"object",
						   nil];
	
	[self performSelector: @selector(performOnMainThreadDictionary:) withObject: dict afterDelay: delay];
}

+(BOOL) canAcceptFileTypesInPasteboard: (NSPasteboard *) pboard {
	
	// Accept a single .tblkSetup or multiple configurations but don't accept a mix or multiple .tblkSetups
	
	NSArray * configExtensions = [NSArray arrayWithObjects: @"ovpn", @"conf", @"tblk", nil];
	
	NSString * type = [pboard availableTypeFromArray: [NSArray arrayWithObject: NSFilenamesPboardType]];
	if (  ! [type isEqualToString: NSFilenamesPboardType]  ) {
		TBLog(@"DB-SI", @"canAcceptFileTypesInPasteboard: returning NO because no 'NSFilenamesPboardType' entries are available in the pasteboard.");
		return NO;
	}
	
	NSArray * paths = [pboard propertyListForType: NSFilenamesPboardType];
	NSUInteger i;
	BOOL haveSetup         = FALSE;
	BOOL haveConfiguration = FALSE;
	for (  i=0; i<[paths count]; i++  ) {
		NSString * path = [paths objectAtIndex:i];
		if (  [configExtensions containsObject: [path pathExtension]]  ) {
			if (  haveSetup  ) {
				TBLog(@"DB-SI", @"canAcceptFileTypesInPasteboard: have seen a .tblkSetup, so returning NO for '%@' in '%@'", [path lastPathComponent], [path stringByDeletingLastPathComponent]);
				return NO;
			}
			haveConfiguration = TRUE;
			TBLog(@"DB-SI", @"canAcceptFileTypesInPasteboard: acceptable: '%@' in '%@'", [path lastPathComponent], [path stringByDeletingLastPathComponent]);
		} else if (  [[path pathExtension] isEqualToString: @"tblkSetup"]  ) {
			if (  haveConfiguration  ) {
				TBLog(@"DB-SI", @"canAcceptFileTypesInPasteboard: have seen a configuration, so returning NO for '%@' in '%@'", [path lastPathComponent], [path stringByDeletingLastPathComponent]);
				return NO;
			}
			if (  [gMC showingImportSetupWindow]  ) {
				TBLog(@"DB-SI", @"canAcceptFileTypesInPasteboard: already importing a .tblksetup, so returning NO for '%@' in '%@'", [path lastPathComponent], [path stringByDeletingLastPathComponent]);
				return NO;
			}
			if (  haveSetup  ) {
				TBLog(@"DB-SI", @"canAcceptFileTypesInPasteboard: have seen a .tblkSetup, so returning NO for '%@' in '%@'", [path lastPathComponent], [path stringByDeletingLastPathComponent]);
				return NO;
			}
			haveSetup = TRUE;
			TBLog(@"DB-SI", @"canAcceptFileTypesInPasteboard: acceptable: '%@' in '%@'", [path lastPathComponent], [path stringByDeletingLastPathComponent]);
		} else {
			TBLog(@"DB-SI", @"canAcceptFileTypesInPasteboard: unknown extension, so returning NO for '%@' in '%@'", [path lastPathComponent], [path stringByDeletingLastPathComponent]);
			return NO;
		}
	}
	
	TBLog(@"DB-SI", @"canAcceptFileTypesInPasteboard: returning 'YES'");
	return YES;
}

+(NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
	
	NSDragOperation sourceDragMask = [sender draggingSourceOperationMask];
	NSPasteboard * pboard = [sender draggingPasteboard];
	
	if (  [[pboard types] containsObject: NSFilenamesPboardType]  ) {
		if (  [self canAcceptFileTypesInPasteboard: pboard]  ) {
			if (  sourceDragMask & NSDragOperationCopy  ) {
				TBLog(@"DB-SI", @"draggingEntered: returning YES");
				return NSDragOperationCopy;
			} else {
				TBLog(@"DB-SI", @"draggingEntered: returning NO because source does not allow copy operation");
			}
		}
	}
	
	TBLog(@"DB-SI", @"draggingEntered: returning NO");
	return NSDragOperationNone;
}

+(BOOL) performDragOperation:(id <NSDraggingInfo>)sender {
	
	NSPasteboard *pboard = [sender draggingPasteboard];
	
	if ( [[pboard types] containsObject: NSFilenamesPboardType] ) {
		NSArray * files = [pboard propertyListForType:NSFilenamesPboardType];
			
			[self performSelectorName:@"openFiles:" target: gMC withObject: files onMainThreadAfterDelay: 0.5];
		
		TBLog(@"DB-SI", @"performDragOperation: returning YES");
		return YES;
	}
	
	TBLog(@"DB-SI", @"performDragOperation: returning NO because pasteboard does not contain 'NSFilenamesPboardType'");
	return NO;
}

+(void) showAlertWindow: (NSDictionary *) dict {
    
    // This method is invoked on the main thread by TBShowAlertWindow() when it is called but is not running on the main thread
    
    if (  ! [NSThread isMainThread]  ) {
        NSLog(@"[UIHelper showAlertWindow] was invoked but not on the main thread; stack trace: %@", callStack());
        [self performSelectorOnMainThread: @selector(showAlertWindow:)  withObject: dict waitUntilDone: NO];
        return;
    }

	TBShowAlertWindowExtended(nilIfNSNull([dict objectForKey: @"title"]),
							  nilIfNSNull([dict objectForKey: @"msg"]),
							  nilIfNSNull([dict objectForKey: @"preferenceToSetTrue"]),
							  nilIfNSNull([dict objectForKey: @"preferenceName"]),
							  nilIfNSNull([dict objectForKey: @"preferenceValue"]),
							  nilIfNSNull([dict objectForKey: @"checkboxTitle"]),
							  nilIfNSNull([dict objectForKey: @"checkboxInfoTitle"]),
							             [[dict objectForKey: @"checkboxIsOn"] boolValue]);
}

+(void) showSuccessNotificationTitle: (NSString *) title
                                 msg: (NSString *) msg {
    
    NSUserNotification * notification = [[[NSUserNotification alloc] init] autorelease];
    if (  ! notification  ) {
        NSLog(@"Cannot create NSUserNotification");
        TBShowAlertWindow(title, msg);
        return;
    }
    
    [notification setTitle:           title];
    [notification setInformativeText: msg];
    [notification setSoundName:       @"NSUserNotificationDefaultSoundName"];
    
    NSUserNotificationCenter * center = [NSUserNotificationCenter defaultUserNotificationCenter];
    if (  ! center  ) {
        NSLog(@"Cannot create NSUserNotificationCenter");
        TBShowAlertWindow(title, msg);
        return;
    }
    
    [center deliverNotification: notification];

}

// The following method is a modified version of the code at http://stackoverflow.com/questions/10517386/how-to-give-nswindow-a-shake-effect-as-saying-no-as-in-login-failure-window/23491643#23491643

+(void)shakeWindow: (NSWindow *) w {
    
    static int   numberOfShakes  = 3;
    static float durationOfShake = 0.5f;
    static float vigourOfShake   = 0.02f;
    
    CGRect frame=[w frame];
    CAKeyframeAnimation * shakeAnimation = [CAKeyframeAnimation animation];
    
    CGMutablePathRef shakePath = CGPathCreateMutable();
    
    CGPathMoveToPoint(shakePath, NULL, NSMinX(frame), NSMinY(frame));
    for (  NSInteger index = 0; index < numberOfShakes; index++  ){
        CGPathAddLineToPoint(shakePath, NULL, NSMinX(frame) - frame.size.width * vigourOfShake, NSMinY(frame));
        CGPathAddLineToPoint(shakePath, NULL, NSMinX(frame) + frame.size.width * vigourOfShake, NSMinY(frame));
    }
    CGPathCloseSubpath(shakePath);
    shakeAnimation.path = shakePath;
    shakeAnimation.duration = durationOfShake;
    
    [w setAnimations:[NSDictionary dictionaryWithObject: shakeAnimation forKey:@"frameOrigin"]];
    [[w animator] setFrameOrigin:[w frame].origin];
    
    CGPathRelease(shakePath);
}

@end
