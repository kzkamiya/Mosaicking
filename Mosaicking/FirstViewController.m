//
//  FirstViewController.m
//  Mosaicking
//
//  Created by Kazutaka KAMIYA on 4/10/15.
//  Copyright (c) 2015 Kazutaka KAMIYA. All rights reserved.
//

#import "FirstViewController.h"

static UIImage* MatToUIImage(const cv::Mat& image)
{
    NSData *data = [NSData dataWithBytes:image.data
                                  length:image.elemSize()*image.total()];
    
    CGColorSpaceRef colorSpace;
    
    if (image.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider =
    CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(image.cols,
                                        image.rows,
                                        8,
                                        8 * image.elemSize(),
                                        image.step.p[0],
                                        colorSpace,
                                        kCGImageAlphaNone|
                                        kCGBitmapByteOrderDefault,
                                        provider,
                                        NULL,
                                        false,
                                        kCGRenderingIntentDefault
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}

static void UIImageToMat(const UIImage* image, cv::Mat& m,
                         bool alphaExist = false)
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width, rows = image.size.height;
    CGContextRef contextRef;
    CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedLast;
    if (CGColorSpaceGetModel(colorSpace) == 0)
    {
        m.create(rows, cols, CV_8UC1);
        //8 bits per component, 1 channel
        bitmapInfo = kCGImageAlphaNone;
        if (!alphaExist)
            bitmapInfo = kCGImageAlphaNone;
        contextRef = CGBitmapContextCreate(m.data, m.cols, m.rows, 8,
                                           m.step[0], colorSpace,
                                           bitmapInfo);
    }
    else
    {
        m.create(rows, cols, CV_8UC4); // 8 bits per component, 4 channels
        if (!alphaExist)
            bitmapInfo = kCGImageAlphaNoneSkipLast |
            kCGBitmapByteOrderDefault;
        contextRef = CGBitmapContextCreate(m.data, m.cols, m.rows, 8,
                                           m.step[0], colorSpace,
                                           bitmapInfo);
    }
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows),
                       image.CGImage);
    CGContextRelease(contextRef);
    CGColorSpaceRelease(colorSpace);
}

@interface FirstViewController ()

@end

@implementation FirstViewController

@synthesize imageView;
@synthesize startStopCaptureButton;
@synthesize toolbar;
@synthesize videoCamera;
@synthesize titleView;

- (NSUInteger)supportedInterfaceOrientations
{
    //only landscapeRight orientation
    return UIInterfaceOrientationMaskLandscapeRight;
}

-(BOOL)shouldAutorotateToInterfaceOrientation:
(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationLandscapeRight);
    //画面の右側にホームボタン
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    videoCamera = [[CvVideoCamera alloc]
                   initWithParentView:imageView];
    videoCamera.delegate = self;
    videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset352x288;
    videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationLandscapeRight;
    videoCamera.defaultFPS = 30;
    videoCamera.recordVideo = YES;
    
    isCapturing = FALSE;
    
    NSString* filePath = [[NSBundle mainBundle]
                          pathForResource:@"scratches" ofType:@"png"];
    UIImage* resImage = [UIImage imageWithContentsOfFile:filePath];
    UIImageToMat(resImage, images.scratches);
    
    filePath = [[NSBundle mainBundle]
                pathForResource:@"fuzzy_border" ofType:@"png"];
    resImage = [UIImage imageWithContentsOfFile:filePath];
    UIImageToMat(resImage, images.fuzzy_border);
    
    cv::Size frameSize(352, 288);
    images.frameSize = frameSize;
    
    filter = new RetroFilter(images);
    
}


-(IBAction)startOrStopCaptureButtonPressed:(id)sender
{
    
    if (!isCapturing) {
        // OFFの画像設定
        [startStopCaptureButton setBackgroundImage:[UIImage imageNamed:@"Stop-50"] forState:UIControlStateNormal];
        // OFFでボタンをタップ中の画像設定
        [startStopCaptureButton setBackgroundImage:[UIImage imageNamed:@"Stop-50"] forState:UIControlStateHighlighted];
        titleView.hidden = TRUE;
        [videoCamera start];
        isCapturing = TRUE;
    } else {
        // ONの画像設定
        [startStopCaptureButton setBackgroundImage:[UIImage imageNamed:@"Video Camera Filled-50"] forState:UIControlStateNormal | UIControlStateSelected];
        // ONでボタンをタップ中の画像設定
        [startStopCaptureButton setBackgroundImage:[UIImage imageNamed:@"Stop-50"] forState:UIControlStateHighlighted | UIControlStateSelected];
        
        titleView.hidden = FALSE;
        [videoCamera stop];
        NSString* relativePath = [videoCamera.videoFileURL relativePath];
        UISaveVideoAtPathToSavedPhotosAlbum(relativePath, self, nil, NULL);
        
        //Alert window
        UIAlertView *alert = [UIAlertView alloc];
        alert = [alert initWithTitle:@"録画完了"
                             message:@"フォトギャラリーへ保存しました。"
                            delegate:self
                   cancelButtonTitle:@"閉じる"
                   otherButtonTitles:nil];
        [alert show];
        
        isCapturing = FALSE;
    }
}

- (void)processImage:(cv::Mat&)image
{
    cv::Mat inputFrame = image, finalFrame;
    bool isNeedRotation = image.size() != images.frameSize;
    
    if (isNeedRotation)
        inputFrame = image.t();
    
    filter->applyToVideo(inputFrame, finalFrame);
    
    if (isNeedRotation)
        finalFrame = finalFrame.t();
    
    finalFrame.copyTo(image);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidDisappear:(BOOL)animated
{
    if (isCapturing) {
        [videoCamera stop];
    }
}

@end
