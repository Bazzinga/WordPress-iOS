//
//  BasePostContentView.h
//  WordPress
//
//  Created by Eric Johnson on 2/28/14.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import "WPContentView.h"
#import "WPContentViewProvider.h"

@class BasePost;

@interface BasePostContentView : WPContentView

@property (assign) BOOL showFullContent;

+ (CGFloat)heightForContentViewProvider:(id<WPContentViewProvider>)provider withWidth:(CGFloat)width showFullContent:(BOOL)showFullContent;
+ (NSAttributedString *)titleAttributedStringForTitle:(NSString *)title showFullContent:(BOOL)showFullContent withWidth:(CGFloat) width;
+ (NSAttributedString *)summaryAttributedStringForString:(NSString *)string;

- (id)initWithFrame:(CGRect)frame showFullContent:(BOOL)showFullContent;
- (void)configurePost:(BasePost *)post withWidth:(CGFloat)width;
- (CGFloat)contentWidth;
- (CGFloat)innerContentWidth;

@end
