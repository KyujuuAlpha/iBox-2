//
//  bochsAppDelegate.m
//  bochs
//
//  Created by WERT on 25.10.08.
//  Copyright __MyCompanyName__ 2008. All rights reserved.
//

#import "bochsAppDelegate.h"
@class RenderView;

@implementation bochsAppDelegate

@synthesize window;

int bochs_main (const char*);

- (void)doBochs:(NSString*)configPath
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	bochs_main([configPath UTF8String]);
	
	[pool release];
}

- (void)refreshThread
{
    NSTimer* t = [NSTimer timerWithTimeInterval:0.1f target:[NSClassFromString(@"BXRenderView") performSelector:@selector(sharedInstance)] selector:@selector(doRedraw) userInfo:nil repeats:YES];
	[[NSRunLoop currentRunLoop] addTimer:t forMode:NSRunLoopCommonModes];
	
	[[NSRunLoop currentRunLoop] run];
}

- (void)selectedOsInPickerView:(OSPickerViewController*)viewController withConfigFile:(NSString*)path
{
    // replace strings in config file
    NSString *configString = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    
    configString = [configString stringByReplacingOccurrencesOfString:@"~/documents" withString:basePath options:NSCaseInsensitiveSearch range:NSMakeRange(0, configString.length)];
    
    // add bios paths
    NSString *biosPath = [[NSBundle mainBundle] pathForResource:@"bios" ofType:nil];
    
    NSAssert([[NSFileManager defaultManager] fileExistsAtPath:biosPath], @"Bios file doesnt exists");
    
    NSString *vgaBiosPath = [[NSBundle mainBundle] pathForResource:@"vgabios" ofType:nil];
    configString = [configString stringByAppendingFormat:@"\nromimage: file=\"%@\", address=0x00000 \nvgaromimage: file=\"%@\"", biosPath, vgaBiosPath];
    
    // write to temp location
    NSString *tempPath = [NSTemporaryDirectory() stringByAppendingString:@"os.ini"];
    
    BOOL success = [configString writeToFile:tempPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    NSAssert(success, @"Could not write config file fo disk");
    
	[[NSClassFromString(@"BXRenderView") alloc] performSelector:@selector(init:) withObject:window];
	[NSThread detachNewThreadSelector:@selector(refreshThread) toTarget:self withObject:nil];
	[NSThread detachNewThreadSelector:@selector(doBochs:) toTarget:self withObject:tempPath];
	
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:1.0f];
	[UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft forView:window cache:NO];
	
	[viewController.navigationController.view removeFromSuperview];
	
	[UIView commitAnimations];
}

- (void)applicationDidFinishLaunching:(UIApplication *)application
{	
	[window makeKeyAndVisible];

	OSPickerViewController* viewController = [[[OSPickerViewController alloc] init] autorelease];
	UINavigationController* navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
	
	[viewController setDelegate:self];
	
	[window addSubview:navigationController.view];
 }


- (void)dealloc {
	[window release];
	[super dealloc];
}


@end

