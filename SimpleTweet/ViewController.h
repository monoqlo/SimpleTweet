//
//  ViewController.h
//  SimpleTweet
//
//  Created by 米山 隆貴 on 12/02/12.
//  Copyright (c) 2012年 筑波大学. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController<UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property(nonatomic, strong)UIImage *tImage;
@property(nonatomic, strong)NSArray *tweetArray;

- (IBAction)sendTweet:(id)sender;
- (IBAction)showCameraSheet;
- (IBAction)reloadImage:(id)sender;
- (IBAction)deleteImage:(id)sender;

@end

@interface UIView(IWantToGetRejected);

+ (void) setAnimationPosition:(CGPoint)p;

@end
