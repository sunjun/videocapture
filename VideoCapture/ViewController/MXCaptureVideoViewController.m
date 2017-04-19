//
//  MXCaptureVideoViewController.m
//  VideoCapture
//
//  Created by michaelxing on 2017/3/5.
//  Copyright © 2017年 dong. All rights reserved.
//

#import "MXCaptureVideoViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "MXAudioSegment.h"
#import <Photos/Photos.h>
#import "MXFilePathManager.h"
#import "MXPlayVideoViewController.h"
#import "MXVideoFilterViewController.h"

#import "OCSocketClient.h"
#import "OCSocketServer.h"

static int current = 0;

@interface MXCaptureVideoViewController ()<AVCaptureFileOutputRecordingDelegate>
{
    AVCaptureSession *_captureSession;
    AVCaptureDevice *_videoDevice;
    AVCaptureDeviceInput *_videoInput;
    AVCaptureMovieFileOutput *_movieOutput;
    AVCaptureVideoPreviewLayer *_captureVideoPreviewLayer;
    
    NSMutableArray  *_audioSegments;
    
    AVAudioPlayer *_audioPlayer;
    NSTimer *_audioTimer;
    NSInteger looping;
    MXAudioSegment *_audioSegment;
    BOOL _isInLoop;
    NSUInteger MAX_SEGMENT;
    AVAssetExportSession *_exportSession;
    BOOL _needSave;
    
    OCSocketClient *_client;
    OCSocketServer *_server;
}



@property (weak, nonatomic) IBOutlet UIView *videoview;
@property (weak, nonatomic) IBOutlet UILabel *recordState;
@property (weak, nonatomic) IBOutlet UIButton *forwardButton;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;
@property (weak, nonatomic) IBOutlet UIButton *outputResultVideo;
@property (weak, nonatomic) IBOutlet UIButton *restartRecord;
@property (weak, nonatomic) IBOutlet UIButton *replayVideoButton;

@end

@implementation MXCaptureVideoViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
  
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.videoview.layer.masksToBounds = YES;
    [self authorization];
    
    [self setup];
    
    //开启socket服务端等待连接
    _isControlPeer = NO;
    _server = [[OCSocketServer alloc] init];
    [_server startServerWithController:self];
//    _client = [[OCSocketClient alloc] init];
//    [_client connect2Server:@"192.168.1.100" port:12345 withController:self];
}

- (void)setup {
    looping = 0;
    current = 0;
    _forwardButton.enabled = NO;
    _nextButton.enabled = YES;
    _isInLoop = NO;
    _recordState.text = @"视频录制停止中";
    _restartRecord.enabled = NO;
    _outputResultVideo.enabled = NO;
    _replayVideoButton.enabled = NO;
//    [self transformCfgFile];
    [self setLoopSongSegment];
//    [self playAudio];
}

- (void)transformCfgFile {
    NSString* path  = [[NSBundle mainBundle] pathForResource:@"[Schumann_Oboe_Romances]Official" ofType:@"cfg"];
    
    //将文件内容读取到字符串中，注意编码NSUTF8StringEncoding 防止乱码，
    NSString* jsonString = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    
    //将字符串写到缓冲区。
    NSData* jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    
    NSError *jsonError;
    NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&jsonError];
    
    NSMutableArray *array=[jsonObject objectForKey:@"red_points"];
    int j = 1;
    for (int i = 0; i < [array count]; i++) {

        NSDictionary *dict = [array objectAtIndex:i];
        NSString *loop_to = [dict objectForKey:@"loop_to"];
        if (loop_to != nil) {
            long start = [[dict objectForKey:@"timestamp"] longValue];
            long end = 0;
            for (int i = 0; i < [array count]; i++) {
                NSDictionary *dict = [array objectAtIndex:i];
                if ([[dict objectForKey:@"uuid"] isEqualToString:loop_to]) {
                    end = [[dict objectForKey:@"timestamp"] longValue];
                }
            }
            NSLog(@"%d %ld %ld", j, start/1000, end/1000);
            j++;
        }
    }
    
}

//读配置文件
- (void) setLoopSongSegment {
    _audioSegments = [[NSMutableArray alloc] initWithCapacity:0];
    
    NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
    
    NSString *path = [NSString stringWithFormat:@"%@/audio.cfg", resourcePath];
    NSError *error;
    
    NSString *config = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    NSArray *lines = [config componentsSeparatedByString:@"\n"];
    
    NSInteger first = YES;
    
    for (NSString *line in lines)
    {
        NSArray *singleLine = [line componentsSeparatedByString:@" "];
        if ([singleLine count] == 3) {
            NSString *startTime = singleLine[1];
            NSString *endTime = singleLine[2];
            
            MXAudioSegment *segment = [[MXAudioSegment alloc] init];
            if (first) {
                first = NO;
                segment.segmentStart = 0.0;
            }
            else {
                MXAudioSegment * temp = _audioSegments.lastObject;
                segment.segmentStart = temp.endLoop;
            }
    
            segment.startLoop = [startTime floatValue];
            segment.endLoop = [endTime floatValue];
            
            [_audioSegments addObject:segment];
        }
    }
    
    MAX_SEGMENT = [_audioSegments count];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)authorization {
    
    switch ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo]) {
        case AVAuthorizationStatusAuthorized:
        {
            [UIAlertController alertControllerWithTitle:@"" message:@"授权成功" preferredStyle:UIAlertControllerStyleAlert];
           
            [self setupAVCaptureInfo];
            break;
        }
        case AVAuthorizationStatusNotDetermined:
        {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (granted) {
                    [self setupAVCaptureInfo];
                    return ;
                }
                else {
                     UIAlertController *controller =  [UIAlertController alertControllerWithTitle:@"" message:@"授权失败" preferredStyle:UIAlertControllerStyleAlert];
                    [self presentViewController:controller animated:NO completion:^{
                        
                    }];
                }
            }];
            break;
        }
        default:
        {
            UIAlertController *controller =  [UIAlertController alertControllerWithTitle:@"" message:@"授权失败" preferredStyle:UIAlertControllerStyleAlert];
            [self presentViewController:controller animated:NO completion:^{
                
            }];

            break;
        }
    }
}

- (void)setupAVCaptureInfo {
    _captureSession = [[AVCaptureSession alloc] init];
    //设置视频分辨率
    /*  通常支持如下格式
     (
     AVAssetExportPresetLowQuality,
     AVAssetExportPreset960x540,
     AVAssetExportPreset640x480,
     AVAssetExportPresetMediumQuality,
     AVAssetExportPreset1920x1080,
     AVAssetExportPreset1280x720,
     AVAssetExportPresetHighestQuality,
     AVAssetExportPresetAppleM4A
     )
     */
    //注意,这个地方设置的模式/分辨率大小将影响你后面拍摄照片/视频的大小,
    if ([_captureSession canSetSessionPreset:AVAssetExportPresetMediumQuality]) {
        [_captureSession setSessionPreset:AVAssetExportPresetMediumQuality];
    }

    [_captureSession beginConfiguration];
    
    [self addVideo];
    [self addPreviewLayer];
    
    [_captureSession commitConfiguration];
    //开启会话-->注意,不等于开始录制
    
    [_captureSession startRunning];
    
}


- (void)addVideo {
    // 获取摄像头输入设备， 创建 AVCaptureDeviceInput 对象
    /* MediaType
     AVF_EXPORT NSString *const AVMediaTypeVideo                 NS_AVAILABLE(10_7, 4_0);       //视频
     AVF_EXPORT NSString *const AVMediaTypeAudio                 NS_AVAILABLE(10_7, 4_0);       //音频
     AVF_EXPORT NSString *const AVMediaTypeText                  NS_AVAILABLE(10_7, 4_0);
     AVF_EXPORT NSString *const AVMediaTypeClosedCaption         NS_AVAILABLE(10_7, 4_0);
     AVF_EXPORT NSString *const AVMediaTypeSubtitle              NS_AVAILABLE(10_7, 4_0);
     AVF_EXPORT NSString *const AVMediaTypeTimecode              NS_AVAILABLE(10_7, 4_0);
     AVF_EXPORT NSString *const AVMediaTypeMetadata              NS_AVAILABLE(10_8, 6_0);
     AVF_EXPORT NSString *const AVMediaTypeMuxed                 NS_AVAILABLE(10_7, 4_0);
     */
    
    /* AVCaptureDevicePosition
     typedef NS_ENUM(NSInteger, AVCaptureDevicePosition) {
     AVCaptureDevicePositionUnspecified         = 0,
     AVCaptureDevicePositionBack                = 1,            //后置摄像头
     AVCaptureDevicePositionFront               = 2             //前置摄像头
     } NS_AVAILABLE(10_7, 4_0) __TVOS_PROHIBITED;
     */
    _videoDevice = [self deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionBack];
    
    [self addVideoInput];
    [self addMovieOutput];
}

- (void)addVideoInput {
    NSError *videoError;
    _videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:_videoDevice error:&videoError];
    if (videoError) {
        NSLog(@"---- 取得摄像头设备时出错 ------ %@",videoError);
        return;
    }
    if([_captureSession canAddInput:_videoInput]){
        [_captureSession addInput:_videoInput];
    }
}


- (void)addMovieOutput {
    _movieOutput = [[AVCaptureMovieFileOutput alloc] init];
    if ([_captureSession canAddOutput:_movieOutput]) {
        [_captureSession addOutput:_movieOutput];
        AVCaptureConnection *captureConnection = [_movieOutput connectionWithMediaType:AVMediaTypeVideo];
        
        // 防止视频抖动
        if ([captureConnection isVideoStabilizationSupported]) {
            captureConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
        }
        //焦点
//        captureConnection.videoScaleAndCropFactor = captureConnection.videoMaxScaleAndCropFactor;
    }
}
#pragma mark 获取摄像头-->前/后

- (AVCaptureDevice *)deviceWithMediaType:(NSString *)mediaType preferringPosition:(AVCaptureDevicePosition)position
{
    
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
    AVCaptureDevice *captureDevice = devices.firstObject;
    
    for ( AVCaptureDevice *device in devices ) {
        if ( device.position == position ) {
            captureDevice = device;
            break;
        }
    }
    
    return captureDevice;
    
    return [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInDualCamera mediaType:mediaType position:position];
}

- (void)addPreviewLayer {
    
    self.videoview.backgroundColor = [UIColor blueColor];
    _captureVideoPreviewLayer = [AVCaptureVideoPreviewLayer layerWithSession:_captureSession];
    _captureVideoPreviewLayer.backgroundColor = [UIColor redColor].CGColor;
    _captureVideoPreviewLayer.frame = self.view.bounds;
    _captureVideoPreviewLayer.connection.videoOrientation = [_movieOutput connectionWithMediaType:AVMediaTypeVideo].videoOrientation;
     _captureVideoPreviewLayer.position = CGPointMake(self.view.bounds.size.width*0.5,self.videoview.bounds.size.height*0.5);
    CALayer *layer = self.videoview.layer;
    layer.masksToBounds = true;
    [layer addSublayer:_captureVideoPreviewLayer];
    
}

- (void)startRecordVideo {
    [_movieOutput startRecordingToOutputFileURL:[self outputFileURL] recordingDelegate:self];
}
- (IBAction)startRecord:(id)sender {
//    [_movieOutput startRecordingToOutputFileURL:[self outputFileURL] recordingDelegate:self];
}

- (NSURL *)outputFileURL
{
    return [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), [NSString stringWithFormat:@"%lu.mov",(unsigned long)looping]]];
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections
{
    NSLog(@"---- 开始录制 ----");
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    NSLog(@"---- 录制结束 ---%@",outputFileURL);
    
    if (outputFileURL.absoluteString.length == 0 && captureOutput.outputFileURL.absoluteString.length == 0 ) {
        return;
    }

    if (_needSave == NO) {
        return;
    }
    
    // Step 1
    // Create an outputURL to which the exported movie will be saved
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *outputURL = paths[0];
    NSString *videoPath = [NSString stringWithFormat:@"mx_%d.mov",current++];
    outputURL = [outputURL stringByAppendingPathComponent:videoPath];
    NSFileManager *manager = [NSFileManager defaultManager];
    [manager createDirectoryAtPath:outputURL withIntermediateDirectories:YES attributes:nil error:nil];
    // Remove Existing File
    [manager removeItemAtPath:outputURL error:nil];

    
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:outputFileURL options:nil];
    CGFloat totalVideoDuration = [MXCaptureVideoViewController getVideoMediaDuration:asset];

    MXAudioSegment *tempAudioSegment = [_audioSegments objectAtIndex:looping - 1];

    CGFloat interval = tempAudioSegment.endLoop - tempAudioSegment.startLoop;
    
    if (totalVideoDuration > interval) {
        int times = (int)(totalVideoDuration / interval);
        NSRange videoRange = NSMakeRange((times - 1) * interval, interval);

        //开始位置startTime
        CMTime startTime = CMTimeMakeWithSeconds(videoRange.location, asset.duration.timescale);
        //截取长度videoDuration
        CMTime videoDuration = CMTimeMakeWithSeconds(videoRange.length, asset.duration.timescale);
        
        CMTimeRange videoTimeRange = CMTimeRangeMake(startTime, videoDuration);
        
        AVMutableComposition* mixComposition = [AVMutableComposition composition];
        AVMutableCompositionTrack *compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        
        [compositionVideoTrack insertTimeRange:videoTimeRange
                                       ofTrack:([asset tracksWithMediaType:AVMediaTypeVideo].count>0) ? [asset tracksWithMediaType:AVMediaTypeVideo].firstObject : nil atTime:kCMTimeZero
                                         error:nil];
        
        // Step 2
        // Create an export session with the composition and write the exported movie to the photo library
        _exportSession = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetHighestQuality];
//        _exportSession.videoComposition = self.mutableVideoComposition;s
        //    _exportSession.audioMix = self.mutableAudioMix;
        _exportSession.outputURL = [NSURL fileURLWithPath:outputURL];
        _exportSession.outputFileType=AVFileTypeQuickTimeMovie;
        _exportSession.timeRange = videoTimeRange;
        
        [_exportSession exportAsynchronouslyWithCompletionHandler:^(void){
            switch (_exportSession.status) {
                case AVAssetExportSessionStatusCompleted:
                {
                    __block PHObjectPlaceholder *placeholder;
                    
                    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                        PHAssetChangeRequest* createAssetRequest = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:_exportSession.outputURL];
                        placeholder = [createAssetRequest placeholderForCreatedAsset];
                        
                    } completionHandler:^(BOOL success, NSError *error) {
                        if (success)
                        {
                            NSLog(@"%@",_exportSession.outputURL.absoluteString);
                        }
                        else
                        {
                            NSLog(@"%@", error);
                        }
                    }];
                }
                    break;
                case AVAssetExportSessionStatusFailed:
                    NSLog(@"Failed:%@",_exportSession.error);
                    break;
                case AVAssetExportSessionStatusCancelled:
                    NSLog(@"Canceled:%@",_exportSession.error);
                    break;
                default:
                    break;
            }
        }];
    }

    
    
}

- (void)playAudio {
    
    NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
    NSString *path = [NSString stringWithFormat:@"%@/song_test_20.m4a", resourcePath];
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL URLWithString:path] error:nil];
    [_audioPlayer prepareToPlay];
    [_audioPlayer play];

    _audioSegment = [_audioSegments objectAtIndex:0];
    __weak typeof (self)weakSelf = self;
    _audioTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 repeats:YES block:^(NSTimer * _Nonnull timer) {
        __strong typeof (self) strongSelf = weakSelf;
        if(fabs(_audioPlayer.duration - _audioPlayer.currentTime) < 0.8) {
            [timer invalidate];
            _recordState.text = @"整个播放完毕，请导出视频！";
            _forwardButton.enabled = NO;
            _nextButton.enabled = NO;
            _restartRecord.enabled = YES;
            _outputResultVideo.enabled = YES;
            _replayVideoButton.enabled = YES;
            return ;
        }
        
        if(fabs(_audioPlayer.currentTime - _audioSegment.startLoop) < 0.1 && !_isInLoop) {
            _isInLoop = YES;
            _recordState.text = [NSString stringWithFormat:@"第%lu个段落 视频录制中",looping+1];
            [strongSelf startRecordVideo];
        }

        if (_isInLoop) {
            if(fabs(_audioPlayer.currentTime - _audioSegment.endLoop) < 0.1) {
                _audioPlayer.currentTime = _audioSegment.startLoop;
            }
        }
        
    }];
}

- (IBAction)nextLoop:(id)sender {
    
    if (_isControlPeer == YES) {
        //控制端 发送下一段指令
        NSString* cmdString = [@(NEXT) stringValue];

        [_client sendCmd:cmdString];
    } else {
        NSLog(@"ibaction nextLoop called\n");
        _isInLoop = NO;
        _recordState.text = @"已停止录制";
        [self stopRecordVideo:YES];
        
        looping++;
        _audioPlayer.currentTime = _audioSegment.endLoop;
        
        if (looping >= MAX_SEGMENT) {
            _nextButton.enabled = NO;
        }
        if (looping > 0) {
            _forwardButton.enabled = YES;
        }
        
        if (looping >= MAX_SEGMENT) {
            _audioSegment = nil;
        } else {
            _audioSegment = [_audioSegments objectAtIndex:looping];
        }
    }
}

- (IBAction)forwardLoop:(id)sender {
    if (_isControlPeer == YES) {
        //控制端 发送上一段指令
        NSString* cmdString = [@(PREVIOUS) stringValue];
        [_client sendCmd:cmdString];

    } else {
        _isInLoop = NO;
        _recordState.text = @"已停止录制";
        [self stopRecordVideo:NO];
        
        looping--;
        
        if (looping < MAX_SEGMENT) {
            _nextButton.enabled = YES;
        }
        if (looping == 0) {
            _forwardButton.enabled = NO;
        }
        
        if (looping >= 0) {
            _audioSegment = [_audioSegments objectAtIndex:looping];
            _audioPlayer.currentTime = _audioSegment.segmentStart;
        }
    }
}

- (void)stopRecordVideo:(BOOL)save
{
    if (_isControlPeer == YES) {
        //控制端 发送结束指令
        NSString* cmdString = [@(STOP) stringValue];
        [_client sendCmd:cmdString];

    } else {
        _needSave = save;
        // 取消视频拍摄
        [_movieOutput stopRecording];
    }
}

- (IBAction)outputVideo:(id)sender {
    if (_isControlPeer == YES) {
        //控制端 发送导出指令
        NSString* cmdString = [@(EXPORT_VIDEO) stringValue];
        [_client sendCmd:cmdString];
        
    } else {
        
        //混合音频和视频
        AVMutableComposition *composition = [AVMutableComposition composition];
        
        
        //音频
        NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
        NSString *path = [NSString stringWithFormat:@"%@/song_test_20.m4a", resourcePath];
        
        AVAsset *audioAsset = [AVAsset assetWithURL:[NSURL fileURLWithPath:path]];
        AVMutableCompositionTrack *audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        
        
        for (NSInteger i = [_audioSegments count] - 1; i >= 0; i--)
        {
            MXAudioSegment *segment = [_audioSegments objectAtIndex:i];
            NSRange audioSnap = NSMakeRange(segment.startLoop, segment.endLoop - segment.startLoop);
            //开始位置startTime
            CMTime startTime = CMTimeMakeWithSeconds(audioSnap.location, audioAsset.duration.timescale);
            //截取长度
            CMTime audioDuration = CMTimeMakeWithSeconds(audioSnap.length, audioAsset.duration.timescale);
            CMTimeRange audioSnapRange = CMTimeRangeMake(startTime, audioDuration);
            [audioTrack insertTimeRange:audioSnapRange ofTrack:[audioAsset tracksWithMediaType:AVMediaTypeAudio][0] atTime:kCMTimeZero error:nil];
        }
        
        //视频
        AVMutableCompositionTrack *videoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        for (NSInteger i = [_audioSegments count] - 1; i >= 0; i--)
        {
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *videoPath = paths[0];
            videoPath = [videoPath stringByAppendingPathComponent:[NSString stringWithFormat:@"mx_%lu.mov",i]];
            
            NSURL *videoURL = [NSURL fileURLWithPath:videoPath];
            NSDictionary *optDict = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
            AVURLAsset *videoAsset = [[AVURLAsset alloc] initWithURL:videoURL options:optDict];
            
            NSLog(@"%@",[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), [NSString stringWithFormat:@"%lu.mov",i]]);
            CMTimeRange videoSnapRange = CMTimeRangeMake(kCMTimeZero, videoAsset.duration);
            [videoTrack insertTimeRange:videoSnapRange ofTrack:[videoAsset tracksWithMediaType:AVMediaTypeVideo][0] atTime:kCMTimeZero error:nil];
        }
        
        CGAffineTransform rotationTransform = CGAffineTransformMakeRotation(M_PI_2);
        //    CGAffineTransform rotateTranslate = CGAffineTransformTranslate(rotationTransform,360,0);
        videoTrack.preferredTransform = rotationTransform;
        
        //导出
        //AVAssetExportSession用于合并文件，导出合并后文件，presetName文件的输出类型
        AVAssetExportSession *assetExportSession = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetHighestQuality];
        
        NSString *outPutPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"finish.mov"];
        //混合后的视频输出路径
        NSURL *compositionURLPath = [NSURL fileURLWithPath:outPutPath];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:outPutPath])
        {
            [[NSFileManager defaultManager] removeItemAtPath:outPutPath error:nil];
        }
        
        //输出视频格式 AVFileTypeMPEG4 AVFileTypeQuickTimeMovie...
        assetExportSession.outputFileType = AVFileTypeQuickTimeMovie;
        assetExportSession.outputURL = compositionURLPath;
        
        
        
        [assetExportSession exportAsynchronouslyWithCompletionHandler:^(void){
            switch (assetExportSession.status) {
                case AVAssetExportSessionStatusCompleted:
                {
                    __block PHObjectPlaceholder *placeholder;
                    
                    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                        PHAssetChangeRequest* createAssetRequest = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:assetExportSession.outputURL];
                        placeholder = [createAssetRequest placeholderForCreatedAsset];
                        
                    } completionHandler:^(BOOL success, NSError *error) {
                        if (success)
                        {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                _recordState.text = @"导出成功，请去相册查看";
                                _nextButton.enabled = YES;
                                _forwardButton.enabled = NO;
                            });
                        }
                        else
                        {
                            NSLog(@"%@", error);
                        }
                    }];
                }
                    break;
                case AVAssetExportSessionStatusFailed:
                    NSLog(@"Failed:%@",assetExportSession.error);
                    break;
                case AVAssetExportSessionStatusCancelled:
                    NSLog(@"Canceled:%@",assetExportSession.error);
                    break;
                default:
                    break;
            }
        }];
    }
}
- (IBAction)videoFilter:(id)sender {
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    MXVideoFilterViewController *viewController = [storyBoard instantiateViewControllerWithIdentifier:@"videofilter"];
    [self.navigationController pushViewController:viewController   animated:NO];
}

- (IBAction)restartRecordButton:(id)sender {
    [self setup];
}

+ (CGFloat)getVideoMediaDuration:(AVURLAsset *)asset {
    CMTime duration = [asset duration];
    return duration.value / duration.timescale;
}
- (IBAction)playAudioEvent:(id)sender {
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    MXPlayVideoViewController *viewController = [storyBoard instantiateViewControllerWithIdentifier:@"playviewcontroller"];
    [viewController setUpData:_audioSegments];
    [self.navigationController pushViewController:viewController   animated:NO];
}

@end
