//
//  MXPlayVideoViewController.m
//  VideoCapture
//
//  Created by michaelxing on 2017/3/21.
//  Copyright © 2017年 dong. All rights reserved.
//

#import "MXPlayVideoViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "MXAudioSegment.h"

@interface MXPlayVideoViewController ()<AVAudioPlayerDelegate>
{
    AVAudioPlayer *_audioPlayer;
    AVPlayer *_videoPlayer;
    NSTimer *_audioTimer ;
    NSArray *_segments;
    MXAudioSegment *_currentSegments;
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
    _videoPlayer = [[AVPlayer alloc] initWithPlayerItem:nil];
    AVPlayerLayer *layer = [AVPlayerLayer playerLayerWithPlayer:_videoPlayer];
    layer.frame = CGRectMake(0, 0, _videoView.bounds.size.width, _videoView.bounds.size.height);
    [self.view.layer addSublayer:layer];
    layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    [self playAudio];
}

- (void)setUpData:(NSArray *)segments
{
    if (segments && [segments count] > 0) {
        _segments = [NSArray arrayWithArray:segments];
        _currentSegments = [_segments objectAtIndex:0];
    }
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
        
        static BOOL inLoop = false;
        static NSUInteger index = 0;
        if ((_audioPlayer.currentTime > _currentSegments.startLoop) && !inLoop) {
            inLoop = true;
            [self playVideo:index];
        }
        else if(_audioPlayer.currentTime > _audioPlayer.duration) {
            inLoop = false;
            [_audioTimer invalidate];
        }
        else if(_audioPlayer.currentTime > _currentSegments.endLoop) {
            [self stopPlayVideo];
            index++;
            if (index < [_segments count]) {
                inLoop = false;
                _currentSegments = [_segments objectAtIndex:index];
            }
        }
    }];

}

// only for test
- (void)playVideo:(NSUInteger)index
{
    NSLog(@"michaeleixng=====");
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *videoPath = paths[0];
    videoPath = [videoPath stringByAppendingPathComponent:[NSString stringWithFormat:@"mx_%lu.mov",index]];
     NSLog(@"michaeleixng=====%@\n",videoPath);
    NSURL *videoURL = [NSURL fileURLWithPath:videoPath];
    AVPlayerItem *item = [AVPlayerItem playerItemWithURL:videoURL];
    
    [_videoPlayer replaceCurrentItemWithPlayerItem:item];
    [_videoPlayer play];
}

- (void)stopPlayVideo {
    [_videoPlayer pause];
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
