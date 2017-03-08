//
//  MXCaptureOverlayView.m
//  VideoCapture
//
//  Created by michaelxing on 2017/3/4.
//  Copyright © 2017年 dong. All rights reserved.
//

#import "MXCaptureOverlayView.h"

@interface MXCaptureOverlayView()
{
    UIButton    *_cancelCapture;
    UIButton    *_startCapture;
    UIButton    *_retakeCapture;
}

@end

@implementation MXCaptureOverlayView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        _cancelCapture = [UIButton buttonWithType:UIButtonTypeCustom];
        [_cancelCapture setBackgroundImage:[UIImage imageNamed:@""] forState:UIControlStateNormal];
        
        
    }
    
    return self;
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
