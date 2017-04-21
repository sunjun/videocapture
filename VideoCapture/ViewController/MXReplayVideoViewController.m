//
//  MXReplayVideoViewController.m
//  VideoCapture
//
//  Created by michaelxing on 2017/4/21.
//  Copyright © 2017年 dong. All rights reserved.
//

#import "MXReplayVideoViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface MXReplayVideoViewController ()
{
    AVPlayer *_videoPlayer;
}

@property (nonatomic, retain) AVPlayerLayer *playerLayer;
@property (weak, nonatomic) IBOutlet UIView *videoView;

@end

@implementation MXReplayVideoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    NSString *outPutPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"finish.mov"];
    NSURL *videoPath = [NSURL fileURLWithPath:outPutPath];
    
    _videoPlayer = [AVPlayer playerWithURL:videoPath];
    _playerLayer = [AVPlayerLayer playerLayerWithPlayer:_videoPlayer];
    _playerLayer.frame = _videoView.bounds;
    [self.view.layer addSublayer:_playerLayer];
    _playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    [self playVideo];
}

- (void) playVideo {
    [_videoPlayer play];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
