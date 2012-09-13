//
//  NSDate_PrettyPrint.h
//  MisfitReader
//
//  Created by hoan.nguyen on 9/12/12.
//
//

#import <Foundation/Foundation.h>

@interface NSDate (PrettyPrint)

- (NSString *)prettyFormatWithTime;
- (NSString *)prettyFormatWithoutTime;

@end

@implementation NSDate (PrettyPrint)

- (NSString *)prettyFormatWithTime
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat: @"hh:mm"];
    return [NSString stringWithFormat:@"%@ %@", [self prettyFormatWithoutTime], [formatter stringFromDate:self]];
}

- (NSString *)prettyFormatWithoutTime
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat: @"EEEE, MMMM dd, yyyy"];
    NSString *result = [formatter stringFromDate:self];
    if ([[formatter stringFromDate:[NSDate date]] isEqualToString:result])
    {
        return @"Today";
    }
    else if ([[formatter stringFromDate:[[NSDate date] dateByAddingTimeInterval:-86400.0]] isEqualToString:result])
    {
        return @"Yesterday";
    } else
    {
        return result;
    }
}

@end