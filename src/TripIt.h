//
//  TripIt.h
//  OAuthSampleTouch
//
//  Created by Tariq Islam on 9/9/12.
//  Copyright (c) 2012 TripIt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GTMOAuthViewControllerTouch.h"

// TripitApiDelegate needs to be implemented by the client using this library
@protocol TripItApiDelegate

- (void)apiReturnedWithString:(NSString *)returnStr error:(NSError *)error;

- (void)oauthReturned:(GTMOAuthAuthentication *)returnedAuth error:(NSError *)error;

@end

@interface TripIt : NSObject

@property (assign) GTMOAuthAuthentication *auth;
@property (assign) id<TripItApiDelegate> delegate;

- (BOOL)setConsumerKey:(NSString *)myConsumerKey 
                                 consumerSecret:(NSString *)myConsumerSecret 
                                     oauthToken:(NSString *)myOauthToken 
                               oauthTokenSecret:(NSString *)myOauthTokenSecret;

- (void)performOauthFlow:(UINavigationController *)navigationController;

- (void)testApiGet;

- (void)performGetObjectOfType:(NSString *)objType withId:(NSString *)objId withFilter:(NSDictionary *)filter;

- (void)performListObjectOfType:(NSString *)objType withFilter:(NSDictionary *)filter;

- (void)performDeleteObjectOfType:(NSString *)objType withId:(NSString *)objId;

- (void)performCreateObjectWithXmlString:(NSString *)xmlString;

- (void)performReplaceObjectOfType:(NSString *)objType withId:(NSString *)objId withXmlString:(NSString *)xmlString;

@end

