//
//  LightViewController.h
//  DoodleNumbers
//
//  Created by Yury Lasty on 6/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GameKit/GameKit.h>

@protocol OrientationDelegate 
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;
@end

@interface LightViewController : UIViewController <GKAchievementViewControllerDelegate, GKLeaderboardViewControllerDelegate> {
	id<OrientationDelegate> _orientationDelegate;
}

+(LightViewController*)sharedInstance;
-(void)stop;
-(void)start;
-(void)showLeaderboard;
-(void)showAchievements;
@property (nonatomic,retain) id<OrientationDelegate> orientationDelegate;

@end
