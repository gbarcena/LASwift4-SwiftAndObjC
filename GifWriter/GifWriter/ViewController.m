//
//  ViewController.m
//  GifWriter
//
//  Created by Gustavo Barcena on 9/28/14.
//  Copyright (c) 2014 GDB. All rights reserved.
//

@import MobileCoreServices;
@import ImageIO;
@import MessageUI;

#import "ViewController.h"
#import "YLGIFImage.h"
#import "YLImageView.h"
#import "GifWriter-Swift.h"

static void * XXContext = &XXContext;
NSInteger const ViewControllerCellImageViewTag = 1000;

@interface ViewController ()  <UICollectionViewDataSource, UICollectionViewDelegate, MFMailComposeViewControllerDelegate>
@property (weak, nonatomic) IBOutlet YLImageView *imageView;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *label;
@property (strong, nonatomic) NSMutableArray *images;
@property (nonatomic) CGImageDestinationRef destination;
@property (nonatomic) float progress;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.images = @[].mutableCopy;
    for (int i = 1; i <= 7; i++) {
        NSString *imageName = [NSString stringWithFormat:@"ninenine_%d", i];
        [self.images addObject:[UIImage imageNamed:imageName]];
    }
    
    [self addObserver:self
           forKeyPath:@"progress"
              options:NSKeyValueObservingOptionNew
              context:XXContext];
}

#pragma mark - UICollectionViewMethods

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.images.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cellIdentifier"
                                                                           forIndexPath:indexPath];
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:ViewControllerCellImageViewTag];
    if (!imageView) {
        imageView = [[UIImageView alloc] initWithFrame:cell.bounds];
        [cell addSubview:imageView];
    }
    imageView.image = self.images[indexPath.row];
    cell.layer.borderColor = [UIColor whiteColor].CGColor;
    cell.layer.borderWidth = 1.0;
    return cell;
}

-(IBAction)makeGIFPressed:(id)sender
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [self makeGIF];
        self.imageView.image = [YLGIFImage imageWithContentsOfFile:[self filePath]];
    });
}

#pragma mark - GIF Generation

-(void)makeGIF
{
    NSInteger frameCount = self.images.count;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.label.text = @"Start Writing";
    });
    [self beginWrite:frameCount];
    for ( int i = 0; i < frameCount; i++ ) {
        UIImage *newImage = self.images[i];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.progress = (float)i/frameCount;
        });
        [NSThread sleepForTimeInterval:0.25];
        [self writeImage:newImage];
    }
    [self endWrite];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.progress = 1;
        self.label.text = @"End Writing";
    });
}

#pragma mark - GIF File properties

// properties to be applied to each frame... such as setting delay time & color map.
- (NSDictionary *)framePropertiesWithFrameDelay:(NSTimeInterval)delay {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:5];
    [dict setObject:@(delay) forKey:(NSString *)kCGImagePropertyGIFDelayTime];
    
    NSDictionary *frameProps = [ NSDictionary dictionaryWithObject: dict
                                                            forKey: (NSString*) kCGImagePropertyGIFDictionary ];
    
    return frameProps;
}

// properties to apply to entire GIF... such as loop count (0 = infinite) and no global color map.
- (NSDictionary *)gifProperties {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:5];
    
    //[dict setObject:[NSNumber numberWithBool:NO] forKey:(NSString *)kCGImagePropertyGIFHasGlobalColorMap];
    [dict setObject:[NSNumber numberWithInt:0] forKey:(NSString *)kCGImagePropertyGIFLoopCount];
    
    NSDictionary *gifProps = [ NSDictionary dictionaryWithObject: dict
                                                          forKey: (NSString*) kCGImagePropertyGIFDictionary ];
    
    return gifProps;
}

#pragma mark - GIF File Location Methods

-(NSString *)filePath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *cacheDirectoryURL = [paths objectAtIndex:0];
    NSString *path = [cacheDirectoryURL  stringByAppendingPathComponent:@"gifs"];
    NSError *error;
    [[NSFileManager defaultManager] createDirectoryAtPath:path
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:&error];
    NSString *fileName = [NSString stringWithFormat:@"ninenine.gif"];
    NSString *filePath = [path stringByAppendingPathComponent:fileName];
    return filePath;
}

-(NSURL *)fileLocation
{
    NSString *filePath = [self filePath];
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    return fileURL;
}

#pragma mark - GIF writing Methods

-(void)beginWrite:(NSUInteger)frameCount
{
    NSUInteger kFrameCount = frameCount;
    NSDictionary *fileProperties = [self gifProperties];
    NSURL *fileURL = [self fileLocation];
    
    self.destination = CGImageDestinationCreateWithURL((__bridge CFURLRef)fileURL, kUTTypeGIF, kFrameCount, NULL);
    CGImageDestinationSetProperties(self.destination, (__bridge CFDictionaryRef)fileProperties);
}

-(void)writeImage:(UIImage *)image
{
    NSTimeInterval frameDelay = .25;
    NSDictionary *frameProperties = [self framePropertiesWithFrameDelay:frameDelay];
    @autoreleasepool {
        CGImageRef imageRef  = image.CGImage;
        CGImageDestinationAddImage(self.destination, imageRef, (__bridge CFDictionaryRef)frameProperties);
    }
}

-(void)endWrite
{
    if (!CGImageDestinationFinalize(self.destination)) {
        NSLog(@"failed to finalize image destination");
    }
    CFRelease(self.destination);
}

#pragma mark - MFMailComposeView Methods

-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - KVC

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (context == XXContext) {
        if ([keyPath isEqualToString:@"progress"]) {
            self.progressView.progress = self.progress;
        }
    }
}

@end
 