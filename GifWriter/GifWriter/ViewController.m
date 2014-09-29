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

@interface ViewController ()  <UICollectionViewDataSource, UICollectionViewDelegate, MFMailComposeViewControllerDelegate, JJGIFWriterDelegate>
@property (weak, nonatomic) IBOutlet YLImageView *imageView;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *label;
@property (strong, nonatomic) NSMutableArray *images;
@property (strong, nonatomic) JJGIFWriter *gifWriter;

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
    
    self.gifWriter = [[JJGIFWriter alloc] initWithImages:self.images
                                          destinationURL:[self fileLocation]];
    self.gifWriter.delegate = self;
    
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
        [self.gifWriter makeGIF];
        self.imageView.image = [YLGIFImage imageWithContentsOfFile:[self filePath]];
    });
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
            self.progressView.progress = self.gifWriter.progress;
        }
    }
}

#pragma mark - JJGIFWriterDelegate Methods

-(void)didStartWritingGIF:(JJGIFWriter *)writer
{
    self.label.text = @"Start Writing";
}

-(void)didEndWritingGIF:(JJGIFWriter *)writer
{
    self.label.text = @"End Writing";
}

@end
 