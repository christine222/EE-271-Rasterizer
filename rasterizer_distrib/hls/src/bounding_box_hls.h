#ifndef BOUNDING_BOX_HLS
#define BOUNDING_BOX_HLS

#include "rast_types_hls.h"

#pragma hls_design 
class BoundingBoxGenerator{
public:
    BoundingBoxGenerator() {}

    #pragma hls_design interface
    void CCS_BLOCK(run)(
        ac_channel<TriangleHLS> &triangle_in, 
        ac_channel<ScreenHLS> &screen_in, 
        ac_channel<ConfigHLS> &config_in,
        ac_channel<BoundingBoxHLS> &bbox_out,
        ac_channel<TriangleHLS> &triangle_out,
        ac_channel<ConfigHLS> &config_out
    ){
        #ifndef __SYNTHESIS__
        while(triangle_in.available(1))
        #endif
        {
            TriangleHLS triangle = triangle_in.read();
            ScreenHLS screen = screen_in.read();
            ConfigHLS config = config_in.read();

            BoundingBoxHLS bbox;
            
            // START CODE HERE
            bbox.lower_left.x = triangle.v[0].x;
            bbox.lower_left.y = triangle.v[0].y;
            bbox.upper_right.x = triangle.v[0].x;
            bbox.upper_right.y = triangle.v[0].y;
            // iterate over remaining vertices
            for (int vertex = 1; vertex < 3; vertex++)
            {
                bbox.upper_right.x = max(bbox.upper_right.x, triangle.v[vertex].x);
                bbox.upper_right.y = max(bbox.upper_right.y, triangle.v[vertex].y);
                bbox.lower_left.x = min(bbox.lower_left.x, triangle.v[vertex].x);
                bbox.lower_left.y = min(bbox.lower_left.y, triangle.v[vertex].y);
            }
            // round down to subsample grid
            bbox.upper_right.x = floor_ss(bbox.upper_right.x, config);
            bbox.upper_right.y = floor_ss(bbox.upper_right.y, config);
            bbox.lower_left.x = floor_ss(bbox.lower_left.x, config);
            bbox.lower_left.y = floor_ss(bbox.lower_left.y, config);

            // clip to screen
            bbox.upper_right.x = min(bbox.upper_right.x, screen.width);
            bbox.upper_right.y = min(bbox.upper_right.y, screen.height);
            bbox.lower_left.x = max(bbox.lower_left.x, 0);
            bbox.lower_left.y = max(bbox.lower_left.y, 0);

            // check if bbox is valid
            bool valid;
            if ((triangle.v[1].x - triangle.v[0].x)*(triangle.v[2].y - triangle.v[1].y) - (triangle.v[2].x - triangle.v[1].x)*(triangle.v[1].y - triangle.v[0].y) > 0) {
                valid = 0;
            }
            else {
            // check if bbox is valid
                valid = (bbox.lower_left.x >= 0) && (bbox.lower_left.y >= 0) && (bbox.upper_right.x < screen.width ) && (bbox.upper_right.y < screen.height);  
            }

            // write to outputs if bbox is valid
            if (valid){
                triangle_out.write(triangle);
                bbox_out.write(bbox);
                config_out.write(config);
            }
            // END CODE HERE
        }
    }
private:
    SignedFixedPoint min(SignedFixedPoint a, SignedFixedPoint b)
    {
        // START CODE HERE
        return (a < b) ? a : b;
        // END CODE HERE
    }

    SignedFixedPoint max(SignedFixedPoint a, SignedFixedPoint b)
    {
        // START CODE HERE
        return (a > b) ? a : b;
        // END CODE HERE
    }

    SignedFixedPoint floor_ss(SignedFixedPoint val, ConfigHLS config)
    {
        // START CODE HERE
        // set lower 8 bits to 0
        ac_int<RADIX, false> mask = 0;
        // val.set_slc(0, mask<8>(0));
        // set bits depending on subsample
        switch(config.subsample){
          case 1:
            mask.set_slc(7, (ac_int<3,false>)0xFF);
            break;
          case 2:
            mask.set_slc(8, (ac_int<2,false>)0xFF);
            break;
          case 4:
            mask.set_slc(9, (ac_int<1,false>)0xFF);  
            break;
          case 8:
            // chop off everything
            break;
        }

        val = val & mask;
        
        // END CODE HERE
        return val;
    }
};

#endif
