//
//  CWViewController.h
//  CathedralWindow
//
//  Created by Hendrik Demmer on 9/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

#import "CWWindow.h"

@interface CWViewController : GLKViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, retain) NSArray * windows;
@property (weak, nonatomic) IBOutlet UIImageView *busyImageView;

@end
