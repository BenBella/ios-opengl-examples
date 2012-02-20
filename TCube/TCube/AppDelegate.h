//
//  AppDelegate.h
//  HelloOpenGL
//
//  Created by Lukáš Andrlík on 2/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OpenGLView.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>
{
    OpenGLView * _glView;
}
@property (nonatomic, retain) IBOutlet OpenGLView * glView;
@property (nonatomic, retain) IBOutlet UIWindow * window;

@end
