#pragma once

#include <opencv2/core/core.hpp>

void alphaBlendC1(const cv::Mat& src, cv::Mat& dst, const cv::Mat& alpha);
void alphaBlendC4(const cv::Mat& src, cv::Mat& dst, const cv::Mat& alpha);

void ExtractAlpha(cv::Mat& rgbaSrc, cv::Mat& alpha);

//NEON-optimized functions
void alphaBlendC1_NEON(const cv::Mat& src, cv::Mat& dst, const cv::Mat& alpha);
void multiply_NEON(cv::Mat& src, float multiplier);

// Accelerate-optimized functions
int cvtColor_Accelerate(void *inData, unsigned int inStep,
                        void *outData, unsigned int outStep,
                        void *buff1Data, unsigned int buff1Step,
                        void *buff2Data, unsigned int buff2Step,
                        unsigned int height, unsigned int width);

int equalizeHist_Accelerate(void *inData, unsigned int inStep,
                            void *outData, unsigned int outStep,
                            unsigned int height, unsigned int width);

//Macros for time measurements
#if 1
  #define TS(name) int64 t_##name = getTickCount()
  #define TE(name) printf("TIMER_" #name ": %.2fms\n", \
    1000.f * ((getTickCount() - t_##name) / getTickFrequency()))
#else
  #define TS(name)
  #define TE(name)
#endif