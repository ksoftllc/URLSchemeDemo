//
//  ViewController.m
//  UrlSchemeDemo
//
//  Created by Chuck Krutsinger on 6/21/17.
//  Copyright © 2017 Countermind Ventures, LLC. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UILabel *miclinicInstalledLabel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSURL* miclinicUrl = [NSURL URLWithString:@"miclinic://"];
    BOOL canOpenMiclinic = [[UIApplication sharedApplication] canOpenURL:miclinicUrl];
    
    if (canOpenMiclinic)
    {
        _miclinicInstalledLabel.text = @"YES";
        _miclinicInstalledLabel.textColor = [UIColor greenColor];
    }
    else
    {
        _miclinicInstalledLabel.text = @"NO";
        _miclinicInstalledLabel.textColor = [UIColor redColor];
    }

}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
