//
//  CWViewController.h
//  CathedralWindow
//
//  Created by Hendrik Demmer on 9/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

@interface CWViewController : GLKViewController

@property (nonatomic, retain) NSArray * windows;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
- (IBAction)donePressed:(id)sender;
- (IBAction)cameraPressed:(id)sender;
- (IBAction)actionPressed:(id)sender;

@end
