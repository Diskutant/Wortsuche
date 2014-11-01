//
//  CAAppDelegate.h
//  Wortsuche
//
//  Created by Christian Aldekamp on 13.08.14.
//  Copyright (c) 2014 Aldekamp. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CAAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSTextField *wordLength;
@property (assign) IBOutlet NSTextField *allowedLetters;
@property (assign) IBOutlet NSTextView *textView;


-(IBAction)search:(id)sender;

-(void)showResults:(NSArray *)theResult;

@end
