//
//  LocationSelectionViewController.m
//  bikemap
//
//  Created by Rickie on 11/27/17.
//  Copyright © 2017 Rickie. All rights reserved.
//

#import <MapKit/MapKit.h>
#import "LocationSelectionViewController.h"
#define METERS_PER_MILE 1609.344
@interface LocationSelectionViewController()
//@property (nonatomic, strong)
@end

@implementation LocationSelectionViewController
NSMutableArray * placeMarks;
LocationSelectCallbackBlock callbackWhenFinish;
CLLocationCoordinate2D searchCenter;
# pragma mark - UISearchBarDelegates
- (void)searchBarBookmarkButtonClicked:(UISearchBar *)searchBar
{
    NSLog(@"%s", __func__);
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    NSLog(@"Search bar clicked, searching starts...");
    [self searchForLocation:searchBar.text];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    NSLog(@"Search bar canceled");
    [self ConstructPlaceList:nil];
    [_tableView reloadData];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    NSLog(@"User starts editing search text");
}

// Clicking the point down button
- (void)searchBarResultsListButtonClicked:(UISearchBar *)searchBar
{
    NSLog(@"User search bar result clicked");
}

#pragma mark - UITableView Delegates
- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [placeMarks count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        return 44;
    } else {
        return 68;
    }
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"LocationCell"];
    NSString * address = @"";
    MKPlacemark * place = [placeMarks objectAtIndex:indexPath.row];
    
    if (cell != nil) {
        if (indexPath.row > 0) {
            address = [place.addressDictionary valueForKey:@"Street"];
            if (address == nil) {
                address = [NSString stringWithFormat:@"%@, %@", [place.addressDictionary valueForKey:@"City"], [place.addressDictionary valueForKey:@"State"]];
            } else {
                address = [address stringByAppendingFormat:@"\n%@, %@", [place.addressDictionary valueForKey:@"City"], [place.addressDictionary valueForKey:@"State"]];
            }
        }
        [cell.textLabel setText:[place name]];
        [cell.detailTextLabel setText:address];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"Row %d was selected, return value %@", (int)indexPath.row, [[placeMarks objectAtIndex:indexPath.row] description]);
    
    if (callbackWhenFinish != nil) {
        callbackWhenFinish([placeMarks objectAtIndex:indexPath.row]);
    }
}

#pragma mark - Supporting functions

- (void) searchForLocation:(NSString *)searchText {
    NSLog(@"%s:%@", __func__, searchText);
    
    // Create and initialize a search request object.
    MKLocalSearchRequest *request = [[MKLocalSearchRequest alloc] init];
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(searchCenter, 0.5*METERS_PER_MILE, 0.5*METERS_PER_MILE);
    
    request.naturalLanguageQuery = searchText;
    request.region = viewRegion;
    
    // Create and initialize a search object.
    MKLocalSearch *search = [[MKLocalSearch alloc] initWithRequest:request];
    
    // Start the search and display the results as annotations on the map.
    [search startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error)
     {
         [self ConstructPlaceList:response.mapItems];
         [_tableView reloadData];
     }];
}

- (void) ConstructPlaceList:(NSArray *) searchResult {
    MKMapItem * currentLoc = [[MKMapItem alloc] initWithPlacemark:[[MKPlacemark alloc] initWithCoordinate:searchCenter]];
    currentLoc.name = @"Current Location";
    placeMarks = [NSMutableArray arrayWithObject:currentLoc.placemark];
    if (searchResult != nil) {
        for (MKMapItem *item in searchResult) {
            [placeMarks addObject:item.placemark];
            NSLog(@"Place: name:%@  address:%@", item.placemark.name, [item.placemark.addressDictionary objectForKey:@"FormattedAddressLines"]);
        }
    }
}

#pragma mark - Life Cycle
- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated ];
    
    //searchCenter = CLLocationCoordinate2DMake(37.802611, -122.405721);
    [self ConstructPlaceList:nil];
}

-(void) initWithUserLocation:(CLLocationCoordinate2D)location Callback:(LocationSelectCallbackBlock)callback {
    
    searchCenter = location;
    callbackWhenFinish = callback;
}
@end
