In order to use this library for your iOS app, include the following files in the src/ directory to your project:

- GTMHTTPFetcher.h/m
- GTMHTTPFetcherLogging.h/m (useful for debugging)
- GTMOAuthAuthentication.h/m
- GTMOAuthSignIn.h/m
- TripIt.h/m

An example iPhone application can be seen in the OAuthTouchExample/ directory. The main steps for creating this application to use the TripIt API binding are as follows:

- Info-iPad.plist / Info-iPad.plist
  - Add the 'URL types' property, which is an array. The 'URL types' is used to implement a custom URL scheme that can be used to open your application, and is needed as part of the OAuth flow. For more information, please read <a href="http://developer.apple.com/library/ios/#DOCUMENTATION/iPhone/Conceptual/iPhoneOSProgrammingGuide/AdvancedAppTricks/AdvancedAppTricks.html">Implementing Custom URL Schemes</a> in the iOS developer docs. Fill in two values in that array:
    - URL identifier: "com.tripit.api"
    - Url Schemes: This is also an array. Add an item to it, with value "tripitapp".

- OAuthSampleRootViewControllerTouch.m
  - This is the main view controller for the app. Look at the <i>signIntoTripit</i> method, which initializes the TripIt API object, and starts the OAuth flow.

- OAuthSampleAppDelegateTouch.m
  - The main app delegate should implement the <i>application:openURL:sourceApplication:annotation:</i> method, which is called when an application is opened in response to a custom URL scheme. Within this method, you need to call the performGetAuthorization: method of the TripIt API object in order to continue with a user's OAuth flow.

The doAnAuthenticatedAPIFetch: method within OAuthSampleRootViewControllerTouch.m has example API calls, both in XML and JSON.

Please also refer to the API's main page here:

http://tripit.github.com/api/
