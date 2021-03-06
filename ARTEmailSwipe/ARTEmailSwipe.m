
/*  Created by Rowan Townshend on 8/14/14.
 Copyright (c) 2014 Rowan Townshend. All rights reserved.
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of
 this software and associated documentation files (the "Software"), to deal in
 the Software without restriction, including without limitation the rights to
 use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
 of the Software, and to permit persons to whom the Software is furnished to do
 so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 If you happen to meet one of the copyright holders in a bar you are obligated
 to buy them one pint of beer.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWAR
 */

#import "ARTEmailSwipe.h"

#define ISIOS6    ([[[UIDevice currentDevice] systemVersion] floatValue] < 7 && [[[UIDevice currentDevice] systemVersion] floatValue] >= 6)


static CGFloat const ARTDefaultBottomViewDistanceFromTop = 40.f;
static CGFloat const ARTDefaultBottomViewClosedHeight = 46.f;
static CGFloat const ARTDefaultBounceOffset = 5.f;
static CGFloat const ARTDefaultBounceDuration = 0.2f;
static CGFloat const ARTDefaultBottomCenterViewOffset = 5.f;
static CGFloat const ARTStatusBar = 20.f;

@interface ARTEmailSwipe ()

@property (nonatomic, strong) UIView *centerViewContainer;
@property (nonatomic, strong) UIView *bottomViewContainer;
@property (nonatomic, strong) UIButton *tapGesture;
@property (nonatomic, strong) UIPanGestureRecognizer *panGestureRecoginser;

@property (nonatomic, assign) ARTOpenType status;
@property (nonatomic, assign) CGFloat dragOffset;
@property (nonatomic, assign) CGFloat transformOffset;

@end

@implementation ARTEmailSwipe

- (id)initWithCoder:(NSCoder *)aDecoder;
{
  self = [super initWithCoder:aDecoder];
  if (self) {
    [self configure];
  }
  return self;
}

- (id)init;
{
  self = [super init];
  if (self) {
    [self configure];
  }
  return self;
}

- (void)configure;
{
  self.status = ARTOpenTypeClosed;
  self.bottomViewClosedHeight = ARTDefaultBottomViewClosedHeight;
  self.bottomViewDistanceFromTop = ARTDefaultBottomViewDistanceFromTop - (ISIOS6 ? 20 : 0);;
  self.bounceOffset = ARTDefaultBounceOffset;
  self.bounceAnimationDuration = ARTDefaultBounceDuration;
  self.bottomCenterViewOffset = ARTDefaultBottomCenterViewOffset;
}

- (void)viewDidLoad;
{
  self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
  
  self.dragOffset =  self.view.bounds.size.height - (self.view.bounds.size.height / 4);
  self.transformOffset =  self.view.bounds.size.height - (self.view.bounds.size.height / 2);
  
  self.centerViewContainer = [[UIView alloc] initWithFrame:self.view.bounds];
  self.centerViewContainer.frame =  self.view.bounds;
  
  self.bottomViewContainer = [[UIView alloc] initWithFrame:self.view.bounds];
  self.bottomViewContainer.frame =  self.view.bounds;
  self.bottomViewContainer.clipsToBounds = YES;
  
  self.bottomViewContainer.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight;
  self.centerViewContainer.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  
  [self.view addSubview:self.bottomViewContainer];
  [self.view addSubview:self.centerViewContainer];
  
  [self addView:self.centerViewContainer withContainer:self.centerViewController];
}

- (void)setCenterViewController:(UIViewController *)centerView;
{
  if (centerView != _centerViewController) {
    [_centerViewController willMoveToParentViewController:nil];
    [_centerViewController.view removeFromSuperview];
    [_centerViewController removeFromParentViewController];
    _centerViewController = centerView;
    if (_centerViewController) {
      [self addChildViewController:_centerViewController];
      [_centerViewController didMoveToParentViewController:self];
    }
  }
  [self addView:self.centerViewContainer withContainer:_centerViewController];
}

- (void)setBottomViewController:(UIViewController *)bottomViewController;
{
  if (self.bottomViewController && self.status != ARTOpenTypeClosed) {
    [self closeBottomView];
    [self.bottomViewContainer removeFromSuperview];
    self.bottomViewContainer = [[UIView alloc] initWithFrame:self.view.bounds];
    self.bottomViewContainer.frame =  self.view.bounds;
    self.bottomViewContainer.clipsToBounds = YES;
    self.bottomViewContainer.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.bottomViewContainer];
    [self.view bringSubviewToFront:self.centerViewContainer];
    [_bottomViewController willMoveToParentViewController:nil];
    [_bottomViewController.view removeFromSuperview];
    [_bottomViewController removeFromParentViewController];
    _bottomViewController = bottomViewController;
    [self addChildViewController:_bottomViewController];
    [_bottomViewController didMoveToParentViewController:self];
  } else if (bottomViewController != _bottomViewController) {
    [_bottomViewController willMoveToParentViewController:nil];
    [_bottomViewController.view removeFromSuperview];
    [_bottomViewController removeFromParentViewController];
    _bottomViewController = bottomViewController;
    if (_bottomViewController) {
      [self addChildViewController:_bottomViewController];
      [_bottomViewController didMoveToParentViewController:self];
    }
    [self addView:self.bottomViewContainer withContainer:_bottomViewController];
  }
}

- (void)addView:(UIView *)view withContainer:(UIViewController *)container;
{
  container.view.frame = view.bounds;
  [self addChildViewController:container];
  [view addSubview:container.view];
  [container didMoveToParentViewController:self];
}

- (void)loadBottomView:(ARTOpenType)openType;
{
  if (self.bottomViewController) {
    
    if (!_bottomViewController.view.superview) {
      
      CGRect frame = self.view.bounds;
      frame.origin.y = (self.view.bounds.size.height - self.bottomViewClosedHeight);
      frame.size.height = self.bottomViewClosedHeight;
      self.bottomViewContainer.frame = frame;
      
      frame =  _bottomViewController.view.frame;
      frame.size.width = self.view.bounds.size.width;
      _bottomViewController.view.frame = frame;
      
      [self.bottomViewContainer addSubview:_bottomViewController.view];
    }
    
    self.status = ARTOpenTypePartly;
    [self bottomViewOpen:openType];
  }
}

- (void)openBottomView;
{
  [self openBottomView:ARTOpenTypeFully];
}

- (void)openBottomView:(ARTOpenType)openType;
{
  [self animateCenterView:NO];
  self.status = openType;
  
  [self loadBottomView:openType];
}

- (void)closeBottomView;
{
  [self animateCenterView:YES];
  self.status = ARTOpenTypeClosed;
}

#pragma mark Animation

- (void)animateCenterView:(BOOL)close;
{
  if (close) {
    if (self.status == ARTOpenTypeFully) {
      [self bottomViewOpen:ARTOpenTypeClosed];
    }
    [self animateCenterView];
  } else  {
    if (self.status == ARTOpenTypeClosed) {
      [self animateCenterView];
    }
  }
}

- (void)animateCenterView;
{
  BOOL open = self.status == ARTOpenTypeClosed;
  
  [UIView animateWithDuration:0.5f animations:^{
    CGRect frame = self.view.bounds;
    frame.size.height = open ? self.view.bounds.size.height - (self.bottomViewClosedHeight + self.bottomCenterViewOffset) : self.view.bounds.size.height;
    self.centerViewContainer.frame = frame;
  } completion:^(BOOL finished) {
    if (!open) {
      self.status = ARTOpenTypeClosed;
    }
  }];
}

- (void)bottomViewOpen:(ARTOpenType)openType;
{
  if (openType != ARTOpenTypeClosed) {
    if (self.status == ARTOpenTypeFully) {
      openType = ARTOpenTypePartly;
    } else if (self.status == ARTOpenTypePartly) {
      openType = ARTOpenTypeFully;
    }
  }
  
  BOOL open = self.status == ARTOpenTypePartly && openType == ARTOpenTypeFully;
  
  if (open) {
    [self.view bringSubviewToFront:self.bottomViewContainer];
    [self addPanGestureToView:self.bottomViewController.view];
  } else {
    [self.bottomViewController.view removeGestureRecognizer:self.panGestureRecoginser];
  }
  
  [self addTapGesture:open];
  [self.bottomDelegate bottomViewOpened:openType];
  self.disableStatusBarAnimation ? : [[UIApplication sharedApplication] setStatusBarStyle:open ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault animated:YES];
  
  [UIView animateWithDuration:0.5f animations:^{
    CGRect frame = self.view.bounds;
    
    self.bottomViewController.view.frame = frame;
    frame.origin.y = openType == ARTOpenTypeClosed ? frame.size.height : open ? self.bottomViewDistanceFromTop : ((frame.size.height - self.bottomViewClosedHeight) + self.bounceOffset);
    frame.size.height = open ? frame.size.height - self.bottomViewDistanceFromTop : self.bottomViewClosedHeight + (ISIOS6 ? ARTStatusBar : 0);
    self.bottomViewContainer.frame = frame;
    self.centerViewContainer.transform = open ? CGAffineTransformMakeScale(0.9, 0.9) : CGAffineTransformMakeScale(1, 1);
    
  } completion:^(BOOL finished) {
    self.status = openType;
    if (!open) {
      [self.view bringSubviewToFront:self.centerViewContainer];
      [UIView animateWithDuration:ARTDefaultBounceDuration animations:^{
        CGRect frame = self.bottomViewContainer.frame;
        frame.origin.y = frame.origin.y - self.bounceOffset;
        self.bottomViewContainer.frame = frame;
      }];
    }
  }];
}

- (void)addTapGesture:(BOOL)add;
{
  if (!add) {
    [self.view addSubview:self.tapGesture];
    NSDictionary *constraintView = @{ @"tap" : self.tapGesture};
    _tapGesture.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[tap]-0-|" options:0 metrics:nil views:constraintView]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[tap(height)]-(0)-|" options:0 metrics:@{@"height": @(self.bottomViewClosedHeight)} views:constraintView]];
  } else {
    [self.tapGesture removeFromSuperview];
  }
}

#pragma mark Gestures

- (void)addPanGestureToView:(UIView *)view;
{
  [self.bottomViewController.view removeGestureRecognizer:self.panGestureRecoginser];
  self.panGestureRecoginser = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
  self.panGestureRecoginser.maximumNumberOfTouches = 1;
  self.panGestureRecoginser.minimumNumberOfTouches = 1;
  [view addGestureRecognizer:self.panGestureRecoginser];
}

- (void)handlePan:(UIGestureRecognizer *)sender;
{
  if ([sender isKindOfClass:[UIPanGestureRecognizer class]]) {
    
    UIPanGestureRecognizer *pan = (UIPanGestureRecognizer *)sender;
    CGPoint translate = [pan translationInView:self.bottomViewContainer];
    self.bottomViewContainer.center = CGPointMake(self.bottomViewContainer.center.x, self.bottomViewContainer.center.y + translate.y);
    [pan setTranslation:CGPointZero inView:self.bottomViewContainer];
    
    CGFloat origin = self.bottomViewContainer.frame.origin.y;
    [self.bottomDelegate panGestureOffset:self.bottomViewContainer.frame.origin state:pan.state];
    
    if (origin < self.transformOffset) {
      CGFloat scale = ((origin / self.transformOffset) / 10) + 0.9;
      scale = scale > 1 ? 1 : scale < 0.9 ? 0.9 : scale;
      
      self.centerViewContainer.transform = CGAffineTransformMakeScale(scale, scale);
      self.disableStatusBarAnimation ? : [[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleLightContent animated:YES];
    } else {
      self.disableStatusBarAnimation ? : [[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleDefault animated:YES];
    }
    
    if (sender.state == UIGestureRecognizerStateEnded) {
      
      if (origin > self.dragOffset) {
        self.status = ARTOpenTypeFully;
        [self bottomViewOpen:ARTOpenTypePartly];
      } else {
        self.status = ARTOpenTypePartly;
        [self bottomViewOpen:ARTOpenTypeFully];
      }
    }
  }
}


#pragma mark - Re-Sizing

- (void)willAnimateRotationToInterfaceOrientation:(__unused UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration;
{
  [self adjustCenterFrame];
  [self adjustBottomFrame];
  
  self.dragOffset =  self.view.bounds.size.height - (self.view.bounds.size.height / 4);
  self.transformOffset =  self.view.bounds.size.height - (self.view.bounds.size.height / 2);
}

- (void)adjustCenterFrame;
{
  CGRect frame = self.view.bounds;
  if (self.status == ARTOpenTypeClosed) {
    frame.origin.y = 0;
  } else if (self.status == ARTOpenTypeFully) {
    frame.size.height = self.view.bounds.size.height - (self.bottomViewClosedHeight + self.bottomCenterViewOffset);
    self.centerViewContainer.transform = CGAffineTransformIdentity;
    self.centerViewContainer.frame = frame;
    self.centerViewContainer.transform = CGAffineTransformMakeScale(0.9, 0.9);
    return;
  } else {
    frame.size.height = self.view.bounds.size.height - (self.bottomViewClosedHeight + self.bottomCenterViewOffset);
  }
  self.centerViewContainer.frame = frame;
}

- (void)adjustBottomFrame;
{
  CGRect frame = self.view.bounds;
  
  if (self.status == ARTOpenTypeFully) {
    frame.origin.y = self.bottomViewDistanceFromTop;
    frame.size.height = frame.size.height - self.bottomViewDistanceFromTop;
  } else {
    frame.origin.y = frame.size.height - self.bottomViewClosedHeight;
    frame.size.height = self.bottomViewClosedHeight;
  }
  self.bottomViewContainer.frame = frame;
}

#pragma mark Lazy Loading

- (UIButton *)tapGesture;
{
  if (!_tapGesture) {
    _tapGesture = [UIButton buttonWithType:UIButtonTypeCustom];
    [_tapGesture addTarget:self action:@selector(bottomViewOpen:) forControlEvents:UIControlEventTouchUpInside];
    _tapGesture.backgroundColor = [UIColor clearColor];
  }
  return _tapGesture;
}

@end
