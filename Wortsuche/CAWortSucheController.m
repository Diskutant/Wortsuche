//
//  CAWortSucheController.m
//  Wortsuche
//
//  Created by Christian Aldekamp on 13.08.14.
//  Copyright (c) 2014 Aldekamp. All rights reserved.
//


#import "CAWortSucheController.h"

@implementation CAWortSucheController

NSMutableData *webData;
NSString *searchString;
NSMutableArray *allowedLettersArray;
NSString *fullAllowedLettersString;
CAAppDelegate *theDelegate;


- (void)startWithString:(NSString *)p_searchString withAllowedLetters:(NSString *)allowedLetters andDelegate:(CAAppDelegate *)delegate{
    NSLog(@"String Suche");
    searchString=p_searchString;
    [self startWithAllowedLetters:allowedLetters andDelegate:delegate];
}

- (void)start:(int)wordLength withAllowedLetters:(NSString *)allowedLetters  andDelegate:(CAAppDelegate *)delegate{
    NSLog(@"Int Suche");
    NSMutableString *mutableSearchString = [[NSMutableString alloc] initWithCapacity:wordLength];
    for (int i = 0; i<wordLength; i++) {
        [mutableSearchString appendString:@"?"];
    }
    searchString = mutableSearchString;
    [self startWithAllowedLetters:allowedLetters andDelegate:delegate];
}


-(void)startWithAllowedLetters:(NSString *)allowedLetters andDelegate:(CAAppDelegate *)delegate{
    theDelegate=delegate;
    fullAllowedLettersString=allowedLetters;
    
    allowedLettersArray = [[NSMutableArray alloc] initWithCapacity:allowedLetters.length];
    for (int i = 0; i < allowedLetters.length; i++) {
        NSString *letter = [allowedLetters substringWithRange:NSMakeRange(i, 1)];
        if (![allowedLettersArray containsObject:letter]) {
            [allowedLettersArray addObject: letter];
        }
    }
    [self loadWords];
}


-(void)loadWords{
    NSLog(@"web request started");
    NSString *post                 = [NSString stringWithFormat:@"str=%@&submit", searchString];
    NSData *postData               = [post dataUsingEncoding:NSUTF8StringEncoding];
    NSString *postLength           = [NSString stringWithFormat:@"%ld", (unsigned long)[postData length]];
    
    NSLog(@"Post data: %@", post);
    
    NSMutableURLRequest *request   = [NSMutableURLRequest new];
    [request setURL:[NSURL URLWithString:@"http://wortsuche.com"]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    
    //start the Search
    NSURLConnection *theConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    
    if(theConnection) {
        webData                        = [NSMutableData data];
        NSLog(@"connection initiated");
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [webData appendData:data];
    //NSLog(@"connection received data");
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSLog(@"connection received response");
    NSHTTPURLResponse *ne          = (NSHTTPURLResponse *)response;
    if([ne statusCode] == 200) {
        NSLog(@"connection state is 200 - all okay");
    } else {
        NSLog(@"connection state is NOT 200");
    }
}

-(void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"Conn Err: %@", [error localizedDescription]);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSLog(@"Conn finished loading");
    
    
    [self parse];
    
}


-(void)parse{
    
    NSString *html                 = [[NSString alloc] initWithBytes: [webData mutableBytes] length:[webData length] encoding:NSUTF8StringEncoding];
    
    //    <li><a href="http://wortsuche.com/word/aal/">aal</a></li>
    
    NSError *error;
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"<a href=\"http://wortsuche.com/word/.*>.*</a></li>\\r" options:NSRegularExpressionCaseInsensitive error:&error];
    
    NSArray *matches = [regex matchesInString:html options:0 range:NSMakeRange(0, [html length])];
    
    NSMutableArray *allowedWords = [[NSMutableArray alloc] init];
    
    
    BOOL found = false;
    BOOL wordFound = true;
    BOOL finalWordFound = false;
    int countOfAllowedWords = 0;
    NSLog(@"Anfang" );
    for (NSTextCheckingResult *match in matches) { //Wortschleife
        NSString *tempString = [html substringWithRange:[match range]];
        NSString *possibleWord = [tempString substringWithRange:NSMakeRange(35, searchString.length)];
        
        wordFound=true;
        for (int i = 0; i < possibleWord.length; i++) { //Letter in PossibleWord Schleife
            NSString *letterFromPossibleWord = [possibleWord substringWithRange:NSMakeRange(i, 1)];
            
            found=false;
            for (NSString *allowedLetter in allowedLettersArray) { //AllowedLetter Schleife
                if([letterFromPossibleWord compare:allowedLetter options:NSCaseInsensitiveSearch] == NSOrderedSame){
                    //letterFromPossibleWord is allowed
                    found=true;
                    break;
                }
            }
            
            if(found==false){
                wordFound=false;
                break;
            }
        }
        if(wordFound==true){
            
            for (NSString *allowedLetter in allowedLettersArray) {
                finalWordFound=true;
                int letterCountPossibleWorld = [self numberOfOccurencesOfLetter:allowedLetter inString:possibleWord];
                int letterCountAllowedLetters = [self numberOfOccurencesOfLetter:allowedLetter inString:fullAllowedLettersString];
                
                if(letterCountAllowedLetters<letterCountPossibleWorld){
                    //NSLog(@"%i < %i %@, %@", letterCountAllowedLetters, letterCountPossibleWorld, possibleWord, allowedLetter);
                    finalWordFound=false;
                    break;
                }else{
                    //NSLog(@"%i > %i %@ %@", letterCountAllowedLetters, letterCountPossibleWorld, possibleWord, allowedLetter);
                    //finalWordFound=false;
                }
                
            }
            
            if(finalWordFound){
                countOfAllowedWords++;
                NSLog(@"%i: %@",countOfAllowedWords, possibleWord);
                [allowedWords addObject:possibleWord];
                
            }
           
            
    
        }
    }
    NSLog(@"Ende");
    
    
    [theDelegate showResults:allowedWords];
    
    
}


-(int)numberOfOccurencesOfLetter:(NSString *)letter inString:(NSString *)string {
    int count = 0;
    NSRange searchRange = NSMakeRange(0, [string length]);
    do {
        // Search for next occurrence
        NSRange range = [string rangeOfString:letter options:NSCaseInsensitiveSearch range:searchRange];
        if (range.location != NSNotFound) {
            count ++;
            // If found, range contains the range of the current iteration
            
            // NOW DO SOMETHING WITH THE STRING / RANGE
            
            // Reset search range for next attempt to start after the current found range
            searchRange.location = range.location + range.length;
            searchRange.length = [string length] - searchRange.location;
        } else {
            // If we didn't find it, we have no more occurrences
            break;
        }
    } while (1);
    
    return count;
}


@end
