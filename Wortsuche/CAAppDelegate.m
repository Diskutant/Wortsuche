//
//  CAAppDelegate.m
//  Wortsuche
//
//  Created by Christian Aldekamp on 13.08.14.
//  Copyright (c) 2014 Aldekamp. All rights reserved.
//

#import "CAAppDelegate.h"
#import "CAWortSucheController.h"

@implementation CAAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
}


-(IBAction)search:(id)sender{
    [self.indicator startAnimation:self];
    CAWortSucheController *wortsuche = [CAWortSucheController new];
    
    NSCharacterSet* notDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    if ([[self.wordLength stringValue] rangeOfCharacterFromSet:notDigits].location == NSNotFound)
    {
        //wordLength contains only the digits 0 through 9
        [wortsuche start:[self.wordLength intValue] withAllowedLetters:[self.allowedLetters stringValue] andDelegate:self];
    }else{
        [wortsuche startWithString:[self.wordLength stringValue] withAllowedLetters:[self.allowedLetters stringValue] andDelegate:self];
    }
}


-(void)showResults:(NSArray<NSString *> *)theResult{
    NSMutableString *mutableString = [[NSMutableString alloc] init];
    int i = 1;
    for (NSString *word in theResult) {
        if(i%3==0){
            [mutableString appendFormat:@"%@\n", word];
        }else{
            [mutableString appendFormat:@"%@\t\t", word];
        }
        i++;

    }
    
    [self.filteredTextView setString:mutableString];
    [self.indicator stopAnimation:self];
}


-(void)showUnfilteredResults:(NSArray<NSString *> *)allWords{
    NSMutableString *mutableString = [[NSMutableString alloc] init];

    for (NSString *word in allWords) {
        [mutableString appendFormat:@"%@ ", word];
    }
    
    [self.unfilteredTextView setString:mutableString];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
    return YES;
}

@end
