//
//  main.m
//  replace
//
//  Created by flexih on 2018/6/12.
//  Copyright © 2018 iQiYi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#include <stdlib.h>

NSString *mas_to_constraint(NSString *masAttribute) {
    static NSDictionary *relations;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        relations = @{@"left": @"NSLayoutAttributeLeft",
                      @"top": @"NSLayoutAttributeTop",
                      @"right": @"NSLayoutAttributeRight",
                      @"bottom": @"NSLayoutAttributeBottom",
                      @"leading": @"NSLayoutAttributeLeading",
                      @"trailing": @"NSLayoutAttributeTrailing",
                      @"width": @"NSLayoutAttributeWidth",
                      @"height": @"NSLayoutAttributeHeight",
                      @"centerX": @"NSLayoutAttributeCenterX",
                      @"centerY": @"NSLayoutAttributeCenterY",
                      };
    });
    return relations[masAttribute];
}

NSString *mas_to_relation(NSString *operator) {
    static NSDictionary *relations;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        relations = @{@"greaterThanOrEqualTo": @"NSLayoutRelationGreaterThanOrEqual",
                      @"equalTo": @"NSLayoutRelationEqual",
                      @"lessThanOrEqualTo": @"NSLayoutRelationLessThanOrEqual",
                      };
    });
    return relations[operator];
}

NSString *each_line(NSString *line, NSString *item1) {
    char *cString = strdup(line.UTF8String);
    char item2[128] = {0};
    char operator[128] = {0};
    char attribute1[128] = {0};
    char attribute2[128] = {0};
    char value[128] = {0};
    char make[128] = {0};
    char offsetValue[128] = {0};
    char *p = cString;
    
    do {
        char ch = *p;
        if (ch == ' ' || ch == '\t' || ch == '\r' || ch == '\n') {
            p++;
        } else {
            break;
        }
    } while (*p);
    
    char *t = p + strlen(p);
    
    do {
        char ch = *t;
        if (ch == ' ' || ch == '\t') {
            t--;
        } else {
            break;
        }
    } while (t != p);
    
    *t = '\0';
    
    if (strstr(p, "//") == p) {
        free(cString);
        return nil;
    }
    
    int r = sscanf(p, "%[^.].%[^.].%[^(]%[^;]", make, attribute1, operator, value);
    if (r != 4) {
        return nil;
    }
    
    free(cString);
    
    if (strcmp(make, "make") != 0) {
        return nil;
    }
    
    NSMutableString *outText = [NSMutableString string];
    char orginOperator[256];
    strcpy(orginOperator, operator);
    if (strstr(operator, "mas_") == operator) {
        size_t len = strlen(operator) - 4;
        memcpy(operator, operator + 4, len);
        operator[len] = 0;
    }
    if (strchr(operator, '.') != NULL) {
        NSString *embed = each_line([line stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%s.", attribute1] withString:@""], item1);
        if (embed) {
            [outText appendString:embed];
            [outText appendString:@"\r\n"];
            char *dot = strrchr(operator, '.');
            if (dot) {
                size_t len = operator + strlen(operator) - dot - 1;
                memcpy(operator, dot + 1, len);
                operator[len] = 0;
            }
        }
    }
    
    char *offsetInValue = strstr(value, ".offset");
    if (offsetInValue != NULL) {
        *offsetInValue = '\0';
        sscanf(offsetInValue + strlen(".offset"), "(%[^)]", offsetValue);
    }
    
    value[strlen(value) - 1] = 0;
    char *realValue = value + 1;
    
    char *dotInValue = strstr(realValue, ".mas_");
    if (dotInValue != NULL) {
        strncpy(item2, realValue, dotInValue - realValue);
        strcpy(attribute2, dotInValue + strlen(".mas_"));
    } else {
        strcpy(attribute2, attribute1);
        item2[0] = 0;
        if (realValue[1] == '(' && realValue[strlen(realValue) - 1] == ')') {
            strncpy(offsetValue, realValue + 2, strlen(realValue) - 3);
        } else if (realValue[0] == '@') {
            strcpy(offsetValue, realValue + 1);
        } else {
            double v;
            if (sscanf(realValue, "%lf", &v) == 1) {
                if ((int)v == v) {
                    sprintf(offsetValue, "%d", (int)v);
                } else {
                    sprintf(offsetValue, "%.1lf", v);
                }
            }
            if (strstr(orginOperator, "mas_") == orginOperator) {
                strcpy(item2, item1?[item1 stringByAppendingString:@".superView"].UTF8String:"self");
            } else {
                strcpy(item2, realValue);
            }
        }
    }
    
    if (offsetValue[0] == 0) {
        offsetValue[0] = '0';
        offsetValue[1] = '\0';
    }
    
    NSString *template = @"[NSLayoutConstraint constraintWithItem:%@ attribute:%@ relatedBy:%@ toItem:%@ attribute:%@ multiplier:1 constant:%@],";
    
    if (strcmp(attribute1, "size") == 0) {
        NSString *w = [NSString stringWithFormat:@"(%s).width", realValue];
        NSString *h = [NSString stringWithFormat:@"(%s).height", realValue];
        NSString *width = [NSString stringWithFormat:template, item1, mas_to_constraint(@"width"), mas_to_relation(@(operator)), @"NULL", mas_to_constraint(@"width"), w];
        NSString *height = [NSString stringWithFormat:template, item1, mas_to_constraint(@"height"), mas_to_relation(@(operator)), @"NULL", mas_to_constraint(@"height"), h];
        [outText appendString:[@[width, height] componentsJoinedByString:@"\r\n"]];
    } else if (strcmp(attribute1, "edges") == 0) {
        NSString *leading = [NSString stringWithFormat:template, item1, mas_to_constraint(@"leading"), mas_to_relation(@(operator)), strlen(item2)==0?@"NULL":@(item2), mas_to_constraint(@"leading"), @"0"];
        NSString *trailing = [NSString stringWithFormat:template, item1, mas_to_constraint(@"trailing"), mas_to_relation(@(operator)), strlen(item2)==0?@"NULL":@(item2), mas_to_constraint(@"trailing"), @"0"];
        NSString *top = [NSString stringWithFormat:template, item1, mas_to_constraint(@"top"), mas_to_relation(@(operator)), strlen(item2)==0?@"NULL":@(item2), mas_to_constraint(@"top"), @"0"];
        NSString *bottom = [NSString stringWithFormat:template, item1, mas_to_constraint(@"bottom"), mas_to_relation(@(operator)), strlen(item2)==0?@"NULL":@(item2), mas_to_constraint(@"bottom"), @"0"];
        [outText appendString:[@[leading, trailing, top, bottom] componentsJoinedByString:@"\r\n"]];
    } else if (strcmp(attribute1, "center") == 0) {
        NSString *x = [NSString stringWithFormat:template, item1, mas_to_constraint(@"centerX"), mas_to_relation(@(operator)), @(item2), mas_to_constraint(@"centerX"), @"0"];
        NSString *y = [NSString stringWithFormat:template, item1, mas_to_constraint(@"centerY"), mas_to_relation(@(operator)), @(item2), mas_to_constraint(@"centerY"), @"0"];
        [outText appendString:[@[x, y] componentsJoinedByString:@"\r\n"]];
    } else {
        id obj2;
        if (strcmp(attribute1, "width") == 0 ||strcmp(attribute1, "height") == 0) {
            obj2 = @"NULL";
        } else {
            obj2 = strlen(item2)==0?@"NULL":@(item2);
        }
        [outText appendString:[NSString stringWithFormat:template, item1, mas_to_constraint(@(attribute1)), mas_to_relation(@(operator)), obj2, mas_to_constraint(@(attribute2)), @(offsetValue)]];
    }
    
    return outText;
}

void each_file(NSURL *fileURL) {
    NSString *text = [NSString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:nil];
    NSMutableString *outText = [text mutableCopy];
    // \[[a-zA-Z0-9_.]+ +mas_makeConstraints:[^{]*\{[^\}]+\}(\];)
    NSRegularExpression *e = [NSRegularExpression regularExpressionWithPattern:@"\\[[a-zA-Z0-9_.]+ +mas_makeConstraints:[^{]*\\{[^\\}]+\\}(\\];)" options:0 error:nil];
    NSArray<NSTextCheckingResult *> *results = [e matchesInString:text options:0 range:NSMakeRange(0, text.length)];
    if (results.count == 0) {
        //NSLog(@"no Masonry inside");
        return;
    }
    
    for (NSTextCheckingResult *result in results.reverseObjectEnumerator) {
        NSRange messageRange = result.range;
        NSRange bodyBegin = [text rangeOfString:@"{" options:0 range:messageRange];
        if (bodyBegin.location == NSNotFound) continue;
        
        NSUInteger location = [text rangeOfString:@" " options:0 range:messageRange].location;
        assert(location != NSNotFound && location - (messageRange.location + 1) < text.length);
        NSString *item1 = [text substringWithRange:NSMakeRange(messageRange.location + 1, location - (messageRange.location + 1))];
        NSMutableArray<NSString *> *lines = [NSMutableArray array];
        __block bool skip = 0;
        [text enumerateSubstringsInRange:NSMakeRange(bodyBegin.location + 1, NSMaxRange(messageRange) - (bodyBegin.location + 1)) options:NSStringEnumerationByLines usingBlock:^(NSString * _Nullable substring, NSRange substringRange, NSRange enclosingRange, BOOL * _Nonnull stop) {
            if (substringRange.length == 0) {
                return;
            }
            NSString *outLine = each_line(substring, item1);
            if (outLine) {
                [lines addObject:outLine];
            } else {
                if ([substring hasSuffix:@"}];"]) return;
                *stop = 1;
                skip = 1;
            }
        }];
        if (skip) {
            continue;
        }
        NSString *outLines = [NSString stringWithFormat:@"[NSLayoutConstraint activateConstraints:@[%@]];", [lines componentsJoinedByString:@"\r\n"]];
        NSString *translatesAutoresizing = [NSString stringWithFormat:@"%@.translatesAutoresizingMaskIntoConstraints = false;\r\n", item1];
        NSString *outMessage = [translatesAutoresizing stringByAppendingString:outLines];
        [outText replaceCharactersInRange:messageRange withString:outMessage];
    }
    
    if (outText.length != text.length || ![outText isEqualToString:text]) {
        [outText writeToURL:fileURL atomically:1 encoding:NSUTF8StringEncoding error:nil];
        NSLog(@"replace %@", fileURL.path);
    }
}

void deepIntoDirectory(NSURL *directoryURL) {
    NSArray<NSURLResourceKey> *resourceKeys = @[NSURLNameKey, NSURLIsDirectoryKey];
    NSDirectoryEnumerator<NSURL *> * directoryEnumerator =
        [[NSFileManager defaultManager] enumeratorAtURL:directoryURL includingPropertiesForKeys:resourceKeys options:NSDirectoryEnumerationSkipsHiddenFiles errorHandler:nil];
    
    for (NSURL *fileURL in directoryEnumerator) {
        NSError *error;
        NSDictionary<NSString *, id> *resourceValues = [fileURL resourceValuesForKeys:resourceKeys error:&error];
        if ([resourceValues[NSURLIsDirectoryKey] boolValue]) {
            deepIntoDirectory(fileURL);
        } else {
            NSString *fileName = resourceValues[NSURLNameKey];
            NSString *extension = fileName.pathExtension;
            if ([extension isEqualToString:@"m"] || [extension isEqualToString:@"mm"]) {
                each_file(fileURL);
            }
        }
    }
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        if (argc < 2) {
            NSLog(@"need replace path");
            return 0;
        }
        
        deepIntoDirectory([NSURL fileURLWithPath:@(argv[1])]);
    }
    return 0;
}
