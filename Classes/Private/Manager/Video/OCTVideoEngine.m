//
//  OCTVideoEngine.m
//  objcTox
//
//  Created by Chuong Vu on 6/19/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTVideoEngine.h"

@import AVFoundation;

static uint8_t *reusableUChromaPlane;
static uint8_t *reusableVChromaPlane;


@interface OCTVideoEngine () <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoDataOutput *dataOutput;
@property (nonatomic, strong) dispatch_queue_t processingQueue;

@property (nonatomic, assign) NSUInteger sizeOfChromaPlanes;

@end

@implementation OCTVideoEngine

- (instancetype)init
{
    self = [super init];
    if (! self) {
        return nil;
    }

    _captureSession = [AVCaptureSession new];
    _dataOutput = [AVCaptureVideoDataOutput new];
    _processingQueue = dispatch_queue_create("me.dvor.objcTox.OCTVideoEngineQueue", NULL);

    return self;
}

#pragma mark - Public

- (BOOL)setupWithError:(NSError **)error
{
    AVCaptureDevice *videoCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoCaptureDevice error:error];

    if (! videoInput) {
        return NO;
    }

    [self.captureSession addInput:videoInput];

    [self.dataOutput setAlwaysDiscardsLateVideoFrames:YES];
    NSNumber *value  = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange];
    [self.dataOutput setVideoSettings:[NSDictionary dictionaryWithObject:value
                                                                  forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    [self.dataOutput setSampleBufferDelegate:self queue:self.processingQueue];

    [self.captureSession addOutput:self.dataOutput];

    return YES;
}

- (void)startVideoSession
{
    dispatch_async(self.processingQueue, ^{
        [self.captureSession startRunning];
    });
}

- (void)stopVideoSession
{
    dispatch_async(self.processingQueue, ^{
        [self.captureSession stopRunning];
    });
}

- (CALayer *)videoCallPreview
{
    AVCaptureVideoPreviewLayer *previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];

    return previewLayer;
}

#pragma mark - Buffer Delegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{

    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);


    if (! imageBuffer) {
        return;
    }

    CVPixelBufferLockBaseAddress(imageBuffer, 0);

    OCTToxAVVideoWidth width = CVPixelBufferGetWidth(imageBuffer);
    OCTToxAVVideoHeight height = CVPixelBufferGetHeight(imageBuffer);

    uint8_t *yPlane = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
    uint8_t *uvPlane = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 1);

    NSUInteger numberOfElementsForChroma = height * width / 4;

    if (numberOfElementsForChroma > self.sizeOfChromaPlanes) {

        if (reusableUChromaPlane) {
            free(reusableUChromaPlane);
        }

        if (reusableVChromaPlane) {
            free(reusableVChromaPlane);
        }

        reusableUChromaPlane = malloc(numberOfElementsForChroma * sizeof(uint8_t));
        reusableVChromaPlane = malloc(numberOfElementsForChroma * sizeof(uint8_t));

        self.sizeOfChromaPlanes = numberOfElementsForChroma;
    }

    for (int i = 0; i < (height * width / 4); i += 2) {
        reusableUChromaPlane[i / 2] = uvPlane[i];
        reusableVChromaPlane[i / 2] = uvPlane[i+1];
    }

    [self.toxav sendVideoFrametoFriend:self.friendNumber
                                 width:width
                                height:height
                                yPlane:yPlane
                                uPlane:reusableUChromaPlane
                                vPlane:reusableVChromaPlane
                                 error:nil];

    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
}

@end
