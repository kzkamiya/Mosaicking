//
//  PostcardPrinter.hpp
//  Chapter05_PrintingPostcard
//
//  Created by Kirill Kornyakov on 5/11/13.
//  Copyright (c) 2013 Alexander Shishkov & Kirill Kornyakov. All rights reserved.
//

#pragma once

#include "opencv2/core/core.hpp"

class PostcardPrinter
{
public:
    struct Images
    {
        cv::Mat face;
        cv::Mat texture;
        cv::Mat text;
    };

    PostcardPrinter(Images images);
    void print(cv::Mat& postcard) const;

private:
    void crumple(cv::Mat& image, const cv::Mat& texture,
                 const cv::Mat& mask = cv::Mat()) const;
    void alphaBlend(const cv::Mat& src, cv::Mat& dst,
                    const cv::Mat& alpha) const;

    Images images_;
};