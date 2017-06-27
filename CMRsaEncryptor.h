//
//  CMRsaEncryptor.h
//
//  Created by Charles Krutsinger on 1/22/15.
//
//  Copyright (c) 2015 Countermind. All rights reserved.
//
//  makes use of a self-signed certificate pair generated by
//  openssl req -x509 -out public_key.pem -outform PEM -new -newkey rsa:4096 -keyout private_key.pem -keyform PEM -days 3650
//  openssl pkcs12 -export -in public_key.pem -inkey private_key.pem -out private_key.p12
//  openssl x509 -in public_key.pem -inform PEM -out public_key.crt -outform DER
//  passphrase countermind
//
//  By default, in iOS private keys cannot be used to encrypt.

@interface CMRsaEncryptor : NSObject

/**
 *  Initialize RSA object with a public key certificate in DER format.
 *
 *  @param tPublicKeyCertificatePath path to public key certificate in DER format.
 *
 *  @return instance
 */
- (CMRsaEncryptor *)initWithPublicKey:(NSString *)tPublicKeyCertificatePath;

/**
 *  Encrypt plain text string using RSA encryption.
 *
 *  @param tPlainTextString string to be encoded
 *
 *  @return cipher text in Base 64 format
 */
-(NSString *)encryptRSA:(NSString *)tPlainTextString;

@end
