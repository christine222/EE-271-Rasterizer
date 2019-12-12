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
                case 1: // MSAA 64x
                    increment.set_slc(0, (ac_int<5,false>)0x10);
                    break;
                case 2: // MSAA 16x
                    increment.set_slc(0, (ac_int<7,false>)0x40);
                    break;
                case 4: // MSAA 4x
                    increment.set_slc(0, (ac_int<9,false>)0x100);
                    break;
                case 8: // MSAA 1x
                    increment.set_slc(0, (ac_int<11,false>)0x400);
                    break;
            }
            // Iterate over box (using normal for loops)
            SampleHLS sample;
            for (sample.x = bbox.lower_left.x; sample.x <= bbox.upper_right.x; sample.x + increment){
                for (sample.y = bbox.lower_left.y; sample.y <= bbox.upper_right.y; sample.y + increment){
                    // jitter sample
                    SampleHLS jitter = jitterSample.run(sample, config);

                    SampleHLS jittered_sample;
                    jittered_sample.x = sample.x + jitter.x;
                    jittered_sample.y = sample.y + jitter.y;

                    // test sample
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
