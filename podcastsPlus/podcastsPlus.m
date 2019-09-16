//
//  podcastsPlus.m
//  podcastsPlus
//
//  Created by Wolfgang Baird on 8/13/19.
//  Copyright © 2019 macenhance. All rights reserved.
//

@import Foundation;

#import "podcastsPlus.h"
#import "MRMediaRemote.h"

podcastsPlus        *plugin;
NSString            *overlayPath;
NSString            *classicPath;
NSImage             *stockArt;
NSImage             *modArt;
NSUserDefaults      *sharedPrefs;
NSMenu              *podcastsPlusMenu;
NSURL               *currentArtwork;
NSString            *currentUUID;

bool  showProgress      = true;
bool  showBadge         = true;
int   iconArt           = 0;
float currentProgress   = 0;

@interface MEPod_Podcasts_GlobalActionController : NSObject
- (void)mainWindowDidChangeKey:(id)arg1;
- (void)decreaseVolume;
- (void)increaseVolume;
- (void)setDoubleSpeed;
- (void)setOneAndAHalfSpeed;
- (void)setOneAndAQuarterSpeed;
- (void)setNormalSpeed;
- (void)setHalfSpeed;
- (void)jumpBackwards;
- (void)jumpForwards;
- (void)previousTrack;
- (void)nextTrack;
- (void)playPause;
@end

MEPod_Podcasts_GlobalActionController *jank;

@implementation MEPod_Podcasts_GlobalActionController

- (void)mainWindowDidChangeKey:(id)arg1; {
    jank = self;
    ZKOrig(void, arg1);
}

@end

@implementation podcastsPlus

+ (podcastsPlus*) sharedInstance {
    static podcastsPlus* plugin = nil;
    
    if (plugin == nil)
        plugin = [[podcastsPlus alloc] init];
    
    return plugin;
}

+ (void)load {
    plugin = [podcastsPlus sharedInstance];
    
    if (!sharedPrefs)
        sharedPrefs = [NSUserDefaults standardUserDefaults];
    
    if ([sharedPrefs objectForKey:@"showProgress"] == nil) [sharedPrefs setBool:true forKey:@"showProgress"];
    if ([sharedPrefs objectForKey:@"showBadge"] == nil) [sharedPrefs setBool:true forKey:@"showBadge"];
    if ([sharedPrefs objectForKey:@"iconArt"] == nil) [sharedPrefs setInteger:1 forKey:@"iconArt"];
    showProgress    = [[sharedPrefs objectForKey:@"showProgress"] boolValue];
    showBadge       = [[sharedPrefs objectForKey:@"showBadge"] boolValue];
    iconArt         = (int)[sharedPrefs integerForKey:@"iconArt"];
    
    ZKSwizzle(_MTMediaRemoteController, Podcasts.GlobalActionController);
    
//    extern CFStringRef kMRMediaRemoteNowPlayingInfoDidChangeNotification;
//    extern CFStringRef kMRMediaRemoteNowPlayingPlaybackQueueDidChangeNotification;
//    extern CFStringRef kMRMediaRemotePickableRoutesDidChangeNotification;
//    extern CFStringRef kMRMediaRemoteNowPlayingApplicationDidChangeNotification;
//    extern CFStringRef kMRMediaRemoteNowPlayingApplicationIsPlayingDidChangeNotification;
//    extern CFStringRef kMRMediaRemoteRouteStatusDidChangeNotification;
    
//    [NSNotificationCenter.defaultCenter addObserver:plugin selector:@selector(updateCurrentPlayingApp) name:kMRMediaRemoteNowPlayingApplicationIsPlayingDidChangeNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:plugin selector:@selector(updateMediaContent) name:kMRMediaRemoteNowPlayingApplicationClientStateDidChange object:nil];
    [NSNotificationCenter.defaultCenter addObserver:plugin selector:@selector(updateMediaContent) name:kMRNowPlayingPlaybackQueueChangedNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:plugin selector:@selector(updateMediaContent) name:kMRPlaybackQueueContentItemsChangedNotification object:nil];
    
    [NSNotificationCenter.defaultCenter addObserver:plugin selector:@selector(updateMediaContent) name:kMRMediaRemoteNowPlayingInfoDidChangeNotification object:nil];
//    [NSNotificationCenter.defaultCenter addObserver:plugin selector:@selector(updateCurrentPlayingState) name:kMRMediaRemoteNowPlayingApplicationDidChangeNotification object:nil];
    
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        MRMediaRemoteGetNowPlayingInfo(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(NSDictionary *info) {
//            NSLog(@"-----f----- %@", info);
//        });
//    });
    
    NSUInteger osx_ver = [[NSProcessInfo processInfo] operatingSystemVersion].minorVersion;
    NSLog(@"%@ loaded into %@ on macOS 10.%ld", [self class], [[NSBundle mainBundle] bundleIdentifier], (long)osx_ver);
}

- (void)updateMediaContent {
    MRMediaRemoteGetNowPlayingInfo(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(NSDictionary *info) {
//        kMRMediaRemoteNowPlayingInfoArtworkData
//        NSString *s = [info objectForKey:@"kMRMediaRemoteNowPlayingInfoAlbum"];
//        NSData *d = [info objectForKey:kMRMediaRemoteNowPlayingInfoArtworkData];
//        NSImage *i = [[NSImage alloc] initWithData:d];
////        NSLog(@"%@ - %@", i, s);
//
//        NSLog(@"Hello");
//
////        if (i) {
////            NSLog(@"Hello 2");
////
////            [NSApp setApplicationIconImage:i];
////            [NSApp.dockTile display];
////        }
//
//
//        NSLog(@"-----f----- %@", info);
    });
}

- (NSImage*)lightRound:(NSImage *)image :(float)shrink {
    NSImage *existingImage = image;
    NSSize newSize = [existingImage size];
    NSImage *composedImage = [[NSImage alloc] initWithSize:newSize];

    float imgW = newSize.width;
    float imgH = newSize.height;
    float xShift = (imgW - (imgW * shrink)) / 2;
    float yShift = (imgH - (imgH * shrink)) / 2;

    [composedImage lockFocus];
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
    NSRect imageFrame = NSRectFromCGRect(CGRectMake(xShift, yShift, (imgW * shrink), (imgH * shrink)));
    NSBezierPath *clipPath = [NSBezierPath bezierPathWithRoundedRect:imageFrame xRadius:imgW/10 yRadius:imgH/10];
    [clipPath setWindingRule:NSEvenOddWindingRule];
    [clipPath addClip];
    [image drawAtPoint:NSZeroPoint fromRect:NSMakeRect(0, 0, imgW, imgH) operation:NSCompositingOperationSourceOver fraction:1];
    [composedImage unlockFocus];

    //    NSData *imageData = [composedImage TIFFRepresentation];
    //    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
    //    imageData = [imageRep representationUsingType:NSPNGFileType properties:[NSDictionary dictionary]];
    //    [imageData writeToFile:@"/Users/w0lf/Desktop/spotifree.png" atomically:YES];

    return composedImage;
}

- (NSImage*)imageRotatedByDegrees:(CGFloat)degrees :(NSImage*)img {
    NSSize    size = [img size];
    NSSize    newSize = NSMakeSize( size.width + 40,
                                   size.height + 40 );
    
    //    NSSize rotatedSize = NSMakeSize(img.size.height, img.size.width) ;
    NSImage* rotatedImage = [[NSImage alloc] initWithSize:newSize] ;
    
    NSAffineTransform* transform = [NSAffineTransform transform] ;
    
    // In order to avoid clipping the image, translate
    // the coordinate system to its center
    //    [transform translateXBy:+img.size.width/2
    //                        yBy:+img.size.height/2] ;
    
    [transform translateXBy:img.size.width / 2
                        yBy:img.size.height / 2];
    
    // then rotate
    [transform rotateByDegrees:degrees] ;
    
    // Then translate the origin system back to
    // the bottom left
    [transform translateXBy:-size.width/2
                        yBy:-size.height/2] ;
    
    //
    
    [rotatedImage lockFocus] ;
    [transform concat] ;
    [img drawAtPoint:NSMakePoint(15,10)
            fromRect:NSZeroRect
           operation:NSCompositingOperationCopy
            fraction:1.0] ;
    [rotatedImage unlockFocus] ;
    
    return rotatedImage;
}

- (NSImage*)roundCorners:(NSImage *)image :(float)shrink {
    NSImage *existingImage = image;
    NSSize newSize = [existingImage size];
    NSImage *composedImage = [[NSImage alloc] initWithSize:newSize];

    float imgW = newSize.width;
    float imgH = newSize.height;
    float xShift = (imgW - (imgW * shrink)) / 2;
    float yShift = (imgH - (imgH * shrink)) / 2;

    [composedImage lockFocus];
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
    NSRect imageFrame = NSRectFromCGRect(CGRectMake(xShift, yShift, (imgW * shrink), (imgH * shrink)));
    NSBezierPath *clipPath = [NSBezierPath bezierPathWithRoundedRect:imageFrame xRadius:imgW yRadius:imgH];
    [clipPath setWindingRule:NSEvenOddWindingRule];
    [clipPath addClip];
    [image drawAtPoint:NSZeroPoint fromRect:NSMakeRect(0, 0, imgW, imgH) operation:NSCompositingOperationSourceOver fraction:1];
    [composedImage unlockFocus];

    return composedImage;
}

- (NSImage*)createIconImage:(NSImage*)stockCover :(int)resultType {
    // 0 = rounded
    // 1 = tilded
    // 2 = square
    //    NSString *myLittleCLIToolPath = NSProcessInfo.processInfo.arguments[0];
    NSImage *resultIMG = [[NSImage alloc] init];
    
    if (stockCover) {
    
        // Square
        if (resultType == 1) {
            resultIMG = stockCover;
        }
        
        // Tilted
        if (resultType == 2) {
            NSSize dims = [[NSApp dockTile] size];
            dims.width *= 0.9;
            dims.height *= 0.9;
            NSImage *smallImage = [[NSImage alloc] initWithSize: dims];
            [smallImage lockFocus];
            [stockCover setSize: dims];
            [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
            [stockCover drawAtPoint:NSZeroPoint fromRect:CGRectMake(0, 0, dims.width, dims.height) operation:NSCompositingOperationCopy fraction:1.0];
            [smallImage unlockFocus];
            smallImage = [plugin imageRotatedByDegrees:15.00 :smallImage];
            resultIMG = smallImage;
        }
        
        // Classic
        if (resultType == 3) {
            if (![classicPath length]) {
                classicPath = @"/tmp";
                NSBundle* bundle = [NSBundle bundleWithIdentifier:@"com.macenhance.podcastsPlus"];
                NSString* bundlePath = [bundle bundlePath];
                if ([bundlePath length])
                    classicPath = [bundlePath stringByAppendingString:@"/Contents/Resources/ClassicOverlay.png"];
            }
            NSImage *rounded = [self roundCorners:stockCover :0.9];
            NSImage *background = rounded;
            NSImage *overlay = [[NSImage alloc] initByReferencingFile:classicPath];
            NSImage *newImage = [[NSImage alloc] initWithSize:[background size]];
            [newImage lockFocus];
            CGRect newImageRect = CGRectZero;
            newImageRect.size = [newImage size];
            [background drawInRect:newImageRect];
            [overlay drawInRect:newImageRect];
            [newImage unlockFocus];
            resultIMG = newImage;
        }
        
        // Modern
        if (resultType == 4) {
            if (![overlayPath length]) {
                overlayPath = @"/tmp";
                NSBundle* bundle = [NSBundle bundleWithIdentifier:@"com.macenhance.podcastsPlus"];
                NSString* bundlePath = [bundle bundlePath];
                if ([bundlePath length])
                    overlayPath = [bundlePath stringByAppendingString:@"/Contents/Resources/ModernOverlay.png"];
            }
            NSImage *rounded = [self roundCorners:stockCover :0.85];
            NSImage *background = rounded;
            NSImage *overlay = [[NSImage alloc] initByReferencingFile:overlayPath];
            NSImage *newImage = [[NSImage alloc] initWithSize:[background size]];
            [newImage lockFocus];
            CGRect newImageRect = CGRectZero;
            newImageRect.size = [newImage size];
            [background drawInRect:newImageRect];
            [overlay drawInRect:newImageRect];
            [newImage unlockFocus];
            resultIMG = newImage;
        }
        
        // Rounded corners
        if (resultType == 5) {
            resultIMG = [self lightRound:stockCover :1];
        }
        
        if (resultIMG == nil) {
            resultIMG = stockCover;
        }
        
    }
    
    return resultIMG;
}

- (NSMenu*)dockaddpodcastsPlus:(NSMenu*)original {
    // Spotify+ meun item
    NSMenuItem *mainItem = [[NSMenuItem alloc] init];
    [mainItem setTitle:@"podcasts+"];
    
    NSMenu* dockspotplusMenu = [plugin generatePodcastsPlusMenu];
    [mainItem setSubmenu:dockspotplusMenu];
    
    [original addItem:[NSMenuItem separatorItem]];
    [[original addItemWithTitle:@"Play/Pause" action:@selector(playPause) keyEquivalent:@""] setTarget:jank];
    [[original addItemWithTitle:@"Next" action:@selector(nextTrack) keyEquivalent:@""] setTarget:jank];
    [[original addItemWithTitle:@"Previous" action:@selector(previousTrack) keyEquivalent:@""] setTarget:jank];
    [[original addItemWithTitle:@"Seek Forward" action:@selector(jumpForwards) keyEquivalent:@""] setTarget:jank];
    [[original addItemWithTitle:@"Seek BackWard" action:@selector(jumpBackwards) keyEquivalent:@""] setTarget:jank];
    [original addItem:[NSMenuItem separatorItem]];
    [[original addItemWithTitle:@"Volume Up" action:@selector(increaseVolume) keyEquivalent:@""] setTarget:jank];
    [[original addItemWithTitle:@"Volume Down" action:@selector(decreaseVolume) keyEquivalent:@""] setTarget:jank];
    
    [original addItem:[NSMenuItem separatorItem]];
    [original addItem:mainItem];
    
    return original;
}

- (IBAction)setIconArt:(id)sender {
    NSMenu *menu = [sender menu];
    NSArray *menuArray = [menu itemArray];
    iconArt = (int)[menuArray indexOfObject:sender];
    NSImage *modifiedIcon = [plugin createIconImage:plugin.stockArt :iconArt];
    plugin.modArt = modifiedIcon;
    if (iconArt == 0) {
        [NSApp setApplicationIconImage:nil];
        plugin.modArt = NSApp.applicationIconImage;
    }
//    [NSApp setApplicationIconImage:modifiedIcon];
//    [[NSApp dockTile] display];
    
    NSView* dockContent = NSApp.dockTile.contentView;
    NSImageView *iv = [[NSImageView alloc] initWithFrame:dockContent.frame];
    [iv setImage:plugin.modArt];
    [dockContent setSubviews:@[iv]];
    [NSApp.dockTile display];
    
    [sharedPrefs setInteger:iconArt forKey:@"iconArt"];
    [plugin updateMenu:podcastsPlusMenu];
}

- (IBAction)toggleProgress:(id)sender {
    showProgress = !showProgress;
    [sharedPrefs setBool:showProgress forKey:@"showProgress"];
    if (!showProgress)
        [plugin.progressIndicator setHidden:true];
    [plugin updateMenu:podcastsPlusMenu];
}

- (IBAction)toggleBadges:(id)sender {
    showBadge = !showBadge;
    [sharedPrefs setBool:showBadge forKey:@"showBadge"];
    if (!showBadge)
        [[NSApp dockTile] setBadgeLabel:nil];
    [plugin updateMenu:podcastsPlusMenu];
}

- (NSMenu*)generatePodcastsPlusMenu {
    // Icon art submenu
    NSMenuItem *artMenu = [[NSMenuItem alloc] init];
    [artMenu setTag:101];
    [artMenu setTitle:@"Dock icon art style"];
    NSMenu *submenuArt = [[NSMenu alloc] init];
    [[submenuArt addItemWithTitle:@"None" action:@selector(setIconArt:) keyEquivalent:@""] setTarget:plugin];
    [[submenuArt addItemWithTitle:@"Square" action:@selector(setIconArt:) keyEquivalent:@""] setTarget:plugin];
    [[submenuArt addItemWithTitle:@"Tilted" action:@selector(setIconArt:) keyEquivalent:@""] setTarget:plugin];
    [[submenuArt addItemWithTitle:@"Classic Circular" action:@selector(setIconArt:) keyEquivalent:@""] setTarget:plugin];
    [[submenuArt addItemWithTitle:@"Modern Circular" action:@selector(setIconArt:) keyEquivalent:@""] setTarget:plugin];
    [[submenuArt addItemWithTitle:@"Rounded Corners" action:@selector(setIconArt:) keyEquivalent:@""] setTarget:plugin];
    for (NSMenuItem* item in [submenuArt itemArray]) [item setState:NSControlStateValueOff];
    if (iconArt < submenuArt.itemArray.count) [[[submenuArt itemArray] objectAtIndex:iconArt] setState:NSControlStateValueOn];
    [artMenu setSubmenu:submenuArt];
    
    // podcasts+ submenu
    NSMenu *submenuRoot = [[NSMenu alloc] init];
    [submenuRoot setTitle:@"podcasts+"];
    [submenuRoot addItem:artMenu];
    [submenuRoot addItem:[NSMenuItem separatorItem]];
    [[submenuRoot addItemWithTitle:@"Dock icon play/pause badge" action:@selector(toggleBadges:) keyEquivalent:@""] setTarget:plugin];
    [[[submenuRoot itemArray] objectAtIndex:2] setState:showBadge];
    [[[submenuRoot itemArray] objectAtIndex:2] setTag:97];
    [[submenuRoot addItemWithTitle:@"Dock icon progress bar" action:@selector(toggleProgress:) keyEquivalent:@""] setTarget:plugin];
    [[[submenuRoot itemArray] objectAtIndex:3] setState:showProgress];
    [[[submenuRoot itemArray] objectAtIndex:3] setTag:98];
    [submenuRoot addItem:[NSMenuItem separatorItem]];
    [[submenuRoot addItemWithTitle:@"Restart Podcasts" action:@selector(restartMe) keyEquivalent:@""] setTarget:plugin];
    
    return submenuRoot;
}

- (void)ff {
    [jank jumpForwards];
}

- (void)updateMenu:(NSMenu*)original {
    if (original) {
        NSMenu* updatedMenu = original;
        [[updatedMenu itemWithTag:97] setState:showBadge];
        [[updatedMenu itemWithTag:98] setState:showProgress];
        NSMenuItem* artMenu = [updatedMenu itemWithTag:101];
        NSArray* artSub = [[artMenu submenu] itemArray];
        for (NSMenuItem* obj in artSub) [obj setState:NSControlStateValueOff];
        [[artSub objectAtIndex:iconArt] setState:NSControlStateValueOn];
    }
}

- (void)setMenu {
    NSMenu* mainMenu = [NSApp mainMenu];
    podcastsPlusMenu = [plugin generatePodcastsPlusMenu];
    NSMenuItem* newItem = [[NSMenuItem alloc] initWithTitle:@"Spotify+" action:nil keyEquivalent:@""];
    [newItem setSubmenu:podcastsPlusMenu];
    [mainMenu insertItem:newItem atIndex:5];
}

- (void)restartMe {
    float seconds = 3.0;
    NSTask *task = [[NSTask alloc] init];
    NSMutableArray *args = [NSMutableArray array];
    [args addObject:@"-c"];
    [args addObject:[NSString stringWithFormat:@"sleep %f; open \"%@\"", seconds, [[NSBundle mainBundle] bundlePath]]];
    [task setLaunchPath:@"/bin/sh"];
    [task setArguments:args];
    [task launch];
    [NSApp terminate:nil];
}

@end


ZKSwizzleInterface(wb_NowPlayingUIWindow, NowPlayingUI.Window, NSObject)
@implementation wb_NowPlayingUIWindow

- (void)layoutSubviews {
    NSWindow *w = (NSWindow*)self;
    [self allSubViews:w.contentView :0];
    return ZKOrig(void);
}

- (void)allSubViews:(NSView*)v :(int)depth {
//    NSLog(@"%d - %@", depth, v);
    for (NSView *subview in v.subviews)
        [self allSubViews:subview :depth++];
}

@end

ZKSwizzleInterface(wb_1, MTPlayerItem, NSObject)
@implementation wb_1

- (NSColor *)averageColor:(CGImageRef)test {
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char rgba[4];
    CGContextRef context = CGBitmapContextCreate(rgba, 1, 1, 8, 4, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    CGContextDrawImage(context, CGRectMake(0, 0, 1, 1), test);
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    
    if(rgba[3] > 0) {
        CGFloat alpha = ((CGFloat)rgba[3])/255.0;
        CGFloat multiplier = alpha/255.0;
        return [NSColor colorWithRed:((CGFloat)rgba[0])*multiplier
                               green:((CGFloat)rgba[1])*multiplier
                                blue:((CGFloat)rgba[2])*multiplier
                               alpha:alpha];
    }
    else {
        return [NSColor colorWithRed:((CGFloat)rgba[0])/255.0
                               green:((CGFloat)rgba[1])/255.0
                                blue:((CGFloat)rgba[2])/255.0
                               alpha:((CGFloat)rgba[3])/255.0];
    }
}

- (Boolean)darkColors {
    Boolean result = true;
    
    if (plugin.currentImage) {
        NSImage *back = plugin.currentImage;
        CGImageSourceRef source = CGImageSourceCreateWithData((CFDataRef)[plugin.currentImage TIFFRepresentation], NULL);
        CGImageRef screenGrab = CGImageSourceCreateImageAtIndex(source, 0, NULL);
        CGImageRef croppedImage = CGImageCreateWithImageInRect(screenGrab, CGRectMake(back.size.width, 0, back.size.width, back.size.height/10));
        NSColor *backGround = [self averageColor:croppedImage];
        CFRelease(croppedImage);
        CFRelease(screenGrab);
        double a = 1 - ( 0.299 * backGround.redComponent * 255 + 0.587 * backGround.greenComponent * 255 + 0.114 * backGround.blueComponent * 255)/255;
        if (a < 0.5)
            result = false; // bright colors - black font
        else
            result = true; // dark colors - white font
    }
        
    return result;
}

// Progress bar drawing
- (void)updateActivity:(id)arg1 {
//    if (iconArt > 0) {
//        [NSApp setApplicationIconImage:plugin.modArt];
//    } else {
//        [NSApp setApplicationIconImage:nil];
//    }
    
    NSString *UUID = (NSString*)[self valueForKey:@"episodeUuid"];
    if (![currentUUID isEqualToString:UUID]) {
        NSLog(@"Howdy");
        currentUUID = UUID;
        currentProgress = 0;
    }
    
    NSURL *artwork = (NSURL*)[self valueForKey:@"artworkUrl"];
    if (![artwork isEqualTo:currentArtwork]) {
        // Update current artwork URL
        currentArtwork = artwork;
        
        // Update app icon async
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSImage *podcastIMG = [[NSImage alloc] initWithContentsOfURL:artwork];
            plugin.stockArt = podcastIMG;
            podcastIMG = [plugin createIconImage:podcastIMG :iconArt];
            plugin.modArt = podcastIMG;
            plugin.useDarkProgress = [self darkColors];
            
            if (podcastIMG.size.width > 0) {
                dispatch_async(dispatch_get_main_queue(), ^(){
                    if (iconArt > 0)
                        [NSApp setApplicationIconImage:podcastIMG];
                    else
                        [NSApp setApplicationIconImage:nil];
                });
            }
        });
    }
    
    if (showProgress == true) {
        double duration = [[self valueForKey:@"_duration"] doubleValue];
        double currentTime = [[self valueForKey:@"_playhead"] doubleValue];
        
        float percentComplete = currentTime/duration;
        float change = percentComplete - currentProgress;
//        NSLog(@"change %f", change);
        if (change > 0.01 || change < 0) {
            currentProgress = percentComplete;
//            NSLog(@"currentProgress : %f", percentComplete);
            
            if (plugin.progressIndicator) {
                NSView* dockContent = NSApp.dockTile.contentView;
                NSImageView *iv = [[NSImageView alloc] initWithFrame:dockContent.frame];
                [iv setImage:plugin.modArt];
                [plugin.progressIndicator setHidden:false];
                
                if (plugin.useDarkProgress) {
                    plugin.progressIndicator.progressColor = NSColor.whiteColor;
                    plugin.indiBackground.layer.backgroundColor = NSColor.whiteColor.CGColor;
                } else {
                    plugin.progressIndicator.progressColor = NSColor.blackColor;
                    plugin.indiBackground.layer.backgroundColor = NSColor.blackColor.CGColor;
                    
                }
                
                [plugin.progressIndicator setDoubleValue:currentTime/duration];
                [dockContent setSubviews:@[iv, plugin.indiBackground, plugin.progressIndicator]];
                [NSApp.dockTile display];
            } else {
                NSDockTile *docTile = [[NSApplication sharedApplication] dockTile];
                NSRect indiFrame = NSMakeRect(6, 6, docTile.size.width - 12, 8);
                plugin.progressIndicator = [[AYProgressIndicator alloc] initWithFrame:indiFrame
                                                                        progressColor:[NSColor blackColor]
                                                                           emptyColor:[NSColor lightGrayColor]
                                                                             minValue:0
                                                                             maxValue:1
                                                                         currentValue:0];
                [plugin.progressIndicator setHidden:NO];
                [plugin.progressIndicator setWantsLayer:YES];
                [plugin.progressIndicator.layer setCornerRadius:4];
                
                plugin.indiBackground = [[NSView alloc] init];
                [plugin.indiBackground setFrame:NSMakeRect(5, 5, docTile.size.width - 10, 10)];
                [plugin.indiBackground setHidden:NO];
                [plugin.indiBackground setWantsLayer:YES];
                [plugin.indiBackground.layer setCornerRadius:5];
                [plugin.indiBackground.layer setBackgroundColor:NSColor.clearColor.CGColor];
            }
            
        }
        
        
    } else {
//        if (plugin.progressIndicator) {
//            if (plugin.progressIndicator.hidden == false) {
//                plugin.progressIndicator.hidden = true;
        
        if (NSApp.applicationIconImage != nil) {
            NSView* dockContent = NSApp.dockTile.contentView;
            NSImageView *iv = [[NSImageView alloc] initWithFrame:dockContent.frame];
            [iv setImage:plugin.modArt];
            [dockContent setSubviews:@[iv]];
            [NSApp setApplicationIconImage:nil];
            [NSApp.dockTile display];
        }
        
        
//            }
//        }
    }
    
    ZKOrig(void, arg1);
}

// Some new content loaded 👌
- (void)updateContentItem {
//    NSURL *artwork = (NSURL*)[self valueForKey:@"artworkUrl"];
    
//    NSString *UUID = (NSString*)[self valueForKey:@"episodeUuid"];
//    if (![currentUUID isEqualToString:UUID]) {
//        NSLog(@"Howdy");
//        currentUUID = UUID;
//        currentProgress = 0;
//    }
    
    // New artwork URL
//    if (![artwork isEqualTo:currentArtwork]) {
//        // Update current artwork URL
//        currentArtwork = artwork;
//
//        // Update app icon async
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//            NSImage *podcastIMG = [[NSImage alloc] initWithContentsOfURL:artwork];
//            plugin.stockArt = podcastIMG;
//            podcastIMG = [plugin createIconImage:podcastIMG :iconArt];
//            plugin.modArt = podcastIMG;
//            plugin.useDarkProgress = [self darkColors];
//
//            dispatch_async(dispatch_get_main_queue(), ^(){
//                if (iconArt > 0)
//                    [NSApp setApplicationIconImage:podcastIMG];
//                else
//                    [NSApp setApplicationIconImage:nil];
//            });
//        });
//    }
//    NSLog(@"dank 02! %@ : %@", self, artwork);
    ZKOrig(void);
}

@end

// Handle menubar additions
ZKSwizzleInterface(wb_2, UINSMenuController, NSObject)
@implementation wb_2

- (void)setMainMenuBar:(id)arg1 {
    ZKOrig(void, arg1);
    
    // Add our addition at the end of the menubar
    NSMenu* mainMenu = [NSApp mainMenu];
    NSMenu *podcastsPlusM = [plugin generatePodcastsPlusMenu];
    NSMenuItem* newItem = [[NSMenuItem alloc] initWithTitle:@"Podcasts+" action:nil keyEquivalent:@""];
    [newItem setSubmenu:podcastsPlusM];
    [mainMenu addItem:newItem];
}

@end

// Handle dock menu additions
ZKSwizzleInterface(wb_3, UINSApplicationDelegate, NSObject)
@implementation wb_3

- (id)applicationDockMenu:(id)arg1 {
    NSMenu* result = ZKOrig(id, arg1);
    result = [plugin dockaddpodcastsPlus:result];
    return result;
}

@end
