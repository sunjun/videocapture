//
//  MXVideoFilterViewController.m
//  VideoCapture
//
//  Created by michaelxing on 2017/4/16.
//  Copyright © 2017年 dong. All rights reserved.
//

#import "MXVideoFilterViewController.h"
#import "GPUImage.h"
#import <Photos/Photos.h>

@interface MXVideoFilterViewController ()

@property (weak, nonatomic) IBOutlet GPUImageView *gpuImageView;

@property (nonatomic, retain) GPUImageView *gpuImageV;

@property (nonatomic, retain) GPUImageMovie *movieFile;
@property (nonatomic, retain) GPUImagePixellateFilter  *filter;
@property (nonatomic, retain) GPUImageMovieWriter *movieWriter;
@property (nonatomic, retain) NSTimer *timer;
@property (weak, nonatomic) IBOutlet UILabel *process;

@end

@implementation MXVideoFilterViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *outPutPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"finish.mov"];
    NSURL *videoPath = [NSURL fileURLWithPath:outPutPath];
    
    self.movieFile = [[GPUImageMovie alloc] initWithURL:videoPath];
    self.movieFile.runBenchmark = YES;
   self.movieFile.playAtActualSpeed = NO;
    
    self.filter = [[GPUImagePixellateFilter alloc] init];
    [self.movieFile addTarget:_filter];
    
    self.gpuImageV = [[GPUImageView alloc] initWithFrame:self.gpuImageView.bounds];
    GPUImageView *filterView = (GPUImageView *)self.gpuImageView;
    
    [self.filter addTarget:filterView];
    
    
    NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/movie.mov"];
    unlink([pathToMovie UTF8String]);
    
    NSURL *movieURL = [NSURL fileURLWithPath:pathToMovie];
    self.movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(640, 480)];
    [self.filter addTarget:_movieWriter];
    self.movieWriter.shouldPassthroughAudio = YES;
    self.movieFile.audioEncodingTarget = _movieWriter;
    [self.movieFile enableSynchronizedEncodingUsingMovieWriter:_movieWriter];
    
    [self.movieWriter startRecording];
    [self.movieFile startProcessing];
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:0.3f target:self selector:@selector(retrievingProcess) userInfo:nil repeats:YES];
    __weak typeof (self) weakSelf = self;
    [self.movieWriter setCompletionBlock:^{
        [weakSelf.filter removeTarget:weakSelf.movieWriter];
        [weakSelf.movieWriter finishRecording];
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.timer invalidate];
           
            __block PHObjectPlaceholder *placeholder;
            
            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                PHAssetChangeRequest* createAssetRequest = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:movieURL];
                placeholder = [createAssetRequest placeholderForCreatedAsset];
                
            } completionHandler:^(BOOL success, NSError *error) {
                if (success)
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        weakSelf.process.text = @"100% 成功输出到相册";
                    });
                }
                else
                {
                    NSLog(@"%@", error);
                }
            }];
        });
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)retrievingProcess
{
    self.process.text = [NSString stringWithFormat:@"%d%%", (int)(_movieFile.progress * 100)];
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
