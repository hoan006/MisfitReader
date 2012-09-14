//
//  constants.h
//  MisfitReader
//
//  Created by hoan.nguyen on 8/28/12.
//  Copyright (c) 2012 Hoan Nguyen Ngoc. All rights reserved.
//

#define kCURL_USER_AGENT @"curl/7.24.0 (x86_64-apple-darwin12.0) libcurl/7.24.0 OpenSSL/0.9.8r zlib/1.2.5"
#define kGOOGLE_CLIENT_LOGIN @"https://www.google.com/accounts/ClientLogin"
#define kGOOGLE_READER_SUBSCRIPTION_LIST @"http://www.google.com/reader/api/0/subscription/list"
#define kGOOGLE_READER_UNREAD_COUNT @"http://www.google.com/reader/api/0/unread-count"
#define kGOOGLE_FEED_API_SERVICE @"http://ajax.googleapis.com/ajax/services/feed/lookup?v=1.0&q="
#define kGOOGLE_READER_TOKEN @"http://www.google.com/reader/api/0/token"
#define kGOOGLE_READER_SUBSCRIBE @"http://www.google.com/reader/api/0/subscription/quickadd"
#define kGOOGLE_READER_EDIT @"http://www.google.com/reader/api/0/subscription/edit"
#define kGOOGLE_READER_SET_TAG @"http://www.google.com/reader/api/0/edit-tag"
#define kGOOGLE_READER_MARK_ALL_AS_READ @"http://www.google.com/reader/api/0/mark-all-as-read"
#define kGOOGLE_READER_UNREAD_ENTRIES_FROM_FEED_URL_AND_TIMESTAMP @"http://www.google.com/reader/atom/%@?n=1000&r=o&ot=%@&xt=user/-/state/com.google/read"
#define kGOOGLE_READER_UNREAD_ENTRIES_FROM_FEED_URL_AND_COUNT @"http://www.google.com/reader/atom/%@?n=%@"

#define kGOOGLE_READER_USER_STATE_READ @"user/-/state/com.google/read"
#define kGOOGLE_READER_USER_STATE_KEPT_UNREAD @"user/-/state/com.google/kept-unread"
#define kGOOGLE_READER_USER_STATE_STARRED @"user/-/state/com.google/starred"

//RGB color macro
#define UIColorFromRGB(rgbValue) [UIColor \
                                   colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
                                   green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
                                   blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

//RGB color macro with alpha
#define UIColorFromRGBWithAlpha(rgbValue,a) [UIColor \
                                              colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
                                              green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
                                              blue:((float)(rgbValue & 0xFF))/255.0 alpha:a]
