// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member, unnecessary_this
import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../smart_refresher.dart';

/// 下拉刷新头的Sliver组件
///
/// 该组件用于实现下拉刷新功能的Sliver部分，负责管理刷新指示器的布局和绘制
///
/// 示例用法：
/// ```dart
/// SliverRefresh(
///   refreshIndicatorLayoutExtent: 60.0,
///   floating: false,
///   refreshStyle: RefreshStyle.Follow,
///   child: CustomRefreshHeader(),
/// );
/// ```
class SliverRefresh extends SingleChildRenderObjectWidget {
  /// 创建下拉刷新头的Sliver组件
  ///
  /// 参数：
  /// - [key]：组件的唯一标识
  /// - [paintOffsetY]：头部指示器布局偏差Y坐标，主要用于FrontStyle
  /// - [refreshIndicatorLayoutExtent]：刷新状态下指示器在Sliver中占据的空间
  /// - [floating]：是否在滚动时保持可见
  /// - [child]：刷新指示器组件
  /// - [refreshStyle]：头部指示器显示样式
  const SliverRefresh({
    super.key,
    this.paintOffsetY,
    this.refreshIndicatorLayoutExtent = 0.0,
    this.floating = false,
    super.child,
    this.refreshStyle,
  }) : assert(refreshIndicatorLayoutExtent >= 0.0);

  /// 刷新状态下指示器在Sliver中占据的空间
  final double refreshIndicatorLayoutExtent;

  /// 是否在滚动时保持可见
  ///
  /// true表示始终可见，false表示仅在刷新时可见
  final bool floating;

  /// 头部指示器显示样式
  final RefreshStyle? refreshStyle;

  /// 头部指示器布局偏差Y坐标
  ///
  /// 主要用于FrontStyle，调整指示器的垂直位置
  final double? paintOffsetY;

  @override

  /// 创建渲染对象
  RenderSliverRefresh createRenderObject(BuildContext context) {
    return RenderSliverRefresh(
      refreshIndicatorExtent: refreshIndicatorLayoutExtent,
      hasLayoutExtent: floating,
      paintOffsetY: paintOffsetY,
      refreshStyle: refreshStyle,
    );
  }

  @override

  /// 更新渲染对象
  void updateRenderObject(BuildContext context, covariant RenderSliverRefresh renderObject) {
    final RefreshStatus mode = SmartRefresher.of(context)!.controller.headerMode!.value;
    renderObject
      ..refreshIndicatorLayoutExtent = refreshIndicatorLayoutExtent
      ..hasLayoutExtent = floating
      ..context = context
      ..refreshStyle = refreshStyle
      ..updateFlag = mode == RefreshStatus.idle
      ..paintOffsetY = paintOffsetY;
  }
}

/// 下拉刷新头的渲染对象
///
/// 负责管理下拉刷新头的布局和绘制逻辑，根据不同的刷新样式调整其位置和大小
class RenderSliverRefresh extends RenderSliverSingleBoxAdapter {
  /// 创建下拉刷新头的渲染对象
  ///
  /// 参数：
  /// - [refreshIndicatorExtent]：刷新状态下指示器的布局范围
  /// - [hasLayoutExtent]：是否占据布局范围
  /// - [child]：刷新指示器的渲染对象
  /// - [paintOffsetY]：头部指示器布局偏差Y坐标
  /// - [refreshStyle]：头部指示器显示样式
  RenderSliverRefresh(
      {required double refreshIndicatorExtent,
      required bool hasLayoutExtent,
      RenderBox? child,
      this.paintOffsetY,
      this.refreshStyle})
      : assert(refreshIndicatorExtent >= 0.0),
        _refreshIndicatorExtent = refreshIndicatorExtent,
        _hasLayoutExtent = hasLayoutExtent {
    this.child = child;
  }

  /// 头部指示器显示样式
  RefreshStyle? refreshStyle;

  /// 构建上下文
  late BuildContext context;

  /// 刷新状态下指示器的布局范围
  double get refreshIndicatorLayoutExtent => _refreshIndicatorExtent;
  double _refreshIndicatorExtent;

  /// 头部指示器布局偏差Y坐标
  double? paintOffsetY;

  /// 更新标志
  ///
  /// 用于触发shouldAcceptUserOffset，否则在进入二级刷新或退出时不会限制滚动
  /// 同时，在状态变化时调用applyNewDimensions可能会导致崩溃
  bool _updateFlag = false;

  /// 设置刷新状态下指示器的布局范围
  set refreshIndicatorLayoutExtent(double value) {
    assert(value >= 0.0);
    if (value == _refreshIndicatorExtent) return;
    _refreshIndicatorExtent = value;
    markNeedsLayout();
  }

  /// 是否占据布局范围
  ///
  /// 为true时，子组件将占据SliverGeometry.layoutExtent空间
  bool get hasLayoutExtent => _hasLayoutExtent;
  bool _hasLayoutExtent;

  /// 设置是否占据布局范围
  set hasLayoutExtent(bool value) {
    if (value == _hasLayoutExtent) return;
    if (!value) {
      _updateFlag = true;
    }
    _hasLayoutExtent = value;
    markNeedsLayout();
  }

  /// 布局范围偏移补偿
  ///
  /// 用于跟踪之前应用到可滚动组件的滚动偏移量，以便在refreshIndicatorLayoutExtent或hasLayoutExtent变化时
  /// 应用适当的增量，保持视觉上的一致性
  double layoutExtentOffsetCompensation = 0.0;

  @override

  /// 执行调整大小
  void performResize() {
    super.performResize();
  }

  @override

  /// 中心偏移调整
  ///
  /// 用于Front样式，调整指示器的中心位置
  double get centerOffsetAdjustment {
    if (refreshStyle == RefreshStyle.front) {
      final RenderViewportBase renderViewport = parent as RenderViewportBase<ContainerParentDataMixin<RenderSliver>>;
      return math.max(0.0, -renderViewport.offset.pixels);
    }
    return 0.0;
  }

  @override

  /// 布局刷新头
  ///
  /// 根据不同的刷新样式调整布局约束
  void layout(Constraints constraints, {bool parentUsesSize = false}) {
    if (refreshStyle == RefreshStyle.front) {
      final RenderViewportBase renderViewport = parent as RenderViewportBase<ContainerParentDataMixin<RenderSliver>>;
      super.layout((constraints as SliverConstraints).copyWith(overlap: math.min(0.0, renderViewport.offset.pixels)),
          parentUsesSize: true);
    } else {
      super.layout(constraints, parentUsesSize: parentUsesSize);
    }
  }

  /// 设置更新标志
  set updateFlag(bool value) {
    _updateFlag = value;
    markNeedsLayout();
  }

  @override

  /// 调试断言，检查是否满足约束条件
  void debugAssertDoesMeetConstraints() {
    assert(geometry!.debugAssertIsValid(informationCollector: () sync* {
      yield describeForError('The RenderSliver that returned the offending geometry was');
    }));
    assert(() {
      if (geometry!.paintExtent > constraints.remainingPaintExtent) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('SliverGeometry has a paintOffset that exceeds the remainingPaintExtent from the constraints.'),
          describeForError('The render object whose geometry violates the constraints is the following'),
          ErrorDescription(
            'The paintExtent must cause the child sliver to paint within the viewport, and so '
            'cannot exceed the remainingPaintExtent.',
          ),
        ]);
      }
      return true;
    }());
  }

  @override

  /// 执行布局
  ///
  /// 根据刷新样式和滚动状态计算并设置SliverGeometry
  void performLayout() {
    // 如果需要更新，应用新的尺寸
    if (_updateFlag) {
      Scrollable.of(context).position.activity!.applyNewDimensions();
      _updateFlag = false;
    }

    // 计算新的布局范围
    final double layoutExtent = (_hasLayoutExtent ? 1.0 : 0.0) * _refreshIndicatorExtent;

    // 如果布局范围变化，调整滚动偏移量以避免视觉跳跃
    if (refreshStyle != RefreshStyle.front) {
      if (layoutExtent != layoutExtentOffsetCompensation) {
        geometry = SliverGeometry(
          scrollOffsetCorrection: layoutExtent - layoutExtentOffsetCompensation,
        );
        layoutExtentOffsetCompensation = layoutExtent;
        return;
      }
    }

    // 检查是否需要激活刷新头
    bool active = constraints.overlap < 0.0 || layoutExtent > 0.0;
    final double overscrolledExtent = -(parent as RenderViewportBase).offset.pixels;

    // 根据刷新样式布局子组件
    if (refreshStyle == RefreshStyle.behind) {
      child!.layout(
        constraints.asBoxConstraints(maxExtent: math.max(0, overscrolledExtent + layoutExtent)),
        parentUsesSize: true,
      );
    } else {
      child!.layout(
        constraints.asBoxConstraints(),
        parentUsesSize: true,
      );
    }

    // 计算子组件的范围
    final double boxExtent =
        (constraints.axisDirection == AxisDirection.up || constraints.axisDirection == AxisDirection.down)
            ? child!.size.height
            : child!.size.width;

    if (active) {
      // 计算需要绘制的范围
      final double needPaintExtent = math.min(
          math.max(
            math.max(
                    (constraints.axisDirection == AxisDirection.up || constraints.axisDirection == AxisDirection.down)
                        ? child!.size.height
                        : child!.size.width,
                    layoutExtent) -
                constraints.scrollOffset,
            0.0,
          ),
          constraints.remainingPaintExtent);

      // 根据不同的刷新样式设置几何信息
      switch (refreshStyle) {
        case RefreshStyle.follow:
          geometry = SliverGeometry(
            scrollExtent: layoutExtent,
            paintOrigin: -boxExtent - constraints.scrollOffset + layoutExtent,
            paintExtent: needPaintExtent,
            hitTestExtent: needPaintExtent,
            hasVisualOverflow: overscrolledExtent < boxExtent,
            maxPaintExtent: needPaintExtent,
            layoutExtent: math.min(needPaintExtent, math.max(layoutExtent - constraints.scrollOffset, 0.0)),
          );
          break;

        case RefreshStyle.behind:
          geometry = SliverGeometry(
            scrollExtent: layoutExtent,
            paintOrigin: -overscrolledExtent - constraints.scrollOffset,
            paintExtent: needPaintExtent,
            maxPaintExtent: needPaintExtent,
            layoutExtent: math.max(layoutExtent - constraints.scrollOffset, 0.0),
          );
          break;

        case RefreshStyle.unFollow:
          geometry = SliverGeometry(
            scrollExtent: layoutExtent,
            paintOrigin: math.min(
                -overscrolledExtent - constraints.scrollOffset, -boxExtent - constraints.scrollOffset + layoutExtent),
            paintExtent: needPaintExtent,
            hasVisualOverflow: overscrolledExtent < boxExtent,
            maxPaintExtent: needPaintExtent,
            layoutExtent: math.min(needPaintExtent, math.max(layoutExtent - constraints.scrollOffset, 0.0)),
          );
          break;

        case RefreshStyle.front:
          geometry = SliverGeometry(
            paintOrigin:
                constraints.axisDirection == AxisDirection.up || constraints.crossAxisDirection == AxisDirection.left
                    ? boxExtent
                    : 0.0,
            visible: true,
            hasVisualOverflow: true,
          );
          break;

        case null:
          break;
      }

      // 设置子组件的父数据
      setChildParentData(child!, constraints, geometry!);
    } else {
      // 如果不激活，设置几何信息为零
      geometry = SliverGeometry.zero;
    }
  }

  @override

  /// 绘制刷新头
  ///
  /// 根据paintOffsetY调整子组件的绘制位置
  void paint(PaintingContext paintContext, Offset offset) {
    paintContext.paintChild(child!, Offset(offset.dx, offset.dy + paintOffsetY!));
  }

  @override

  /// 应用绘制变换
  ///
  /// 空实现，不应用任何变换
  void applyPaintTransform(RenderObject child, Matrix4 transform) {}
}

/// 上拉加载更多的Sliver组件
///
/// 该组件用于实现上拉加载更多功能的Sliver部分，负责管理加载指示器的布局和绘制
///
/// 示例用法：
/// ```dart
/// SliverLoading(
///   mode: LoadStatus.idle,
///   floating: false,
///   shouldFollowContent: true,
///   layoutExtent: 60.0,
///   hideWhenNotFull: true,
///   child: CustomLoadMoreFooter(),
/// );
/// ```
class SliverLoading extends SingleChildRenderObjectWidget {
  /// 内容不满一页时是否隐藏和禁用加载
  final bool? hideWhenNotFull;

  /// 是否在滚动时保持可见
  final bool? floating;

  /// 加载状态
  final LoadStatus? mode;

  /// 加载指示器的布局范围
  final double? layoutExtent;

  /// 内容不满一页时是否跟随内容
  final bool? shouldFollowContent;

  /// 创建上拉加载更多的Sliver组件
  ///
  /// 参数：
  /// - [key]：组件的唯一标识
  /// - [mode]：加载状态
  /// - [floating]：是否在滚动时保持可见
  /// - [shouldFollowContent]：内容不满一页时是否跟随内容
  /// - [layoutExtent]：加载指示器的布局范围
  /// - [hideWhenNotFull]：内容不满一页时是否隐藏和禁用加载
  /// - [child]：加载指示器组件
  const SliverLoading({
    super.key,
    this.mode,
    this.floating,
    this.shouldFollowContent,
    this.layoutExtent,
    this.hideWhenNotFull,
    super.child,
  });

  @override

  /// 创建渲染对象
  RenderSliverLoading createRenderObject(BuildContext context) {
    return RenderSliverLoading(
        hideWhenNotFull: hideWhenNotFull,
        mode: mode,
        hasLayoutExtent: floating,
        shouldFollowContent: shouldFollowContent,
        layoutExtent: layoutExtent);
  }

  @override

  /// 更新渲染对象
  void updateRenderObject(BuildContext context, covariant RenderSliverLoading renderObject) {
    renderObject
      ..mode = mode
      ..hasLayoutExtent = floating!
      ..layoutExtent = layoutExtent
      ..shouldFollowContent = shouldFollowContent
      ..hideWhenNotFull = hideWhenNotFull;
  }
}

/// 上拉加载更多的渲染对象
///
/// 负责管理上拉加载更多的布局和绘制逻辑，根据不同的加载状态调整其位置和大小
class RenderSliverLoading extends RenderSliverSingleBoxAdapter {
  /// 创建上拉加载更多的渲染对象
  ///
  /// 参数：
  /// - [child]：加载指示器的渲染对象
  /// - [mode]：加载状态
  /// - [layoutExtent]：加载指示器的布局范围
  /// - [hasLayoutExtent]：是否占据布局范围
  /// - [shouldFollowContent]：内容不满一页时是否跟随内容
  /// - [hideWhenNotFull]：内容不满一页时是否隐藏和禁用加载
  RenderSliverLoading({
    RenderBox? child,
    this.mode,
    double? layoutExtent,
    bool? hasLayoutExtent,
    this.shouldFollowContent,
    this.hideWhenNotFull,
  }) {
    _hasLayoutExtent = hasLayoutExtent;
    this.layoutExtent = layoutExtent;
    this.child = child;
  }

  /// 内容不满一页时是否跟随内容
  bool? shouldFollowContent;

  /// 内容不满一页时是否隐藏和禁用加载
  bool? hideWhenNotFull;

  /// 加载状态
  LoadStatus? mode;

  /// 加载指示器的布局范围
  double? _layoutExtent;

  /// 设置加载指示器的布局范围
  set layoutExtent(double? extent) {
    if (extent == _layoutExtent) return;
    _layoutExtent = extent;
    markNeedsLayout();
  }

  /// 获取加载指示器的布局范围
  double? get layoutExtent => _layoutExtent;

  /// 是否占据布局范围
  bool get hasLayoutExtent => _hasLayoutExtent!;
  bool? _hasLayoutExtent;

  /// 设置是否占据布局范围
  set hasLayoutExtent(bool value) {
    if (value == _hasLayoutExtent) return;
    _hasLayoutExtent = value;
    markNeedsLayout();
  }

  /// 计算内容是否填满一页
  ///
  /// 参数：
  /// - [cons]：Sliver约束
  /// - 返回值：内容填满一页返回true，否则返回false
  bool _computeIfFull(SliverConstraints cons) {
    final RenderViewport viewport = parent as RenderViewport;
    RenderSliver? sliverP = viewport.firstChild;
    double totalScrollExtent = cons.precedingScrollExtent;
    while (sliverP != this) {
      if (sliverP is RenderSliverRefresh) {
        totalScrollExtent -= sliverP.geometry!.scrollExtent;
        break;
      }
      sliverP = viewport.childAfter(sliverP!);
    }
    // 考虑底部布局范围，需要减去其高度
    return totalScrollExtent > cons.viewportMainAxisExtent;
  }

  /// 计算绘制原点
  ///
  /// 参数：
  /// - [layoutExtent]：布局范围
  /// - [reverse]：是否反向
  /// - [follow]：是否跟随内容
  /// - 返回值：绘制原点
  double? computePaintOrigin(double? layoutExtent, bool reverse, bool follow) {
    if (follow) {
      if (reverse) {
        return layoutExtent;
      }
      return 0.0;
    } else {
      if (reverse) {
        return math.max(constraints.viewportMainAxisExtent - constraints.precedingScrollExtent, 0.0) + layoutExtent!;
      } else {
        return math.max(constraints.viewportMainAxisExtent - constraints.precedingScrollExtent, 0.0);
      }
    }
  }

  @override

  /// 调试断言，检查是否满足约束条件
  void debugAssertDoesMeetConstraints() {
    assert(geometry!.debugAssertIsValid(informationCollector: () sync* {
      yield describeForError('The RenderSliver that returned the offending geometry was');
    }));
    assert(() {
      if (geometry!.paintExtent > constraints.remainingPaintExtent) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('SliverGeometry has a paintOffset that exceeds the remainingPaintExtent from the constraints.'),
          describeForError('The render object whose geometry violates the constraints is the following'),
          ErrorDescription(
            'The paintExtent must cause the child sliver to paint within the viewport, and so '
            'cannot exceed the remainingPaintExtent.',
          ),
        ]);
      }
      return true;
    }());
  }

  @override

  /// 执行布局
  ///
  /// 根据加载状态和内容是否填满一页计算并设置SliverGeometry
  void performLayout() {
    assert(constraints.growthDirection == GrowthDirection.forward);
    if (child == null) {
      geometry = SliverGeometry.zero;
      return;
    }

    // 检查是否需要激活加载组件
    bool active;
    if (hideWhenNotFull! && mode != LoadStatus.noMore) {
      active = _computeIfFull(constraints);
    } else {
      active = true;
    }

    // 根据是否激活布局子组件
    if (active) {
      child!.layout(constraints.asBoxConstraints(), parentUsesSize: true);
    } else {
      child!.layout(constraints.asBoxConstraints(maxExtent: 0.0, minExtent: 0.0), parentUsesSize: true);
    }

    // 计算子组件范围
    double childExtent = constraints.axis == Axis.vertical ? child!.size.height : child!.size.width;
    final double paintedChildSize = calculatePaintOffset(constraints, from: 0.0, to: childExtent);
    final double cacheExtent = calculateCacheOffset(constraints, from: 0.0, to: childExtent);
    assert(paintedChildSize.isFinite);
    assert(paintedChildSize >= 0.0);

    if (active) {
      // 考虑反向加载和HideAlways==loadStyle
      geometry = SliverGeometry(
        scrollExtent: !_hasLayoutExtent! || !_computeIfFull(constraints) ? 0.0 : layoutExtent ?? 0.0,
        paintExtent: paintedChildSize,
        paintOrigin: computePaintOrigin(
            (!_hasLayoutExtent! || !_computeIfFull(constraints) ? layoutExtent : 0.0) ?? 0.0,
            constraints.axisDirection == AxisDirection.up || constraints.axisDirection == AxisDirection.left,
            _computeIfFull(constraints) || (shouldFollowContent ?? false))!,
        cacheExtent: cacheExtent,
        maxPaintExtent: childExtent,
        hitTestExtent: paintedChildSize,
        visible: true,
        hasVisualOverflow: true,
      );
      setChildParentData(child!, constraints, geometry!);
    } else {
      geometry = SliverGeometry.zero;
    }
  }
}

/// 刷新内容的Sliver组件
///
/// 该组件用于包裹刷新列表的内容部分，负责管理内容的布局和绘制
///
/// 示例用法：
/// ```dart
/// SliverRefreshBody(
///   child: ListView.builder(
///     itemCount: 20,
///     itemBuilder: (context, index) => ListTile(title: Text('Item $index')),
///   ),
/// );
/// ```
class SliverRefreshBody extends SingleChildRenderObjectWidget {
  /// 创建刷新内容的Sliver组件
  ///
  /// 参数：
  /// - [key]：组件的唯一标识
  /// - [child]：刷新列表的内容组件
  const SliverRefreshBody({
    super.key,
    super.child,
  });

  @override

  /// 创建渲染对象
  RenderSliverRefreshBody createRenderObject(BuildContext context) => RenderSliverRefreshBody();
}

/// 刷新内容的渲染对象
///
/// 负责管理刷新列表内容的布局和绘制逻辑，根据内容大小调整其滚动范围
class RenderSliverRefreshBody extends RenderSliverSingleBoxAdapter {
  /// 创建刷新内容的渲染对象
  ///
  /// 参数：
  /// - [child]：刷新列表内容的渲染对象
  RenderSliverRefreshBody({
    super.child,
  });

  @override

  /// 执行布局
  ///
  /// 根据内容大小调整其滚动范围，确保内容能够正确滚动
  void performLayout() {
    if (child == null) {
      geometry = SliverGeometry.zero;
      return;
    }

    // 首先使用一个很大的maxExtent来布局子组件，以获取其真实大小
    child!.layout(constraints.asBoxConstraints(maxExtent: 1111111), parentUsesSize: true);

    double? childExtent;
    // 根据主轴方向获取子组件的范围
    switch (constraints.axis) {
      case Axis.horizontal:
        childExtent = child!.size.width;
        break;
      case Axis.vertical:
        childExtent = child!.size.height;
        break;
    }

    // 如果子组件的范围等于我们设置的最大范围，说明子组件可以无限大
    // 此时我们将其maxExtent设置为视口大小
    if (childExtent == 1111111) {
      child!.layout(constraints.asBoxConstraints(maxExtent: constraints.viewportMainAxisExtent), parentUsesSize: true);

      // 重新获取子组件的范围
      switch (constraints.axis) {
        case Axis.horizontal:
          childExtent = child!.size.width;
          break;
        case Axis.vertical:
          childExtent = child!.size.height;
          break;
      }
    }

    // 计算绘制和缓存范围
    final double paintedChildSize = calculatePaintOffset(constraints, from: 0.0, to: childExtent);
    final double cacheExtent = calculateCacheOffset(constraints, from: 0.0, to: childExtent);

    assert(paintedChildSize.isFinite);
    assert(paintedChildSize >= 0.0);

    // 设置几何信息
    geometry = SliverGeometry(
      scrollExtent: childExtent,
      paintExtent: paintedChildSize,
      cacheExtent: cacheExtent,
      maxPaintExtent: childExtent,
      hitTestExtent: paintedChildSize,
      hasVisualOverflow: childExtent > constraints.remainingPaintExtent || constraints.scrollOffset > 0.0,
    );

    // 设置子组件的父数据
    setChildParentData(child!, constraints, geometry!);
  }
}
