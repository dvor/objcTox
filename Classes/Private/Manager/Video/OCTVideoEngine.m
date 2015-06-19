//
//  OCTVideoEngine.m
//  objcTox
//
//  Created by Chuong Vu on 6/19/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTVideoEngine.h"

@import AVFoundation;

@interface OCTVideoEngine () <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoDataOutput *dataOutput;
@property (nonatomic, strong) dispatch_queue_t processingQueue;

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

    return self;
}

- (BOOL)setupWithError:(NSError **)error
{
    AVCaptureDevice *videoCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoCaptureDevice error:error];

    if (! videoInput) {
        return NO;
    }

    [self.captureSession addInput:videoInput];

    self.processingQueue = dispatch_queue_create("me.dvor.objcTox.OCTVideoEngineQueue", NULL);

    [self.dataOutput setAlwaysDiscardsLateVideoFrames:YES];
    NSNumber *value  = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange];

    [self.dataOutput setVideoSettings:[NSDictionary dictionaryWithObject:value
                                                                  forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    [self.dataOutput setSampleBufferDelegate:self queue:self.processingQueue];

    return YES;
}

- (void)startVideoSession
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.captureSession startRunning];
    });
}

- (void)stopVideoSession
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.captureSession stopRunning];
    });
}

#pragma mark - Private methods

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

    uint8_t uPlane[height * width / 4];
    uint8_t vPlane[height * width / 4];

    for (int i = 0; i < (height * width / 4); i += 2) {
        uPlane[i] = uvPlane[i];
        vPlane[i] = uvPlane[i+1];
    }

    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);

    [self.toxav sendVideoFrametoFriend:self.friendNumber
                                 width:width
                                height:height
                                yPlane:yPlane
                                uPlane:uPlane
                                vPlane:vPlane
                                 error:nil];
}

@end
