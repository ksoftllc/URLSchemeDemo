//
//  CMSecureUrlScheme.m
//  HANDI
//
//  Created by Chuck Krutsinger on 7/18/17.
//  Copyright © 2017 Countermind. All rights reserved.
//

#import "CMSecureUrlScheme.h"
#import <JWT/JWT.h>

//keys used in the query string
#define kJWT_QUERY_KEY @"jwt"
#define kCALLBACK_QUERY_KEY @"callback"

//keys used in JWT decoder and encoder
#define kPAYLOAD_KEY @"payload"

//keys used in the JWT claim
#define kUSER_CLAIM_KEY @"user"
#define kTIMESTAMP_CLAIM_KEY @"timestamp"

//keys used in SecureUrlSchemeConfig.plist
#define kSchemeName       @"SchemeName"
#define kValidSchemeHosts @"ValidSchemeHosts"
#define kSourceApplicationWhiteList @"SourceApplicationWhiteList"
#define kSecondsUntilTokensExpire @"SecondsUntilTokensExpire"


@interface CMSecureUrlSchemeValidator ()

@property (nonatomic, strong)   NSString*               payloadUser;
@property (nonatomic, strong)   NSNumber*               payloadTimestamp;
@property (nonatomic, strong)   NSURL*                  url;
@property (nonatomic, strong)   NSString*               sourceApplication;
@property (nonatomic, strong)   NSString*               schemeName;
@property (nonatomic, strong)   NSArray*                validSchemeHosts;
@property (nonatomic, strong)   NSDictionary*           sourceApplicationWhiteList;
@property (nonatomic, strong)   NSString*               jwt;
@property (nonatomic, strong)   NSData*                 miClinicPublicKey;
@property (nonatomic, strong)   NSData*                 sourceApplicationPublicKey;
@property (nonatomic, strong)   NSDictionary*           payload;
@property (nonatomic, assign)   NSInteger               secondsUntilTokensExpire;
@property (nonatomic, assign)   NSTimeInterval          ageOfTimestampInSeconds;

@end

@implementation CMSecureUrlSchemeValidator

@synthesize verb = m_verb;

#pragma mark - Public 

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        NSBundle* aBundle = [NSBundle bundleForClass:[self class]];
        NSString* aSecureUrlSchemeConfigFile = [aBundle pathForResource:@"SecureUrlSchemeConfig" ofType:@"plist"];
        if (aSecureUrlSchemeConfigFile)
        {
            NSDictionary* aSchemeConfigDict = [[NSDictionary alloc] initWithContentsOfFile:aSecureUrlSchemeConfigFile];
            if (aSchemeConfigDict)
            {
                self.schemeName = [aSchemeConfigDict objectForKey:kSchemeName];
                self.validSchemeHosts = [aSchemeConfigDict objectForKey:kValidSchemeHosts];
                self.sourceApplicationWhiteList = [aSchemeConfigDict objectForKey:kSourceApplicationWhiteList];
                NSString* aPublicKeyPath = [aBundle pathForResource:@"miclinic_public_key" ofType:@"crt"];
                self.miClinicPublicKey = [[NSData alloc] initWithContentsOfFile:aPublicKeyPath];
                self.secondsUntilTokensExpire = [[aSchemeConfigDict objectForKey:kSecondsUntilTokensExpire] integerValue];
            }
        }
    }
    return self;
}

- (instancetype)initWithUrlReceived:(NSURL*)tURL
                            options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)tOptions
{
    self = [self init];
    if (self && [self didInitializeWithUrlReceived])
    {
        self.url = tURL;
        self.sourceApplication = [tOptions objectForKey:UIApplicationOpenURLOptionsSourceApplicationKey];
        self.jwt = [[self parametersDictionaryFromQuery:[tURL query]] objectForKey:kJWT_QUERY_KEY];
        m_verb = [self.url host];
        [self loadSourceApplicationPublicKey:self.sourceApplication];
    }
    return self;
}

-(BOOL)isValid
{
    //series of guard clauses
    
    if (![self didInitializeWithUrlReceived])
    {
        NSLog(@"Unable to open URL %@ because scheme did not initialize", [self.url absoluteString]);
        return NO;
    }
    
    if (![self isSourceApplicationWhiteListed])
    {
        NSLog(@"URL %@ rejected because calling app %@ is not white listed"
                   ,[self.url absoluteString]
                   ,self.sourceApplication);
        return NO;
    }
    
    if (![self isValidHostCommand])
    {
        NSLog(@"Unable to open URL %@ - %@ is not a valid host value"
                   , [self.url absoluteString]
                   , [self.url host]);
        return NO;
    }
    
    if (!self.jwt)
    {
        NSLog(@"Unable to open URL %@ - does not contain required JWT", [self.url absoluteString]);
        return NO;
    }
    
    if (!self.sourceApplicationPublicKey)
    {
        NSLog(@"Public key for source application %@ failed to load.", self.sourceApplication);
        return NO;
    }
    
    if (![self didDecodeJWT])
    {
        //error already logged
        return NO;
    }
    
    if (!self.payloadTimestamp)
    {
        NSLog(@"URL did not include timestamp in JWT payload");
        return NO;
    }
    
    if (![self freshTimestamp])
    {
        NSLog(@"Timestamp had expired - aged %fl seconds", self.ageOfTimestampInSeconds);
        return NO;
    }
    
    if (![self isCurrentUsername])
    {
        NSLog(@"URL payload is from different user than current user: %@", self.payloadUser);
        return NO;
    }
    
    //at this point everything has checked out, URL valid
    return YES;
}

#pragma mark - Private

- (BOOL)isSourceApplicationWhiteListed
{
    NSPredicate* aSourceAppPrefixIsInSourceAppWhiteList = [NSPredicate predicateWithFormat:@"%@ BEGINSWITH SELF"
                                                           , self.sourceApplication];
    
    NSArray* aMatches = [self.sourceApplicationWhiteList.allKeys filteredArrayUsingPredicate:aSourceAppPrefixIsInSourceAppWhiteList];
    BOOL aIsWhiteListed = aMatches.count > 0;
    if (aIsWhiteListed)
    {
        [self loadSourceApplicationPublicKey:[self.sourceApplicationWhiteList objectForKey:[aMatches firstObject]]];
    }
    return aIsWhiteListed;
}


- (BOOL)didDecodeJWT
{
    BOOL aDidDecode = NO;
#pragma clang diagnostic push //supress warnings for deprecated call
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    JWTBuilder* aDecoder = [JWT decodeMessage:self.jwt].secretData(self.sourceApplicationPublicKey).algorithmName(@"RS256");
#pragma clang diagnostic pop
    self.payload = [aDecoder.decode objectForKey:kPAYLOAD_KEY];
    if (!aDecoder.jwtError)
    {
        self.payloadUser = [self.payload objectForKey:kUSER_CLAIM_KEY];
        self.payloadTimestamp = [self.payload objectForKey:kTIMESTAMP_CLAIM_KEY];
        self.ageOfTimestampInSeconds = -[[[NSDate alloc] initWithTimeIntervalSince1970:[self.payloadTimestamp doubleValue]] timeIntervalSinceNow];
        aDidDecode = YES;
    }
    else
    {
        //any problem with JWT will wind up here - bad signature, JWT altered, etc.
        NSLog(@"Unable to decode JWT: %@ - %@", self.jwt, aDecoder.jwtError);
    }
    return aDidDecode;
}

- (void)loadSourceApplicationPublicKey:(NSString*)tSourceApplicationKeyName
{
    NSBundle* aBundle = [NSBundle bundleForClass:[self class]];
    NSString* aPublicKeyPath = [aBundle pathForResource:tSourceApplicationKeyName
                                                 ofType:@"crt"];
    self.sourceApplicationPublicKey = [[NSData alloc] initWithContentsOfFile:aPublicKeyPath];
}

- (NSDictionary*)parametersDictionaryFromQuery:(NSString*)tQuery
{
    NSString* aQueryString = [tQuery stringByRemovingPercentEncoding];
    NSMutableDictionary* queryDict = [NSMutableDictionary new];
    NSArray* queryComponents = [aQueryString componentsSeparatedByString:@"&"];
    for (NSString* pair in queryComponents)
    {
        NSArray* elements = [pair componentsSeparatedByString:@"="];
        NSString* key = elements[0];
        NSString* val = elements[1];
        [queryDict setObject:val forKey:key];
    }
    return queryDict;
}

- (BOOL)isValidHostCommand
{
    BOOL isValidHostCommand = NO;
    if ([self.validSchemeHosts containsObject:[self.url host]])
    {
        isValidHostCommand = YES;
    }
    
    return isValidHostCommand;
}

- (BOOL)didInitializeWithUrlReceived
{
    BOOL aDidInitialize = NO;
    if (self.schemeName
        && self.miClinicPublicKey
        && self.validSchemeHosts
        && self.sourceApplicationWhiteList)
    {
        aDidInitialize = YES;
    }
    return aDidInitialize;
}

#define HARDCODED_USERNAME_FOR_DEMO @"g"

- (BOOL)isCurrentUsername
{
    NSString* aCurrentUsername = HARDCODED_USERNAME_FOR_DEMO; //hardcoded for this demo app
    return [self.payloadUser isEqualToString:aCurrentUsername];
}

- (BOOL)freshTimestamp
{
    return self.ageOfTimestampInSeconds < self.secondsUntilTokensExpire;
}

@end


@interface CMSecureUrlSchemeOpener ()

@property (nonatomic, strong)   NSString*               payloadUser;
@property (nonatomic, strong)   NSNumber*               payloadTimestamp;
@property (nonatomic, strong)   NSURL*                  url;
@property (nonatomic, strong)   NSString*               jwt;
@property (nonatomic, strong)   NSData*                 privateKey;
@property (nonatomic, strong)   NSDictionary*           payload;
@property (nonatomic, strong)   OpenUrlCompletionBlock  openUrlCompletionBlock;
@property (nonatomic, weak)     UIApplication*          application; //to allow test mock instance

@end

@implementation CMSecureUrlSchemeOpener

#pragma mark - Public

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        NSBundle* aBundle = [NSBundle bundleForClass:[self class]];
        NSString* aPrivateKeyPath = [aBundle pathForResource:@"private_key_demo" ofType:@"p12"];
        self.privateKey = [[NSData alloc] initWithContentsOfFile:aPrivateKeyPath];
        self.application = [UIApplication sharedApplication];
    }
    return self;
}

-(instancetype)initWithUrlString:(NSString *)tUrlString
{
    self = [self init];
    if (self)
    {
        self.url = [NSURL URLWithString:tUrlString];
    }
    return self;
}

-(void)openWithCompletionBlock:(OpenUrlCompletionBlock)tCompletionBlock
{
    BOOL aSuccess = YES;
    self.openUrlCompletionBlock = tCompletionBlock;
    
    if (![self didInitializeToOpenUrl])
    {
        NSLog(@"URL scheme did not successfully initialize URL: %@", self.url);
        aSuccess = NO;
    }
    else if (![self.application canOpenURL:self.url])
    {
        NSLog(@"Application for this URL %@ is not installed or not white listed", self.url);
        aSuccess = NO;
    }
    else if (![self jwtAddedToQuery])
    {
        NSLog(@"Unable to append JWT to query string of URL %@", self.url);
        aSuccess = NO;
    }
    
    if (aSuccess)
    {
        [self.application openURL:self.url
                          options:@{}
                completionHandler:self.openUrlCompletionBlock];
    }
    else
    {
        [self executeCompletionBlockWith:aSuccess];
    }
}

#pragma mark - Private

- (BOOL)jwtAddedToQuery
{
    BOOL aJwtCreated = NO;
    NSError* aErr;
    NSString* aJWT = [self jsonWebTokenWithPayload:@{} error:&aErr];
    if (aErr)
    {
        NSLog(@"Unable to create JWT - %@", aErr);
    }
    else
    {
        aJwtCreated = YES;
        NSString* aUrlString = [NSString stringWithFormat:@"%@?jwt=%@"
                                , self.url.absoluteString
                                , aJWT];
        self.url = [NSURL URLWithString:aUrlString];
    }
    return aJwtCreated;
}

- (NSString*)jsonWebTokenWithPayload:(NSDictionary* _Nullable)tPayloadDict error:(NSError ** _Nullable)tError
{
    NSMutableDictionary* aCombinedPayloadDict = [NSMutableDictionary new];
    [aCombinedPayloadDict addEntriesFromDictionary:tPayloadDict ? tPayloadDict : @{}];
    [aCombinedPayloadDict addEntriesFromDictionary:@{
                                                     kUSER_CLAIM_KEY:HARDCODED_USERNAME_FOR_DEMO,
                                                     kTIMESTAMP_CLAIM_KEY:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]]
                                                     }];
#pragma GCC diagnostic push //methods marked as deprecated before implementing new API - ignore them
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
    JWTBuilder* aJwtBuilder = [JWT encodePayload:aCombinedPayloadDict]
    .secretData(self.privateKey)
    .privateKeyCertificatePassphrase(@"Countermind!")
    .algorithmName(@"RS256");
#pragma GCC diagnostic pop
    NSString* aJwt = aJwtBuilder.encode;
    
    *tError = aJwtBuilder.jwtError; //pass any errors along
    return aJwt;
}

- (void)executeCompletionBlockWith:(BOOL)tSuccess
{
    if (self.openUrlCompletionBlock)
    {
        self.openUrlCompletionBlock(tSuccess);
    }
}

- (BOOL)didInitializeToOpenUrl
{
    BOOL aDidInitialize = NO;
    if (self.url && self.privateKey)
    {
        aDidInitialize = YES;
    }
    return aDidInitialize;
}


@end
