//
//  InfoUtil.m
//  WeexApp
//
//  Created by 韩炜伟 on 16/8/10.
//  Copyright © 2016年 taobao. All rights reserved.
//

#import "InfoUtil.h"


@implementation InfoUtil


+ (id) getInfo: (NSString *)bundleName{
    NSDictionary * infoDict = [[NSBundle mainBundle] infoDictionary];
    return [infoDict objectForKey :bundleName];

}

@end
