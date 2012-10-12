/* Copyright (c) 2012 TripIt
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
// OAuthSampleRootViewControllerTouch.m

#import "OAuthSampleRootViewControllerTouch.h"
#import "GTMHTTPFetcherLogging.h"
#import "TripIt.h"

@implementation OAuthSampleRootViewControllerTouch

@synthesize signInOutButton = mSignInOutButton;
@synthesize emailField = mEmailField;
@synthesize tokenField = mTokenField;
@synthesize tripIt;

- (void)awakeFromNib {
    NSLog(@"awakeFromNib");
    // Set this to enable debugging logging of HTTP request/response details
    [GTMHTTPFetcher setLoggingEnabled:YES];
    [self updateUI];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation {
    // Returns non-zero on iPad, but backward compatible to SDKs earlier than 3.2.
    if (UI_USER_INTERFACE_IDIOM()) {
        return YES;
    }
    return [super shouldAutorotateToInterfaceOrientation:orientation];
}

- (BOOL)isSignedIn {
    BOOL isSignedIn = false;
    if (tripIt != nil) {
        isSignedIn = [[tripIt auth] hasAccessToken];
    }
    return isSignedIn;
}

- (IBAction)signInOutClicked:(id)sender {
    if ([self isSignedIn]) {
        [self signOut];
    }
    else {
        [self signInToTripIt];
    }
    [self updateUI];
}

- (void)signOut {
    // Dealloc our retained authentication object.
    self.tripIt = nil;
}


// Main method that does OAuth
- (void)signInToTripIt {
    // Initialize the TripIt API object
    self.tripIt = [[[TripIt alloc] init] autorelease];
    
    // uncomment the line below to test complete OAuth flow
    [tripIt setConsumerKey:@"2b785575d91647d6e3d6d0bc027da8186878eacd" consumerSecret:@"86c0d63f2f2fd101204189abad66e2b8d03410bc" oauthToken:nil oauthTokenSecret:nil];
    
    // uncomment the line below to test only an API fetch
//    [tripIt setConsumerKey:@"2b785575d91647d6e3d6d0bc027da8186878eacd" consumerSecret:@"86c0d63f2f2fd101204189abad66e2b8d03410bc" oauthToken:@"USER_OAUTH_TOKEN" oauthTokenSecret:@"USER_OAUTH_TOKEN_SECRET"];
    
    // Set the delegate so that oauth and api return callbacks are executed
    [tripIt setDelegate:self];
    
    // If the oauth token/secret has been set in the tripIt object, then no need to do oauth
    if ([[tripIt auth] hasAccessToken]) {
        NSLog(@"HAS TOKEN, SKIPPING OAUTH REQUEST...");
        
        // Just to prove we're signed in, we'll attempt an authenticated fetch for the
        // signed-in user
        [self doAnAuthenticatedAPIFetch];
        return;
    }
    // Start OAuth flow
    [tripIt performOauthFlow];
}


// Test that the oauth token and secret work and can make an actual API request
- (void)doAnAuthenticatedAPIFetch {
    [tripIt testApiGet];

    // list endpoint
//    NSDictionary *dict =  [[NSDictionary alloc] initWithObjectsAndKeys:@"true", @"past", nil];
//    [tripIt performListObjectOfType:@"trip" withFilter:dict];
    
    // get endpoint
//    NSDictionary *dict =  [[NSDictionary alloc] initWithObjectsAndKeys:@"true", @"include_objects", nil];
//    [tripIt performGetObjectOfType:@"trip" withId:@"50161232" withFilter:nil];
    
    // create endpoint
//    NSString *post = @"<Request><Trip>" \
//        "<start_date>2014-12-09</start_date>" \
//        "<end_date>2014-12-27</end_date>" \
//        "<primary_location>New York, NY</primary_location>" \
//        "</Trip></Request>";
//    [tripIt performCreateObjectWithString:post isJson:false];
    
    //replace endpoint
//    NSString *post = @"<Request><Trip>" \
//        "<start_date>2014-01-01</start_date>" \
//        "<end_date>2014-02-01</end_date>" \
//        "<primary_location>New York, NY</primary_location>" \
//        "</Trip></Request>";
//    [tripIt performReplaceObjectOfType:@"trip" withId:@"50195261" withString:post isJson:false];
    
    // delete endpoint
//    [tripIt performDeleteObjectOfType:@"trip" withId:@"50161232"];
    
    // JSON create example
//    NSString *post = @"{\"Trip\": \
//        {\"start_date\":\"2014-12-09\", \
//        \"end_date\":\"2014-12-27\", \
//        \"primary_location\":\"New York, NY\" \
//        } \
//    }";
//    [tripIt performCreateObjectWithString:post isJson:true];
    
    // JSON replace example
//    NSString *post = @"{\"Trip\": \
//    {\"start_date\":\"2015-01-09\", \
//    \"end_date\":\"2015-01-27\", \
//    \"primary_location\":\"New York, NY\" \
//    } \
//    }";
//    [tripIt performReplaceObjectOfType:@"trip" withId:@"50195492" withString:post isJson:true];
    
}


- (void)updateUI {
    // update the text showing the signed-in state and the button title
    // A real program would use NSLocalizedString() for strings shown to the user.
    if ([self isSignedIn]) {
        // signed in
        NSString *email = [[tripIt auth] userEmail];
        NSString *token = [[tripIt auth] token];
        
        [mEmailField setText:email];
        [mTokenField setText:token];
        [mSignInOutButton setTitle:@"Sign Out"];
    } else {
        // signed out
        [mEmailField setText:@"Not signed in"];
        [mTokenField setText:@"No authorization token"];
        [mSignInOutButton setTitle:@"Sign In..."];
    }
}

// Implement TripItApiDelegate protocol
- (void)oauthReturned:(GTMOAuthAuthentication *)returnedAuth error:(NSError *)error {
    NSLog(@"Oauth Returned:");
    NSMutableString *returnStr = [NSMutableString string];
    
    if (error != nil) {
        // Authentication failed (perhaps the user denied access, or closed the
        // window before granting access)
        [returnStr appendString:@"Authentication error: "];
        NSData *responseData = [[error userInfo] objectForKey:@"data"]; // kGTMHTTPFetcherStatusDataKey
        if ([responseData length] > 0) {
            // show the body of the server's authentication failure response
            [returnStr appendString:[[[NSString alloc] initWithData:responseData
                                                           encoding:NSUTF8StringEncoding] autorelease]];
        }
    } 
    else {
        [returnStr appendString:@"Auth COMPLETED"];
    }
    NSLog(@"%@", returnStr);
    
    [self updateUI];
    [self doAnAuthenticatedAPIFetch];
}

// Implement TripItApiDelegate protocol
- (void)apiReturnedWithString:(NSString *)returnStr error:(NSError *)error {
    if (error != nil) {
        // failed; either an NSURLConnection error occurred, or the server returned
        // a status value of at least 300
        //
        // the NSError domain string for server status errors is kGTMHTTPFetcherStatusDomain
        int status = [error code];
        // fetch failed
        NSLog(@"API fetch error: %d - %@", status, error);
    }        
    NSLog(@"API response: %@", returnStr);
}

- (void)dealloc {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self];
    [mSignInOutButton release];
    [mEmailField release];
    [mTokenField release];
    self.tripIt = nil;
    [super dealloc];
}


@end

