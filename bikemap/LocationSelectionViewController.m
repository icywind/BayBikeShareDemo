//
//  LocationSelectionViewController.m
//    This class serves a search and selection UI for the origin and destination
//  input from the BikeShareMapViewController.
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
NSString * locTitle;
BOOL bUseUserLocation;

# pragma mark - UISearchBarDelegates
- (void)searchBarBookmarkButtonClicked:(UISearchBar *)searchBar
{
    NSLog(@"%s", __func__);
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    NSLog(@"Search bar clicked, searching starts...");
    [self searchForLocation:searchBar.text];
    [self.view endEditing:YES];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    NSLog(@"Search bar canceled");
    [self dismissViewControllerAnimated:YES completion:nil];
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
    if (indexPath.row == 0 && bUseUserLocation) {
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
        if (indexPath.row > 0 || !bUseUserLocation) {
            address = [self getAddress:place];
        }
        [cell.textLabel setText:[place name]];
        [cell.detailTextLabel setText:address];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"Row %d was selected, return value %@", (int)indexPath.row, [[placeMarks objectAtIndex:indexPath.row] description]);
    MKPlacemark * mark = [placeMarks objectAtIndex:indexPath.row];
    [self confirmSearchChoice:mark callback:^(BOOL ok) {
        if (ok) {
            if (callbackWhenFinish != nil) {
                callbackWhenFinish([placeMarks objectAtIndex:indexPath.row]);
            }
            
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }];

}

#pragma mark - Life Cycle
- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated ];
    
    //searchCenter = CLLocationCoordinate2DMake(37.802611, -122.405721);
    [self ConstructPlaceList:nil];
}

#pragma mark - Supporting functions

-(void) initWithUserLocation:(CLLocationCoordinate2D)location title:(NSString*)titleText userLocation:(BOOL)useUserLocation Callback:(LocationSelectCallbackBlock)callback
{
    locTitle = titleText;
    bUseUserLocation = useUserLocation;
    searchCenter = location;
    callbackWhenFinish = callback;
}

- (NSString *) getAddress:(MKPlacemark *) place {
    NSString * address =  [place.addressDictionary valueForKey:@"Street"];
    NSString * city = [place.addressDictionary valueForKey:@"City"];
    NSString * state = [place.addressDictionary valueForKey:@"State"];
    
    if (address == nil) {
        address = @"";
    } else {
        address = [address stringByAppendingString:@"\n"];
    }
    
    if (city != nil) {
        address = [address stringByAppendingString:city];
    }
    
    if (state != nil) {
        if (city != nil) {
            address = [address stringByAppendingString:@", "];
        }
        address = [address stringByAppendingString:state];
    }
    
    return address;
}

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

//
// Make the places list from the search result.  If this is for the origin, add the current location
// to the first element.
- (void) ConstructPlaceList:(NSArray *) searchResult {
    MKMapItem * currentLoc = [[MKMapItem alloc] initWithPlacemark:[[MKPlacemark alloc] initWithCoordinate:searchCenter]];
    placeMarks = [NSMutableArray array];
    
    if (bUseUserLocation) {
        currentLoc.name = @"Current Location";
        [placeMarks addObject:currentLoc.placemark];
    }
    
    if (searchResult != nil) {
        for (MKMapItem *item in searchResult) {
            [placeMarks addObject:item.placemark];
            NSLog(@"Place: name:%@  address:%@", item.placemark.name, [item.placemark.addressDictionary objectForKey:@"FormattedAddressLines"]);
        }
    }
}


// Confirm the search result with an alert dialog
- (void) confirmSearchChoice:(MKPlacemark *)place  callback:(void (^)(BOOL))callbackBlock
{
    NSString * nameAndAddress = [NSString stringWithFormat:@"%@\n%@",
                                 place.name,
                                 [self getAddress:place]
                                 ];
    
    
    UIAlertController * alert=[UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"Is this the %@", locTitle]
                                                                  message:nameAndAddress
                                                           preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* yesButton = [UIAlertAction actionWithTitle:@"Yes"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * action)
                                {
                                    callbackBlock(YES);
                                }];
    
    UIAlertAction* noButton = [UIAlertAction actionWithTitle:@"No"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * action)
                               {
                                   callbackBlock(NO);
                               }];
    
    [alert addAction:noButton];
    [alert addAction:yesButton];
    
    [self presentViewController:alert animated:YES completion:nil];
}

@end
