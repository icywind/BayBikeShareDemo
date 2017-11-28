//
//  LocationSelectionViewController.h
//  bikemap
//
//  Created by Rickie on 11/27/17.
//  Copyright © 2017 Rickie. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

typedef void (^LocationSelectCallbackBlock)(MKPlacemark *);

@interface LocationSelectionViewController : UIViewController <UITableViewDelegate, UISearchBarDelegate>

@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;
@property (strong, nonatomic) IBOutlet UITableView *tableView;

-(void) initWithUserLocation:(CLLocationCoordinate2D)location Callback:(LocationSelectCallbackBlock)callback;
@end
