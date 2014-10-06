//
//  ViewController.h
//  UDPTester
//
//  Created by davide on 03/10/14.
//  Copyright (c) 2014 NT. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIButton *sendButton;
@property (weak, nonatomic) IBOutlet UIButton *receiveButton;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (weak, nonatomic) IBOutlet UIWebView *webView;

- (IBAction)sendButtonTapped:(id)sender;
- (IBAction)receiveButtonTapped:(id)sender;
- (IBAction)segmentedControlValueChanged:(UISegmentedControl*)sender;

@end

