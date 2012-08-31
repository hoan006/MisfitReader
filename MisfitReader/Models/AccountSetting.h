//
//  AccountSetting.h
//  MisfitReader
//
//  Created by hoan.nguyen on 8/30/12.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface AccountSetting : NSManagedObject

@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSString * google_auth;
@property (nonatomic, retain) NSString * password;
@property (nonatomic, retain) NSString * google_token;

@end
