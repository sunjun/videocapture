//
//  MXSongSegment.h
//  VideoCapture
//
//  Created by michaelxing on 2017/3/5.
//  Copyright © 2017年 dong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface MXAudioSegment : NSObject

@property (nonatomic, assign) CGFloat       segmentStart;
@property (nonatomic, assign) CGFloat       startLoop;
@property (nonatomic, assign) CGFloat       endLoop;

@end
