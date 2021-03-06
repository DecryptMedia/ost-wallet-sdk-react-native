/*
 Copyright © 2019 OST.com Inc
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 */

#import <CoreImage/CoreImage.h>
#import "OstWalletRnSdk.h"
#import "OstWorkFlowCallbackImpl.h"
#import "OstRNErrorUtils.h"

@implementation OstWalletRnSdk

RCT_EXPORT_MODULE(OstWalletSdk) ;

#pragma mark - Initialize

RCT_EXPORT_METHOD(initialize:(NSString *)url
                  config: (NSDictionary *) config
                  callback:(RCTResponseSenderBlock)callback)
{
  __weak NSError *error = nil;
  
  [OstWalletSdk initializeWithApiEndPoint:url config: config error:&error];
  
  if (error != nil) {
    NSDictionary *err = [OstRNErrorUtils errorToJson: error internalCode: @"rn_owrs_init_1"];
    callback(@[ err ]);
    return;
  }
  callback(@[[NSNull null]]);
}

#pragma mark - Getters

RCT_EXPORT_METHOD(getUser: (NSString *)userId
                  callback:(RCTResponseSenderBlock)callback) {
  
  OstUser *user = [OstWalletSdk getUser:userId];
  if (nil != user) {
    callback( @[user.data ] );
    return;
  }
  
  callback( @[] );
}

RCT_EXPORT_METHOD(getToken: (NSString *)tokenId
                  callback:(RCTResponseSenderBlock)callback) {
  
  OstToken *token = [OstWalletSdk getToken: tokenId];
  if (nil != token) {
    callback( @[token.data ] );
    return;
  }

  callback( @[] );
}

RCT_EXPORT_METHOD(getActiveSessionsForUserId: (NSString * _Nonnull) userId
                  spendingLimit:(NSString * _Nullable) spendingLimit
                  callback:(RCTResponseSenderBlock)callback) {
  
  NSMutableArray <NSDictionary *> *response = [[NSMutableArray alloc]init];
  if ( nil == userId ) {
    callback( @[response] );
    return;
  }
  
  NSArray<OstSession *> *sessions = [OstWalletSdk getActiveSessionsWithUserId: userId spendingLimit: spendingLimit];
  if ( nil == sessions || sessions.count < 1 ) {
    callback( @[response] );
    return;
  }
  
  for(OstSession *s in sessions) {
    NSDictionary *data = s.data;
    [response addObject: data];
  }
  callback( @[response] );
}

RCT_EXPORT_METHOD(getCurrentDeviceForUserId: (NSString * _Nonnull) userId
                  callback:(RCTResponseSenderBlock)callback) {
  if ( nil == userId ) {
    callback( @[] );
    return;
  }
  OstUser *user = [OstWalletSdk getUser:userId];
  if ( nil == user ) {
    callback( @[] );
    return;
  }
  OstDevice *device = [user getCurrentDevice];
  if ( nil == device ) {
    callback( @[] );
    return;
  }

  callback( @[device.data]);
}

RCT_EXPORT_METHOD(isBiometricEnabled: (NSString *)userId
                  callback:(RCTResponseSenderBlock)callback) {
  
  BOOL isBiometricEnabled = [OstWalletSdk isBiometricEnabledWithUserId:userId];
  callback( @[@(isBiometricEnabled)] );
}

#pragma mark - Workflows

RCT_EXPORT_METHOD(setupDevice:(NSString *)userId
                  tokenId:(NSString *)tokenId
                  uuid:(NSString *)uuid)
{
  
  OstWorkflowContext *context = [[ OstWorkflowContext alloc] initWithWorkflowId:uuid workflowType:OstWorkflowTypeSetupDevice];
  OstWorkFlowCallbackImpl *workflowCallback = [[OstWorkFlowCallbackImpl alloc] initWithId: uuid workflowContext:context];
  [OstWalletSdk setupDeviceWithUserId: userId tokenId:tokenId forceSync: false delegate: workflowCallback];
}

RCT_EXPORT_METHOD(activateUser: (NSString *) userId
                  pin: (NSString *) pin
                  passphrasePrefix: (NSString *) passphrasePrefix
                  expiresAfterInSecs: (NSString *) expiresAfterInSecs
                  spendingLimit: (NSString *) spendingLimit
                  uuid: (NSString *) uuid){
  
  OstWorkflowContext *context = [[ OstWorkflowContext alloc] initWithWorkflowId:uuid workflowType:OstWorkflowTypeActivateUser];
  OstWorkFlowCallbackImpl *workflowCallback = [[OstWorkFlowCallbackImpl alloc] initWithId: uuid workflowContext:context];
  
  [OstWalletSdk activateUserWithUserId:userId
                               userPin:pin
                      passphrasePrefix:passphrasePrefix
                         spendingLimit:spendingLimit
                      expireAfterInSec: [expiresAfterInSecs doubleValue]
                              delegate:workflowCallback] ;
}

RCT_EXPORT_METHOD(addSession: (NSString *) userId
                  expiresAfterInSecs: (NSString *) expiresAfterInSecs
                  spendingLimit: (NSString *) spendingLimit
                  uuid: (NSString *) uuid )
{
  OstWorkflowContext *context = [[ OstWorkflowContext alloc] initWithWorkflowId:uuid workflowType:OstWorkflowTypeAddSession];
  OstWorkFlowCallbackImpl *workflowCallback = [[OstWorkFlowCallbackImpl alloc] initWithId: uuid workflowContext:context];
  
  [OstWalletSdk addSessionWithUserId:userId spendingLimit:spendingLimit expireAfterInSec:[expiresAfterInSecs doubleValue] delegate:workflowCallback];
  
}

RCT_EXPORT_METHOD(executeTransaction: (NSString *) userId
                  tokenHolderAddresses: (NSString *) tokenHolderAddresses
                  amounts: (NSString *) amounts
                  ruleName: (NSString *) ruleName
                  meta: (NSDictionary *) meta
                  options: (NSDictionary *) options
                  uuid: (NSString *) uuid )
{
  [OstWalletRnSdk coreExecuteTransaction: userId
                    tokenHolderAddresses: tokenHolderAddresses
                                 amounts: amounts
                                ruleName: ruleName
                                    meta: meta
                                 options: options
                                    uuid: uuid];
}
+ (void) coreExecuteTransaction: (NSString *) userId
           tokenHolderAddresses: (NSString *) tokenHolderAddresses
                        amounts: (NSString *) amounts
                       ruleName: (NSString *) ruleName
                           meta: (NSDictionary *) meta
                        options: (NSDictionary *) options
                           uuid: (NSString *) uuid
{
    OstWorkflowContext *context = [[ OstWorkflowContext alloc] initWithWorkflowId:uuid workflowType:OstWorkflowTypeExecuteTransaction];
    OstWorkFlowCallbackImpl *workflowCallback = [[OstWorkFlowCallbackImpl alloc] initWithId: uuid workflowContext:context];
    
    NSData *data = [tokenHolderAddresses dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    
    NSArray *addressesArr = [NSJSONSerialization
                             JSONObjectWithData:data
                             options:0
                             error:&error];
    
    if( nil != error ) {
        OstError *ostError = [OstRNErrorUtils invalidJsonArrayError:@"rn_owrs_et_1"];
        [workflowCallback flowInterruptedWithWorkflowContext: context error: ostError];
        return;
    }
    
    data = [amounts dataUsingEncoding:NSUTF8StringEncoding];
    error = nil;
    NSArray *amountsArr = [NSJSONSerialization
                           JSONObjectWithData:data
                           options:0
                           error:&error];
    
    if( nil != error ) {
        OstError *ostError = [OstRNErrorUtils invalidJsonArrayError:@"rn_owrs_et_2"];
        [workflowCallback flowInterruptedWithWorkflowContext: context error: ostError];
        return;
    }
    
    NSDictionary *metaObj = meta;
    if ( nil == metaObj ) {
      metaObj = [[NSDictionary alloc]init];
    }
  
    
    //Convert rule name to know rule enum.
    OstExecuteTransactionType ruleType;
    if ( [@"Pricer" caseInsensitiveCompare: ruleName] == NSOrderedSame ) {
        ruleType = OstExecuteTransactionTypePay;
    }else if ( [@"Direct Transfer" caseInsensitiveCompare: ruleName] == NSOrderedSame ){
        ruleType = OstExecuteTransactionTypeDirectTransfer;
    }else{
        OstError *ostError = [[OstError alloc]initWithInternalCode:@"rn_owrs_et_4"
                                                         errorCode: OstErrorCodeRulesNotFound
                                                         errorInfo: nil];
        [workflowCallback flowInterruptedWithWorkflowContext: context error: ostError];
        return;
    }
    
    [OstWalletSdk executeTransactionWithUserId:userId
                          tokenHolderAddresses:addressesArr
                                       amounts:amountsArr
                               transactionType:ruleType
                                          meta:metaObj
                                       options:options
                                      delegate:workflowCallback];
}

RCT_EXPORT_METHOD(getDeviceMnemonics: (NSString *) userId
                  uuid: (NSString *) uuid )
{
  
  OstWorkflowContext *context = [[ OstWorkflowContext alloc] initWithWorkflowId:uuid workflowType:OstWorkflowTypeGetDeviceMnemonics];
  OstWorkFlowCallbackImpl *workflowCallback = [[OstWorkFlowCallbackImpl alloc] initWithId: uuid workflowContext:context];
  
  [OstWalletSdk getDeviceMnemonicsWithUserId:userId delegate:workflowCallback];
}

RCT_EXPORT_METHOD(authorizeCurrentDeviceWithMnemonics: (NSString *) userId
                  mnemonics: (NSString *) mnemonics
                  uuid: (NSString *) uuid )
{
  
  OstWorkflowContext *context = [[ OstWorkflowContext alloc] initWithWorkflowId:uuid workflowType:OstWorkflowTypeAuthorizeDeviceWithMnemonics];
  OstWorkFlowCallbackImpl *workflowCallback = [[OstWorkFlowCallbackImpl alloc] initWithId: uuid workflowContext:context];
  
  NSArray *byteMnemonices = [mnemonics componentsSeparatedByString:@" "];
  [OstWalletSdk authorizeCurrentDeviceWithMnemonicsWithUserId:userId mnemonics:byteMnemonices delegate:workflowCallback];
  
}

RCT_EXPORT_METHOD(getAddDeviceQRCode: (NSString *) userId
                  successCallback:(RCTResponseSenderBlock)successCallback
                  errorCallback:(RCTResponseSenderBlock)errorCallback)
{
 
  NSError *error = nil;
  
  
  CIImage * img = [OstWalletSdk getAddDeviceQRCodeWithUserId:userId error: &error];
  if( error ){
    NSDictionary *err = [OstRNErrorUtils errorToJson: error internalCode: @"rn_owrs_gadqr_1"];
    errorCallback(@[ err ]);
    return;
  }
  CIContext *contextToUse = [[CIContext alloc]init];
  NSData *imgData = [contextToUse JPEGRepresentationOfImage: img
                                                 colorSpace: img.colorSpace
                                                    options:@{}];
  NSString *img64Str = [imgData base64EncodedStringWithOptions: NSDataBase64Encoding64CharacterLineLength];
  
  //Invoke successCallback
  successCallback(@[ img64Str ]);
  
}

RCT_EXPORT_METHOD(performQRAction: (NSString *) userId
                  data: (NSString *) data
                  uuid: (NSString *) uuid
                  )
{
  OstWorkflowContext *context = [[ OstWorkflowContext alloc] initWithWorkflowId:uuid workflowType:OstWorkflowTypePerformQRAction];
  OstWorkFlowCallbackImpl *workflowCallback = [[OstWorkFlowCallbackImpl alloc] initWithId: uuid workflowContext:context];
  
  [OstWalletSdk performQRActionWithUserId:userId payload:data delegate:workflowCallback];
}

RCT_EXPORT_METHOD(resetPin: (NSString *) userId
                  appSalt: (NSString *) appSalt
                  currentPin: (NSString *) currentPin
                  newPin: (NSString *) newPin
                  uuid: (NSString *) uuid
                  )
{
  OstWorkflowContext *context = [[ OstWorkflowContext alloc] initWithWorkflowId:uuid workflowType:OstWorkflowTypeResetPin];
  OstWorkFlowCallbackImpl *workflowCallback = [[OstWorkFlowCallbackImpl alloc] initWithId: uuid workflowContext:context];
  
  [OstWalletSdk resetPinWithUserId:userId passphrasePrefix:appSalt oldUserPin:currentPin newUserPin:newPin delegate:workflowCallback];
}

RCT_EXPORT_METHOD(initiateDeviceRecovery: (NSString *) userId
                  pin: (NSString *) pin
                  appSalt: (NSString *) appSalt
                  deviceAddressToRecover: (NSString *) deviceAddressToRecover
                  uuid: (NSString *) uuid
                  )
{
  OstWorkflowContext *context = [[ OstWorkflowContext alloc] initWithWorkflowId:uuid workflowType:OstWorkflowTypeInitiateDeviceRecovery];
  OstWorkFlowCallbackImpl *workflowCallback = [[OstWorkFlowCallbackImpl alloc] initWithId: uuid workflowContext:context];
  
  [OstWalletSdk initiateDeviceRecoveryWithUserId:userId recoverDeviceAddress:deviceAddressToRecover userPin:pin passphrasePrefix:appSalt delegate:workflowCallback];
}

RCT_EXPORT_METHOD(abortDeviceRecovery: (NSString *) userId
                  pin: (NSString *) pin
                  appSalt: (NSString *) appSalt
                  uuid: (NSString *) uuid
                  )
{
  OstWorkflowContext *context = [[ OstWorkflowContext alloc] initWithWorkflowId:uuid workflowType:OstWorkflowTypeAbortDeviceRecovery];
  OstWorkFlowCallbackImpl *workflowCallback = [[OstWorkFlowCallbackImpl alloc] initWithId: uuid workflowContext:context];
  
  [OstWalletSdk abortDeviceRecoveryWithUserId:userId userPin:pin passphrasePrefix:appSalt delegate:workflowCallback];
}

RCT_EXPORT_METHOD(revokeDevice: (NSString *) userId
                  deviceAddress: (NSString *) deviceAddress
                  uuid: (NSString *) uuid
                  )
{
  OstWorkflowContext *context = [[OstWorkflowContext alloc] initWithWorkflowId:uuid workflowType:OstWorkflowTypeRevokeDevice];
  OstWorkFlowCallbackImpl *workflowCallback = [[OstWorkFlowCallbackImpl alloc] initWithId: uuid workflowContext:context];
  
  [OstWalletSdk revokeDeviceWithUserId:userId deviceAddressToRevoke:deviceAddress delegate:workflowCallback];
}

RCT_EXPORT_METHOD(updateBiometricPreference: (NSString *) userId
                  enable: (BOOL) enable
                  uuid: (NSString *) uuid
                  )
{
  OstWorkflowContext *context = [[ OstWorkflowContext alloc] initWithWorkflowId:uuid workflowType:OstWorkflowTypeUpdateBiometricPreference];
  OstWorkFlowCallbackImpl *workflowCallback = [[OstWorkFlowCallbackImpl alloc] initWithId: uuid workflowContext:context];
  
  [OstWalletSdk updateBiometricPreferenceWithUserId:userId enable:enable delegate:workflowCallback];
}

RCT_EXPORT_METHOD(logoutAllSessions: (NSString *) userId
                  uuid: (NSString *) uuid
                  )
{
  OstWorkflowContext *context = [[ OstWorkflowContext alloc] initWithWorkflowId:uuid workflowType:OstWorkflowTypeLogoutAllSessions];
  OstWorkFlowCallbackImpl *workflowCallback = [[OstWorkFlowCallbackImpl alloc] initWithId: uuid workflowContext:context];
 
  [OstWalletSdk logoutAllSessionsWithUserId:userId delegate:workflowCallback];
}

@end
