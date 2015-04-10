//
//  FirstViewController.h
//  Mosaicking
//
//  Created by Kazutaka KAMIYA on 4/10/15.
//  Copyright (c) 2015 Kazutaka KAMIYA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <opencv2/highgui/cap_ios.h>
#import "CvEffects/RetroFilter.hpp"

@interface FirstViewController : UIViewController<CvVideoCameraDelegate>
{
    CvVideoCamera* videoCamera;
    bool isCapturing;
    RetroFilter::Images images;
    cv::Ptr<RetroFilter> filter;
}

@property (nonatomic, retain) CvVideoCamera* videoCamera;
@property (nonatomic, retain) IBOutlet UIImageView *imageView;
@property (nonatomic, retain) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIButton *startStopCaptureButton;
@property (weak, nonatomic) IBOutlet UIView *titleView;

-(IBAction)startOrStopCaptureButtonPressed:(id)sender;

@end
