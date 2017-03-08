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

@interface MXCaptureVideoViewController ()<AVCaptureFileOutputRecordingDelegate, AVAudioPlayerDelegate>
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
}
@property (weak, nonatomic) IBOutlet UIView *videoview;
@property (weak, nonatomic) IBOutlet UILabel *recordState;
@property (weak, nonatomic) IBOutlet UIButton *forwardButton;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;
@property (weak, nonatomic) IBOutlet UIButton *outputResultVideo;
@property (weak, nonatomic) IBOutlet UIButton *restartRecord;

@end

@implementation MXCaptureVideoViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.videoview.layer.masksToBounds = YES;
    [self authorization];
    
    [self setup];
}
- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)setup {
    looping = 0;
    _forwardButton.enabled = NO;
    _nextButton.enabled = YES;
    _isInLoop = NO;
    _recordState.text = @"视频录制停止中";
    _restartRecord.enabled = NO;
    _outputResultVideo.enabled = NO;
    [self setLoopSongSegment];
    [self playAudio];
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
    NSFileManager *manager = [NSFileManager defaultManager];
    [manager createDirectoryAtPath:outputURL withIntermediateDirectories:YES attributes:nil error:nil];
    outputURL = [outputURL stringByAppendingPathComponent:@"output.mov"];
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
        _exportSession = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetMediumQuality];
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
                            NSLog(@"didFinishRecordingToOutputFileAtURLs");
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

    
    

    
//    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:outputFileURL options:nil];
//    CGFloat totalVideoDuration = [MXCaptureVideoViewController getVideoMediaDuration:asset];
//    CGFloat interval = _audioSegment.endLoop - _audioSegment.startLoop;
//    if (totalVideoDuration > interval) {
//        int times = (int)(totalVideoDuration / interval);
//        NSRange videoRange = NSMakeRange((times - 1) * interval, interval);
//        
//        //开始位置startTime
//        CMTime startTime = CMTimeMakeWithSeconds(videoRange.location, asset.duration.timescale);
//        //截取长度videoDuration
//        CMTime videoDuration = CMTimeMakeWithSeconds(videoRange.length, asset.duration.timescale);
//        CMTimeRange videoTimeRange = CMTimeRangeMake(startTime, videoDuration);
//    }
    
//        //视频采集compositionVideoTrack
//        AVMutableComposition* mixComposition = [AVMutableComposition composition];
//        AVMutableCompositionTrack *compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
//        
//        [compositionVideoTrack insertTimeRange:videoTimeRange ofTrack:([asset tracksWithMediaType:AVMediaTypeVideo].count>0) ? [asset tracksWithMediaType:AVMediaTypeVideo].firstObject : nil atTime:kCMTimeZero error:nil];
//    
//        //AVAssetExportSession用于合并文件，导出合并后文件，presetName文件的输出类型
//        AVAssetExportSession *assetExportSession = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetPassthrough];
//        
//
//        //输出视频格式 AVFileTypeMPEG4 AVFileTypeQuickTimeMovie...
//        assetExportSession.outputFileType = AVFileTypeQuickTimeMovie;
//        //    NSArray *fileTypes = assetExportSession.
//        
//        assetExportSession.outputURL = outputFileURL;
//        //输出文件是否网络优化
//        assetExportSession.shouldOptimizeForNetworkUse = YES;
//        
//        [assetExportSession exportAsynchronouslyWithCompletionHandler:^{
//            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
//                PHAssetChangeRequest *changeAssetRequest = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:outputFileURL];
//                PHAssetCollection *targetCollection = [[PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil] lastObject];
//                PHAssetCollectionChangeRequest *changeCollectRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:targetCollection];
//                PHObjectPlaceholder *assetPlaceHolder = [changeAssetRequest placeholderForCreatedAsset];
//                [changeCollectRequest addAssets:@[assetPlaceHolder]];
//            } completionHandler:^(BOOL success, NSError * _Nullable error) {
//                NSLog(@"--保持成功 ----");
//            
//            }];
//        }];
//
//    }
    
//    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
//        PHAssetChangeRequest *changeAssetRequest = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:outputFileURL];
//        PHAssetCollection *targetCollection = [[PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil] lastObject];
//        PHAssetCollectionChangeRequest *changeCollectRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:targetCollection];
//        PHObjectPlaceholder *assetPlaceHolder = [changeAssetRequest placeholderForCreatedAsset];
//        [changeCollectRequest addAssets:@[assetPlaceHolder]];
//    } completionHandler:^(BOOL success, NSError * _Nullable error) {
//        NSLog(@"--保持成功 ----");
//    
//    }];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

//- (void)writeVideoToPhotoLibrary:(NSURL *)url
//{
//    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
//    
//    [library writeVideoAtPathToSavedPhotosAlbum:url completionBlock:^(NSURL *assetURL, NSError *error){
//        if (error) {
//            NSLog(@"Video could not be saved");
//        }
//    }];
//}


- (void)playAudio {
    
    NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
    NSString *path = [NSString stringWithFormat:@"%@/song_test_20.m4a", resourcePath];
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL URLWithString:path] error:nil];
    [_audioPlayer setDelegate:self];
    [_audioPlayer prepareToPlay];
    [_audioPlayer play];

    _audioSegment = [_audioSegments objectAtIndex:0];
    _audioTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 repeats:YES block:^(NSTimer * _Nonnull timer) {
//        NSLog(@"%f",_audioPlayer.currentTime);
        if(fabs(_audioPlayer.duration - _audioPlayer.currentTime) < 0.1) {
            [timer invalidate];
            self.recordState.text = @"整个播放完毕，请导出视频！";
            self.forwardButton.enabled = NO;
            self.nextButton.enabled = NO;
            self.restartRecord.enabled = YES;
            self.outputResultVideo.enabled = YES;
            return ;
        }
        
        if(fabs(_audioPlayer.currentTime - _audioSegment.startLoop) < 0.1 && !_isInLoop) {
            _isInLoop = YES;
            self.recordState.text = [NSString stringWithFormat:@"第%d个段落 视频录制中",looping+1];
            [self startRecordVideo];
        }

        if (_isInLoop) {
            if(fabs(_audioPlayer.currentTime - _audioSegment.endLoop) < 0.1) {
                _audioPlayer.currentTime = _audioSegment.startLoop;
            }
        }
        
    }];
}

- (IBAction)nextLoop:(id)sender {
    
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

- (IBAction)forwardLoop:(id)sender {
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
- (void)stopRecordVideo:(BOOL)save
{
    _needSave = save;
    // 取消视频拍摄
    [_movieOutput stopRecording];
}

- (IBAction)outputVideo:(id)sender {
    //
}
- (IBAction)restartRecordButton:(id)sender {
    [self setup];
}

+ (CGFloat)getVideoMediaDuration:(AVURLAsset *)asset {
    CMTime duration = [asset duration];
    return duration.value / duration.timescale;
}

@end