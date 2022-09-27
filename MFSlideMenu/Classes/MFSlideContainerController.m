//
//  MFSlideContainerController.m
//  MFSlideContainer
//
//  Created by zouyuk on 2022/9/18.
//

#import "MFSlideContainerController.h"

#define kScreenWidth [UIScreen mainScreen].bounds.size.width
CGFloat const kMaxSpeed = 800;

@interface MFSlideContainerController ()
/// 主控制器
@property (nonatomic, strong) UIViewController *mainVC;
/// 侧边控制器
@property (nonatomic, strong) UIViewController *leftVC;

/// 侧滑后的平移手势
@property (nonatomic, strong) UIPanGestureRecognizer *leftPan;
/// 侧滑后的主控制器平移手势
@property (nonatomic, strong) UIPanGestureRecognizer *leftMainPan;
/// 点击收起侧边栏
@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;

/// 毛玻璃遮罩
@property (nonatomic, strong) UIView *maskView;
/// 阴影层
@property (nonatomic, strong) UIView *shadowView;
/// 侧边控制器边缘渐变层
@property (nonatomic, strong) UIView *glView;
/// 侧滑显示类型
@property (nonatomic, assign) MFSlideContainerType slideType;
/// 侧边栏展示区域大小（默认 屏幕宽度 - mainVisibleWidth）
@property (nonatomic, assign , readwrite) CGFloat leftVisibleWidth;

/// 侧边栏起始X点
@property (nonatomic, assign) CGFloat leftVcOriginX;

/// 侧滑距离百分比
@property (nonatomic, assign) CGFloat slideRatio;

@end

@implementation MFSlideContainerController

+ (instancetype)containerViewControllerWithLeftVC:(UIViewController *)leftVC mainVC:(UIViewController *)mainVC slideType:(MFSlideContainerType)slideType{
    return  [[MFSlideContainerController alloc] initWithLeftVC:leftVC mainVC:mainVC slideType:slideType];
}

- (instancetype)initWithLeftVC:(UIViewController *)leftVC mainVC:(UIViewController *)mainVC slideType:(MFSlideContainerType)slideType{
    
    self = [super init];
    if (self) {
        self.leftVC = leftVC;
        self.mainVC = mainVC;
        self.slideType = slideType;
        [self initialization];
    }
    return self;
}

#pragma mark - lift Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initSubviews];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // 如果mainVC有导航栏,需要自定义导航栏,系统导航栏无法跟随移动
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    // 显示导航栏,否则侧边栏中的跳转后的控制器没有导航栏
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    // pop后返回的主页,不设置的话返回的是侧滑展示出来的状态
    [self hideLeftView];
}

#pragma mark - Setup
- (void)initialization
{
    _enableEdgePan = YES;
    _showVagueMask = YES;
    _showShadowMask = YES;
    _maskShadowColor = [UIColor colorWithRed:0/255.f green:0/255.f blue:0/255.f alpha:0.5];
    _animationDuration = 0.25;
    _mainVisibleWidth = 60;
    _leftVcOriginX = -_mainVisibleWidth;
    //滑动侧边栏类型下 默认展示全部侧边VC
    if (self.slideType == MFSlideContainerTypeSlideLeftVc) {
        _mainVisibleWidth = 0;
        _leftVcOriginX = -kScreenWidth;
    }
    _leftVisibleWidth = kScreenWidth - _mainVisibleWidth;
    
}

- (void)initSubviews {
    // 添加子控制器,子控制器可以使用父控制器的navigationController
    [self addChildViewController:self.mainVC];
    [self addChildViewController:self.leftVC];
    
    if (self.slideType == MFSlideContainerTypeSlideMainVc) {
        //滑动主控制器
        [self.view addSubview:self.leftVC.view];
        [self.view addSubview:self.maskView];
        [self.view addSubview:self.shadowView];
        [self.view addSubview:self.mainVC.view];
        [self.mainVC.view addGestureRecognizer:self.tapGesture];
    }else{
        //滑动侧边栏
        [self.view addSubview:self.mainVC.view];
        [self.view addSubview:self.maskView];
        [self.view addSubview:self.shadowView];
        [self.view addSubview:self.glView];
        [self.view addSubview:self.leftVC.view];
    }
    self.leftVC.view.frame = CGRectMake(self.leftVcOriginX, 0, self.view.bounds.size.width, self.view.bounds.size.height);
    self.mainVC.view.frame = self.view.bounds;
    // 添加手势
    [self.mainVC.view addGestureRecognizer:self.leftEdgePan];
    [self.mainVC.view addGestureRecognizer:self.leftMainPan];
    [self.leftVC.view addGestureRecognizer:self.leftPan];
    
}

#pragma mark - Gesture

- (void)screenEdgeGesture:(UIPanGestureRecognizer *)pan {
    // 移动的距离
    CGPoint point = [pan translationInView:pan.view];
    // 移动的速度
    CGPoint verPoint = [pan velocityInView:pan.view];
    //默认滑动侧边栏
    //移动的视图
    UIView *moveView = self.leftVC.view;
    //x坐标最大值
    CGFloat maxMoveX = -self.mainVisibleWidth;
    //x坐标最小值
    CGFloat minMoveX = -moveView.bounds.size.width;
    //滑动临界值
    CGFloat midValue = -self.view.bounds.size.width / 2;
    if (self.slideType == MFSlideContainerTypeSlideMainVc) {//滑动主控制器
        moveView = self.mainVC.view;
        maxMoveX = self.leftVisibleWidth;
        minMoveX = 0;
        midValue = self.view.bounds.size.width / 2;
    }
    CGRect frame = moveView.frame;
    frame.origin.x += point.x;
    // 边界限定:
    if (frame.origin.x >= maxMoveX) {
        frame.origin.x = maxMoveX;
    }
    if (frame.origin.x <= minMoveX) {
        frame.origin.x = minMoveX;
    }
    
    moveView.frame = frame;
    
    if (self.slideType == MFSlideContainerTypeSlideMainVc) {//滑动主控制器
        CGFloat ratio = frame.origin.x*1.f/self.leftVisibleWidth;
        CGFloat tempMoveX = ratio * self.mainVisibleWidth;
        CGRect leftFrame = self.leftVC.view.frame;
        leftFrame.origin.x = -(self.mainVisibleWidth - tempMoveX);
        self.leftVC.view.frame = leftFrame;
    }
    //改变阴影透明度
    [self setupMaskViewAlpha];

    if (pan.state == UIGestureRecognizerStateEnded) {
        /// 判断手势
        // 速度大于 kMaxSpeed 时自动展示完整
        // 小于 kMaxSpeed 时为拖动效果 , 拖动超过 kScreenWidth / 2 时自动展示完全
        if (verPoint.x >= kMaxSpeed) {
            [self showLeftView];
        } else {
            if (frame.origin.x >= midValue) {
                [self showLeftView];
            } else {
                [self hideLeftView];
            }
        }
    }
    
    [pan setTranslation:CGPointZero inView:pan.view];
}

- (void)leftVcPanGesture:(UIPanGestureRecognizer *)pan {
    // 移动的距离
    CGPoint point = [pan translationInView:pan.view];
    // 移动的速度
    CGPoint verPoint = [pan velocityInView:pan.view];
    
    //默认滑动侧边栏
    //移动的视图
    UIView *moveView = self.leftVC.view;
    //x坐标最大值
    CGFloat maxMoveX = -self.mainVisibleWidth;
    //x坐标最小值
    CGFloat minMoveX = -moveView.bounds.size.width;
    //滑动临界值
    CGFloat midValue = -self.view.bounds.size.width / 2;
    
    if (self.slideType == MFSlideContainerTypeSlideMainVc) {//滑动主控制器
        moveView = self.mainVC.view;
        maxMoveX = self.leftVisibleWidth;
        minMoveX = 0;
        midValue = self.view.bounds.size.width / 2;
    }
    CGRect frame = moveView.frame;
    frame.origin.x += point.x;
    // 边界限定:
    if (frame.origin.x >= maxMoveX) {
        frame.origin.x = maxMoveX;
    }
    if (frame.origin.x <= minMoveX) {
        frame.origin.x = minMoveX;
    }
    
    moveView.frame = frame;
    if (self.slideType == MFSlideContainerTypeSlideMainVc) {//滑动主控制器
        CGFloat ratio = frame.origin.x*1.f/self.leftVisibleWidth;
        CGFloat tempMoveX = ratio * self.mainVisibleWidth;
        CGRect leftFrame = self.leftVC.view.frame;
        leftFrame.origin.x = -(self.mainVisibleWidth - tempMoveX);
        self.leftVC.view.frame = leftFrame;
    }
    [self setupMaskViewAlpha];

    if (pan.state == UIGestureRecognizerStateEnded) {
        /// 判断手势
        // 速度大于 kMaxSpeed 时自动展示完整
        // 小于 kMaxSpeed 时为拖动效果 , 拖动超过 kScreenWidth / 2 时自动展示完全
        if (verPoint.x < -kMaxSpeed) {
            [self hideLeftView];
        } else {
            // 左滑超过 kScreenWidth / 2 时自动收回
            if (frame.origin.x >= midValue) {
                [self showLeftView];
            } else {
                [self hideLeftView];
            }
        }
    }
    
    [pan setTranslation:CGPointZero inView:pan.view];
}

- (void)setupMaskViewAlpha{
    self.glView.hidden = NO;
    CGRect frame = self.leftVC.view.frame;
    
    //移动的视图
    UIView *moveView = self.leftVC.view;
    CGFloat moveDistance = moveView.frame.origin.x + self.leftVisibleWidth;
    if (self.slideType == MFSlideContainerTypeSlideMainVc) {//滑动主控制器
        moveView = self.mainVC.view;
        moveDistance = moveView.frame.origin.x;
    }
    
    CGFloat ratio = (moveDistance)*1.f/self.leftVisibleWidth;
    self.maskView.alpha = self.shadowView.alpha = self.slideType == MFSlideContainerTypeSlideMainVc ? 1 - ratio : ratio;
    CGRect glFrame = self.glView.frame;
    glFrame.origin.x = frame.origin.x + frame.size.width;
    self.glView.frame = glFrame;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(slideContainerScrollDistance:ratio:)]) {
        [self.delegate slideContainerScrollDistance:moveDistance ratio:ratio];
    }
}

- (void)showLeftView{
  
    self.showStatus = MFSlideShowStatusTypeShow;
    [UIView animateWithDuration:self.animationDuration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        
        if (self.slideType == MFSlideContainerTypeSlideMainVc) {//滑动主控制器
            CGRect frame = self.mainVC.view.frame;
            frame.origin.x = self.leftVisibleWidth;
            self.mainVC.view.frame = frame;
            
            CGRect leftFrame = self.leftVC.view.frame;
            leftFrame.origin.x = 0;
            self.leftVC.view.frame = leftFrame;
        }else{
            CGRect frame = self.leftVC.view.frame;
            frame.origin.x = -self.mainVisibleWidth;
            self.leftVC.view.frame = frame;
            
            CGRect glFrame = self.glView.frame;
            glFrame.origin.x = frame.origin.x + frame.size.width;
            self.glView.frame = glFrame;
            
        }
        self.maskView.alpha = self.shadowView.alpha = self.slideType == MFSlideContainerTypeSlideMainVc ? 0 : 1;
        
    } completion:^(BOOL finished) {
        self.leftEdgePan.enabled = NO;
        self.leftPan.enabled = YES;
        self.leftMainPan.enabled = YES;
        self.tapGesture.enabled = YES;
        self.tapGesture.enabled = YES;
        [self responseleftViewDidAppear];
    }];
}

- (void)hideLeftView{
    
    self.showStatus = MFSlideShowStatusTypeHide;
    [UIView animateWithDuration:self.animationDuration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        
        if (self.slideType == MFSlideContainerTypeSlideMainVc) {//滑动主控制器
            CGRect frame = self.mainVC.view.frame;
            frame.origin.x = 0;
            self.mainVC.view.frame = frame;
            
            CGRect leftFrame = self.leftVC.view.frame;
            leftFrame.origin.x = self.leftVcOriginX;
            self.leftVC.view.frame = leftFrame;
        }else{
            CGRect frame = self.leftVC.view.frame;
            frame.origin.x = self.leftVcOriginX;
            self.leftVC.view.frame = frame;
            
            CGRect glFrame = self.glView.frame;
            glFrame.origin.x = frame.origin.x + frame.size.width;
            self.glView.frame = glFrame;
        }
        
        self.maskView.alpha = self.shadowView.alpha = self.slideType == MFSlideContainerTypeSlideMainVc ? 1 : 0;
    } completion:^(BOOL finished) {
        self.leftEdgePan.enabled = self.enableEdgePan;
        self.leftPan.enabled = NO;
        self.leftMainPan.enabled = NO;
        self.tapGesture.enabled = NO;
        self.glView.hidden = YES;
        [self responseleftViewDidDisappear];
    }];
}

- (void)responseleftViewDidAppear{
    if (self.delegate && [self.delegate respondsToSelector:@selector(leftViewDidAppear)]) {
        [self.delegate leftViewDidAppear];
    }
}

- (void)responseleftViewDidDisappear{
    if (self.delegate && [self.delegate respondsToSelector:@selector(leftViewDidDisappear)]) {
        [self.delegate leftViewDidDisappear];
    }
}

#pragma mark - Setter
- (void)setEnableEdgePan:(BOOL)enableEdgePan{
    _enableEdgePan = enableEdgePan;
    self.leftEdgePan.enabled = enableEdgePan;
}

- (void)setShowVagueMask:(BOOL)showVagueMask{
    _showVagueMask = showVagueMask;
    self.maskView.hidden = !showVagueMask;
}

- (void)setShowShadowMask:(BOOL)showShadowMask{
    _showShadowMask = showShadowMask;
    self.shadowView.hidden = !showShadowMask;
}

- (void)setMaskShadowColor:(UIColor *)maskShadowColor{
    _maskShadowColor = maskShadowColor;
    self.shadowView.backgroundColor = maskShadowColor;
}

- (void)setAnimationDuration:(NSTimeInterval)animationDuration{
    _animationDuration = animationDuration;
    if (_animationDuration < 0) {
        _animationDuration = 0.25;
    }
}

- (void)setMainVisibleWidth:(CGFloat)mainVisibleWidth{
    
    if (mainVisibleWidth > self.view.bounds.size.width) {
        mainVisibleWidth = self.view.bounds.size.width;
    }
    
    if (mainVisibleWidth < 0) {
        mainVisibleWidth = 0;
    }
    
    _mainVisibleWidth = mainVisibleWidth;
    
    _leftVcOriginX = -_mainVisibleWidth;
    _leftVisibleWidth = self.view.frame.size.width - _mainVisibleWidth;
    
    if (self.slideType == MFSlideContainerTypeSlideLeftVc) {
        _leftVcOriginX = - self.view.frame.size.width;
    }
    
    self.leftVC.view.frame = CGRectMake(self.leftVcOriginX, 0, self.view.bounds.size.width, self.view.bounds.size.height);
}

-(void)setStatusBarType:(UIStatusBarStyle)statusBarType{
    _statusBarType = statusBarType;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setNeedsStatusBarAppearanceUpdate];
    });
}

#pragma mark - Getter
- (UIScreenEdgePanGestureRecognizer *)leftEdgePan{
    if (!_leftEdgePan) {
        _leftEdgePan =[[UIScreenEdgePanGestureRecognizer alloc]initWithTarget:self action:@selector(screenEdgeGesture:)];
        _leftEdgePan.edges = UIRectEdgeLeft;
        _leftEdgePan.enabled = YES;
    }
    return _leftEdgePan;
}

- (UIPanGestureRecognizer *)leftPan{
    if (!_leftPan) {
        _leftPan =[[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(leftVcPanGesture:)];
        _leftPan.enabled = NO;
    }
    return _leftPan;
}

- (UIPanGestureRecognizer *)leftMainPan{
    if (!_leftMainPan) {
        _leftMainPan =[[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(leftVcPanGesture:)];
        _leftMainPan.enabled = NO;
    }
    return _leftMainPan;
}

- (UITapGestureRecognizer *)tapGesture {
    if (!_tapGesture) {
        _tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideLeftView)];
        _tapGesture.enabled = NO;
    }
    return _tapGesture;
}

- (UIView *)maskView{
    if (!_maskView) {
        _maskView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
        UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:effect];
        effectView.frame = _maskView.bounds;
        [_maskView addSubview:effectView];
        _maskView.alpha = 0;
        _maskView.userInteractionEnabled = NO;
    }
    return _maskView;
}

- (UIView *)shadowView{
    if (!_shadowView) {
        _shadowView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
        _shadowView.backgroundColor = self.maskShadowColor;
        _shadowView.alpha = 0;
        _shadowView.userInteractionEnabled = NO;
    }
    return _shadowView;
}

- (UIView *)glView{
    if (!_glView) {
        _glView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 30, self.view.bounds.size.height)];
        CAGradientLayer *gl = [[CAGradientLayer alloc]init];
        gl.frame = _glView.bounds;
        gl.colors = @[(__bridge id)UIColor.blackColor.CGColor,(__bridge id)UIColor.clearColor.CGColor];
        gl.startPoint = CGPointMake(0, 0.5);
        gl.endPoint = CGPointMake(1, 0.5);
        [_glView.layer addSublayer:gl];
        _glView.hidden = YES;
        _glView.alpha = 0.1;
    }
    return _glView;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(configStatusBarStyle)]) {
        UIStatusBarStyle delegateStatusBarType = [self.delegate configStatusBarStyle];
        return delegateStatusBarType;
    }
    UIStatusBarStyle tempStatusBar = _statusBarType;
    //使用完复原
    _statusBarType = self.defaultStatusBarType;
    return tempStatusBar;
}

@end
