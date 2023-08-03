#import <Availability.h>
#import "ASWebAuthSession.h"

#import <AuthenticationServices/ASWebAuthenticationSession.h>

#import <Cordova/CDVAvailability.h>

API_AVAILABLE(ios(12.0))
ASWebAuthenticationSession *_asAuthenticationVC;

@implementation ASWebAuthSession;

- (void)pluginInitialize {
}

-(void)appIsActive {
    [_asAuthenticationVC start];
}

-(void)cancel:(CDVInvokedUrlCommand *)command {
    CDVPluginResult *result;

    // Check if the authentication session is initialized and cancel it
    if (_asAuthenticationVC) {
        [_asAuthenticationVC cancel];
        _asAuthenticationVC = nil;
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString: @"Authentication session canceled"];
    } else {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"error"];
    }

    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void)start:(CDVInvokedUrlCommand *)command {

    if (@available(iOS 12.0, *)) {
        NSString* redirectScheme = [command.arguments objectAtIndex:0];
        NSURL* requestURL = [NSURL URLWithString:[command.arguments objectAtIndex:1]];

        redirectScheme = [redirectScheme stringByAddingPercentEncodingWithAllowedCharacters: [NSCharacterSet URLHostAllowedCharacterSet]];

        ASWebAuthenticationSession* authenticationVC =
        [[ASWebAuthenticationSession alloc] initWithURL:requestURL
                                   callbackURLScheme: [[NSURL URLWithString: redirectScheme] scheme]
                                   completionHandler:^(NSURL * _Nullable callbackURL,
                                                       NSError * _Nullable error) {
                                       CDVPluginResult *result;
                                       if (callbackURL) {
                                           result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString: callbackURL.absoluteString];

                                       } else {
                                           result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"error"];
                                       }

                                       [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
                                        _asAuthenticationVC = nil;
                                   }];

        // Need to keep a strong reference for < iOS 13.0 until the authentication session is complete
        _asAuthenticationVC = authenticationVC;
        if (@available(iOS 13.0, *)) {
            _asAuthenticationVC.presentationContextProvider = self;
        }

        UIApplicationState state = [UIApplication sharedApplication].applicationState;
        if (state != UIApplicationStateActive) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appIsActive) name:UIApplicationDidBecomeActiveNotification object:nil];
        } else {
            [self appIsActive];
        }
    }
}

- (nonnull ASPresentationAnchor)presentationAnchorForWebAuthenticationSession:(nonnull ASWebAuthenticationSession *)session API_AVAILABLE(ios(13.0)){
    return [[[UIApplication sharedApplication] windows] firstObject];
}

@end
