//
//  TripIt.h
//  OAuthSampleTouch
//
// Copyright 2008-2012 Concur Technologies, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License"); you may
// not use this file except in compliance with the License. You may obtain
// a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations
// under the License.


#import <UIKit/UIKit.h>
#import "GTMOAuthSignIn.h"

// TripitApiDelegate needs to be implemented by the client using this library
@protocol TripItApiDelegate

- (void)apiReturnedWithString:(NSString *)returnStr error:(NSError *)error;

- (void)oauthReturned:(GTMOAuthAuthentication *)returnedAuth error:(NSError *)error;

@end

@interface TripIt : NSObject

@property (retain) GTMOAuthAuthentication *auth;
@property (retain) GTMOAuthSignIn *signIn;
@property (assign) id<TripItApiDelegate> delegate;
@property (retain) NSURL *requestUrl;
@property (retain) NSURL *accessUrl;
@property (retain) NSURL *authorizeUrl;
@property (retain) NSURL *authorizeCookieUrl;
@property (retain) NSString *baseApiUrlStr;
@property (retain) NSString *scope;
@property (retain) NSString *callback;


- (BOOL)setConsumerKey:(NSString *)myConsumerKey 
                                 consumerSecret:(NSString *)myConsumerSecret 
                                     oauthToken:(NSString *)myOauthToken 
                               oauthTokenSecret:(NSString *)myOauthTokenSecret;

- (void)performOauthFlow;

- (void)performGetAuthorization:(NSURL *)redirectedRequest;

- (void)testApiGet;

- (void)performGetObjectOfType:(NSString *)objType withId:(NSString *)objId withFilter:(NSDictionary *)filter;

- (void)performListObjectOfType:(NSString *)objType withFilter:(NSDictionary *)filter;

- (void)performDeleteObjectOfType:(NSString *)objType withId:(NSString *)objId;

- (void)performCreateObjectWithString:(NSString *)postString isJson:(BOOL)isJson;

- (void)performReplaceObjectOfType:(NSString *)objType withId:(NSString *)objId withString:(NSString *)postString isJson:(BOOL)isJson;

@end

