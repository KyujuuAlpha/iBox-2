//
//  BXRenderView.h
//  BochsKit
//
//  Created by Alsey Coleman Miller on 11/8/14.
//  Copyright (c) 2014 Bochs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface BXRenderView : UIView
{
    CGSize sz;
    int* imageData;
    CGContextRef imageContext;
}

+ (BXRenderView *)sharedInstance;

- (instancetype)init:(UIWindow*)window;

- (void)addToWindow:(UIWindow*)window;

- (void)doRedraw;

- (void)vKeyDown:(int)keyCode;
- (void)vKeyUp:(int)keyCode;

- (void)rescaleFrame;

- (int *)imageData;
- (CGContextRef)imageContext;
- (void)recreateImageContextWithX:(int)x y:(int)y bpp:(int)bpp;

@end
