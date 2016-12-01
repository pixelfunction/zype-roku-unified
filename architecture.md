# App Architecture

## Components

### Grid Screens
To display content the app utilizes [Grid Screen](https://sdkdocs.roku.com/display/sdkdoc/roGridScreen). If the app is *nested*, the **channels** (`source/screens/home/home.brs`) function is called. Otherwise, the **grid** function is triggered.

### Video Details Screen
Details of a specific video are displayed using [Springboard Screen](https://sdkdocs.roku.com/display/sdkdoc/roSpringboardScreen).

### Content
To pull the content the app makes [API](http://dev.zype.com/api_docs/intro/) calls to Zype Platform using [App Key](http://dev.zype.com/glossary/). As example, check out the *get\_videos* function within `helpers/api_utility_functions/getters.brs`. You can easily utilize helper functions to add new query functions.

### App Settings
Every app can be configured through the Zype Platform. The app settings are pulled when the app is launched first time and available as a global object. Check out the *set\_dynamic\_config* function within `source/configs/config.brs`.

## Monetizations

### Device Linking and Entitlements (Universal SVOD, Redemption Codes)

In order to use *Native Subscription VOD* and *Entitlements*, the app must support Device Linking that let's generate an **access token**. Then, the access token can be used as an **authentication key**. If a video is monetized, we can check if a consumer with that very **access token** has access to that specific video, and can play it. The OAuth helper functions reside within `source/helpers/oauth/oauth.brs`

Device Linking is done through [Zype API](http://dev.zype.com/api_docs/device_linking/). Helper functions for the device linking reside within `source/helpers/linking/device_linking.brs`

The logic to decide to play or not a specific video can find within `source/screens/players/player.brs`, the *canPlay* function.

### In-App-Purchasing (Native SVOD/TVOD)

All In-App-Purchasing (Roku Billing Services) functions reside within `source/helpers/iap/iap.brs`. Here is a simple logic of the In-App-Purchasing flow for Roku: [Supporting In App Purchases in Your Roku BrightScript Channels](https://blog.roku.com/developer/2013/06/06/supporting-in-app-purchases-in-your-roku-brightscript-channels/) and [Roku Billing Services](https://blog.roku.com/developer/2016/04/07/roku-billing-services/).

### AVOD

To play ads the app uses [Roku Ad Framework](https://blog.roku.com/developer/2016/02/10/roku-ad-framework/).

If *show_ads* from `source/screens/players/player.brs` returns *True* then ads are going to play by calling *play\_episode\_with\_ad*. Otherwise, *play\_episode\_ad\_free*.

### Mixing Monetization Types

Coming soon!

