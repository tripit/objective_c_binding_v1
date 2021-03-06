/* Copyright (c) 2010 Google Inc.
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
// OAuthSampleAppDelegateTouch.m

#import "OAuthSampleAppDelegateTouch.h"
#import "OAuthSampleRootViewControllerTouch.h"

@implementation OAuthSampleAppDelegateTouch

@synthesize window = mWindow;
@synthesize navigationController = mNavigationController;

- (void)dealloc {
  [mNavigationController release];
  [mWindow release];
  [super dealloc];
}

- (void)applicationDidFinishLaunching:(UIApplication *)application {
  [mWindow addSubview:[mNavigationController view]];
  [mWindow makeKeyAndVisible];
}

- (void)applicationWillTerminate:(UIApplication *)application {
  [[NSUserDefaults standardUserDefaults] synchronize];
}

// Need to implement this function in order to get the callback redirect from the browser after
// the user signs in to TripIt to approve the app.
- (BOOL)application:(UIApplication *)application 
            openURL:(NSURL *)url 
  sourceApplication:(NSString *)sourceApplication 
         annotation:(id)annotation {
    if (!url) {  
        return NO; 
    }
    // Continue on with the 3rd part of OAuth flow
    OAuthSampleRootViewControllerTouch *mvc = (OAuthSampleRootViewControllerTouch *) self.navigationController.topViewController;
    [mvc.tripIt performGetAuthorization:url];
    
    return YES;
}

@end

