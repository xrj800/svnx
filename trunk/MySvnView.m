//
// MySvnView.m - Superclass of MySvnLogView & MySvnRepositoryBrowserView
//

#import "MySvnView.h"
#import "MyRepository.h"
#import "Tasks.h"
#include "CommonUtils.h"
#include "DbgUtils.h"


@implementation MySvnView

- (id) initWithFrame: (NSRect) frameRect
{
	if (self = [super initWithFrame: frameRect])
	{

	}

	return self;
}


- (void) dealloc
{
//	NSLog(@"dealloc svn view");

    [self setPendingTask: nil]; 
    [self setUrl: nil]; 
    [self setRevision: nil]; 

    [super dealloc];
}


- (void) unload
{
	// tell the task center to cancel pending callbacks to prevent crash
	[[Tasks sharedInstance] cancelCallbacksOnTarget:self];

	[self setPendingTask: nil]; 
//	[self setUrl: nil]; 
//	[self setRevision: nil]; 

	[fView release];	// the nib is responsible for releasing its top-level objects

	// these objects are bound to the file owner and retain it
	// we need to unbind them 
	[progress unbind:@"animate"];		// -> self retainCount -1
	[refetch unbind:@"value"];		// -> self retainCount -1
}


- (IBAction) refetch: (id) sender
{
	if ( [sender state] == NSOnState )
	{
		[self fetchSvn];
	}
	else
	{
		[self setIsFetching:FALSE];

		if ( [self pendingTask] != nil )
		{
			NSTask *task = [[self pendingTask] valueForKey:@"task"];
			
			if ( [task isRunning] )
			{
				[task terminate];
			}
		}

		[self setPendingTask:nil];
	}
}


//----------------------------------------------------------------------------------------
#pragma mark	-
#pragma mark	svn related methods

- (void) fetchSvn
{
	[self setIsFetching:TRUE];
}


- (void) svnCommandComplete: (id) taskObj
{
//	NSLog(@"hom %@", [taskObj valueForKey:@"stdout"]);
	if ( [[taskObj valueForKey:@"status"] isEqualToString:@"completed"] )
	{
		[self performSelectorOnMainThread: @selector(fetchSvnReceiveDataFinished:)
			  withObject:                  taskObj
			  waitUntilDone:               YES];
//		[self fetchSvnReceiveDataFinished:taskObj];
	}
	else if ( [[taskObj valueForKey:@"stderr"] length] > 0 )
		[self svnError:[taskObj valueForKey:@"stderr"]];
}


- (void) svnError: (NSString*) errorString
{
	NSAlert *alert = [NSAlert alertWithMessageText: @"svn Error"
									 defaultButton: @"OK"
								   alternateButton: nil
									   otherButton: nil
						 informativeTextWithFormat: @"%@", errorString];
	
	[alert setAlertStyle:NSCriticalAlertStyle];
	
 	[self setIsFetching:NO];
	
	if ( [self window] != nil )
	{
		[alert beginSheetModalForWindow: [self window]
						  modalDelegate: self
						 didEndSelector: nil
						    contextInfo: nil];
	}
	else
	{
		[alert runModal];
	}
}


- (void) fetchSvnReceiveDataFinished: (id) taskObj
{
	[self setIsFetching:FALSE];
}


//----------------------------------------------------------------------------------------
#pragma mark	-
#pragma mark	Helpers

- (NSInvocation*) makeCallbackInvocationOfKind: (int) callbackKind
{
	// only one kind of invocation for now, but more complex callbacks will be possible in the future

	return MakeCallbackInvocation(self, @selector(svnCommandComplete:));
}


//----------------------------------------------------------------------------------------
#pragma mark	-
#pragma mark	Accessors

- (NSInvocation*) svnOptionsInvocation { return fOptionsInvocation; }

- (void) setSvnOptionsInvocation: (NSInvocation*) aSvnOptionsInvocation
{
	id old = fOptionsInvocation;
	fOptionsInvocation = [aSvnOptionsInvocation retain];
	[old release];
}


// - url:
- (NSURL*) url { return fURL; }

- (void) setUrl: (NSURL*) anUrl
{
	id old = fURL;
	fURL = [anUrl retain];
	[old release];
}


// - revision:
- (NSString*) revision { return fRevision; }

- (void) setRevision: (NSString*) aRevision
{
	id old = fRevision;
	fRevision = [aRevision retain];
	[old release];
}


// - isFetching:
- (BOOL) isFetching { return isFetching; }

- (void) setIsFetching: (BOOL) flag
{
	isFetching = flag;
}

// - pendingTask:
- (id) pendingTask { return pendingTask; }

- (void) setPendingTask: (id) aPendingTask
{
	id old = pendingTask;
	pendingTask = [aPendingTask retain];
	[old release];
}


//----------------------------------------------------------------------------------------
// Returns the displayed repository or nil.

- (MyRepository*) repository
{
	NSDocument* document = [[[self window] windowController] document];
	return [document isKindOfClass: [MyRepository class]] ? (MyRepository*) document : nil;
}


//----------------------------------------------------------------------------------------

- (NSDictionary*) documentNameDict
{
	id itsTitle = nil;
	MyRepository* itsRepository = [self repository];
	if (itsRepository)
		itsTitle = [itsRepository windowTitle];

	if (itsTitle == nil)
		itsTitle = [[self window] title];

	if (itsTitle == nil)
		itsTitle = @"";

	return [NSDictionary dictionaryWithObject: itsTitle forKey: @"documentName"];
}


@end
