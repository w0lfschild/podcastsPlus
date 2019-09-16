//
//  podcastsPlus.h
//  podcastsPlus
//
//  Created by Wolfgang Baird on 8/13/19.
//  Copyright © 2019 macenhance. All rights reserved.
//

@import AppKit;
@import MediaPlayer;

#import <objc/runtime.h>
#import <Foundation/Foundation.h>
#import "ZKSwizzle/ZKSwizzle.h"
#import "AYProgressIndicator/AYProgressIndicator.h"

@interface podcastsPlus : NSObject

@property (strong, nonatomic) AYProgressIndicator *progressIndicator;
@property (strong, nonatomic) NSImage *currentImage;
@property (strong, nonatomic) NSImage *stockArt;
@property (strong, nonatomic) NSImage *modArt;
@property (nonatomic) Boolean useDarkProgress;
@property NSView *indiBackground;

@end
