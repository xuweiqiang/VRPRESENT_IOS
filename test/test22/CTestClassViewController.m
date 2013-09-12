//
//  CTestClassViewController.m
//  test22
//
//  Created by weiqiang xu on 11/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "CTestClassViewController.h"

@implementation CTestClassViewController

@synthesize glView;
@synthesize toolbar;
@synthesize progressView;


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    [super viewDidLoad];
    glView.progressView = self.progressView;
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload
{
    [brightslider release];
    brightslider = nil;
    [contrastslider release];
    contrastslider = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [glView setAnimationFrameInterval:2];
    [glView startAnimation];
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [glView stopAnimation];
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

- (void)dealloc {
    [brightslider release];
    [contrastslider release];
    [super dealloc];
}
- (IBAction)BrightnessValuechanged:(id)sender {
    [glView setBrightness:brightslider.value];
}

- (IBAction)ContrastValueChanged:(id)sender {
    [glView setContrast:contrastslider.value];
}
@end
