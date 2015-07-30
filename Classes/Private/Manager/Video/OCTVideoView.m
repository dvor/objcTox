//
//  OCTVideoView.m
//  objcTox
//
//  Created by Chuong Vu on 6/21/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTVideoView.h"
@import Foundation;

@interface OCTVideoView ()

@property (strong, nonatomic) CIImage *image;
@property (strong, nonatomic) CIContext *coreImageContext;

@end

@implementation OCTVideoView

- (instancetype)initWithFrame:(CGRect)frame
{
    EAGLContext *eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];

    return [self initWithFrame:frame context:eaglContext];
}

- (instancetype)initWithFrame:(CGRect)frame context:(EAGLContext *)context
{
    _coreImageContext = [CIContext contextWithEAGLContext:context];

    self = [super initWithFrame:frame context:context];

    if (! self) {
        return nil;
    }

    self.enableSetNeedsDisplay = NO;

    return self;
}

- (void)drawRect:(CGRect)rect
{
    if (self.image) {
        CGFloat scale = self.window.screen.scale;
        CGRect destRect = CGRectApplyAffineTransform(self.bounds, CGAffineTransformMakeScale(scale, scale));
        [self.coreImageContext drawImage:self.image inRect:destRect fromRect:self.image.extent];
    }
}
@end
