//
//  ViewController.m
//  VideoCapture
//
//  Created by michaelxing on 2017/2/28.
//  Copyright © 2017年 dong. All rights reserved.
//

#import "ViewController.h"
#import <MobileCoreServices/MobileCoreServices.h> 
#import <AssetsLibrary/AssetsLibrary.h>
#import "MXFilePathManager.h"
#import <Photos/Photos.h>

@interface ViewController ()<
UINavigationControllerDelegate,
UIImagePickerControllerDelegate,
AVAudioPlayerDelegate>

@property (nonatomic, retain)   AVAudioPlayer *audioPlayer;
@property (nonatomic, retain)   UIImagePickerController *pickerController;
@property (nonatomic, retain)   NSTimer *timer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)captureVideo:(id)sender {
    
    _pickerController = [[UIImagePickerController alloc] init];
    _pickerController.delegate = self;
    _pickerController.allowsEditing = NO;
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        _pickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
        _pickerController.mediaTypes =  [[NSArray alloc] initWithObjects: (NSString *) kUTTypeMovie, nil];
        _pickerController.cameraCaptureMode = UIImagePickerControllerCameraCaptureModeVideo;
        _pickerController.videoQuality = UIImagePickerControllerQualityTypeMedium;
    }
    
    [self presentViewController:_pickerController animated:NO completion:nil];
    
    int64_t delayInSeconds = 1;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [_pickerController startVideoCapture];
    });
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    if ([mediaType isEqualToString:@"public.movie"]) {
        NSURL *videoURL = [info objectForKey:UIImagePickerControllerMediaURL];
        
        NSData *data = [NSData dataWithContentsOfURL:videoURL];
        NSString *filePath = [MXFilePathManager savePathWithFileSuffix:@"MOV"];
        BOOL success = [data writeToFile:filePath atomically:YES];
        
        if (success) {
            NSLog(@"写入成功-----");
        }
        
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            PHAssetChangeRequest *changeAssetRequest = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:videoURL];
            PHAssetCollection *targetCollection = [[PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil] lastObject];
            PHAssetCollectionChangeRequest *changeCollectRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:targetCollection];
            PHObjectPlaceholder *assetPlaceHolder = [changeAssetRequest placeholderForCreatedAsset];
            [changeCollectRequest addAssets:@[assetPlaceHolder]];
        } completionHandler:^(BOOL success, NSError * _Nullable error) {
            NSLog(@"finish");
        }];

    }
    
    [self dismissViewControllerAnimated:NO completion:nil];
    
    [self.audioPlayer stop];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:NO completion:nil];
    [self.audioPlayer stop];
    self.audioPlayer.currentTime = 0;
    [_timer invalidate];
}

- (IBAction)playAudio:(id)sender {
    
    NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
    NSString *path = [NSString stringWithFormat:@"%@/song.mp3", resourcePath];
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL URLWithString:path] error:nil];
    [self.audioPlayer setDelegate:self];
    self.audioPlayer.numberOfLoops = -1;
    [self.audioPlayer prepareToPlay];
    [self.audioPlayer play];
    
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1 repeats:YES block:^(NSTimer * _Nonnull timer) {
    
        
        NSLog(@"currentTime=%f",self.audioPlayer.currentTime);
        
        if(fabs(self.audioPlayer.currentTime - 8.0) < 0.1) {
            self.audioPlayer.currentTime = 5.0;
        }
        if(fabs(self.audioPlayer.currentTime - 5.0) < 0.1) {
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self captureVideo:nil];
                });
            });
        }
        
       
    }];
}


@end
