//
//  CTestClassViewController.h
//  test22
//
//  Created by weiqiang xu on 11/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EAGLView.h"
@interface CTestClassViewController : UIViewController
{
    EAGLView* glView;
    UIToolbar* toolbar;
    UIProgressView* progressView;
    IBOutlet UISlider *brightslider;
    IBOutlet UISlider *contrastslider;
}
- (IBAction)BrightnessValuechanged:(id)sender;
- (IBAction)ContrastValueChanged:(id)sender;
@property (nonatomic,retain) IBOutlet EAGLView* glView;
@property (nonatomic,retain) IBOutlet UIToolbar* toolbar;
@property (nonatomic,retain) IBOutlet UIProgressView* progressView;
@end
