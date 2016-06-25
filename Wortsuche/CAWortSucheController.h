//
//  CAWortSucheController.h
//  Wortsuche
//
//  Created by Christian Aldekamp on 13.08.14.
//  Copyright (c) 2014 Aldekamp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SYXmlParser.h"
#import "CAAppDelegate.h"

@interface CAWortSucheController : NSObject{

    NSArray<NSString *> *resultArray;
    NSMutableData *webData;
    NSString *searchString;
    NSMutableArray<NSString *> *allowedLettersArray;
    NSString *fullAllowedLettersString;
    CAAppDelegate *theDelegate;
    int wordLength;
    bool isIntSearch;
    bool containsAsterisk;
}


- (void)start:(int)wordLength withAllowedLetters:(NSString *)allowedLetters andDelegate:(CAAppDelegate *)delegate;
- (void)startWithString:(NSString *)searchString withAllowedLetters:(NSString *)allowedLetters andDelegate:(CAAppDelegate *)delegate;

@end
