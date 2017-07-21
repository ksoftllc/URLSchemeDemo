//
//  CMSecureUrlScheme.h
//  HANDI
//
//  Created by Chuck Krutsinger on 7/18/17.
//  Copyright © 2017 Countermind. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 *  Class for validating that a URL with a JWT in the query string conforms to a URL scheme as defined by 
 *  SecureUrlSchemeConfig.plist file. Validations include: JWT signature is valid, payload includes
 *  a timestamp that is within the acceptable age (usually seconds), payload includes a user name that 
 *  is the same as the user currently logged in, the URL host is one of the verbs accepted by the scheme,
 *  and that the application that sent the URL is white listed as an acceptable source.
 *
 *  Usage is to initWithUrlReceived:options: then confirm with isValid before carrying out the action indicated by the 
 *  URL. After being initialized and validated, the verb (host portion of URL) will be populated and the app can then
 *  proceed to act on it.
 */
@interface CMSecureUrlSchemeValidator : NSObject

/**
 * User id of authenticated user if included in payload. Will be encoded into outgoing URL or decoded from arriving URL.
 */

/**
 * Verb (host portion of URL) describing what action an incoming URL is requesting
 */
@property (nonatomic, readonly, strong)   NSString* _Nullable verb;

/**
 * Creates an instance using the scheme definition plist and the URL.
 * 
 * @param   tURL        the URL that is to be opened if valid
 * @param   tOptions    A dictionary of URL handling options provided with URL when passed to AppDelegate. Dictionary
 *                      should contain a value for UIApplicationOpenURLOptionsSourceApplicationKey with the bundle ID 
 *                      of the app that is trying to open the URL.
 * @return  instance
 */
- (instancetype _Nullable )initWithUrlReceived:(nonnull NSURL*)tURL
                                       options:(nonnull NSDictionary<UIApplicationOpenURLOptionsKey,id> *)tOptions;

/**
 * Confirms that the URL scheme is fully initialized and that the URL is valid and has a properly signed JWT in the 
 * query string. In the process, it decodes the JWT payload and populates the relevant properties after confirming
 * that the user name in the payload matches the currently logged in user.
 *
 * @return  YES if valid URL that conforms to the scheme and is properly signed. Otherwise returns NO.
 */
- (BOOL)isValid;

@end


/**
 * Completion block for after a URL is opened.
 *
 * @param success   YES if the URL was opened, otherwise NO
 */
typedef void (^OpenUrlCompletionBlock)(BOOL success);

/**
 * Class that will validate, sign and append a JWT, and then open a URL. 
 *
 * Usage is initWithUrlString: and then call openWithCompletionBlock: to open the URL.
 */
@interface CMSecureUrlSchemeOpener : NSObject

/**
 * User id of authenticated user if included in payload. Will be encoded into outgoing URL or decoded from arriving URL.
 */

/**
 * Verb (host portion of URL) describing what action an incoming URL is requesting
 */
@property (nonatomic, readonly, strong)   NSString* _Nullable verb;

/**
 * Creates a URL and appends a signed JWT in the query string. Does not open the URL. To do that, call open on this 
 * instance. The JWT will have a payload containing the user name of the MI Clinic user currently logged in
 * and a timestamp for when the JWT was created.
 *
 * @param   tUrlString          a string for the URL to be opened
 */
- (instancetype _Nullable )initWithUrlString:(nonnull NSString*)tUrlString;

/*!
 * Opens the URL and then executes the completion block passing in a BOOL to indicate if the URL opened.
 * @b WARNING: Will fail to open if the scheme is not white listed in the Info.plist file in the
 * @c LSApplicationQueriesSchemes array of strings.
 *
 * @param tCompletionBlock  code to execute after the URL open is attempted. BOOL param will indicate if URL opened.
 */
- (void)openWithCompletionBlock:(nullable OpenUrlCompletionBlock)tCompletionBlock;

@end
