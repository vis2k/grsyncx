//
//  MainViewController.m
//  grsyncx
//
//  Created by Michal Zelinka on 12/01/2020.
//  Copyright © 2020 Michal Zelinka. All rights reserved.
//

#import "MainViewController.h"
#import "SyncingViewController.h"
#import "WindowActionsResponder.h"

@interface SourceHelpPopupViewController : NSViewController
@end

@interface MainViewController () <WindowActionsResponder>

@property (nonatomic, weak) IBOutlet NSPathControl *sourcePathCtrl;
@property (nonatomic, weak) IBOutlet NSPathControl *destinationPathCtrl;

@property (nonatomic, weak) IBOutlet NSButton *sourcePathChangeButton;
@property (nonatomic, weak) IBOutlet NSButton *destinationPathChangeButton;

// trailing "/" in source path
@property (nonatomic, weak) IBOutlet NSButton *wrapInSourceFolderButton;
@property (nonatomic, weak) IBOutlet NSButton *wrapInSourceFolderHelpButton;

// -t, --times | Preserve time
@property (nonatomic, weak) IBOutlet NSButton *preserveTimeButton;
// -p, --perms | Preserve permissions
@property (nonatomic, weak) IBOutlet NSButton *preservePermissionsButton;
// -o, --owner | Preserve owner (super-user only)
@property (nonatomic, weak) IBOutlet NSButton *preserveOwnerButton;
// -g, --group | Preserve group
@property (nonatomic, weak) IBOutlet NSButton *preserveGroupButton;
// -E | Preserve extended attributes
@property (nonatomic, weak) IBOutlet NSButton *preserveExtAttrsButton;

// --delete | Delete extraneous files from the destination dirs
@property (nonatomic, weak) IBOutlet NSButton *deleteOnDestButton;
// -x, --one-file-system | Don't cross filesystem boundaries
@property (nonatomic, weak) IBOutlet NSButton *dontLeaveFilesystButton;
// -v, --verbose | Increase verbosity
@property (nonatomic, weak) IBOutlet NSButton *verboseButton;
// --progress | Show progress during transfer
@property (nonatomic, weak) IBOutlet NSButton *showTransProgressButton;
// --ignore-existing | Ignore files which already exist in the destination
@property (nonatomic, weak) IBOutlet NSButton *ignoreExistingButton;
// --size-only | Skip file that match in size, ignore time and checksum
@property (nonatomic, weak) IBOutlet NSButton *sizeOnlyButton;
// -u, --update | Skip files that are newer in the destination
@property (nonatomic, weak) IBOutlet NSButton *skipNewerButton;
// --modify-window=1 | Compare modification times with reduced accuracy, workaround for a FAT FS limitation
@property (nonatomic, weak) IBOutlet NSButton *windowsCompatButton;

// -c, --checksum | Skip based on checksum, not time and size
@property (nonatomic, weak) IBOutlet NSButton *alwaysChecksumButton;
// -z, --compress | Compress data during transfer (if one+ side is remote)
@property (nonatomic, weak) IBOutlet NSButton *compressFileDataButton;
// -D | Same as --devices --specials
@property (nonatomic, weak) IBOutlet NSButton *preserveDevicesButton;
// --existing | Only update existing files, skip new
@property (nonatomic, weak) IBOutlet NSButton *existingFilesButton;
// -P | Same as --partial --progress
@property (nonatomic, weak) IBOutlet NSButton *partialTransFilesButton;
// --numeric-ids | Keep numeric UID/GID instead of mapping its names
@property (nonatomic, weak) IBOutlet NSButton *noUIDGIDMapButton;
// -l | Symbolic links are copied as such, do not copy link target file
@property (nonatomic, weak) IBOutlet NSButton *preserveSymlinksButton;
// -H, --hard-links | Hard-links are copied as such, do not copy link target file
@property (nonatomic, weak) IBOutlet NSButton *preserveHardLinksButton;
// -b, --backup | Make backups of existing files in the destination, see --suffix & --backup-dir
@property (nonatomic, weak) IBOutlet NSButton *makeBackupsButton;
// -i, --itemize-changes | Show additional information on every changed file
@property (nonatomic, weak) IBOutlet NSButton *showItemizedChangesButton;
// -d (vs -r) | If checked, source subdirectories will be ignored
@property (nonatomic, weak) IBOutlet NSButton *disableRecursionButton;
// -s | Protect remote args from shell expansion, avoids the need to manually escape filename args like --exclude
@property (nonatomic, weak) IBOutlet NSButton *protectRemoteArgsButton;

@property (nonatomic, weak) IBOutlet NSTextView *additionalOptsTextView;

@end

@implementation MainViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	[self resignFirstResponder];
	// Do any additional setup after loading the view.

	// rsync --stats
	// rsync --itemize-changes:
	// http://www.staroceans.org/e-book/understanding-the-output-of-rsync-itemize-changes.html

	_sourcePathCtrl.URL = [NSURL fileURLWithPath:NSHomeDirectory()];
	if (@available(macOS 10.15, *)) {
		_additionalOptsTextView.textContainer.textView.font =
			[NSFont monospacedSystemFontOfSize:13 weight:NSFontWeightRegular];
	}

	_sourcePathCtrl.layer.cornerRadius = 4;
	_destinationPathCtrl.layer.cornerRadius = 4;
}


- (void)setRepresentedObject:(id)representedObject {
	[super setRepresentedObject:representedObject];

	// Update the view, if already loaded.
}


#pragma mark - Actions


- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message
{
	NSAlert *alert = [[NSAlert alloc] init];
	alert.messageText = title ?: @"";
	alert.informativeText = message ?: @"";
	alert.alertStyle = NSAlertStyleCritical;
	[alert addButtonWithTitle:NSLocalizedString(@"Close", @"Button title")];
	[alert beginSheetModalForWindow:self.view.window completionHandler:nil];
}


#pragma mark - UI actions


- (IBAction)pickFolder:(id)sender
{
	NSString *title = nil;
	NSPathControl *pathCtrl = nil;

	if (sender == _sourcePathChangeButton || sender == _sourcePathCtrl) {
		title = NSLocalizedString(@"Select Source folder", @"View label");
		pathCtrl = _sourcePathCtrl;
	} else {
		title = NSLocalizedString(@"Select Destination folder", @"View label");
		pathCtrl = _destinationPathCtrl;
	}

	BOOL pickingDest = pathCtrl == _destinationPathCtrl;

	NSOpenPanel *panel = [NSOpenPanel openPanel];
	panel.title = title;
	panel.directoryURL = pathCtrl.URL;
	panel.canChooseDirectories = YES;
	panel.canCreateDirectories = YES;
	panel.canChooseFiles = !pickingDest;
	panel.allowsMultipleSelection = NO;

	[panel beginSheetModalForWindow:self.view.window
	  completionHandler:^(NSModalResponse result) {
		if (result == NSModalResponseOK)
			pathCtrl.URL = panel.URLs.firstObject;
	}];
}

- (IBAction)displayHelp:(id)sender
{
	SourceHelpPopupViewController *vc = [[SourceHelpPopupViewController alloc] init];

	CGSize size = vc.view.bounds.size;

//	CGFloat inset = 12;
//	CGRect frame = CGRectMake(inset, inset, size.width-2*inset, size.height-2*inset);
//
//	NSTextField *desc = [[NSTextField alloc] initWithFrame:frame];
//	desc.editable = NO;
//	desc.selectable = NO;
//	desc.backgroundColor = [NSColor clearColor];
//	desc.bezeled = NO; desc.bordered = NO;
//	desc.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
//	desc.stringValue = NSLocalizedString(@"This settings allows to wrap contents of "
//		"the Source directory within a folder in the Destination path named same as "
//		"the Source directory.\n\nIf you have a couple of `example.*` files in your "
//		"Source path, wrapping them will put them to a `Destination/Source/example.*` "
//		"path.\n\nWithout wrapping, these files will be included directly at the "
//		"`Destination/example.*` path.", @"Source wrap popup help description");
//	[vc.view addSubview:desc];


	NSImage *image = [NSImage imageNamed:@"source_wrap_hint"];

	NSImageView *imageView = [NSImageView imageViewWithImage:image];
	imageView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;

	CGRect imgFrame = imageView.frame;
	imgFrame.origin.x = round((size.width - imgFrame.size.width)/2);
	imgFrame.origin.y = round((size.height - imgFrame.size.height)/2);
	imageView.frame = imgFrame;
	[vc.view addSubview:imageView];

	NSRect rect = [sender convertRect:[sender bounds] toView:self.view];

	NSPopover *helpPopover = [NSPopover new];
	helpPopover.contentSize = vc.preferredContentSize;
	helpPopover.behavior = NSPopoverBehaviorTransient;;
	helpPopover.animates = YES;
	helpPopover.contentViewController = vc;
	[helpPopover showRelativeToRect:rect ofView:self.view preferredEdge:NSRectEdgeMaxX];
}


#pragma mark - Rsync command


- (NSArray<NSString *> *)collectArguments
{
	NSMutableArray<NSString *> *args = [NSMutableArray arrayWithCapacity:32];

	#define isOn(btn) (btn.state == NSControlStateValueOn)

	if (isOn(_preserveTimeButton))           [args addObject:@"-t"];
	if (isOn(_preservePermissionsButton))    [args addObject:@"-p"];
	if (isOn(_preserveOwnerButton))          [args addObject:@"-o"];
	if (isOn(_preserveGroupButton))          [args addObject:@"-g"];
	if (isOn(_preserveExtAttrsButton))       [args addObject:@"-E"];

	if (isOn(_deleteOnDestButton))           [args addObject:@"--delete"];
	if (isOn(_dontLeaveFilesystButton))      [args addObject:@"-x"];
	if (isOn(_verboseButton))                [args addObject:@"-v"];
	if (isOn(_showTransProgressButton))      [args addObject:@"--progress"];
	if (isOn(_ignoreExistingButton))         [args addObject:@"--ignore-existing"];
	if (isOn(_sizeOnlyButton))               [args addObject:@"--size-only"];
	if (isOn(_skipNewerButton))              [args addObject:@"--update"];
	if (isOn(_windowsCompatButton))          [args addObject:@"--modify-window=1"];

	if (isOn(_alwaysChecksumButton))         [args addObject:@"--checksum"];
	if (isOn(_compressFileDataButton))       [args addObject:@"--compress"];
	if (isOn(_preserveDevicesButton))        [args addObject:@"-D"];
	if (isOn(_existingFilesButton))          [args addObject:@"--existing"];
	if (isOn(_partialTransFilesButton))      [args addObject:@"-P"];
	if (isOn(_noUIDGIDMapButton))            [args addObject:@"--numeric-ids"];
	if (isOn(_preserveSymlinksButton))       [args addObject:@"-l"];
	if (isOn(_preserveHardLinksButton))      [args addObject:@"-H"];
	if (isOn(_makeBackupsButton))            [args addObject:@"--backup"];
	if (isOn(_showItemizedChangesButton))    [args addObject:@"-i"];

	if (isOn(_disableRecursionButton))       [args addObject:@"-d"];
	else                                     [args addObject:@"-r"];

	if (isOn(_protectRemoteArgsButton))      [args addObject:@"-s"];

	NSArray<NSString *> *additionalArgs =
	[[_additionalOptsTextView.textStorage.string
	  componentsSeparatedByString:@" "] filteredArrayUsingPredicate:
	 [NSPredicate predicateWithBlock:^BOOL(NSString *arg,
	  NSDictionary<NSString *,id> *__unused bindings) {
		return arg.length > 0;
	}]];

	if (additionalArgs.count)
		[args addObjectsFromArray:additionalArgs];

	return [args copy];
}

- (void)runRsyncSimulated:(BOOL)simulated
{


	[self performSegueWithIdentifier:@"SyncingSegue" sender:nil];



	return;


	NSURL *srcURL = _sourcePathCtrl.pathItems.lastObject.URL;
	NSURL *dstURL = _destinationPathCtrl.pathItems.lastObject.URL;

	NSString *err = nil;
	NSView *focusElement = nil;

	if (!srcURL) {
		err = NSLocalizedString(@"Source path isn't set", @"View label");
		focusElement = _sourcePathCtrl;
	}
	else if (!dstURL) {
		err = NSLocalizedString(@"Destination path isn't set", @"View label");
		focusElement = _destinationPathCtrl;
	}

	if (err) {

		if (focusElement)
			[focusElement becomeFirstResponder];

		[self showAlertWithTitle:err message:nil];

		return;
	}

	NSMutableArray<NSString *> *args = [[self collectArguments] mutableCopy];

	if (simulated)
		[args addObject:@"-n"];

	NSString *srcPath = srcURL.path;
	NSString *dstPath = dstURL.path;

	if (_wrapInSourceFolderButton.state == NSControlStateValueOff)
		srcPath = [srcPath stringByAppendingString:@"/"];

	[args addObject:srcPath];
	[args addObject:dstPath];

	NSTask *task = [NSTask new];
	task.launchPath = @"/usr/bin/rsync";
	task.arguments = args;

	NSPipe *pipe = [NSPipe new];
	task.standardOutput = pipe;
	task.standardError = pipe;

/// Asynchronous
	static id observer = nil;
	NSFileHandle *handle = pipe.fileHandleForReading;

	[handle waitForDataInBackgroundAndNotify];

	observer = [[NSNotificationCenter defaultCenter] addObserverForName:
	  NSFileHandleDataAvailableNotification object:handle
	  queue:nil usingBlock:^(NSNotification *__unused note) {

		NSData *data = [handle availableData];

		if (data.length == 0)
			return;

		NSString *line = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		NSLog(@"out: %@", line);

		[handle waitForDataInBackgroundAndNotify];
	}];

	task.terminationHandler = ^(NSTask *__unused endedTask) {
		[[NSNotificationCenter defaultCenter] removeObserver:observer];
		observer = nil;
	};
////

	[task launch];

//// Synchronous
//
//	[task waitUntilExit];
//	NSLog(@"Finished");
//
//	NSFileHandle *read = [pipe fileHandleForReading];
//	NSData *dataRead = [read readDataToEndOfFile];
//	NSString *stringRead = [[NSString alloc] initWithData:dataRead encoding:NSUTF8StringEncoding];
//	NSLog(@"output: %@", stringRead);
////
}


#pragma mark - Window actions responder


- (void)didReceiveSimulateAction
{
	[self runRsyncSimulated:YES];
}

- (void)didReceiveExecuteAction
{
	[self runRsyncSimulated:NO];
}


@end




@implementation SourceHelpPopupViewController

- (void)loadView
{
	self.view = [NSView new];
}

- (NSSize)preferredContentSize
{
	return CGSizeMake(512, 192);
}

@end
