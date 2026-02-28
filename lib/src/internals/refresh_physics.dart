// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member, unnecessary_this
import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../smart_refresher.dart';
import 'slivers.dart';

/// 用于配置下拉刷新和上拉加载的滚动物理效果
///
/// 该类扩展了Flutter的[ScrollPhysics]，主要用于：
/// 1. 允许视口超出边缘滚动，无论父级物理效果是什么
/// 2. 处理刷新过程中的滚动拦截
/// 3. 处理二级刷新打开和关闭时的滚动
/// 4. 支持自定义弹簧回弹动画
/// 5. 适配iOS和Android不同的滚动效果
///
/// 可以通过[RefreshConfiguration]设置更多参数
///
/// 示例用法：
/// ```dart
/// SmartRefresher(
///   physics: RefreshPhysics(
///     maxOverScrollExtent: 100.0,
///     springDescription: SpringDescription(
///       stiffness: 170.0,
///       damping: 16.0,
///       mass: 1.0,
///     ),
///   ),
///   controller: _refreshController,
///   onRefresh: _onRefresh,
///   child: ListView.builder(
///     itemCount: 20,
///     itemBuilder: (context, index) => ListTile(title: Text("Item $index")),
///   ),
/// );
/// ```
///
/// 参考：
/// * [RefreshConfiguration] - 控制SmartRefresher组件在子树中的行为
// ignore: MUST_BE_IMMUTABLE
class RefreshPhysics extends ScrollPhysics {
  /// 最大上拉超出范围
  final double? maxOverScrollExtent;

  /// 最大下拉超出范围
  final double? maxUnderScrollExtent;

  /// 顶部碰撞边界
  final double? topHitBoundary;

  /// 底部碰撞边界
  final double? bottomHitBoundary;

  /// 弹簧动画描述
  final SpringDescription? springDescription;

  /// 拖动速度比例
  final double? dragSpeedRatio;

  /// 刷新完成后是否允许滚动
  final bool? enableScrollWhenRefreshCompleted;

  /// 刷新控制器
  final RefreshController? controller;

  /// 更新标志，用于控制运行时类型
  final int? updateFlag;

  /// 视口渲染对象
  ///
  /// 在弹跳时查找视口，用于计算头部和底部的布局范围
  /// 这对性能没有影响，只执行一次
  RenderViewport? viewportRender;

  /// 创建滚动物理效果，用于控制下拉刷新和上拉加载的行为
  ///
  /// 参数：
  /// - [parent]：父级滚动物理效果
  /// - [updateFlag]：更新标志，用于控制运行时类型
  /// - [maxOverScrollExtent]：最大上拉超出范围
  /// - [maxUnderScrollExtent]：最大下拉超出范围
  /// - [springDescription]：弹簧动画描述
  /// - [controller]：刷新控制器
  /// - [dragSpeedRatio]：拖动速度比例
  /// - [topHitBoundary]：顶部碰撞边界
  /// - [bottomHitBoundary]：底部碰撞边界
  /// - [enableScrollWhenRefreshCompleted]：刷新完成后是否允许滚动
  RefreshPhysics({
    super.parent,
    this.updateFlag,
    this.maxUnderScrollExtent,
    this.springDescription,
    this.controller,
    this.dragSpeedRatio,
    this.topHitBoundary,
    this.bottomHitBoundary,
    this.enableScrollWhenRefreshCompleted,
    this.maxOverScrollExtent,
  });

  @override

  /// 创建一个新的滚动物理效果，将当前物理效果应用到父级物理效果上
  ///
  /// 参数：
  /// - [ancestor]：父级滚动物理效果
  /// - 返回值：一个新的RefreshPhysics实例
  RefreshPhysics applyTo(ScrollPhysics? ancestor) {
    return RefreshPhysics(
        parent: buildParent(ancestor),
        updateFlag: updateFlag,
        springDescription: springDescription,
        dragSpeedRatio: dragSpeedRatio,
        topHitBoundary: topHitBoundary,
        bottomHitBoundary: bottomHitBoundary,
        controller: controller,
        enableScrollWhenRefreshCompleted: enableScrollWhenRefreshCompleted,
        maxUnderScrollExtent: maxUnderScrollExtent,
        maxOverScrollExtent: maxOverScrollExtent);
  }

  /// 查找视口渲染对象
  ///
  /// 参数：
  /// - [context]：上下文
  /// - 返回值：视口渲染对象，如果找不到则返回null
  RenderViewport? findViewport(BuildContext? context) {
    if (context == null) {
      return null;
    }
    RenderViewport? result;
    context.visitChildElements((Element e) {
      final RenderObject? renderObject = e.findRenderObject();
      if (renderObject is RenderViewport) {
        assert(result == null);
        result = renderObject;
      } else {
        result = findViewport(e);
      }
    });
    return result;
  }

  @override

  /// 决定是否接受用户的拖动偏移
  ///
  /// 参数：
  /// - [position]：滚动位置
  /// - 返回值：如果允许拖动则返回true，否则返回false
  bool shouldAcceptUserOffset(ScrollMetrics position) {
    // 如果父级是NeverScrollableScrollPhysics，则不接受用户拖动
    if (parent is NeverScrollableScrollPhysics) {
      return false;
    }
    return true;
  }

  /// 获取运行时类型
  ///
  /// 这是一个特殊的实现，用于解决Flutter中的一个限制：
  /// 在Scrollable.dart的_shouldUpdatePosition方法中，它使用physics.runtimeType来检查两个物理效果是否相同
  /// 这会影响新的物理效果是否应该替换旧的物理效果
  /// 如果updateFlag为0，则返回RefreshPhysics类型，否则返回BouncingScrollPhysics类型
  @override
  Type get runtimeType {
    if (updateFlag == 0) {
      return RefreshPhysics;
    } else {
      return BouncingScrollPhysics;
    }
  }

  @override

  /// 将物理效果应用到用户拖动偏移上
  ///
  /// 该方法用于控制用户拖动时的滚动行为，特别是在超出边界时的效果
  ///
  /// 参数：
  /// - [position]：滚动位置信息
  /// - [offset]：用户拖动的偏移量
  /// - 返回值：应用物理效果后的偏移量
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    // 延迟初始化视口渲染对象
    viewportRender ??= findViewport(controller!.position?.context.storageContext);

    // 检查是否启用了下拉刷新或上拉加载
    final bool isPullDownEnabled = viewportRender?.firstChild is RenderSliverRefresh;
    final bool isPullUpEnabled = viewportRender?.lastChild is RenderSliverLoading;

    // 如果向上滚动但未启用下拉刷新，或向下滚动但未启用上拉加载，则使用父级物理效果
    if ((offset > 0.0 && !isPullDownEnabled) || (offset < 0 && !isPullUpEnabled)) {
      return parent!.applyPhysicsToUserOffset(position, offset);
    }
    // 处理超出范围或二级刷新状态的情况
    if (position.outOfRange) {
      // 计算超出起始位置的距离
      final double overscrollPastStart = math.max(position.minScrollExtent - position.pixels, 0.0);
      // 计算超出结束位置的距离
      final double overscrollPastEnd = math.max(position.pixels - position.maxScrollExtent, 0.0);
      // 取两者中的最大值
      final double overscrollPast = math.max(overscrollPastStart, overscrollPastEnd);

      // 判断是否需要应用缓动效果
      final bool easing = (overscrollPastStart > 0.0 && offset < 0.0) || (overscrollPastEnd > 0.0 && offset > 0.0);

      // 计算摩擦系数
      final double friction = easing
          ? frictionFactor((overscrollPast - offset.abs()) / position.viewportDimension)
          : frictionFactor(overscrollPast / position.viewportDimension);

      // 计算方向和最终偏移量
      final double direction = offset.sign;
      return direction * _applyFriction(overscrollPast, offset.abs(), friction) * (dragSpeedRatio ?? 1.0);
    }

    // 默认情况下使用父级物理效果
    return super.applyPhysicsToUserOffset(position, offset);
  }

  /// 应用摩擦效果到拖动偏移上
  ///
  /// 参数：
  /// - [extentOutside]：超出边界的距离
  /// - [absDelta]：拖动的绝对偏移量
  /// - [gamma]：摩擦系数
  /// - 返回值：应用摩擦效果后的偏移量
  static double _applyFriction(double extentOutside, double absDelta, double gamma) {
    assert(absDelta > 0);
    double total = 0.0;

    // 如果超出了边界
    if (extentOutside > 0) {
      // 计算到达限制所需的偏移量
      final double deltaToLimit = extentOutside / gamma;

      // 如果当前偏移量小于到达限制所需的偏移量
      if (absDelta < deltaToLimit) {
        return absDelta * gamma;
      }

      // 累计超出边界的距离
      total += extentOutside;
      // 减去到达限制所需的偏移量
      absDelta -= deltaToLimit;
    }

    // 返回总距离加上剩余的偏移量
    return total + absDelta;
  }

  /// 计算摩擦系数
  ///
  /// 参数：
  /// - [overscrollFraction]：超出滚动范围的比例
  /// - 返回值：摩擦系数
  double frictionFactor(double overscrollFraction) => 0.52 * math.pow(1 - overscrollFraction, 2);

  @override

  /// 应用边界条件到滚动位置
  ///
  /// 该方法用于控制滚动位置的边界条件，防止滚动超出允许的范围
  ///
  /// 参数：
  /// - [position]：当前滚动位置
  /// - [value]：期望的滚动位置
  /// - 返回值：需要调整的偏移量，如果不需要调整则返回0.0
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    final ScrollPosition scrollPosition = position as ScrollPosition;
    viewportRender ??= findViewport(controller!.position?.context.storageContext);

    // 检查内容是否不满一屏
    final bool isContentNotFull = position.minScrollExtent == position.maxScrollExtent;

    // 检查是否启用了下拉刷新和上拉加载
    final bool enablePullDown = viewportRender == null ? false : viewportRender!.firstChild is RenderSliverRefresh;
    final bool enablePullUp = viewportRender == null ? false : viewportRender!.lastChild is RenderSliverLoading;

    // 检查是否启用了对应方向的刷新
    if ((position.pixels - value > 0.0 && !enablePullDown) || (position.pixels - value < 0 && !enablePullUp)) {
      return parent!.applyBoundaryConditions(position, value);
    }

    // 计算顶部和底部的额外空间
    double topExtra = 0.0;
    double bottomExtra = 0.0;

    // 计算顶部额外空间（下拉刷新时）
    if (enablePullDown) {
      final RenderSliverRefresh sliverHeader = viewportRender!.firstChild as RenderSliverRefresh;
      topExtra = sliverHeader.hasLayoutExtent ? 0.0 : sliverHeader.refreshIndicatorLayoutExtent;
    }

    // 计算底部额外空间（上拉加载时）
    if (enablePullUp) {
      final RenderSliverLoading? sliverFooter = viewportRender!.lastChild as RenderSliverLoading?;
      bool shouldHideFooter = false;

      // 检查是否需要隐藏底部加载组件
      if (!isContentNotFull && sliverFooter!.geometry!.scrollExtent != 0) {
        shouldHideFooter = true;
      } else if (isContentNotFull) {
        // 内容不满一屏时的处理
        final refreshConfig = RefreshConfiguration.of(controller!.position!.context.storageContext);
        if (controller!.footerStatus == LoadStatus.noMore && !refreshConfig!.enableLoadingWhenNoData) {
          shouldHideFooter = true;
        } else if (refreshConfig?.hideFooterWhenNotFull ?? false) {
          shouldHideFooter = true;
        }
      }

      bottomExtra = shouldHideFooter ? 0.0 : (sliverFooter!.layoutExtent ?? 0.0);
    }

    // 计算最终的边界位置
    final double topBoundary = position.minScrollExtent - (maxOverScrollExtent ?? 0.0) - topExtra;
    final double bottomBoundary = position.maxScrollExtent + (maxUnderScrollExtent ?? 0.0) + bottomExtra;

    // 处理弹道滚动（惯性滚动）的边界条件
    if (scrollPosition.activity is BallisticScrollActivity) {
      // 处理顶部碰撞边界
      if (topHitBoundary != null && topHitBoundary != double.infinity) {
        if (value < -topHitBoundary! && -topHitBoundary! <= position.pixels) {
          // 碰到顶部边缘
          return value + topHitBoundary!;
        }
      }

      // 处理底部碰撞边界
      if (bottomHitBoundary != null && bottomHitBoundary != double.infinity) {
        if (position.pixels < bottomHitBoundary! + position.maxScrollExtent &&
            bottomHitBoundary! + position.maxScrollExtent < value) {
          // 碰到底部边缘
          return value - bottomHitBoundary! - position.maxScrollExtent;
        }
      }
    }

    // 处理超出顶部边界的情况
    if (maxOverScrollExtent != null &&
        maxOverScrollExtent != double.infinity &&
        value < topBoundary &&
        topBoundary < position.pixels) {
      // 碰到顶部边缘
      return value - topBoundary;
    }

    // 处理超出底部边界的情况
    if (maxUnderScrollExtent != null &&
        maxUnderScrollExtent != double.infinity &&
        position.pixels < bottomBoundary &&
        bottomBoundary < value) {
      // 碰到底部边缘
      return value - bottomBoundary;
    }

    // 处理用户拖动时的边界条件
    // 这很重要，因为不同设备在不同帧和时间可能有不同的弹跳行为，导致返回不同的速度
    if (scrollPosition.activity is DragScrollActivity) {
      // 处理上拉超出顶部边界的情况
      if (maxOverScrollExtent != null &&
          maxOverScrollExtent != double.infinity &&
          value < position.pixels &&
          position.pixels <= topBoundary) {
        // 上拉超出范围
        return value - position.pixels;
      }

      // 处理下拉超出底部边界的情况
      if (maxUnderScrollExtent != null &&
          maxUnderScrollExtent != double.infinity &&
          bottomBoundary <= position.pixels &&
          position.pixels < value) {
        // 下拉超出范围
        return value - position.pixels;
      }
    }

    // 不需要调整
    return 0.0;
  }

  @override

  /// 创建弹道滚动模拟
  ///
  /// 该方法用于创建滚动结束后的惯性滚动模拟，控制滚动的减速和回弹效果
  ///
  /// 参数：
  /// - [position]：当前滚动位置
  /// - [velocity]：滚动速度
  /// - 返回值：弹道滚动模拟对象，如果不需要模拟则返回null
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    // 延迟初始化视口渲染对象
    viewportRender ??= findViewport(controller!.position?.context.storageContext);

    // 检查是否启用了下拉刷新和上拉加载
    final bool enablePullDown = viewportRender == null ? false : viewportRender!.firstChild is RenderSliverRefresh;
    final bool enablePullUp = viewportRender == null ? false : viewportRender!.lastChild is RenderSliverLoading;

    // 检查是否启用了对应方向的刷新
    if ((velocity < 0.0 && !enablePullDown) || (velocity > 0 && !enablePullUp)) {
      return parent!.createBallisticSimulation(position, velocity);
    }

    // 处理超出范围或二级刷新状态的情况
    if (position.outOfRange) {
      // 创建弹跳滚动模拟
      return BouncingScrollSimulation(
        spring: springDescription ?? spring,
        position: position.pixels,
        // 乘以0.91是为了避免弹簧回弹停止后释放手势
        velocity: velocity * 0.91,
        leadingExtent: position.minScrollExtent,
        trailingExtent: position.maxScrollExtent,
        tolerance: toleranceFor(position),
      );
    }

    // 默认使用父级模拟
    return super.createBallisticSimulation(position, velocity);
  }
}
