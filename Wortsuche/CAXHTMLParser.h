//
//  CAXHTMLParser.h
//  Wortsuche
//
//  Created by Christian Aldekamp on 13.08.14.
//  Copyright (c) 2014 Aldekamp. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CAXHTMLParser : NSObject <NSXMLParserDelegate>
{
    NSXMLParser *parser;
    NSMutableString *element;
    NSData *data;
}


- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qualifiedName
    attributes:(NSDictionary *)attributeDict;
@end
