#include <Accelerate/Accelerate.h>

int cvtColor_Accelerate(void *inData, unsigned int inStep,
                        void *outData, unsigned int outStep,
                        void *buff1Data, unsigned int buff1Step,
                        void *buff2Data, unsigned int buff2Step,
                        unsigned int height, unsigned int width)
{
    vImage_Buffer src = { inData, height, width, inStep };
    vImage_Buffer dst = { outData, height, width, outStep };
    vImage_Buffer buff1 = { buff1Data, height, width, buff1Step };
    vImage_Buffer buff2 = { buff2Data, height, width, buff2Step };
    
    const int16_t matrix[4 * 4] = {  77, 0, 0, 0,
        150, 0, 0, 0,
        29, 0, 0, 0,
        0, 0, 0, 0 };
    int32_t divisor = 256;
    
    vImage_Error err;
    err = vImageMatrixMultiply_ARGB8888(&src, &buff1,
                                        matrix, divisor,
                                        NULL, NULL, 0 );
    
    err = vImageConvert_ARGB8888toPlanar8(&buff1, &dst,
                                          &buff2, &buff2, &buff2, 0);
    return err;
}

int equalizeHist_Accelerate(void *inData, unsigned int inStep,
                            void *outData, unsigned int outStep,
                            unsigned int height, unsigned int width)
{
    vImage_Buffer src = { inData, height, width, inStep };
    vImage_Buffer dest = { outData, height, width, outStep };
    
    vImage_Error err;
    err = vImageEqualization_Planar8( &src, &dest, 0 );
    
    return err;
}