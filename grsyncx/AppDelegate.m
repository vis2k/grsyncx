//
//  AppDelegate.m
//  grsyncx
//
//  Created by Michal Zelinka on 12/01/2020.
//  Copyright © 2020 Michal Zelinka. All rights reserved.
//

#import "AppDelegate.h"
#import "Notifications.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *__unused)aNotification
{
	// Insert code here to initialize your application
}

- (void)applicationWillTerminate:(NSNotification *__unused)aNotification
{
	// Insert code here to tear down your application
}

//- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag
//{
//
//}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *__unused)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName:GRSAppWillTerminateNotification object:nil];

	return YES; // For now
}

@end
