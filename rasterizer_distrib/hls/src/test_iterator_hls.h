#include "jitter_hls.h"
#include "sample_test_hls.h"

class TestIterator{
public:
    TestIterator(){}
    
    #pragma hls_design interface
    void CCS_BLOCK(run)(
        ac_channel<BoundingBoxHLS> &bbox_in, 
        ac_channel<TriangleHLS> &triangle_in,
        ac_channel<ConfigHLS> &config_in,
        ac_channel<SampleHLS> &sample_out   
    ){
        #ifndef __SYNTHESIS__
        while(triangle_in.available(1))
        #endif
        {
            BoundingBoxHLS bbox = bbox_in.read();
            TriangleHLS triangle = triangle_in.read();
            ConfigHLS config = config_in.read();

            // START CODE HERE

            // Create increment value from config.subsample
            ac_int<24, false> increment = 0;
            switch(config.subsample){
                case 1: // MSAA 64: sample is 1/8 pixel
                    increment.set_slc(0, (ac_int<8,false>)0x100);
                    break;
                case 2: // MSAA 16x: sample is 1/4 a pixel
                    increment.set_slc(0, (ac_int<9,false>)0x200);
                    break;
                case 4: // MSAA 4x: sample is 1/2 a pixel
                    increment.set_slc(0, (ac_int<10,false>)0x200);
                    break;
                case 8: // MSAA 1x
                    increment.set_slc(0, (ac_int<11,false>)0x400);
                    break;
            }
            // Iterate over box (using normal for loops)
            SampleHLS sample;
            sample.x = bbox.lower_left.x;
            sample.y = bbox.lower_left.y;
            while(sample.x <= bbox.upper_right.x){
                while(sample.y <= bbox.upper_right.y){
                    // jitter sample
                    SampleHLS jitter = jitterSample.run(sample, config);

                    SampleHLS jittered_sample;
                    jittered_sample.x = sample.x + jitter.x;
                    jittered_sample.y = sample.y + jitter.y;

                    // test sampleå
                    bool hit = sampleTest.run(triangle, jittered_sample);

                    // if hit, write out the sample (including RGB values)
                    if (hit){
                        jittered_sample.R = sample.R;
                        jittered_sample.G = sample.G;
                        jittered_sample.B = sample.B;
                        sample_out.write(jittered_sample);
                    }
                    sample.y = increment + sample.y;
                }
                sample.x = increment + sample.x;
            }
                    
        // END CODE HERE
        }
    }
private:
    SampleTest sampleTest;
    JitterSample jitterSample;
};
