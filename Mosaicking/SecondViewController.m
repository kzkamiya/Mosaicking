//
//  SecondViewController.m
//  Mosaicking
//
//  Created by Kazutaka KAMIYA on 4/10/15.
//  Copyright (c) 2015 Kazutaka KAMIYA. All rights reserved.
//

#import "SecondViewController.h"

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

@interface SecondViewController ()

@end

@implementation SecondViewController

@synthesize imageView;
@synthesize startStopCaptureButton;
@synthesize toolbar;
@synthesize videoCamera;
@synthesize titleView;

- (NSUInteger)supportedInterfaceOrientations
{
    //only portrait orientation
    //    return UIInterfaceOrientationMaskPortrait;
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
    self.videoCamera = [[CvVideoCamera alloc]
                        initWithParentView:imageView];
    self.videoCamera.delegate = self;
    //    self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionFront;
    //    self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset352x288;
    //    self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset352x288;
    self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationLandscapeRight;
    self.videoCamera.defaultFPS = 30;
    
    isCapturing = FALSE;
    
    //Load images
    NSString* filePath = [[NSBundle mainBundle]
                          pathForResource:@"glasses" ofType:@"png"];
    UIImage* resImage = [UIImage imageWithContentsOfFile:filePath];
    UIImageToMat(resImage, parameters.glasses, true);
    cvtColor(parameters.glasses, parameters.glasses, CV_BGRA2RGBA);
    
    filePath = [[NSBundle mainBundle]
                pathForResource:@"mustache" ofType:@"png"];
    resImage = [UIImage imageWithContentsOfFile:filePath];
    UIImageToMat(resImage, parameters.mustache, true);
    cvtColor(parameters.mustache, parameters.mustache, CV_BGRA2RGBA);
    
    //Load Cascade Classisiers
    NSString* filename = [[NSBundle mainBundle]
                          pathForResource:@"lbpcascade_frontalface" ofType:@"xml"];
    parameters.face_cascade.load([filename UTF8String]);
    
    filename = [[NSBundle mainBundle]
                pathForResource:@"haarcascade_mcs_eyepair_big" ofType:@"xml"];
    //    filename = [[NSBundle mainBundle]
    //                pathForResource:@"haarcascade_eye" ofType:@"xml"];
    parameters.eyes_cascade.load([filename UTF8String]);
    
    filename = [[NSBundle mainBundle]
                pathForResource:@"haarcascade_mcs_mouth" ofType:@"xml"];
    parameters.mouth_cascade.load([filename UTF8String]);
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
        faceAnimator = new FaceAnimator(parameters);
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

-(IBAction)startCaptureButtonPressed:(id)sender
{
    [videoCamera start];
    isCapturing = TRUE;
    
    faceAnimator = new FaceAnimator(parameters);
}

-(IBAction)stopCaptureButtonPressed:(id)sender
{
    [videoCamera stop];
    isCapturing = FALSE;
}

- (void)processImage:(cv::Mat&)image
{
    int64 timeStart = cv::getTickCount();
    faceAnimator->detectAndAnimateFaces(image);
    int64 timeEnd = cv::getTickCount();
    float durationMs =
    1000.f * float(timeEnd - timeStart) / cv::getTickFrequency();
    NSLog(@"Processing time = %.3fms", durationMs);
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