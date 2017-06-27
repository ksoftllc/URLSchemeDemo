//
//  CMRsaEncryptor.m
//
//  Created by Charles Krutsinger on 1/22/15.
//
//  Copyright (c) 2015 Countermind. All rights reserved.
//

#import "CMRsaEncryptor.h"

@implementation CMRsaEncryptor
{
    SecKeyRef           m_key;
}

-(CMRsaEncryptor *)initWithPublicKey:(NSString *)tPublicKeyCertificatePath
{
    self = [super init];
    
    if (self)
    {
        NSData* aCertData = [[NSFileManager  defaultManager] contentsAtPath: tPublicKeyCertificatePath];
        
        SecCertificateRef aCertificateRef = SecCertificateCreateWithData(kCFAllocatorDefault, (__bridge CFDataRef)aCertData);
        if (aCertificateRef != NULL) {
            SecTrustRef aTrustRef = NULL;
            SecPolicyRef aPolicyRef = SecPolicyCreateBasicX509();
            
            if (aPolicyRef) {
                if (SecTrustCreateWithCertificates((CFTypeRef)aCertificateRef, aPolicyRef, &aTrustRef) == noErr) {
                    SecTrustResultType result;
                    if (SecTrustEvaluate(aTrustRef, &result) == noErr) {
                        m_key = SecTrustCopyPublicKey(aTrustRef);
                    }
                }
            }
            
            if (aPolicyRef) CFRelease(aPolicyRef);
            if (aTrustRef) CFRelease(aTrustRef);
            if (aCertificateRef) CFRelease(aCertificateRef);
        }
    }
    return m_key ? self : nil;
}

- (NSString *)encryptRSA:(NSString *)tPlainTextString
{
    size_t cipherBufferSize = SecKeyGetBlockSize(m_key);
    uint8_t *cipherBuffer = malloc(cipherBufferSize);
    uint8_t *nonce = (uint8_t *)[tPlainTextString UTF8String];
    SecKeyEncrypt(m_key,
                  kSecPaddingPKCS1,
                  nonce,
                  strlen( (char*)nonce ),
                  &cipherBuffer[0],
                  &cipherBufferSize);
    NSData *encryptedData = [NSData dataWithBytes:cipherBuffer length:cipherBufferSize];
    return [encryptedData base64EncodedStringWithOptions:0];
}

@end
