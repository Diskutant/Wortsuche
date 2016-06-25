//
//  CAWortSucheController.m
//  Wortsuche
//
//  Created by Christian Aldekamp on 13.08.14.
//  Copyright (c) 2014 Aldekamp. All rights reserved.
//


#import "CAWortSucheController.h"

@implementation CAWortSucheController


-(id)init{
    isIntSearch=false;
    containsAsterisk=false;
    return self;
}


- (void)startWithString:(NSString *)pSearchString withAllowedLetters:(NSString *)allowedLetters andDelegate:(CAAppDelegate *)delegate{
    NSLog(@"Search by String");
    searchString=pSearchString;
    [self setAllowedLetters:allowedLetters andDelegate:delegate];
    [self loadWords:delegate];
}

- (void)start:(int)pWordLength withAllowedLetters:(NSString *)allowedLetters  andDelegate:(CAAppDelegate *)delegate{
    NSLog(@"Search by Int");
    
    [self setAllowedLetters:allowedLetters andDelegate:delegate];
    isIntSearch=true;
    wordLength = pWordLength;
    
    NSArray<NSString *> *loadedArray = [self loadFromFileWithWordLength:pWordLength];
    
    if(loadedArray.count>0){
        [theDelegate showUnfilteredResults:loadedArray];
        [theDelegate showResults:[self getAllowedWords:loadedArray]];
    } else {
        NSMutableString *mutableSearchString = [[NSMutableString alloc] initWithCapacity:pWordLength];
        
        for (int i = 0; i<pWordLength; i++) {
            [mutableSearchString appendString:@"?"];
        }
        
        searchString = mutableSearchString;
        [self loadWords:delegate];
    }
}


-(void)setAllowedLetters:(NSString *)allowedLetters andDelegate:(CAAppDelegate *)delegate{
    theDelegate                 = delegate;
    fullAllowedLettersString    = allowedLetters;
    allowedLettersArray         = [[NSMutableArray alloc] initWithCapacity:allowedLetters.length];
    
    for (int i = 0; i < allowedLetters.length; i++) {
        NSString *letter = [allowedLetters substringWithRange:NSMakeRange(i, 1)];
        if (![allowedLettersArray containsObject:letter]) {
            [allowedLettersArray addObject: letter];
        }
    }
    
    
    if(!isIntSearch){
        containsAsterisk = [searchString containsString:@"*"];
     
        for (int i = 0; i < searchString.length; i++) {
            NSString *letter = [searchString substringWithRange:NSMakeRange(i, 1)];
            if(![letter isEqualToString:@"*"] && ![letter isEqualToString:@"?"]){
                [allowedLettersArray addObject: letter];
                fullAllowedLettersString = [fullAllowedLettersString stringByAppendingString:letter];
            }
        }
    }

}


-(void)loadWords:(CAAppDelegate *)delegate{
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
        webData = [NSMutableData data];
        NSLog(@"connection initiated");
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [webData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSHTTPURLResponse *ne          = (NSHTTPURLResponse *)response;
    
    if([ne statusCode] != 200) {
        NSLog(@"connection state is %li", (long)[ne statusCode]);
    }
}

-(void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"Conn Err: %@", [error localizedDescription]);
   [[theDelegate indicator] stopAnimation:self];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSLog(@"Conn finished loading");
  
    NSArray<NSString *> * allWords =  [self getAllWords];
    
    [theDelegate showUnfilteredResults:allWords];
    
    if(isIntSearch){
        [self saveToFile:allWords withWordLength:wordLength];
    }
    
    [theDelegate showResults:[self getAllowedWords: allWords]];
}


-(NSArray<NSString *> *)getAllowedWords:(NSArray<NSString *> *)allWords {
    NSMutableArray *allowedWords    = [[NSMutableArray alloc] init];
    BOOL found                      = false;
    BOOL wordFound                  = true;
    BOOL finalWordFound             = false;
    int countOfAllowedWords         = 0;
    
    for (NSString *possibleWord in allWords) {
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
                    finalWordFound=false;
                    break;
                }
            }
            
            if(finalWordFound){
                countOfAllowedWords++;
                NSLog(@"%i: %@",countOfAllowedWords, possibleWord);
                [allowedWords addObject:possibleWord];
                
            }
        }
    }
    
    return allowedWords;
}


-(NSArray<NSString *> *)getAllWords{
    NSError         *error;
    NSMutableArray *allWords;
    NSString        *html       = [[NSString alloc] initWithBytes: [webData mutableBytes] length:[webData length] encoding:NSUTF8StringEncoding];
    
    
    //if there is only 1 result at wortsuche.com the page looks a bit different...
    NSRegularExpression *regexOneResult  = [NSRegularExpression regularExpressionWithPattern:@"<span id=\"word-name\"><h1>.*</h1></span>" options:NSRegularExpressionCaseInsensitive error:&error];
    NSArray<NSTextCheckingResult *> *matchesOneResult            = [regexOneResult matchesInString:html options:0 range:NSMakeRange(0, [html length])];
    
    //if no match for regexOneResult is not found we have a list of words
    if(matchesOneResult.count==0){
        NSRegularExpression *regex  = [NSRegularExpression regularExpressionWithPattern:@"<a href=\"http://wortsuche.com/word/.*>.*</a></li>\\r" options:NSRegularExpressionCaseInsensitive error:&error];
        
        NSArray *matches = [regex matchesInString:html options:0 range:NSMakeRange(0, [html length])];
        allWords = [[NSMutableArray alloc] initWithCapacity:matches.count];
        
        for (NSTextCheckingResult *match in matches) {
            NSString *tempString = [html substringWithRange:[match range]];
            NSRange rangeStart = [tempString rangeOfString:@">"];
            NSRange rangeEnd = [tempString rangeOfString:@"</"];
            
            NSString *possibleWord = [tempString substringWithRange:NSMakeRange(rangeStart.location+rangeStart.length, (rangeEnd.location-rangeStart.location)-rangeStart.length)];
            [allWords addObject:possibleWord];
        }
    }else{
        allWords = [[NSMutableArray alloc] initWithCapacity:matchesOneResult.count];
        NSString *tempString = [html substringWithRange:[[matchesOneResult objectAtIndex:0] range]];
        NSRange rangeStart = [tempString rangeOfString:@"h1>"];
        NSRange rangeEnd = [tempString rangeOfString:@"</h1"];
        NSString *possibleWord = [tempString substringWithRange:NSMakeRange(rangeStart.location+rangeStart.length, (rangeEnd.location-rangeStart.location)-rangeStart.length)];
        [allWords addObject:possibleWord];
    }
    
    return allWords;
}


-(int)numberOfOccurencesOfLetter:(NSString *)letter inString:(NSString *)string {
    NSRange searchRange = NSMakeRange(0, [string length]);
    int count = 0;

    do {
        // Search for next occurrence
        NSRange range = [string rangeOfString:letter options:NSCaseInsensitiveSearch range:searchRange];
        if (range.location != NSNotFound) {
            count ++;
            // If found, range contains the range of the current iteration
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


-(NSString *)getCacheFilePath:(int)length {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    
    if (![paths count]) { return nil; }
    
    NSString *bundleName    = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
    NSString *cacheDir      = [[paths objectAtIndex:0] stringByAppendingPathComponent:bundleName];
    NSString *returnVal     = [NSString stringWithFormat:@"%@/%i-words.xml", cacheDir, length];
    
    return returnVal;
}


-(void)saveToFile:(NSArray<NSString *> *)array withWordLength:(int)length{
    [array writeToFile:[self getCacheFilePath:length] atomically:YES];
}


-(NSArray<NSString *> *)loadFromFileWithWordLength:(int)length{
   return [NSArray arrayWithContentsOfFile:[self getCacheFilePath:length]];
}

@end
