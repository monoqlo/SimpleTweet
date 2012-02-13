//
//  ViewController.m
//  SimpleTweet
//
//  Created by 米山 隆貴 on 12/02/12.
//  Copyright (c) 2012年 筑波大学. All rights reserved.
//

#import "ViewController.h"
#import <Twitter/TWTweetComposeViewController.h>
#import <Twitter/TWRequest.h>
#import <Accounts/Accounts.h>

@implementation ViewController {
    IBOutlet UIBarButtonItem *sendButton;
    IBOutlet UIBarButtonItem *cameraButton;
    IBOutlet UIImageView *previewImageView;
    IBOutlet UIBarButtonItem *reloadButton;
    IBOutlet UIBarButtonItem *deleteImageButton;
    IBOutlet UIActivityIndicatorView *indicator;
}

@synthesize tImage;
@synthesize tweetArray;

#pragma mark -
- (void)getTweet
{
    deleteImageButton.enabled = NO;
    self.tweetArray = nil;
    [indicator startAnimating];
    
    //  First, we need to obtain the account instance for the user's Twitter account
    ACAccountStore *store = [[ACAccountStore alloc] init];
    ACAccountType *twitterAccountType = 
    [store accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    //  Request access from the user for access to his Twitter accounts
    [store requestAccessToAccountsWithType:twitterAccountType 
                     withCompletionHandler:^(BOOL granted, NSError *error) {
                         if (!granted) {
                             // The user rejected your request 
                             NSLog(@"User rejected access to his account.");
                         } 
                         else {
                             // Grab the available accounts
                             NSArray *twitterAccounts = 
                             [store accountsWithAccountType:twitterAccountType];
                             
                             if ([twitterAccounts count] > 0) {
                                 // Use the first account for simplicity 
                                 ACAccount *account = [twitterAccounts objectAtIndex:0];
                                 
                                 // Now make an authenticated request to our endpoint
                                 NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
                                 [params setObject:@"1" forKey:@"include_entities"];
                                 
                                 //  The endpoint that we wish to call
                                 NSURL *url = 
                                 [NSURL 
                                  URLWithString:@"http://api.twitter.com/1/statuses/home_timeline.json"];
                                 
                                 //  Build the request with our parameter 
                                 TWRequest *request = 
                                 [[TWRequest alloc] initWithURL:url 
                                                     parameters:params 
                                                  requestMethod:TWRequestMethodGET];
                                 
                                 // Attach the account object to this request
                                 [request setAccount:account];
                                 
                                 [request performRequestWithHandler:
                                  ^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                                      if (!responseData) {
                                          // inspect the contents of error 
                                          NSLog(@"%@", error);
                                      } 
                                      else {
                                          NSError *jsonError;
                                          NSArray *timeline = 
                                          [NSJSONSerialization 
                                           JSONObjectWithData:responseData 
                                           options:NSJSONReadingMutableLeaves 
                                           error:&jsonError];            
                                          if (timeline) {                          
                                              // at this point, we have an object that we can parse
                                              NSInteger index = rand()%20;
                                              
                                              self.tweetArray = timeline;
                                              NSData *dt = [NSData dataWithContentsOfURL:
                                                            [NSURL URLWithString:[[[self.tweetArray objectAtIndex:index] objectForKey:@"user"]objectForKey:@"profile_image_url"]]];
                                              UIImage *img = [[UIImage alloc] initWithData:dt];
                                              previewImageView.image = img;
                                              self.tImage = img;
                                              
                                              deleteImageButton.enabled = YES;
                                              
                                              [indicator stopAnimating];
                                          } 
                                          else { 
                                              // inspect the contents of jsonError
                                              NSLog(@"%@", jsonError);
                                          }
                                      }
                                  }];
                                 
                             } // if ([twitterAccounts count] > 0)
                         } // if (granted) 
                     }];
}

#pragma mark - IBActions
- (IBAction)reloadImage:(id)sender
{
    [self getTweet];
}

- (IBAction)deleteImage:(id)sender
{
    if (self.tImage) {
        self.tImage = nil;
        //previewImageView.image = nil;
        [UIView beginAnimations:@"suck" context:NULL];
        [UIView setAnimationDuration:1.0f];
        [UIView setAnimationTransition:103 forView:previewImageView cache:YES];
        [UIView setAnimationPosition:CGPointMake(260, 450)]; // どこを吸い込まれる中心点にするかの設定
        previewImageView.image = nil;
        [UIView commitAnimations];
        
        deleteImageButton.enabled = NO;
    }
}

- (IBAction)sendTweet:(id)sender
{
    // ビューコントローラの初期化
    TWTweetComposeViewController *tweetViewController = [[TWTweetComposeViewController alloc] init];
    
    // 送信文字列を設定
    //[tweetViewController setInitialText:@"iOS5.0 Twitter送信テスト"];
    
    // 送信画像を設定
    if (self.tImage) {
        [tweetViewController addImage:self.tImage];
    }
    
    // イベントハンドラ定義
    tweetViewController.completionHandler = ^(TWTweetComposeViewControllerResult res) {
        if (res == TWTweetComposeViewControllerResultCancelled) {
            NSLog(@"キャンセル");
        }
        else if (res == TWTweetComposeViewControllerResultDone) {
            NSLog(@"成功");
        }
        [self dismissModalViewControllerAnimated:YES];
    };
    
    // 送信View表示
    [self presentModalViewController:tweetViewController animated:YES];
}

- (IBAction)showCameraSheet
{
    // アクションシートを作る
    UIActionSheet*  sheet;
    sheet = [[UIActionSheet alloc] 
             initWithTitle:@"Select Soruce Type" 
             delegate:self
             cancelButtonTitle:@"Cancel" 
             destructiveButtonTitle:nil 
             otherButtonTitles:@"Photo Library", @"Camera", nil];
    
    // アクションシートを表示する
    [sheet showInView:self.view];
}

#pragma mark - UIActionSheet Delegate 
- (void)actionSheet:(UIActionSheet*)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // ソースタイプを決定する
    UIImagePickerControllerSourceType sourceType = 0;
    switch (buttonIndex) {
        case 0: {
            sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            break;
        }
        case 1: {
            sourceType = UIImagePickerControllerSourceTypeCamera;
            break;
        }
        case 2: {
            return;
        }
    }
    
    // 使用可能かどうかチェックする
    if (![UIImagePickerController isSourceTypeAvailable:sourceType]) {
        return;
    }
    
    // イメージピッカーを作る
    UIImagePickerController*    imagePicker;
    imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.sourceType = sourceType;
    imagePicker.delegate = self;
    
    // イメージピッカーを表示する
    [self presentModalViewController:imagePicker animated:YES];
}

#pragma mark - ImagePickerViewContoroller Delegate 
- (void)imagePickerController:(UIImagePickerController*)picker 
        didFinishPickingImage:(UIImage*)image 
                  editingInfo:(NSDictionary*)editingInfo
{
    // 投稿用の画像を用意
    self.tImage = image;
    previewImageView.image = image;
    deleteImageButton.enabled = YES;
    
    // イメージピッカーを隠す
    [self dismissModalViewControllerAnimated:YES];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController*)picker
{
    // イメージピッカーを隠す
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - MemoryWarning

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    [self getTweet];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end
