//
//  BikeLocation.h
//  bikemap
//
//  Created by Rickie on 11/21/17.
//  Copyright © 2017 Rickie. All rights reserved.
//

#ifndef BikeLocation_h
#define BikeLocation_h

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

typedef enum  {
    IN_SERVICE  = 1,
    NOT_IN_SERVICE = 3
} StationStatusType;

@interface BikeLocation : NSObject <MKAnnotation>

- (id)initWithData:(NSDictionary *)data;
- (MKMapItem*)mapItem;

- (BOOL) inService;
- (BOOL) hasAvailableBike;
- (BOOL) isFull;
- (BOOL) isEmpty;
- (BOOL) isInDistanceOf:(CLLocation *)target distance:(CLLocationDistance)distance;

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic, readonly, copy) NSString *title;
@property (nonatomic, readonly, copy) NSString *subtitle;


@end

#endif /* BikeLocation_h */
