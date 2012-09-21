//
//  TripIt.m
//  OAuthSampleTouch
//
//  Created by Tariq Islam on 9/9/12.
//  Copyright (c) 2012 TripIt. All rights reserved.
//

#import "TripIt.h"

@implementation TripIt

NSURL *requestUrl;
NSURL *accessUrl;
NSURL *authorizeUrl;
NSString *baseApiUrlStr;
NSString *scope;

@synthesize auth;
@synthesize delegate;

// Initializer of the TripIt object
- (TripIt *)init {
    requestUrl = [NSURL URLWithString:@"https://api.tripit.com/oauth/request_token"];
    accessUrl = [NSURL URLWithString:@"https://api.tripit.com/oauth/access_token"];
    authorizeUrl = [NSURL URLWithString:@"https://m.tripit.com/oauth/authorize"];
    baseApiUrlStr = @"https://api.tripit.com/v1";
    scope = @"https://api.tripit.com/";
    
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
    
    auth = [[[GTMOAuthAuthentication alloc] initWithSignatureMethod:kGTMOAuthSignatureMethodHMAC_SHA1
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

// Performs the 3-legged OAuth flow:
// - Request access token
// - User access token to direct user through webview to TripIt's authentication and approval site
// - Upon approval of app, fetches the user's oauth token and oauth token secret.
// - Calls the finishedSelector
- (void)performOauthFlow:(UINavigationController *)navigationController {
    
    if (auth == nil) {
        // perhaps display something friendlier in the UI?
        NSAssert(NO, @"A valid consumer key and consumer secret are required for signing in to TripIt");
    }
    
    // This could be anything, since we don't really use it; the finishedSelector is instead called
    // when TripIt redirects with the oauth token and secret
    [auth setCallback:@"http://www.example.com/OAuthCallback"];
        
    // Display the autentication view.
    GTMOAuthViewControllerTouch *viewController;
    viewController = [[[GTMOAuthViewControllerTouch alloc] initWithScope:scope
                                                                language:nil
                                                         requestTokenURL:requestUrl
                                                       authorizeTokenURL:authorizeUrl
                                                          accessTokenURL:accessUrl
                                                          authentication:auth
                                                          appServiceName:@"TripIt"
                                                                delegate:self
                                                        finishedSelector:@selector(viewController:finishedWithAuth:error:)] autorelease];
    
    // Optional: display some html briefly before the sign-in page loads
    NSString *html = @"<html><body bgcolor=silver><div align=center>Loading TripIt sign-in page...</div></body></html>";
    [viewController setInitialHTMLString:html];
    
    [navigationController pushViewController:viewController 
                                    animated:YES];
}

- (void)viewController:(GTMOAuthViewControllerTouch *)viewController
      finishedWithAuth:(GTMOAuthAuthentication *)returnedAuth
                 error:(NSError *)error {
    
    NSLog(@"HERE");
    
    [self.delegate oauthReturned:returnedAuth error:error];
}


// Performs an API fetch using the non-blocking GTMHTTPFetcher
// This method should never be called directly by the API binding user.
- (void)performApiFetch:(NSString *)urlStr 
                 isPost:(BOOL)post
          withXmlString:(NSString *)xmlString {
    
    NSLog(@"**********Url for API: %@", urlStr);

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
                    didFinishSelector:@selector(myFetcher:finishedWithData:error:)];
}

- (void)myFetcher:(GTMHTTPFetcher *)fetcher 
 finishedWithData:(NSData *)retrievedData 
            error:(NSError *)error {
    
    NSString *str = [[[NSString alloc] initWithData:retrievedData
                                           encoding:NSUTF8StringEncoding] autorelease];
    if (error != nil) {
        // failed; either an NSURLConnection error occurred, or the server returned
        // a status value of at least 300
        //
        // the NSError domain string for server status errors is kGTMHTTPFetcherStatusDomain
        int status = [error code];
        // fetch failed
        NSLog(@"API fetch error: %d - %@", status, error);
    }        
    NSLog(@"API response: %@", str);
    
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
- (NSMutableString *)createUrlParamsFromFilter:(NSDictionary *)filter {
    NSMutableString *urlParams = [[NSMutableString alloc] init];
    for (id key in filter) {
        NSString *value = [filter objectForKey:key];
        [urlParams appendFormat:@"/%@/%@", key, value];
    }
    return urlParams;
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
- (void)performCreateObjectWithXmlString:(NSString *)xmlString {
    
    NSString *urlStr = [NSString stringWithFormat:@"%@/create", baseApiUrlStr];
    NSString *post = [NSString stringWithFormat:@"xml=%@", xmlString];
    
    [self performApiFetch:urlStr 
                   isPost:true
           withXmlString:post];
}

// Performs the 'replace' API call
// http://tripit.github.com/api/doc/v1/index.html#method_replace
- (void)performReplaceObjectOfType:(NSString *)objType 
                            withId:(NSString *)objId 
                     withXmlString:(NSString *)xmlString {
    
    NSString *urlStr = [NSString stringWithFormat:@"%@/replace/%@/id/%@", baseApiUrlStr, objType, objId];
    NSString *post = [NSString stringWithFormat:@"xml=%@", xmlString];
    
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

@end