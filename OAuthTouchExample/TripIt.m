//
//  TripIt.m
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

#import "TripIt.h"

@implementation TripIt

@synthesize auth;
@synthesize signIn;
@synthesize delegate;
@synthesize requestUrl;
@synthesize accessUrl;
@synthesize authorizeUrl;
@synthesize authorizeCookieUrl;
@synthesize baseApiUrlStr;
@synthesize scope;
@synthesize callback;

// Initializer of the TripIt object
- (TripIt *)init {
    self.requestUrl = [NSURL URLWithString:@"https://api.tripit.com/oauth/request_token"];
    self.accessUrl = [NSURL URLWithString:@"https://api.tripit.com/oauth/access_token"];
    self.authorizeUrl = [NSURL URLWithString:@"https://m.tripit.com/oauth/authorize"];
    self.authorizeCookieUrl = [NSURL URLWithString:@"https://m.tripit.com"];
    self.baseApiUrlStr = @"https://api.tripit.com/v1";
    self.scope = @"https://api.tripit.com/v1/";
    self.callback = @"tripitapp://OAuthCallback";
    
    return self;
}

// Sets the consumer key, consumer secret, oauth token, and oauth token secret in an GTMOAuthAuthentication object
- (BOOL)setConsumerKey:(NSString *)myConsumerKey 
        consumerSecret:(NSString *)myConsumerSecret 
            oauthToken:(NSString *)myOauthToken 
      oauthTokenSecret:(NSString *)myOauthTokenSecret {
    
    if ([myConsumerKey length] == 0 || [myConsumerSecret length] == 0) {
        return false;
    }
    
    self.auth = [[[GTMOAuthAuthentication alloc] initWithSignatureMethod:kGTMOAuthSignatureMethodHMAC_SHA1
                                                             consumerKey:myConsumerKey
                                                              privateKey:myConsumerSecret] autorelease];

    // setting the service name lets us inspect the auth object later to know
    // what service it is for
    [auth setServiceProvider:@"TripIt"];

    // If there's an oauth token and secret, then set that in the auth object
    if ([myOauthToken length] != 0 && [myOauthTokenSecret length] != 0) {
        NSString *tokenString = [NSString stringWithFormat:@"oauth_token=%@&oauth_token_secret=%@", myOauthToken, myOauthTokenSecret];
        [auth setKeysForResponseString:tokenString];
        [auth setHasAccessToken:YES];
    }
    
    return true;
}

// Start the 3-legged OAuth flow:
// - Request access token
// - User access token to direct user through webview to TripIt's authentication and approval site
// - Upon approval of app, fetches the user's oauth token and oauth token secret.
// - Calls the finishedSelector
- (void)performOauthFlow:(UINavigationController *)navigationController {
    
    if (auth == nil) {
        // perhaps display something friendlier in the UI?
        NSAssert(NO, @"A valid consumer key and consumer secret are required for signing in to TripIt");
    }
    
    [auth setCallback:self.callback];
    [auth setScope:self.scope];
    
    // use the supplied auth and OAuth endpoint URLs
    signIn = [[GTMOAuthSignIn alloc] initWithAuthentication:auth
                                             requestTokenURL:self.requestUrl
                                           authorizeTokenURL:self.authorizeUrl
                                              accessTokenURL:self.accessUrl
                                                    delegate:self
                                          webRequestSelector:@selector(signIn:displayRequest:)
                                            finishedSelector:@selector(signIn:finishedWithAuth:error:)];
    [signIn startSigningIn];
}


// 2nd part of the 3-legged OAuth flow:
// This is called during the 2nd part of OAUth flow, 
// when the user has to sign into TripIt from a browser and approve the
// 3rd party app.
- (void)signIn:(GTMOAuthSignIn *)signIn displayRequest:(NSURLRequest *)request {
    if (request != nil) {
        [[UIApplication sharedApplication] openURL:[request URL]];
    }
}

// 3rd part of the 3-legged OAuth flow:
// fetch the user's oauth token
- (void)performGetAuthorization:(NSURL *)redirectedRequest {
    [self.signIn requestRedirected:redirectedRequest];
}

// 
- (void)signIn:(GTMOAuthSignIn *)signIn
finishedWithAuth:(GTMOAuthAuthentication *)returnedAuth
         error:(NSError *)error { 
    [self.delegate oauthReturned:returnedAuth error:error];
}

// Performs an API fetch using the non-blocking GTMHTTPFetcher
// This method should never be called directly by the API binding user.
- (void)performApiFetch:(NSString *)urlStr 
                 isPost:(BOOL)post
          withXmlString:(NSString *)xmlString {

    NSURL *url = [NSURL URLWithString:urlStr];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    if (post) {
        // Note that for a request with a body, such as a POST or PUT request, the
        // library will include the body data when signing only if the request has
        // the proper content type header:
        
        NSData *postData = [xmlString dataUsingEncoding:NSASCIIStringEncoding];
        NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
        
        [request setHTTPMethod:@"POST"];
        [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
        [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        [request setHTTPBody:postData];
    }
    
    [auth authorizeRequest:request];

    GTMHTTPFetcher* myFetcher = [GTMHTTPFetcher fetcherWithRequest:request];    
    [myFetcher beginFetchWithDelegate:self
                    didFinishSelector:@selector(apiFetcher:finishedWithData:error:)];
}

- (void)apiFetcher:(GTMHTTPFetcher *)fetcher 
 finishedWithData:(NSData *)retrievedData 
            error:(NSError *)error {
    
    NSString *str = [[[NSString alloc] initWithData:retrievedData
                                           encoding:NSUTF8StringEncoding] autorelease];
    [self.delegate apiReturnedWithString:str error:error];
}

// A simple test method to see is a call to the API is working
- (void)testApiGet {
    NSString *urlStr = @"https://api.tripit.com/v1/list/trip";
    [self performApiFetch:urlStr 
                   isPost:false 
           withXmlString:nil];
}

// Creates a url string from a NSDictionary
- (NSString *)createUrlParamsFromFilter:(NSDictionary *)filter {
    NSMutableString *urlParams = [[NSMutableString alloc] initWithString:@""];
    for (id key in filter) {
        NSString *value = [filter objectForKey:key];
        [urlParams appendFormat:@"/%@/%@", key, value];
    }
    NSString *immutableString = [NSString stringWithString:urlParams];
    [urlParams release];
    return immutableString;
    
}

// Performs the 'get' API call
// http://tripit.github.com/api/doc/v1/index.html#method_get
- (void)performGetObjectOfType:(NSString *)objType 
                        withId:(NSString *)objId
                    withFilter:(NSDictionary *)filter {
    
    NSString *filterString = @"";
    if (filter != nil) {
        filterString = [self createUrlParamsFromFilter:filter];
    }
    NSString *urlStr = [NSString stringWithFormat:@"%@/get/%@/id/%@%@", baseApiUrlStr, objType, objId, filterString];
    
    [self performApiFetch:urlStr 
                   isPost:false 
           withXmlString:nil];
}

// Performs the 'list' API call
// http://tripit.github.com/api/doc/v1/index.html#method_list
- (void)performListObjectOfType:(NSString *)objType 
                     withFilter:(NSDictionary *)filter {
    
    NSString *filterString = @"";
    if (filter != nil) {
        filterString = [self createUrlParamsFromFilter:filter];
    }
    NSString *urlStr = [NSString stringWithFormat:@"%@/list/%@%@", baseApiUrlStr, objType, filterString];
    
    [self performApiFetch:urlStr 
                   isPost:false 
           withXmlString:nil];
}

// Performs the 'create' API call
// http://tripit.github.com/api/doc/v1/index.html#method_create
- (void)performCreateObjectWithString:(NSString *)postString isJson:(BOOL)isJson{
    
    NSString *urlStr = [NSString stringWithFormat:@"%@/create", baseApiUrlStr];
    NSMutableString *post = [NSMutableString stringWithCapacity:100];
    if (isJson) {
        [post appendString:@"format=json&json="];
    }
    else {
        [post appendString:@"format=xml&xml="];
    }
    [post appendString:postString];
    
    [self performApiFetch:urlStr 
                   isPost:true
           withXmlString:post];
}

// Performs the 'replace' API call
// http://tripit.github.com/api/doc/v1/index.html#method_replace
- (void)performReplaceObjectOfType:(NSString *)objType 
                            withId:(NSString *)objId 
                        withString:(NSString *)postString 
                            isJson:(BOOL)isJson {
    
    NSString *urlStr = [NSString stringWithFormat:@"%@/replace/%@/id/%@", baseApiUrlStr, objType, objId];
    NSMutableString *post = [NSMutableString stringWithCapacity:100];
    if (isJson) {
        [post appendString:@"format=json&json="];
    }
    else {
        [post appendString:@"format=xml&xml="];
    }
    [post appendString:postString];
//    NSString *post = [NSString stringWithFormat:@"xml=%@", postString];
    
    [self performApiFetch:urlStr 
                   isPost:true
           withXmlString:post];
}

// Performs the 'delete' API call
// http://tripit.github.com/api/doc/v1/index.html#method_delete
- (void)performDeleteObjectOfType:(NSString *)objType
                           withId:(NSString *)objId {
    
    NSString *urlStr = [NSString stringWithFormat:@"%@/delete/%@/id/%@", baseApiUrlStr, objType, objId];
    
    [self performApiFetch:urlStr 
                   isPost:false 
           withXmlString:nil];
}

- (void)dealloc {
    self.auth = nil;
    self.signIn = nil;
    self.requestUrl = nil;
    self.accessUrl = nil;
    self.authorizeUrl = nil;
    self.authorizeCookieUrl = nil;
    self.baseApiUrlStr = nil;
    self.scope = nil;
    self.callback = nil;
    [super dealloc];
}

@end