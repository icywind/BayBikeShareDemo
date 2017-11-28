//
//  ViewController.h
//  bikemap
//
//  Created by Rickie on 11/21/17.
//  Copyright © 2017 Rickie. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>


@interface BikeShareMapViewController : UIViewController <CLLocationManagerDelegate, MKMapViewDelegate>
{
    CLLocationManager *objLocationManager;
}

- (IBAction)repositionTapped:(id)sender;
- (IBAction)refreshTapped:(id)sender;
- (IBAction)routeButtonTapped:(id)sender;
- (IBAction)startTextEditDidEnd:(id)sender;
- (IBAction)startTextActionTriggered:(id)sender;
- (IBAction)startTextValueChanged:(id)sender;
- (IBAction)destTextEditStarted:(id)sender;
- (IBAction)destTextEditDidEnd:(id)sender;
- (IBAction)destTextActionTriggered:(id)sender;

- (IBAction)startSliderValueChanged:(id)sender;
- (IBAction)destSliderValueChanged:(id)sender;
- (IBAction)confirmButtonPressed:(id)sender;
- (IBAction)cancelInputPressed:(id)sender;

@property (strong, nonatomic) IBOutlet UIView *routeView;
@property (strong, nonatomic) IBOutlet UITextField *startTextfield;
@property (strong, nonatomic) IBOutlet UITextField *destRextfield;
@property (strong, nonatomic) IBOutlet UISlider *startDistSlider;
@property (strong, nonatomic) IBOutlet UISlider *destDistSlider;
@property (strong, nonatomic) IBOutlet UILabel *startSliderValueLabel;
@property (strong, nonatomic) IBOutlet UILabel *destSliderValueLabel;
@property (strong, nonatomic) IBOutlet UIButton *confirmButton;


@end;
