//
//  MXPlayVideoViewController.m
//  VideoCapture
//
//  Created by michaelxing on 2017/3/21.
//  Copyright © 2017年 dong. All rights reserved.
//

#import "MXPlayVideoViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface MXPlayVideoViewController ()<AVAudioPlayerDelegate>
{
    AVAudioPlayer *_audioPlayer;
    AVPlayer *_videoPlayer;
    NSTimer *_audioTimer ;
}

@property (weak, nonatomic) IBOutlet UIView *videoView;

@end

@implementation MXPlayVideoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self playAudio];
}

- (void) playAudio {
    // 取出资源的URL
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"song_test_20.m4a" withExtension:nil];
    
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    [_audioPlayer setDelegate:self];
    [_audioPlayer prepareToPlay];
    [_audioPlayer play];
    
    
    _audioTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 repeats:YES block:^(NSTimer * _Nonnull timer) {
        
        // only test
        static BOOL inLoop = FALSE;
        if (!inLoop) {
            inLoop = TRUE;
            [self playerVideo];
        }
    }];

}

// only for test 
- (AVPlayer *)playerVideo
{
    if (_videoPlayer == nil) {
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *videoPath = paths[0];
        videoPath = [videoPath stringByAppendingPathComponent:[NSString stringWithFormat:@"mx_%lu.mov",0]];
        
        // 1.获取URL(远程/本地)
        NSURL *videoURL = [NSURL fileURLWithPath:videoPath];

        // 2.创建AVPlayerItem
        AVPlayerItem *item = [AVPlayerItem playerItemWithURL:videoURL];
        
        // 3.创建AVPlayer
        _videoPlayer = [AVPlayer playerWithPlayerItem:item];
        
        // 4.添加AVPlayerLayer
        AVPlayerLayer *layer = [AVPlayerLayer playerLayerWithPlayer:_videoPlayer];
        layer.frame = CGRectMake(0, 0, _videoView.bounds.size.width, _videoView.bounds.size.height);
        [self.view.layer addSublayer:layer];
        layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        
        [_videoPlayer play];
    }
    return _videoPlayer;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
