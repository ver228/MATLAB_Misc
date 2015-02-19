#include <mex.h>
#define IMAGE_WIDTH 2048
#define IMAGE_HEIGHT 2048

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    
    
    uint8_T *buffer = (uint8_T *)mxGetData(prhs[0]);
    double * buffer_indexes = mxGetPr(prhs[1]);
    if (buffer_indexes[0]>=buffer_indexes[1])
        mexErrMsgTxt("Invalid index range.");
    
    plhs[0] = mxCreateNumericMatrix(IMAGE_WIDTH,IMAGE_HEIGHT,mxUINT8_CLASS,mxREAL);
    
    uint8_T* image = (uint8_T*)mxGetData(plhs[0]);
    //mexPrintf("%f-%i\n", indexes[1], (int)indexes[1]);
    
    int image_ind = 0;
    int buffer_ind = (int)buffer_indexes[0]-1;
    uint16_T num_zeros = 0;
    while (buffer_ind < (int)buffer_indexes[1] && image_ind < IMAGE_WIDTH*IMAGE_HEIGHT)
    {
        if (buffer[buffer_ind] != 0)
        {
            image[image_ind] = buffer[buffer_ind];
            image_ind++;
            buffer_ind++;
        }    
        else
        {
            
            num_zeros = (unsigned char)buffer[buffer_ind+1] << 8 | (unsigned char)buffer[buffer_ind+2];
            //mexPrintf("%i\n", num_zeros);
            //mexPrintf("%i %i %i\n", buffer[buffer_ind], buffer[buffer_ind+1], buffer[buffer_ind+2]);
            image_ind += num_zeros;
            buffer_ind += 3;
            //return;
        }
        
    }
    
    
}