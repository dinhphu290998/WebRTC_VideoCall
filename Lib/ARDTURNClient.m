/*
 *  Copyright 2014 The WebRTC Project Authors. All rights reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. An additional intellectual property rights grant can be found
 *  in the file PATENTS.  All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

#import "ARDTURNClient+Internal.h"

#import "ARDUtilities.h"
#import "RTCIceServer+JSON.h"

// TODO(tkchin): move this to a configuration object.
static NSString *kTURNRefererURLString = @"https://appr.tc";
static NSString *kARDTURNClientErrorDomain = @"ARDTURNClient";
static NSInteger kARDTURNClientErrorBadResponse = -1;

@implementation ARDTURNClient {
  NSURL *_url;
}

- (instancetype)initWithURL:(NSURL *)url {
  NSParameterAssert([url absoluteString].length);
  if (self = [super init]) {
    _url = url;
  }
  return self;
}

- (void)requestServersWithCompletionHandler:
(void (^)(NSArray *turnServers, NSError *error))completionHandler {

  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:_url];
  [NSURLConnection sendAsyncRequest:request
                  completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                    if (error) {
                      completionHandler(nil, error);
                      return;
                    }
                    NSDictionary *responseDict = [NSDictionary dictionaryWithJSONData:data];
                    NSString *iceServerUrl = responseDict[@"ice_server_url"];
                    [self makeTurnServerRequestToURL:[NSURL URLWithString:iceServerUrl]
                               WithCompletionHandler:completionHandler];
                  }];
}

#pragma mark - Private

- (void)makeTurnServerRequestToURL:(NSURL *)url
             WithCompletionHandler:(void (^)(NSArray *turnServers,
                                             NSError *error))completionHandler {
  NSMutableURLRequest *iceServerRequest = [NSMutableURLRequest requestWithURL:url];
  iceServerRequest.HTTPMethod = @"POST";
  [iceServerRequest addValue:kTURNRefererURLString forHTTPHeaderField:@"referer"];
  [NSURLConnection sendAsyncRequest:iceServerRequest
                  completionHandler:^(NSURLResponse *response,
                                      NSData *data,
                                      NSError *error) {
                    if (error) {
                      completionHandler(nil, error);
                      return;
                    }

                    //      NSDictionary *turnResponseDict = [NSDictionary dictionaryWithJSONData:data];

                    NSDictionary *turnResponseDict;
                    turnResponseDict = @{@"lifetimeDuration": @"86400s",
                                         @"iceServers": @[@{
                                                            @"urls": @[@"turn:157.7.209.73:1908"],
                                                            @"username": @"vmio",
                                                            @"credential": @"vm69vm69"
                                                            }
//                                                            @"urls": @[@"turn:192.158.29.39:3478?transport=udp",
//                                                                       @"turn:192.158.29.39:3478?transport=tcp"],
//                                                            @"username": @"28224511:1379330808",
//                                                            @"credential": @"JZEOEt2V3Qb0y27GRntt2u2PAYA="
//                                                            }, @{
//                                                            @"urls": @[@"stun:stun01.sipphone.com",
//                                                                       @"stun:stun.ekiga.net",
//                                                                       @"stun:stun.fwdnet.net",
//                                                                       @"stun:stun.ideasip.com",
//                                                                       @"stun:stun.iptel.org",
//                                                                       @"stun:stun.rixtelecom.se",
//                                                                       @"stun:stun.schlund.de",
//                                                                       @"stun:stunserver.org",
//                                                                       @"stun:stun.softjoys.com",
//                                                                       @"stun:stun.voiparound.com",
//                                                                       @"stun:stun.voipbuster.com",
//                                                                       @"stun:stun.voipstunt.com",
//                                                                       @"stun:stun.voxgratia.org",
//                                                                       @"stun:stun.xten.com"
//                                                                       ]
//                                                            }
                                                          ],
                                         @"blockStatus": @"NOT_BLOCKED",
                                         @"iceTransportPolicy": @"all"
                                         };
                    NSMutableArray *turnServers = [NSMutableArray array];
                    [turnResponseDict[@"iceServers"] enumerateObjectsUsingBlock:
                     ^(NSDictionary *obj, NSUInteger idx, BOOL *stop){
                       [turnServers addObject:[RTCIceServer serverFromJSONDictionary:obj]];
                     }];
                    if (!turnServers) {
                      NSError *responseError =
                      [[NSError alloc] initWithDomain:kARDTURNClientErrorDomain
                                                 code:kARDTURNClientErrorBadResponse
                                             userInfo:@{
                                                        NSLocalizedDescriptionKey: @"Bad TURN response.",
                                                        }];
                      completionHandler(nil, responseError);
                      return;
                    }
                    completionHandler(turnServers, nil);
                  }];
}

@end
