#pragma once

#include <opencv2/core/core.hpp>
#include <opencv2/objdetect/objdetect.hpp>

class FaceAnimator
{
public:
    struct Parameters
    {
        cv::Mat glasses;
        cv::Mat mustache;
        cv::CascadeClassifier face_cascade;
        cv::CascadeClassifier eyes_cascade;
        cv::CascadeClassifier mouth_cascade;
    };

    FaceAnimator(Parameters images);
    virtual ~FaceAnimator() {};

    void detectAndAnimateFaces(cv::Mat& frame);

private:
    Parameters parameters_;
    cv::Mat mask_orig_;
    cv::Mat mask_must_;
    cv::Mat frame_gray;
    
    void putImage(cv::Mat& frame, const cv::Mat& image, const cv::Mat& alpha, 
                  cv::Rect face, cv::Rect facialFeature, float shift);
    void PreprocessToGray(cv::Mat& frame);

    //Members for optimization
    void PreprocessToGray_optimized(cv::Mat& frame);
    cv::Mat accBuffer1;
    cv::Mat accBuffer2;
};