//
//  ReaderPostView.m
//  WordPress
//
//  Created by Michael Johnston on 11/19/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ReaderPostView.h"
#import "WPContentViewSubclass.h"
#import "ContentActionButton.h"
#import "UILabel+SuggestSize.h"
#import "NSAttributedString+HTML.h"
#import "NSString+Helpers.h" 

@interface ReaderPostView()

@property (nonatomic, strong) UIButton *tagButton;
@property (nonatomic, strong) UIButton *followButton;
@property (nonatomic, strong) UIButton *likeButton;
@property (nonatomic, strong) UIButton *reblogButton;
@property (nonatomic, strong) UIButton *commentButton;

@end

@implementation ReaderPostView

- (id)initWithFrame:(CGRect)frame showFullContent:(BOOL)showFullContent {
    self = [super initWithFrame:frame showFullContent:showFullContent];
    
    if (self) {
        UIView *contentView = self.showFullContent ? [self viewForFullContent] : [self viewForContentPreview];
        [self addSubview:contentView];

        // For the full view, allow the featured image to be tapped
        if (self.showFullContent) {
            UITapGestureRecognizer *imageTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(featuredImageAction:)];
            super.cellImageView.userInteractionEnabled = YES;
            [super.cellImageView addGestureRecognizer:imageTap];
        }

        _followButton = [ContentActionButton buttonWithType:UIButtonTypeCustom];
        _followButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        _followButton.backgroundColor = [UIColor clearColor];
        _followButton.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:12.0f];
        NSString *followString = NSLocalizedString(@"Follow", @"Prompt to follow a blog.");
        NSString *followedString = NSLocalizedString(@"Following", @"User is following the blog.");
        [_followButton setTitle:followString forState:UIControlStateNormal];
        [_followButton setTitle:followedString forState:UIControlStateSelected];
        [_followButton setTitleEdgeInsets: UIEdgeInsetsMake(0, RPVSmallButtonLeftPadding, 0, 0)];
        [_followButton setImage:[UIImage imageNamed:@"reader-postaction-follow"] forState:UIControlStateNormal];
        [_followButton setImage:[UIImage imageNamed:@"reader-postaction-following"] forState:UIControlStateSelected];
        [_followButton setTitleColor:[UIColor colorWithHexString:@"aaa"] forState:UIControlStateNormal];
        [_followButton addTarget:self action:@selector(followAction:) forControlEvents:UIControlEventTouchUpInside];
        [super.byView addSubview:_followButton];
        
        _tagButton = [ContentActionButton buttonWithType:UIButtonTypeCustom];
        _tagButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        _tagButton.backgroundColor = [UIColor clearColor];
        _tagButton.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:12.0f];
        [_tagButton setTitleEdgeInsets: UIEdgeInsetsMake(0, RPVSmallButtonLeftPadding, 0, 0)];
        [_tagButton setImage:[UIImage imageNamed:@"reader-postaction-tag"] forState:UIControlStateNormal];
        [_tagButton setTitleColor:[UIColor colorWithHexString:@"aaa"] forState:UIControlStateNormal];
        [_tagButton addTarget:self action:@selector(tagAction:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_tagButton];

        // Action buttons
        _reblogButton = [super addActionButtonWithImage:[UIImage imageNamed:@"reader-postaction-reblog-blue"] selectedImage:[UIImage imageNamed:@"reader-postaction-reblog-done"]];
        [_reblogButton addTarget:self action:@selector(reblogAction:) forControlEvents:UIControlEventTouchUpInside];
        
        _commentButton = [super addActionButtonWithImage:[UIImage imageNamed:@"reader-postaction-comment-blue"] selectedImage:[UIImage imageNamed:@"reader-postaction-comment-active"]];
        [_commentButton addTarget:self action:@selector(commentAction:) forControlEvents:UIControlEventTouchUpInside];
        
        _likeButton = [super addActionButtonWithImage:[UIImage imageNamed:@"reader-postaction-like-blue"] selectedImage:[UIImage imageNamed:@"reader-postaction-like-active"]];
        [_likeButton addTarget:self action:@selector(likeAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return self;
}

- (void)configurePost:(BasePost *)post withWidth:(CGFloat)width {
   
    // Margins
    CGFloat contentWidth = width;
    if (IS_IPAD) {
        contentWidth = WPTableViewFixedWidth;
    }
    contentWidth -= RPVHorizontalInnerPadding * 2;
    
    self.post = (ReaderPost *)post;
    self.contentProvider = self.post;
    
    // This will show the placeholder avatar. Do this here instead of prepareForReuse
    // so avatars show up after a cell is created, and not dequeued.
    [self setAvatar:nil];
    
    self.titleLabel.attributedText = [[self class] titleAttributedStringForTitle:self.post.postTitle
                                                                 showFullContent:self.showFullContent
                                                                       withWidth:contentWidth];
    
    if (self.showFullContent) {
        NSData *data = [self.post.content dataUsingEncoding:NSUTF8StringEncoding];
		self.textContentView.attributedString = [[NSAttributedString alloc] initWithHTMLData:data
                                                                                 options:[WPStyleGuide defaultDTCoreTextOptions]
                                                                      documentAttributes:nil];
        [self.textContentView relayoutText];
    } else {
        self.snippetLabel.attributedText = [[self class] summaryAttributedStringForString:self.post.summary];
    }
    
    self.bylineLabel.text = [self.post authorString];
    [self refreshDate];
    
	self.cellImageView.hidden = YES;
	if (self.post.featuredImageURL) {
		self.cellImageView.hidden = NO;
	}
    
    if ([self.post.primaryTagName length] > 0) {
        self.tagButton.hidden = NO;
        [self.tagButton setTitle:self.post.primaryTagName forState:UIControlStateNormal];
    } else {
        self.tagButton.hidden = YES;
    }
    
	if ([self.post isWPCom]) {
		self.likeButton.hidden = NO;
		self.reblogButton.hidden = NO;
        self.commentButton.hidden = NO;
	} else {
		self.likeButton.hidden = YES;
		self.reblogButton.hidden = YES;
        self.commentButton.hidden = YES;
	}
    
    [self.followButton setSelected:[self.post.isFollowing boolValue]];
	self.reblogButton.userInteractionEnabled = ![self.post.isReblogged boolValue];
	
	[self updateActionButtons];

}

- (void)layoutSubviews {

    // Determine button visibility before parent lays them out
    BOOL commentsOpen = [[self.post commentsOpen] boolValue] && [self.post isWPCom];
    self.commentButton.hidden = !commentsOpen;

	[super layoutSubviews];
}

- (CGFloat)layoutAttributionAt:(CGFloat)yPosition {
    yPosition = [super layoutAttributionAt:yPosition];
    
    CGFloat innerContentWidth = [self innerContentWidth];
    CGFloat bylineX = RPVAvatarSize + RPVAuthorPadding + RPVHorizontalInnerPadding;

    if ([self.post isFollowable]) {
        self.followButton.hidden = NO;
        CGFloat followX = bylineX - 4; // Fudge factor for image alignment
        CGFloat followY = RPVAuthorPadding + self.bylineLabel.frame.size.height - 2;
        CGFloat height = ceil([self.followButton.titleLabel suggestedSizeForWidth:innerContentWidth].height);
        self.followButton.frame = CGRectMake(followX, followY, RPVFollowButtonWidth, height);
    } else {
        self.followButton.hidden = YES;
    }
    
    return yPosition;
}

- (CGFloat)layoutTextContentAt:(CGFloat)yPosition {
    if ([self.post.summary length] == 0) {
        return yPosition;
    }
    return [super layoutTextContentAt:yPosition];
}

- (void)reset {
    [super reset];
    [self.tagButton setTitle:nil forState:UIControlStateNormal];
    [self.followButton setSelected:NO];
}

- (void)updateActionButtons {
    [super updateActionButtons];
    self.likeButton.selected = self.post.isLiked.boolValue;
    self.reblogButton.selected = self.post.isReblogged.boolValue;
	self.reblogButton.userInteractionEnabled = !self.reblogButton.selected;
}

- (void)setAvatar:(UIImage *)avatar {
    if (avatar) {
        self.avatarImageView.image = avatar;
    } else {
        self.avatarImageView.image = [UIImage imageNamed:@"gravatar-reader"];
    }
}

- (BOOL)privateContent {
    return self.post.isPrivate;
}


#pragma mark - Actions

- (void)reblogAction:(id)sender {
    if ([self.delegate respondsToSelector:@selector(postView:didReceiveReblogAction:)]) {
        [self.delegate postView:self didReceiveReblogAction:sender];
    }
}

- (void)commentAction:(id)sender {
    if ([self.delegate respondsToSelector:@selector(postView:didReceiveCommentAction:)]) {
        [self.delegate postView:self didReceiveCommentAction:sender];
    }
}

- (void)likeAction:(id)sender {
    if ([self.delegate respondsToSelector:@selector(postView:didReceiveLikeAction:)]) {
        [self.delegate postView:self didReceiveLikeAction:sender];
    }
}

@end
