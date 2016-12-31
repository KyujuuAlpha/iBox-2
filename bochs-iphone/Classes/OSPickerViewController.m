//
//  OSPickerViewController.m
//  bochs
//
//  Created by WERT on 19.07.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "OSPickerViewController.h"

@interface OSPickerViewController ()

@property (readonly) NSString *documentsPath;

@end

@implementation OSPickerViewController

- (id)init
{
	if (self = [super initWithStyle:UITableViewStylePlain]) 
	{
		delegate = nil;
		
		NSArray* filesArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.documentsPath error:nil];
		
		osArray = [[NSMutableArray alloc] initWithCapacity:[filesArray count]];

		for (NSString* path in filesArray)
		{
			if ([path hasPrefix:@"."])
				continue;
			
			[osArray addObject:path];
		}
		
		self.title = @"Choose OS";
		self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"About" style:UIBarButtonItemStyleBordered target:self action:@selector(aboutAction:)] autorelease];
	}
	
	return self;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex)
	{
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://isoftcom.com/"]];
	}
}

- (void)aboutAction:(id)obj
{
	UIAlertView* alertView = [[[UIAlertView alloc] initWithTitle:@"Bochs 2.3.1 - iPhone edition" message:@"Original software site: http://bochs.sourceforge.net/\n\nPorting to iPhone by Wert (i@wert.cx) from iSoftTeam. Find out more apps from iSoftTeam at: http://isoftcom.com/" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:@"Visit site", nil] autorelease];
	[alertView show];
}

- (void)setDelegate:(id<OSPickerViewControllerDelegate>)_delegate
{
	delegate = _delegate;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [osArray count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	static NSString* cell_id = @"C_D";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cell_id];
	if (cell == nil) 
	{
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:cell_id] autorelease];
	}
	
	cell.text = [osArray objectAtIndex:[indexPath row]];
	
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
	return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	[delegate selectedOsInPickerView:self withConfigFile:[NSString stringWithFormat:@"%@/%@/os.ini", self.documentsPath, [osArray objectAtIndex:[indexPath row]]]];
}

-(NSString *)documentsPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}

@end

