//
//  MFPluginController.m
//  XcodeTextTools
//
//  Created by Michaël Fortin on 2014-03-14.
//  Copyright (c) 2014 Michaël Fortin. All rights reserved.
//

#import "MFPluginController.h"
#import "NSMenu+XcodeTextTools.h"
#import "NSTextView+XcodeTextTools.h"
#import "IDEKit.h"

@implementation MFPluginController
{
	NSBundle *_pluginBundle;
	NSTextView *_activeTextView;
}

#pragma mark Lifetime

- (id)initWithPluginBundle:(NSBundle *)pluginBundle
{
    self = [super init];
    if (self)
    {
		_pluginBundle = pluginBundle;
		
		[self insertMenuItems];
        [self registerForNotifications];
    }
    return self;
}

- (void)insertMenuItems
{
	NSArray *menuItems = @[[NSMenuItem separatorItem], [self createTextToolsMenuItem]];
	
	NSMenu *editMenu = [[[NSApp mainMenu] itemWithTitle:@"Edit"] submenu];
	[editMenu xctt_insertItems:menuItems beforeItem:1 where:^BOOL(NSMenuItem *item) { return [item isSeparatorItem]; }];
}

- (NSMenuItem *)createTextToolsMenuItem
{
	NSMenu *submenu = [[NSMenu alloc] init];
	[submenu addItem:[self createMenuItemWithTitle:@"Cut Line" action:@selector(cutLine_clicked:)]];
	[submenu addItem:[self createMenuItemWithTitle:@"Copy Line" action:@selector(copyLine_clicked:)]];
	[submenu addItem:[self createMenuItemWithTitle:@"Paste Line" action:@selector(pasteLine_clicked:)]];
	[submenu addItem:[self createMenuItemWithTitle:@"Duplicate Line" action:@selector(duplicateLine_clicked:)]];
	[submenu addItem:[self createMenuItemWithTitle:@"Delete Line" action:@selector(deleteLine_clicked:)]];
	[submenu addItem:[NSMenuItem separatorItem]];
	[submenu addItem:[self createMenuItemWithTitle:@"Highlight Occurences of Selection" action:@selector(highlightSelection_clicked:)]];
	[submenu addItem:[self createMenuItemWithTitle:@"Remove Highlighting" action:@selector(removeHighlighting_clicked:)]];
	[submenu addItem:[NSMenuItem separatorItem]];
	[submenu addItem:[self createMenuItemWithTitle:@"Expand Selection" action:@selector(expandSelection_clicked:)]];
	
	NSMenuItem *textToolsMenuItem = [[NSMenuItem alloc] initWithTitle:@"Text Tools" action:NULL keyEquivalent:@""];
	[textToolsMenuItem setSubmenu:submenu];
	
	return textToolsMenuItem;
}

- (NSMenuItem *)createMenuItemWithTitle:(NSString *)title action:(SEL)action
{
	NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:title action:action keyEquivalent:@""];
	[item setTarget:self];
	return item;
}

- (void)registerForNotifications
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activeEditorContextDidChange:)
												 name:@"IDEEditorAreaLastActiveEditorContextDidChangeNotification" object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Line Manipulation Action Methods

- (void)cutLine_clicked:(id)sender
{
	[[[self currentSourceTextView] manipulator] cutLine];
}

- (void)copyLine_clicked:(id)sender
{
	[[[self currentSourceTextView] manipulator] copyLine];
}

- (void)pasteLine_clicked:(id)sender
{
	[[[self currentSourceTextView] manipulator] pasteLine];
}

- (void)duplicateLine_clicked:(id)sender
{
	[[[self currentSourceTextView] manipulator] duplicateLine];
}

- (void)deleteLine_clicked:(id)sender
{
	[[[self currentSourceTextView] manipulator] deleteLine];
}

#pragma mark Highlighting Action Methods

- (void)highlightSelection_clicked:(id)sender
{
	[[[self currentSourceTextView] manipulator] highlightSelection];
}

- (void)removeHighlighting_clicked:(id)sender
{
	[[[self currentSourceTextView] manipulator] removeHighlighting];
}

#pragma mark Selection Action Methods

- (void)expandSelection_clicked:(id)sender
{
	[[[self currentSourceTextView] manipulator] expandSelection];
}

#pragma mark Implementation

- (IDEEditor *)currentEditor
{
	NSWindowController *currentWindowController = [[NSApp keyWindow] windowController];
	if ([currentWindowController isKindOfClass:NSClassFromString(@"IDEWorkspaceWindowController")])
	{
		IDEWorkspaceWindowController *workspaceController = (IDEWorkspaceWindowController *)currentWindowController;
		IDEEditorArea *editorArea = [workspaceController editorArea];
		IDEEditorContext *editorContext = [editorArea lastActiveEditorContext];
		return [editorContext editor];
	}
	return nil;
}

- (DVTSourceTextView *)currentSourceTextView
{
	IDEEditor *currentEditor = [self currentEditor];
	
    if ([currentEditor isKindOfClass:NSClassFromString(@"IDESourceCodeEditor")])
        return (DVTSourceTextView *)[(id)currentEditor textView];
    
    if ([currentEditor isKindOfClass:NSClassFromString(@"IDESourceCodeComparisonEditor")])
        return [(id)currentEditor performSelector:NSSelectorFromString(@"keyTextView")];
    
    return nil;
}

- (void)activeEditorContextDidChange:(NSNotification *)notification
{
	IDEEditorContext *context = [notification userInfo][@"IDEEditorContext"];
    _activeTextView = [self getSourceTextViewFromEditorContext:context];
}

- (DVTSourceTextView *)getSourceTextViewFromEditorContext:(IDEEditorContext *)context
{
    IDEEditor *editor = [context editor];
    NSScrollView *scrollView = [editor mainScrollView];
    NSClipView *clipView = [scrollView contentView];
	
    id documentView = [clipView documentView];
    
	return [documentView isKindOfClass:[DVTSourceTextView class]] ? documentView : nil;
}

@end