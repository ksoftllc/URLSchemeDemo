//
//  CMRsaDecryptor.m
//
//  Created by Charles Krutsinger on 1/22/15.
//
//  Copyright (c) 2015 Countermind. All rights reserved.
//

#import "CMRsaDecryptor.h"

@implementation CMRsaDecryptor
{
    SecKeyRef           m_key;
}

-(CMRsaDecryptor *)initWithPrivateKey:(NSString *)tPrivateKeyPath withPassphrase:(NSString *)tPassphrase
{
    self = [super init];
    if (self)
    {
        NSData *aP12Data = [[NSFileManager  defaultManager] contentsAtPath: tPrivateKeyPath];
        
        NSMutableDictionary * aKeyOptionsDict = [[NSMutableDictionary alloc] init];
        
        //change to the actual password you used here
        [aKeyOptionsDict setObject:tPassphrase forKey:(__bridge id)kSecImportExportPassphrase];
        
        CFArrayRef aItemsImported = CFArrayCreate(NULL, 0, 0, NULL);
        
        OSStatus aSecurityError = SecPKCS12Import((__bridge CFDataRef) aP12Data,
                                                  (__bridge CFDictionaryRef)aKeyOptionsDict, &aItemsImported);
        
        if (aSecurityError == noErr && CFArrayGetCount(aItemsImported) > 0) {
            CFDictionaryRef aIdentityDict = CFArrayGetValueAtIndex(aItemsImported, 0);
            SecIdentityRef aIdentityRef = (SecIdentityRef)CFDictionaryGetValue(aIdentityDict, kSecImportItemIdentity);
            
            aSecurityError = SecIdentityCopyPrivateKey(aIdentityRef, &m_key);
            
            if (aSecurityError != noErr) {
                m_key = NULL;
            }
        }
        CFRelease(aItemsImported);
    }
    return self;
}

- (NSString *)decryptRSA:(NSString *)tCipherString
{
    size_t plainBufferSize = SecKeyGetBlockSize(m_key);
    uint8_t *plainBuffer = malloc(plainBufferSize);
    NSData *incomingData = [[NSData alloc] initWithBase64EncodedString:tCipherString options:0];
    uint8_t *cipherBuffer = (uint8_t*)[incomingData bytes];
    size_t cipherBufferSize = SecKeyGetBlockSize(m_key);
    SecKeyDecrypt(m_key,
                  kSecPaddingPKCS1,
                  cipherBuffer,
                  cipherBufferSize,
                  plainBuffer,
                  &plainBufferSize);
    NSData *decryptedData = [NSData dataWithBytes:plainBuffer length:plainBufferSize];
    return [[NSString alloc] initWithData:decryptedData encoding:NSUTF8StringEncoding];
}

@end
