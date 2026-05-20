//
//  CYLFlatDesignTabBarItem.m
//  CYLFlatDesignTabBarController
//
//  Created by apple on 2026/2/6.
//

#import "CYLFlatDesignTabBarItem.h"

NSString *const CYLFlatDesignTabBarItemDidChange = @"CYLFlatDesignTabBarItemDidChange";

@interface CYLFlatDesignTabBarItem ()

@property (nonatomic, strong) NSMutableDictionary *titleTextAttributesForState;
@property (nonatomic, strong) NSMutableDictionary *badgeTextAttributesForState;

@end

@implementation CYLFlatDesignTabBarItem

- (NSMutableDictionary *)titleTextAttributesForState {
    if (!_titleTextAttributesForState) {
        _titleTextAttributesForState = [NSMutableDictionary dictionary];
    }
    return _titleTextAttributesForState;
}

- (NSMutableDictionary *)badgeTextAttributesForState {
    if (!_badgeTextAttributesForState) {
        _badgeTextAttributesForState = [NSMutableDictionary dictionary];
    }
    return _badgeTextAttributesForState;
}

- (instancetype)init {
    return [self initWithTitle:nil image:nil];
}

- (instancetype)initWithTitle:(NSString *)title image:(UIImage *)image {
    return [self initWithTitle:title image:image selectedImage:nil];
}

- (instancetype)initWithTitle:(NSString *)title image:(UIImage *)image selectedImage:(UIImage *)selectedImage {
    if (self = [super init]) {
        _enabled = YES;
        _title = title;
        _image = image;
        _selectedImage = selectedImage;
        _badgeValue = nil;
        _badgeColor = [UIColor systemRedColor];
        _titlePositionAdjustment = UIOffsetZero;
        
        _badgeSize = CGSizeZero;
        _badgeContentInset = UIEdgeInsetsMake(1, 6, 1, 6);
        _badgePositionAdjustment = UIOffsetZero;
        _imagePositionAdjustment = UIOffsetZero;
        _layoutCentered = NO;
        _backgroundColor = nil;
        _selectedBackgroundColor = nil;
    }
    return self;
}

- (instancetype)initWithTitle:(NSString *)title
              tabBarItemImage:(id)tabBarItemImage
      tabBarItemSelectedImage:(id)tabBarItemSelectedImage
                        index:(NSInteger)index
      titlePositionAdjustment:(UIOffset)titlePositionAdjustment
                  imageInsets:(UIEdgeInsets)imageInsets
               lottieFilePath:(NSString *)lottieFilePath
              lottieSizeValue:(NSValue *)lottieSizeValue {
    return [self initWithTitle:title image:tabBarItemImage selectedImage:tabBarItemSelectedImage];
}

- (void)setEnabled:(BOOL)enabled {
    if (_enabled != enabled) {
        _enabled = enabled;
        [[NSNotificationCenter defaultCenter] postNotificationName:CYLFlatDesignTabBarItemDidChange object:self];
    }
}

- (void)setTitle:(NSString *)title {
    if (![_title isEqualToString:title]) {
        _title = [title copy];
        [[NSNotificationCenter defaultCenter] postNotificationName:CYLFlatDesignTabBarItemDidChange object:self];
    }
}

- (void)setImage:(UIImage *)image {
    if (_image != image) {
        _image = image;
        [[NSNotificationCenter defaultCenter] postNotificationName:CYLFlatDesignTabBarItemDidChange object:self];
    }
}

- (void)setSelectedImage:(UIImage *)selectedImage {
    if (_selectedImage != selectedImage) {
        _selectedImage = selectedImage;
        [[NSNotificationCenter defaultCenter] postNotificationName:CYLFlatDesignTabBarItemDidChange object:self];
    }
}

- (void)setBadgeColor:(UIColor *)badgeColor {
    if (_badgeColor != badgeColor) {
        _badgeColor = badgeColor;
        [[NSNotificationCenter defaultCenter] postNotificationName:CYLFlatDesignTabBarItemDidChange object:self];
    }
}

- (void)setBadgeValue:(NSString *)badgeValue {
    if (![_badgeValue isEqualToString:badgeValue]) {
        _badgeValue = [badgeValue copy];
        [[NSNotificationCenter defaultCenter] postNotificationName:CYLFlatDesignTabBarItemDidChange object:self];
    }
}

- (void)setBadgeSize:(CGSize)badgeSize {
    if (!CGSizeEqualToSize(_badgeSize, badgeSize)) {
        _badgeSize = badgeSize;
        [[NSNotificationCenter defaultCenter] postNotificationName:CYLFlatDesignTabBarItemDidChange object:self];
    }
}

- (void)setBadgePositionAdjustment:(UIOffset)badgePositionAdjustment {
    if (!UIOffsetEqualToOffset(_badgePositionAdjustment, badgePositionAdjustment)) {
        _badgePositionAdjustment = badgePositionAdjustment;
        [[NSNotificationCenter defaultCenter] postNotificationName:CYLFlatDesignTabBarItemDidChange object:self];
    }
}

- (void)setBadgeContentInset:(UIEdgeInsets)badgeContentInset {
    if (!UIEdgeInsetsEqualToEdgeInsets(_badgeContentInset, badgeContentInset)) {
        _badgeContentInset = badgeContentInset;
        [[NSNotificationCenter defaultCenter] postNotificationName:CYLFlatDesignTabBarItemDidChange object:self];
    }
}

- (void)setTitlePositionAdjustment:(UIOffset)titlePositionAdjustment {
    if (!UIOffsetEqualToOffset(_titlePositionAdjustment, titlePositionAdjustment)) {
        _titlePositionAdjustment = titlePositionAdjustment;
        [[NSNotificationCenter defaultCenter] postNotificationName:CYLFlatDesignTabBarItemDidChange object:self];
    }
}

- (void)setImagePositionAdjustment:(UIOffset)imagePositionAdjustment {
    if (!UIOffsetEqualToOffset(_imagePositionAdjustment, imagePositionAdjustment)) {
        _imagePositionAdjustment = imagePositionAdjustment;
        [[NSNotificationCenter defaultCenter] postNotificationName:CYLFlatDesignTabBarItemDidChange object:self];
    }
}

- (void)setTitleTextAttributes:(NSDictionary<NSAttributedStringKey,id> *)attributes forState:(UIControlState)state {
    if (![[self titleTextAttributesForState:state] isEqualToDictionary:attributes]) {
        self.titleTextAttributesForState[@(state)] = attributes;
        [[NSNotificationCenter defaultCenter] postNotificationName:CYLFlatDesignTabBarItemDidChange object:self];
    }
}

- (NSDictionary<NSAttributedStringKey,id> *)titleTextAttributesForState:(UIControlState)state {
    return self.titleTextAttributesForState[@(state)];
}

- (void)setBadgeTextAttributes:(NSDictionary<NSAttributedStringKey,id> *)textAttributes forState:(UIControlState)state {
    if (![[self badgeTextAttributesForState:state] isEqualToDictionary:textAttributes]) {
        self.badgeTextAttributesForState[@(state)] = textAttributes;
        [[NSNotificationCenter defaultCenter] postNotificationName:CYLFlatDesignTabBarItemDidChange object:self];
    }
}

- (NSDictionary<NSAttributedStringKey,id> *)badgeTextAttributesForState:(UIControlState)state {
    return self.badgeTextAttributesForState[@(state)];
}

- (void)setLayoutCentered:(BOOL)layoutCentered {
    if (_layoutCentered != layoutCentered) {
        _layoutCentered = layoutCentered;
        [[NSNotificationCenter defaultCenter] postNotificationName:CYLFlatDesignTabBarItemDidChange object:self];
    }
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    if (_backgroundColor != backgroundColor) {
        _backgroundColor = backgroundColor;
        [[NSNotificationCenter defaultCenter] postNotificationName:CYLFlatDesignTabBarItemDidChange object:self];
    }
}

- (void)setSelectedBackgroundColor:(UIColor *)selectedBackgroundColor {
    if (_selectedBackgroundColor != selectedBackgroundColor) {
        _selectedBackgroundColor = selectedBackgroundColor;
        [[NSNotificationCenter defaultCenter] postNotificationName:CYLFlatDesignTabBarItemDidChange object:self];
    }
}

- (BOOL)isEqual:(id)object {
    if (self == object) return YES;
    if (![object isKindOfClass:[CYLFlatDesignTabBarItem class]]) return NO;
    CYLFlatDesignTabBarItem *otherItem = (CYLFlatDesignTabBarItem *)object;
    BOOL titleIsEqual = (self.title == otherItem.title || [self.title isEqualToString:otherItem.title]);
    return self.enabled == otherItem.enabled &&
            titleIsEqual &&
            self.image == otherItem.image &&
            self.selectedImage == otherItem.selectedImage &&
            self.badgeColor == otherItem.badgeColor &&
            self.badgeValue == otherItem.badgeValue &&
            CGSizeEqualToSize(self.badgeSize, otherItem.badgeSize) &&
            UIOffsetEqualToOffset(self.badgePositionAdjustment, otherItem.badgePositionAdjustment) &&
            UIEdgeInsetsEqualToEdgeInsets(self.badgeContentInset, otherItem.badgeContentInset) &&
            UIOffsetEqualToOffset(self.titlePositionAdjustment, otherItem.titlePositionAdjustment) &&
            UIOffsetEqualToOffset(self.imagePositionAdjustment, otherItem.imagePositionAdjustment) &&
            [self.titleTextAttributesForState isEqualToDictionary:otherItem.titleTextAttributesForState] &&
            [self.badgeTextAttributesForState isEqualToDictionary:otherItem.badgeTextAttributesForState] &&
            self.layoutCentered == otherItem.layoutCentered &&
            self.backgroundColor == otherItem.backgroundColor &&
            self.selectedBackgroundColor == otherItem.selectedBackgroundColor;
}

@end
