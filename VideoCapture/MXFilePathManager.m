//
//  MXFilePathManager.m
//  VideoCapture
//
//  Created by michaelxing on 2017/3/1.
//  Copyright © 2017年 dong. All rights reserved.
//

#import "MXFilePathManager.h"

@implementation MXFilePathManager

+ (NSString *)savePathWithFileSuffix:(NSString *)suffix
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath = [paths objectAtIndex:0];
    
    NSDate *date = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyyMMddHHmmss"];
    NSString *currentDateAndTime = [formatter stringFromDate:date];
    
    NSString *fileName = [NSString stringWithFormat:@"%@.%@",currentDateAndTime,suffix];
    NSString *filePath = [documentPath stringByAppendingPathComponent:fileName];
    
    return filePath;
    
}
@end
