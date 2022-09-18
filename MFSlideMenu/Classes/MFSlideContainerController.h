//
//  MFSlideContainerController.h
//  MFSlideContainer
//
//  Created by zouyuk on 2022/9/18.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 侧滑栏显示类型
typedef enum {
    MFSlideContainerTypeSlideLeftVc,        // 滑动侧边栏
    MFSlideContainerTypeSlideMainVc         // 滑动主控制器
} MFSlideContainerType;

/// 侧滑栏显示状态
typedef enum {
    MFSlideShowStatusTypeHide,        // 侧边栏隐藏
    MFSlideShowStatusTypeShow         // 侧边栏显示
} MFSlideShowStatusType;

@protocol MFSlideContainerDelegate <NSObject>

@optional
/// 正在滑动中的回调
/// @param distance 滑动距离
/// @param ratio 滑动距离/总滑动长度
- (void)slideContainerScrollDistance:(CGFloat)distance ratio:(CGFloat)ratio;

/// 侧边栏显示
- (void)leftViewDidAppear;
/// 侧边栏消失
- (void)leftViewDidDisappear;

@end

@interface MFSlideContainerController : UIViewController

/// 初始化
/// @param leftVC 侧边控制器
/// @param mainVC 主控制器
/// @param slideType 显示类型
+ (instancetype)containerViewControllerWithLeftVC:(UIViewController *)leftVC mainVC:(UIViewController *)mainVC slideType:(MFSlideContainerType)slideType;

/// 初始化
/// @param leftVC 侧边控制器
/// @param mainVC 主控制器
/// @param slideType 显示类型
- (instancetype)initWithLeftVC:(UIViewController *)leftVC mainVC:(UIViewController *)mainVC slideType:(MFSlideContainerType)slideType;

@property (nonatomic, weak) id<MFSlideContainerDelegate> delegate;

//////////////////////  API  //////////////////////

/// 是否开启边缘侧滑响应手势（默认 YES）
@property (nonatomic, assign) BOOL enableEdgePan;

/// 是否展示模糊遮罩层（默认 YES）
@property (nonatomic, assign) BOOL showVagueMask;

/// 是否展示阴影层（默认 YES）
@property (nonatomic, assign) BOOL showShadowMask;

/// 遮罩阴影颜色
@property (nonatomic, strong) UIColor *maskShadowColor;

/// 滑动动画时长（默认 0.25s）
@property (nonatomic, assign) NSTimeInterval animationDuration;

/// 主控制器最小展示区域大小（默认 60  最小0，最大屏幕宽度）
@property (nonatomic, assign) CGFloat mainVisibleWidth;
/// 侧边栏展示区域大小（默认 屏幕宽度 - mainVisibleWidth）
@property (nonatomic, assign , readonly) CGFloat leftVisibleWidth;

/// 侧边栏显示状态（默认隐藏）
@property (nonatomic, assign) MFSlideShowStatusType showStatus;

/// 显示侧边栏
- (void)showLeftView;
/// 隐藏侧边栏
- (void)hideLeftView;

@end

NS_ASSUME_NONNULL_END
