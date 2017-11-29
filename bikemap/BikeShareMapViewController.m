//
//  BikeShareMapViewController.m
//    This class serves as the main view controller for the Bay Area Ride Share Planner
//
//  Created by Rickie on 11/21/17.
//  Copyright © 2017 Rickie. All rights reserved.
//

#import <MapKit/MapKit.h>
#import <dispatch/dispatch.h>

#import "BikeShareMapViewController.h"
#import "BikeLocation.h"
#import "LocationSelectionViewController.h"

#define StationInfoURL @"https://feeds.bayareabikeshare.com/stations/stations.json"

// Anotation titles
#define StartTitle @"My Origin"
#define DestTitle  @"My Destination"

#define ID_REG_LOCATION @"Reg Location"
#define ID_GREEN_LOCATION @"Green Location"
#define ID_RED_LOCATION @"Red Location"
#define ID_ORIGIN @"Start Location"
#define ID_DESTINATION @"Destination Location"
#define SEGUE_SELECTION @"GotoSelection"

// Conversions
#define METERS_PER_MILE 1609.344
#define ToRadian(x) ((x) * M_PI/180)
#define ToDegrees(x) ((x) * 180/M_PI)

@interface BikeShareMapViewController ()
@property (strong, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) NSArray * stationList;
@property (strong, nonatomic) MKPolyline * routeOverlay;
@end

typedef enum {
    BS_STARTUP,
    BS_INITIALIZED,
    BS_PLANCONFIRMED   // user pressed confirm with valid start and end points
} BikeShareViewState;


/*==============================================================================
 *    Class View Controller Implementation
 *==============================================================================
 */
@implementation BikeShareMapViewController

@synthesize mapView;

MKPlacemark * originPoint;
MKPlacemark * destinationPoint;
BikeShareViewState myState;
BikeLocation * selectedBikeLocation;
double latitude_UserLocation, longitude_UserLocation;
NSString * title;

- (void) loadUserLocation
{
    objLocationManager = [[CLLocationManager alloc] init];
    objLocationManager.delegate = self;
    objLocationManager.distanceFilter = kCLDistanceFilterNone;
    objLocationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    if ([objLocationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [objLocationManager requestWhenInUseAuthorization];
    }
    [objLocationManager startUpdatingLocation];
}

#pragma mark Delegate functions

- (MKAnnotationView *)mapView:(MKMapView *)theMapView viewForAnnotation:(id <MKAnnotation>)annotation {
    
    NSString * viewId;
    int check = -1;
    
    if ([annotation isKindOfClass:[BikeLocation class]]) {
        if (myState == BS_PLANCONFIRMED) {
            check = [self checkStation:annotation];
            if (check == 0 || check == 2) {
                viewId = ID_GREEN_LOCATION;
            } else if (check == 1 || check == 3) {
                viewId = ID_RED_LOCATION;
            } else {
                return nil;
            }
        } else {
            viewId = ID_REG_LOCATION;
        }
    } else {
        if ([annotation.title isEqualToString:StartTitle]) {
            viewId = ID_ORIGIN;
        } else if ([annotation.title isEqualToString:DestTitle]) {
            viewId = ID_DESTINATION;
        } else {
            // in case of something weird happens
            NSLog(@"Unknow annotation, title = %@", annotation.title);
            return nil;
        }
    }
    
    MKAnnotationView *annotationView = (MKAnnotationView *) [theMapView dequeueReusableAnnotationViewWithIdentifier:viewId];
    
    if (annotationView == nil) {
        annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation
                                                      reuseIdentifier:viewId];
        annotationView.enabled = YES;
        annotationView.canShowCallout = YES;
        
        if ([viewId isEqual: ID_REG_LOCATION] || check == 0 || check == 1) {
            UIButton *embedButton = [UIButton buttonWithType:UIButtonTypeSystem];
            [embedButton addTarget:self action:@selector(annoButtonActionOnStartPoint:) forControlEvents:UIControlEventTouchUpInside];
            annotationView.detailCalloutAccessoryView = embedButton;
            [embedButton setTitle:@"Direction to Here" forState:UIControlStateNormal];
        } else if (check == 2 || check == 3) {
            UIButton *embedButton = [UIButton buttonWithType:UIButtonTypeSystem];
            [embedButton addTarget:self action:@selector(annoButtonActionOnEndPoint:) forControlEvents:UIControlEventTouchUpInside];
            annotationView.detailCalloutAccessoryView = embedButton;
            [embedButton setTitle:@"Direction from Here" forState:UIControlStateNormal];
        }
    } else {
        annotationView.annotation = annotation;
    }
    
    annotationView.image = [self getAnnationImage:viewId];
    return annotationView;
}

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations __OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_6_0)
{
    CLLocation *newLocation = [locations objectAtIndex:0];
    latitude_UserLocation = newLocation.coordinate.latitude;
    longitude_UserLocation = newLocation.coordinate.longitude;
    // [objLocationManager stopUpdatingLocation];
    // TBD : Maybe there should be a strategy to stop the location update, but it is not totally needed for the requirement for now.
    
    
    // Only reload and center map at startup
    if (myState == BS_STARTUP) {
        [self loadInitialMapView];
        [self obtainData:StationInfoURL];
        originPoint = [[MKPlacemark alloc] initWithCoordinate:CLLocationCoordinate2DMake(latitude_UserLocation, longitude_UserLocation) ];
        myState = BS_INITIALIZED;
    }
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error
{
    //   [objLocationManager stopUpdatingLocation];
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
    MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc] initWithPolyline:overlay];
    renderer.strokeColor = [UIColor redColor];
    renderer.lineWidth = 4.0;
    return  renderer;
}


- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    // here we illustrate how to detect which annotation type was clicked on for its callout
    id <MKAnnotation> annotation = [view annotation];
    if ([annotation isKindOfClass:[BikeLocation class]])
    {
        selectedBikeLocation = annotation;
    }
}

// function to handle annotation callout action, made for Starting Point
- (void)annoButtonActionOnStartPoint:(id)sender {
    if (selectedBikeLocation != nil) {
        NSDictionary *launchOptions = @{MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeWalking};

        MKMapItem *startPositionMapitem = originPoint != nil? [[MKMapItem alloc] initWithPlacemark:originPoint] : [MKMapItem mapItemForCurrentLocation];
        
        [MKMapItem openMapsWithItems:@[startPositionMapitem, selectedBikeLocation.mapItem]
                       launchOptions:launchOptions];
        
    }
}

// function to handle annotation callout action, made for Destination Point
- (void)annoButtonActionOnEndPoint:(id)sender {
    if (selectedBikeLocation != nil) {
        NSDictionary *launchOptions = @{MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeWalking};
        
        MKMapItem *endPositionMapitem = [[MKMapItem alloc] initWithPlacemark:destinationPoint];
        
        [MKMapItem openMapsWithItems:@[selectedBikeLocation.mapItem, endPositionMapitem]
                       launchOptions:launchOptions];
        
    }
}


# pragma mark - View lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];
    myState = BS_STARTUP;
    
    // Set up gesture recognizer to dismiss keyboard when user tap outside the text fields
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    
    // Setup Slider and show values
    [_startSliderValueLabel setText:[NSString stringWithFormat:@"%1.2f miles", [_startDistSlider value]]];
    [_destSliderValueLabel setText:[NSString stringWithFormat:@"%1.2f miles", [_startDistSlider value]]];
    [self.view addGestureRecognizer:tap];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadUserLocation];
    [_confirmButton setEnabled:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

# pragma mark - From Data to view
- (void)plotBikePositions:(NSArray *) bikeStationList {
    for (id<MKAnnotation> annotation in mapView.annotations) {
        if ([annotation isKindOfClass:[BikeLocation class]]) {
            [mapView removeAnnotation:annotation];
        }
    }
    for (NSDictionary *station in bikeStationList) {
        BikeLocation *annotation = [[BikeLocation alloc] initWithData:station];
        if (myState == BS_PLANCONFIRMED) {
            int check = [self checkStation:annotation];
            if (check != -1) {
                [mapView addAnnotation:annotation];
            }
        } else {
            [mapView addAnnotation:annotation];
        }
    }
}

- (NSDictionary*) getDataFromJSONData:(NSData*)data {
    NSError * error=nil;
    if (data != nil) {
        // NSArray * parsedData = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        //JSONDecoder *jsonKitDecoder = [JSONDecoder decoder];
        //NSDictionary *items = [jsonKitDecoder objectWithData:data];
        NSDictionary * items = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
        // TODO handle error
        return items;
    } else {
        return nil;
    }
}

- (void) obtainData:(NSString*) dataURL {
    NSError *error;
    NSData *data = [NSData dataWithContentsOfURL: [NSURL URLWithString:dataURL] options:NSDataReadingUncached error:&error];
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
    _stationList = [json objectForKey:@"stationBeanList"];
    //NSLog(@"json: %@", list);
    [self plotBikePositions:_stationList];
}

#pragma mark - UI Controls
- (IBAction)refreshTapped:(id)sender {
    [self obtainData:StationInfoURL];
}

- (IBAction)routeButtonTapped:(id)sender {
    [_routeView setHidden:!_routeView.isHidden];
    [_startTextfield setEnabled:YES];
    [_destRextfield setEnabled:YES];
    
    if ([_routeView isHidden]) {
        [self dismissKeyboard];
    }
}

- (IBAction)startTextEditDidEnd:(id)sender {
    [self dismissKeyboard];
}

// User finished input and hit "Search" on the keyboard
- (IBAction)startTextActionTriggered:(id)sender {
}

- (IBAction)startTextEditDidBegin:(id)sender {
    originPoint = nil;
    [self performSegueWithIdentifier:SEGUE_SELECTION sender:sender];
}

- (IBAction)destTextEditStarted:(id)sender {
    destinationPoint = nil;
    [self performSegueWithIdentifier:SEGUE_SELECTION sender:sender];
}

// This will get called too before the view appears
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:SEGUE_SELECTION]) {
        
        // Get destination view
        LocationSelectionViewController *vc = (LocationSelectionViewController*)[segue destinationViewController];
        
        BOOL isStartPoint = (sender == _startTextfield);
        NSString * locTitle = isStartPoint?@"Start Point":@"Destination";
        // Pass the information to your destination view
        [vc initWithUserLocation:CLLocationCoordinate2DMake(latitude_UserLocation, longitude_UserLocation)
                           title:locTitle
                    userLocation:isStartPoint
                        Callback:^(MKPlacemark *placeMake) {
                            if (isStartPoint) {
                                originPoint = placeMake;
                                [_startTextfield setText:placeMake.name];
                            } else {
                                destinationPoint = placeMake;
                                [_destRextfield setText:placeMake.name];
                            }
                            
                            if (originPoint != nil && destinationPoint != nil) {
                                dispatch_async(dispatch_get_main_queue(), ^(void) {
                                    [_confirmButton setEnabled:YES];
                                });
                            }
                        }
        ];
    }
}

- (IBAction)startTextValueChanged:(id)sender {
    originPoint = nil;
    [_confirmButton setEnabled:NO];
}

- (IBAction)repositionTapped:(id)sender {
    [self loadInitialMapView];
}

- (IBAction)destTextEditDidEnd:(id)sender {
    [self dismissKeyboard];
}

- (IBAction)destTextActionTriggered:(id)sender {
    [self dismissKeyboard];
}

- (IBAction)startSliderValueChanged:(id)sender {
    [_startSliderValueLabel setText:[NSString stringWithFormat:@"%1.2f miles", [(UISlider*)sender value]]];
}

- (IBAction)destSliderValueChanged:(id)sender {
    [_destSliderValueLabel setText:[NSString stringWithFormat:@"%1.2f miles", [(UISlider*)sender value]]];
}

- (IBAction)confirmButtonPressed:(id)sender {
    [_routeView setHidden:YES];
    
    myState = BS_PLANCONFIRMED;
    
    // Clear current annotations
    [self ClearPoints];
    
    // Plot the Start and End mark
    if ([_startTextfield.text isEqualToString:CURRENT_LOCATION_TEXT]) {
        CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(latitude_UserLocation, longitude_UserLocation);
        MKPointAnnotation *point  = [MKPointAnnotation new];
        point.coordinate = coord;
        point.title = StartTitle;
        [mapView addAnnotation:point];
        originPoint = [[MKPlacemark alloc] initWithCoordinate:coord];
    }
    
    if (originPoint != nil) {
        [mapView addAnnotation:[self GetAnnotation:originPoint withTitle:StartTitle]];
    }
    
    if (destinationPoint != nil) {
        [mapView addAnnotation:[self GetAnnotation:destinationPoint withTitle:DestTitle]];
    }
    
    [self obtainData:StationInfoURL];
    [self GetDirection];
}

- (IBAction)cancelInputPressed:(id)sender {
    [_startTextfield setEnabled:YES];
    [_startTextfield setText:CURRENT_LOCATION_TEXT];
    originPoint = [[MKPlacemark alloc] initWithCoordinate:CLLocationCoordinate2DMake(latitude_UserLocation, longitude_UserLocation) ];
    [_destRextfield setEnabled:YES];
    [_destRextfield setText:@""];
    destinationPoint = nil;
    [_confirmButton setEnabled:NO];
    [self dismissKeyboard];
}

-(void)dismissKeyboard
{
    [self.view endEditing:YES];
}

// Given a station, find out if it is OK to show it on the map.
//   Return values:
//      0 : OK to show as green for starting
//      1 : OK to show as red for starting
//      2 : OK to show as green for end
//      3 : OK to show as red for end
//      -1: not within distance of neither point, or it is not in service (Don't show)
- (int) checkStation:(BikeLocation*) station {
    if (station.inService) {
        if ( [station isInDistanceOf:originPoint.location distance:_startDistSlider.value * METERS_PER_MILE]) {
            if ( [station hasAvailableBike] ) {
                return 0;
            } else {
                return 1;
            }
        } else if ([station isInDistanceOf:destinationPoint.location distance:_destDistSlider.value * METERS_PER_MILE]) {
            if ( [station isFull]) {
                return 3;
            } else {
                return 2;
            }
        }
    }
    return -1;
}

#pragma mark - Support functions

// this function setups predefined annotation views:
//   Black pin = basic station location
//   Red pin = not for service
//   Green pin = for service
//   Yellow pin = starting point (origin)
//   Flag = destintation
// Returns: UIImage for shown as the annotation icon on map
-(UIImage *) getAnnationImage:(NSString *)locationId {
    NSString * imagefIle;
    if ([locationId isEqualToString:ID_ORIGIN]) {
        imagefIle = @"startingPoint.png";
    } else if ([locationId isEqualToString:ID_DESTINATION]) {
        imagefIle = @"destinationPoint.png";
    } else if ([locationId isEqualToString:ID_REG_LOCATION]) {
        imagefIle = @"blackpin.png";
    } else if ([locationId isEqualToString:ID_GREEN_LOCATION]) {
        imagefIle = @"greenpin.png";
    } else if ([locationId isEqualToString:ID_RED_LOCATION]) {
        imagefIle = @"redpin.png";
    }
    
    if (imagefIle != nil) {
        return [UIImage imageNamed:imagefIle];
    }
    
    return nil;
}

// Utitity function to make an annotation from a placemark
- (MKPointAnnotation *) GetAnnotation:(MKPlacemark *)placeMark withTitle:(NSString *)title{
    MKPointAnnotation *point = [MKPointAnnotation new];
    point.coordinate = placeMark.coordinate;
    point.title = title;
    point.subtitle = placeMark.name;
    
    return point;
}

// Clear all the annotation on map
- (void) ClearPoints {
    for (id<MKAnnotation> annotation in mapView.annotations) {
            [mapView removeAnnotation:annotation];
    }
}

// Origin and Destination are set; direction between the two points can be requested
- (void) GetDirection {
    MKDirectionsRequest *directionsRequest = [MKDirectionsRequest new];
    MKMapItem * destMapItem = [[MKMapItem alloc] initWithPlacemark:destinationPoint];
    MKMapItem * originMapItem = [[MKMapItem alloc] initWithPlacemark:originPoint];
    [directionsRequest setSource:originMapItem];
    [directionsRequest setDestination:destMapItem];
    // Bicycling is consider walking (rather than car or transit)
    [directionsRequest setTransportType:MKDirectionsTransportTypeWalking];
    MKDirections * directions = [[MKDirections alloc] initWithRequest:directionsRequest];
    [directions calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
        // Now handle the result
        if (error) {
            NSLog(@"There was an error getting your directions");
            return;
        }
        
        // So there wasn't an error - let's plot those routes
        [self plotRouteOnMap:[response.routes firstObject]];
    }];
}

// Draw the route from Origin to Destination on the map
- (void) plotRouteOnMap:(MKRoute *)route
{
    if(_routeOverlay) {
        [self.mapView removeOverlay:_routeOverlay];
    }
    
    // Update the ivar
    _routeOverlay = route.polyline;
    
    [self loadMapViewForRoute];
    
    // Add it to the map
    [self.mapView addOverlay:_routeOverlay];
}

// Load the initial view of the map, centered at user's current location
- (void) loadInitialMapView {
    CLLocationCoordinate2D zoomLocation;
    zoomLocation.latitude = latitude_UserLocation;
    zoomLocation.longitude= longitude_UserLocation;
    
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(zoomLocation, 0.5*METERS_PER_MILE, 0.5*METERS_PER_MILE);
    
    [mapView setRegion:viewRegion animated:YES];
}

// Origin and Destination have been determinted
- (void) loadMapViewForRoute {
    CLLocationCoordinate2D center = [self midpointBetweenCoordinate:originPoint.coordinate andCoordinate:destinationPoint.coordinate];
    
    double distance = [originPoint.location distanceFromLocation:destinationPoint.location];
    double minRadius = 0.5*METERS_PER_MILE;
    double maxWalkDistance = MAX(_startDistSlider.value, _destDistSlider.value)*METERS_PER_MILE;
    double computeRadius = MAX(minRadius, maxWalkDistance + distance/1.5f);
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(center, computeRadius, computeRadius);
    
    [mapView setRegion:viewRegion animated:YES];
}

// The following midpoint calculation code is copied from Stackoverflow user Bala
- (CLLocationCoordinate2D)midpointBetweenCoordinate:(CLLocationCoordinate2D)c1 andCoordinate:(CLLocationCoordinate2D)c2
{
    c1.latitude = ToRadian(c1.latitude);
    c2.latitude = ToRadian(c2.latitude);
    CLLocationDegrees dLon = ToRadian(c2.longitude - c1.longitude);
    CLLocationDegrees bx = cos(c2.latitude) * cos(dLon);
    CLLocationDegrees by = cos(c2.latitude) * sin(dLon);
    CLLocationDegrees latitude = atan2(sin(c1.latitude) + sin(c2.latitude), sqrt((cos(c1.latitude) + bx) * (cos(c1.latitude) + bx) + by*by));
    CLLocationDegrees longitude = ToRadian(c1.longitude) + atan2(by, cos(c1.latitude) + bx);
    
    CLLocationCoordinate2D midpointCoordinate;
    midpointCoordinate.longitude = ToDegrees(longitude);
    midpointCoordinate.latitude = ToDegrees(latitude);
    
    return midpointCoordinate;
}

@end
