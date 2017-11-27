//
//  BikeLocation.m
//  bikemap
//
//  Created by Rickie on 11/21/17.
//  Copyright © 2017 Rickie. All rights reserved.
//
#import <AddressBook/AddressBook.h>
#import "BikeLocation.h"

@interface BikeLocation ()
@property (nonatomic, strong) MKMapItem* mkMapItem;
@property (nonatomic, readonly) int availableBikes;
@property (nonatomic, readonly) int availableDocks;
@property (nonatomic, readonly) int totalDocks;
@property (nonatomic, readonly) StationStatusType status;
@end

@implementation BikeLocation

@synthesize coordinate;
@synthesize title;
@synthesize subtitle;



- (id)initWithData:(NSDictionary *)data
{
    self = [super init];
    double latitude = [[data objectForKey:@"latitude"] doubleValue];
    double longitude = [[data objectForKey:@"longitude"] doubleValue];
    
    title = [data objectForKey:@"stationName"];
    coordinate = CLLocationCoordinate2DMake((CLLocationDegrees)latitude, (CLLocationDegrees)longitude);
    
    MKPlacemark * placeMark = [[MKPlacemark alloc]
                              initWithCoordinate:self.coordinate];
    self.mkMapItem = [[MKMapItem alloc] initWithPlacemark:placeMark];
    self.mkMapItem.name = title;
    _availableBikes = [[data objectForKey:@"availableBikes"] intValue];
    _availableDocks = [[data objectForKey:@"availableDocks"] intValue];
    _totalDocks = [[data objectForKey:@"totalDocks"] intValue];
    _status = [[data objectForKey:@"statusKey"] intValue];
    
    return self;
}

- (MKMapItem*)mapItem {
    return self.mkMapItem;
}

- (BOOL) inService {
    return _status == IN_SERVICE;
}

- (BOOL) hasAvailableBike {
    return _availableBikes > 0;
}

- (BOOL) isFull {
    return _availableDocks == 0;
}
- (BOOL) isEmpty {
    return _availableBikes == 0;
}
- (BOOL) isInDistanceOf:(CLLocation *)target distance:(CLLocationDistance)distance {
    return distance >= [target distanceFromLocation:[self.mkMapItem.placemark location]];
}

@end
