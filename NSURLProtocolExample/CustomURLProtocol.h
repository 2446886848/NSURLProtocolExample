//
//  CustomURLProtocol.h
//  NSURLProtocolExample
//
//  Created by lujb on 15/6/15.
//  Copyright (c) 2015年 lujb. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CustomURLProtocol : NSURLProtocol

@property (nonatomic, strong, class) NSDictionary<NSString *, NSString *> *replacedUrlMap;

@end
