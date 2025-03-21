//
//  ACDownload.m
//  ACThreads
//
//  Created by Abdullah on 23/03/1446 AH.
//

#import "ACDownload.h"
#import <Photos/Photos.h>

static void Alert(float Timer,id Message, ...) {

    va_list args;
    va_start(args, Message);
    NSString *Formated = [[NSString alloc] initWithFormat:Message arguments:args];
    va_end(args);

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Timer * NSEC_PER_SEC), dispatch_get_main_queue(), ^{

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:Formated message:nil preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction *action = [UIAlertAction actionWithTitle:@"確定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        }];

        [alert addAction:action];

        [topMostController() presentViewController:alert animated:true completion:nil];
 
    });


}

@implementation ACDownload

+ (void)downloadMediaFromURL:(NSURL *)mediaURL {
    // 確認檔案類型（圖片或影片）
    NSString *fileExtension = [mediaURL pathExtension];
    
    // 創建會話來下載數據
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithURL:mediaURL
                                                       completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        if (!error) {
            NSData *data = [NSData dataWithContentsOfURL:location];
            
            if ([self isImage:fileExtension]) {
                // 如果是圖片
                UIImage *image = [UIImage imageWithData:data];
                [self saveImageToCameraRoll:image];
            } else if ([self isVideo:fileExtension]) {
                // 如果是影片
                NSURL *fileURL = [self saveVideoToTemporaryFile:data];
                [self saveVideoToCameraRoll:fileURL];
            }
        } else {
            NSLog(@"下載錯誤: %@", error.localizedDescription);
        }
    }];
    
    [downloadTask resume];
}

#pragma mark - Helper Methods

// 確認是否為圖片
+ (BOOL)isImage:(NSString *)fileExtension {
    NSArray *imageExtensions = @[@"png", @"jpg", @"jpeg", @"gif", @"bmp"];
    return [imageExtensions containsObject:[fileExtension lowercaseString]];
}

// 確認是否為影片
+ (BOOL)isVideo:(NSString *)fileExtension {
    NSArray *videoExtensions = @[@"mp4", @"mov", @"avi", @"m4v"];
    return [videoExtensions containsObject:[fileExtension lowercaseString]];
}

// 儲存圖片到相簿
+ (void)saveImageToCameraRoll:(UIImage *)image {
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        [PHAssetChangeRequest creationRequestForAssetFromImage:image];
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        if (success) {
            Alert(0.1, [NSString stringWithFormat:@"圖片已成功儲存"]);
        } else {
            NSLog(@"圖片儲存失敗: %@", error.localizedDescription);
        }
    }];
}

// 儲存影片到暫存檔案
+ (NSURL *)saveVideoToTemporaryFile:(NSData *)videoData {
    NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"ACThreads.mp4"];
    NSURL *tempURL = [NSURL fileURLWithPath:tempPath];
    [videoData writeToURL:tempURL atomically:YES];
    return tempURL;
}

// 儲存影片到相簿
+ (void)saveVideoToCameraRoll:(NSURL *)videoURL {
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:videoURL];
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        if (success) {
            Alert(0.1, [NSString stringWithFormat:@"影片已成功儲存"]);
        } else {
            NSLog(@"影片儲存失敗: %@", error.localizedDescription);
        }
    }];
}

@end

