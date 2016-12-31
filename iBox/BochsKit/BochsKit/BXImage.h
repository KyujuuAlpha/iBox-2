//
//  BXImage.h
//  BochsKit
//
//  Created by Alsey Coleman Miller on 11/8/14.
//  Copyright (c) 2014 Bochs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BXImage : NSObject

+(void)createImageWithURL:(NSURL *)url sizeInMB:(NSUInteger)sizeInMB completion:(void (^)(BOOL success))completion;

+(NSUInteger)numberOfCylindersForImageWithSizeInMB:(NSUInteger)sizeInMB;

@end
