// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member, unnecessary_this
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import 'indicator/classic_indicator.dart';
import 'indicator/material_indicator.dart';
import 'internals/indicator_wrap.dart';
import 'internals/refresh_physics.dart';
import 'internals/slivers.dart';

/// 内容不满一页时是否跟随内容的回调函数类型
///
/// 参数：
/// - [status]：当前加载状态
/// - 返回值：是否跟随内容
typedef ShouldFollowContent = bool Function(LoadStatus? status);

/// 全局默认指示器构建函数类型
///
/// 返回值：构建的指示器组件
typedef IndicatorBuilder = Widget Function();

/// 用于将刷新功能与物理效果关联的构建函数类型
///
/// 参数：
/// - [context]：构建上下文
/// - [physics]：滚动物理效果
/// - 返回值：构建的刷新组件
typedef RefresherBuilder = Widget Function(BuildContext context, RefreshPhysics physics);

/// 刷新头部的状态枚举
///
/// 定义了下拉刷新过程中可能的各种状态
enum RefreshStatus {
  /// 初始状态，未被拖动，或拖动被取消后，或刷新完成后收起
  idle,

  /// 拖动距离足够，释放后将触发onRefresh回调
  canRefresh,

  /// 刷新中，等待onRefresh回调完成
  refreshing,

  /// 刷新完成
  completed,

  /// 刷新失败
  failed,
}

/// 加载底部的状态枚举
///
/// 定义了上拉加载过程中可能的各种状态
enum LoadStatus {
  /// 初始状态，可以通过手势上拉触发加载更多
  idle,

  /// 拖动距离足够，释放后将触发onLoading回调
  canLoading,

  /// 加载中，等待onLoading回调完成
  loading,

  /// 没有更多数据可加载，此状态下不允许继续加载
  noMore,

  /// 加载失败，初始状态，可以点击重试
  /// 如果需要通过上拉触发加载更多，应在RefreshConfiguration中设置enableLoadingWhenFailed = true
  failed
}

/// 刷新头部的显示样式枚举
///
/// 定义了刷新指示器的不同显示风格
enum RefreshStyle {
  /// 指示器始终跟随内容移动
  follow,

  /// 指示器跟随内容移动，当指示器到达顶部并完全可见时，不再跟随内容
  unFollow,

  /// 指示器大小随边界距离缩放，看起来像是显示在内容后面
  behind,

  /// 此样式类似于Flutter原生的RefreshIndicator，显示在内容上方
  front
}

/// 加载底部的显示样式枚举
///
/// 定义了加载指示器的不同显示风格
enum LoadStyle {
  /// 无论何种状态，指示器始终占据布局范围
  showAlways,

  /// 无论何种状态，指示器始终不占据布局范围（布局范围为0.0）
  hideAlways,

  /// 仅在加载状态下，指示器占据布局范围，其他状态下布局范围为0.0
  showWhenLoading
}

/// 这是提供下拉刷新和上拉加载功能的核心组件。
/// [RefreshController] 不能为空，每个 SmartRefresher 只能对应一个控制器。
///
/// **Header 指示器**：已内置多种样式，包括 [ClassicHeader]、[WaterDropMaterialHeader]、[MaterialClassicHeader] 等。
/// **Footer 指示器**：已内置 [ClassicFooter]。
/// **自定义指示器**：如果需要自定义样式，可以使用 [CustomHeader] 或 [CustomFooter]。
///
/// **使用示例**：
/// ```dart
/// SmartRefresher(
///   controller: _refreshController,
///   enablePullDown: true,
///   enablePullUp: true,
///   header: ClassicHeader(),
///   footer: ClassicFooter(),
///   onRefresh: () async {
///     // 执行刷新逻辑
///     await Future.delayed(Duration(seconds: 1));
///     _refreshController.refreshCompleted();
///   },
///   onLoading: () async {
///     // 执行加载更多逻辑
///     await Future.delayed(Duration(seconds: 1));
///     _refreshController.loadComplete();
///   },
///   child: ListView.builder(
///     itemCount: 20,
///     itemBuilder: (context, index) {
///       return ListTile(title: Text('Item $index'));
///     },
///   ),
/// );
/// ```
///
/// 相关组件：
/// * [RefreshConfiguration]：为子树中的所有 SmartRefresher 提供全局配置
/// * [RefreshController]：控制 header 和 footer 状态的控制器
class SmartRefresher extends StatefulWidget {
  /// 刷新内容组件
  ///
  /// 注意事项：
  /// - 如果 child 继承自 ScrollView，内部会获取其 slivers 并添加 header 和 footer
  /// - 否则，会将 child 包装到 SliverToBoxAdapter 中，再添加 header 和 footer
  /// - 如果你的 child 内部包含可滚动组件，请考虑转换为 Sliver 并使用 CustomScrollView，或使用 [builder] 构造函数
  final Widget? child;

  /// 头部刷新指示器
  ///
  /// 显示位置：
  /// - 如果 reverse 为 false，header 显示在内容顶部
  /// - 如果 reverse 为 true，header 显示在内容底部
  /// - 如果 scrollDirection = Axis.horizontal，header 显示在左侧或右侧
  ///
  /// 注意：必须传递 sliver 组件，否则会抛出错误
  final Widget? header;

  /// 底部加载更多指示器
  ///
  /// 显示位置：
  /// - 如果 reverse 为 true，footer 显示在内容顶部
  /// - 如果 reverse 为 false，footer 显示在内容底部
  /// - 如果 scrollDirection = Axis.horizontal，footer 显示在左侧或右侧
  ///
  /// 注意：必须传递 sliver 组件，否则会抛出错误
  final Widget? footer;

  /// 是否启用上拉加载更多功能
  final bool enablePullUp;

  /// 是否启用下拉刷新功能
  final bool enablePullDown;

  /// 下拉刷新回调
  ///
  /// 注意：回调执行时，必须使用 [RefreshController] 结束刷新状态，否则会一直保持刷新状态
  final VoidCallback? onRefresh;

  /// 上拉加载更多回调
  ///
  /// 注意：回调执行时，必须使用 [RefreshController] 结束加载状态，否则会一直保持加载状态
  final VoidCallback? onLoading;

  /// 控制内部状态的控制器
  ///
  /// 必须提供，用于控制刷新和加载状态
  final RefreshController controller;

  /// 自定义内容构建器
  ///
  /// 用于处理特殊的第三方组件，这些组件需要传递 slivers 但不继承自 ScrollView
  final RefresherBuilder? builder;

  /// 滚动方向（复制自 ScrollView）
  final Axis? scrollDirection;

  /// 是否反向滚动（复制自 ScrollView）
  final bool? reverse;

  /// 滚动控制器（复制自 ScrollView）
  final ScrollController? scrollController;

  /// 是否使用 primary scroll controller（复制自 ScrollView）
  final bool? primary;

  /// 滚动物理效果（复制自 ScrollView）
  final ScrollPhysics? physics;

  /// 缓存区域大小（复制自 ScrollView）
  final double? cacheExtent;

  /// 语义化子组件数量（复制自 ScrollView）
  final int? semanticChildCount;

  /// 拖动开始行为（复制自 ScrollView）
  final DragStartBehavior? dragStartBehavior;

  /// 是否启用智能预加载（基于上一次加载高度的一半进行预加载）
  final bool? enableSmartPreload;

  /// 创建一个带有下拉刷新和上拉加载功能的组件
  ///
  /// **必填参数**：
  /// - [controller]：控制刷新和加载状态的控制器，不能为空
  ///
  /// **核心参数**：
  /// - [child]：刷新内容组件
  /// - [enablePullDown]：是否启用下拉刷新，默认为 true
  /// - [enablePullUp]：是否启用上拉加载，默认为 false
  /// - [onRefresh]：下拉刷新回调函数
  /// - [onLoading]：上拉加载回调函数
  ///
  /// **指示器参数**：
  /// - [header]：自定义头部刷新指示器
  /// - [footer]：自定义底部加载指示器
  ///
  /// **滚动相关参数**（复制自 ScrollView）：
  /// - [scrollDirection]：滚动方向
  /// - [reverse]：是否反向滚动
  /// - [scrollController]：滚动控制器
  /// - [primary]：是否使用 primary scroll controller
  /// - [physics]：滚动物理效果
  /// - [cacheExtent]：缓存区域大小
  /// - [semanticChildCount]：语义化子组件数量
  /// - [dragStartBehavior]：拖动开始行为
  ///
  /// **使用注意**：
  /// - 如果 child 继承自 ScrollView，内部会获取其 slivers 并添加 header 和 footer
  /// - 否则，会将 child 包装到 SliverToBoxAdapter 中
  /// - 如果 child 内部包含可滚动组件，请考虑转换为 Sliver 并使用 CustomScrollView，或使用 [builder] 构造函数
  /// - 对于 AnimatedList、RecordableList 等特殊组件，建议使用 [builder] 构造函数
  const SmartRefresher(
      {super.key,
      required this.controller,
      this.child,
      this.header,
      this.footer,
      this.enablePullDown = true,
      this.enablePullUp = false,
      this.onRefresh,
      this.onLoading,
      this.dragStartBehavior,
      this.primary,
      this.cacheExtent,
      this.semanticChildCount,
      this.reverse,
      this.physics,
      this.scrollDirection,
      this.scrollController,
      this.enableSmartPreload})
      : builder = null;

  /// 创建一个带有下拉刷新和上拉加载功能的组件，使用自定义构建器
  ///
  /// **适用场景**：
  /// - 处理特殊的第三方组件，这些组件需要传递 slivers 但不继承自 ScrollView
  /// - 避免 scrollable 嵌套 scrollable 的问题
  /// - 例如：在 NestedScrollView 上方实现刷新（目前 NestedScrollView 不支持边缘过度滚动）
  ///
  /// **必填参数**：
  /// - [controller]：控制刷新和加载状态的控制器，不能为空
  /// - [builder]：自定义内容构建器，不能为空
  ///
  /// **其他参数**：
  /// - [enablePullDown]：是否启用下拉刷新，默认为 true
  /// - [enablePullUp]：是否启用上拉加载，默认为 false
  /// - [onRefresh]：下拉刷新回调函数
  /// - [onLoading]：上拉加载回调函数
  const SmartRefresher.builder({
    super.key,
    required this.controller,
    required this.builder,
    this.enablePullDown = true,
    this.enablePullUp = false,
    this.onRefresh,
    this.onLoading,
    this.enableSmartPreload,
  })  : header = null,
        footer = null,
        child = null,
        scrollController = null,
        scrollDirection = null,
        physics = null,
        reverse = null,
        semanticChildCount = null,
        dragStartBehavior = null,
        cacheExtent = null,
        primary = null;

  static SmartRefresher? of(BuildContext? context) {
    return context!.findAncestorWidgetOfExactType<SmartRefresher>();
  }

  static SmartRefresherState? ofState(BuildContext? context) {
    return context!.findAncestorStateOfType<SmartRefresherState>();
  }

  @override
  State<StatefulWidget> createState() {
    // implement createState
    return SmartRefresherState();
  }
}

class SmartRefresherState extends State<SmartRefresher> {
  RefreshPhysics? _physics;
  bool _updatePhysics = false;
  double viewportExtent = 0;
  bool _canDrag = true;

  /// 默认头部指示器：根据平台自动选择
  /// - iOS: 使用 ClassicHeader
  /// - 其他平台: 使用 MaterialClassicHeader
  final RefreshIndicator defaultHeader =
      defaultTargetPlatform == TargetPlatform.iOS ? const ClassicHeader() : const MaterialClassicHeader();

  /// 默认底部加载指示器：始终使用 ClassicFooter
  final LoadIndicator defaultFooter = const ClassicFooter();

  /// 根据子组件构建 slivers 列表
  ///
  /// 处理逻辑：
  /// 1. 如果 child 是 ScrollView：
  ///    - 如果是 BoxScrollView，构建子布局并处理 padding
  ///    - 否则，直接获取其 slivers
  /// 2. 如果 child 不是 Scrollable，包装到 SliverRefreshBody 中
  /// 3. 根据配置添加 header 和 footer
  List<Widget>? _buildSliversByChild(BuildContext context, Widget? child, RefreshConfiguration? configuration) {
    List<Widget>? slivers;
    if (child is ScrollView) {
      if (child is BoxScrollView) {
        //avoid system inject padding when own indicator top or bottom
        Widget sliver = child.buildChildLayout(context);
        if (child.padding != null) {
          slivers = [SliverPadding(sliver: sliver, padding: child.padding!)];
        } else {
          slivers = [sliver];
        }
      } else {
        slivers = List.from(child.buildSlivers(context), growable: true);
      }
    } else if (child is! Scrollable) {
      slivers = [
        SliverRefreshBody(
          child: child ?? Container(),
        )
      ];
    }
    if (widget.enablePullDown) {
      slivers?.insert(
          0,
          widget.header ??
              (configuration?.headerBuilder != null ? configuration?.headerBuilder!() : null) ??
              defaultHeader);
    }
    //insert header or footer
    if (widget.enablePullUp) {
      slivers?.add(widget.footer ??
          (configuration?.footerBuilder != null ? configuration?.footerBuilder!() : null) ??
          defaultFooter);
    }

    return slivers;
  }

  /// 获取滚动物理效果
  ///
  /// 根据配置和当前状态创建并返回自定义的 RefreshPhysics
  ///
  /// **参数**：
  /// - [conf]：刷新配置，可能为空
  /// - [physics]：原始的滚动物理效果
  ///
  /// **返回值**：
  /// - 带有刷新功能的自定义滚动物理效果
  ScrollPhysics _getScrollPhysics(RefreshConfiguration? conf, ScrollPhysics physics) {
    // 判断是否使用弹性物理效果
    final bool isBouncingPhysics = physics is BouncingScrollPhysics ||
        (physics is AlwaysScrollableScrollPhysics &&
            ScrollConfiguration.of(context).getScrollPhysics(context).runtimeType == BouncingScrollPhysics);

    return _physics = RefreshPhysics(
            dragSpeedRatio: conf?.dragSpeedRatio ?? 1,
            springDescription: conf?.springDescription ??
                const SpringDescription(
                  mass: 1.0,
                  stiffness: 364.72,
                  damping: 35.2,
                ),
            controller: widget.controller,
            updateFlag: _updatePhysics ? 0 : 1,
            enableScrollWhenRefreshCompleted: conf?.enableScrollWhenRefreshCompleted ?? false,
            maxUnderScrollExtent: conf?.maxUnderScrollExtent ?? (isBouncingPhysics ? double.infinity : 0.0),
            maxOverScrollExtent: conf?.maxOverScrollExtent ?? (isBouncingPhysics ? double.infinity : 60.0),
            topHitBoundary:
                conf?.topHitBoundary ?? (isBouncingPhysics ? double.infinity : 0.0), // 需要根据 iOS 或 Android 修复默认值
            bottomHitBoundary: conf?.bottomHitBoundary ?? (isBouncingPhysics ? double.infinity : 0.0))
        .applyTo(!_canDrag ? const NeverScrollableScrollPhysics() : physics);
  }

  /// 根据 slivers 构建自定义滚动视图
  ///
  /// 处理逻辑：
  /// 1. 如果 childView 不是 Scrollable，创建 CustomScrollView
  /// 2. 如果 childView 是 Scrollable，包装并修改其 viewport
  /// 3. 根据配置添加 header 和 footer
  ///
  /// **参数**：
  /// - [childView]：原始子视图
  /// - [slivers]：slivers 列表
  /// - [conf]：刷新配置
  ///
  /// **返回值**：
  /// - 带有刷新功能的滚动视图
  Widget? _buildBodyBySlivers(Widget? childView, List<Widget>? slivers, RefreshConfiguration? conf) {
    Widget? body;
    if (childView is! Scrollable) {
      bool? primary = widget.primary;
      Key? key;
      double? cacheExtent = widget.cacheExtent;

      Axis? scrollDirection = widget.scrollDirection;
      int? semanticChildCount = widget.semanticChildCount;
      bool? reverse = widget.reverse;
      ScrollController? scrollController = widget.scrollController;
      DragStartBehavior? dragStartBehavior = widget.dragStartBehavior;
      ScrollPhysics? physics = widget.physics;
      Key? center;
      double? anchor;
      ScrollViewKeyboardDismissBehavior? keyboardDismissBehavior;
      String? restorationId;
      Clip? clipBehavior;

      if (childView is ScrollView) {
        primary = primary ?? childView.primary;
        cacheExtent = cacheExtent ?? childView.cacheExtent;
        key = key ?? childView.key;
        semanticChildCount = semanticChildCount ?? childView.semanticChildCount;
        reverse = reverse ?? childView.reverse;
        dragStartBehavior = dragStartBehavior ?? childView.dragStartBehavior;
        scrollDirection = scrollDirection ?? childView.scrollDirection;
        physics = physics ?? childView.physics;
        center = center ?? childView.center;
        anchor = anchor ?? childView.anchor;
        keyboardDismissBehavior = keyboardDismissBehavior ?? childView.keyboardDismissBehavior;
        restorationId = restorationId ?? childView.restorationId;
        clipBehavior = clipBehavior ?? childView.clipBehavior;
        scrollController = scrollController ?? childView.controller;
      }
      body = CustomScrollView(
        // ignore: DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE
        controller: scrollController,
        cacheExtent: cacheExtent,
        key: key,
        scrollDirection: scrollDirection ?? Axis.vertical,
        semanticChildCount: semanticChildCount,
        primary: primary,
        clipBehavior: clipBehavior ?? Clip.hardEdge,
        keyboardDismissBehavior: keyboardDismissBehavior ?? ScrollViewKeyboardDismissBehavior.manual,
        anchor: anchor ?? 0.0,
        restorationId: restorationId,
        center: center,
        physics: _getScrollPhysics(conf, physics ?? const AlwaysScrollableScrollPhysics()),
        slivers: slivers!,
        dragStartBehavior: dragStartBehavior ?? DragStartBehavior.start,
        reverse: reverse ?? false,
      );
    } else {
      body = Scrollable(
        physics: _getScrollPhysics(conf, childView.physics ?? const AlwaysScrollableScrollPhysics()),
        controller: childView.controller,
        axisDirection: childView.axisDirection,
        semanticChildCount: childView.semanticChildCount,
        dragStartBehavior: childView.dragStartBehavior,
        viewportBuilder: (context, offset) {
          Viewport viewport = childView.viewportBuilder(context, offset) as Viewport;
          if (widget.enablePullDown) {
            viewport.children.insert(
                0, widget.header ?? (conf?.headerBuilder != null ? conf?.headerBuilder!() : null) ?? defaultHeader);
          }
          //insert header or footer
          if (widget.enablePullUp) {
            viewport.children
                .add(widget.footer ?? (conf?.footerBuilder != null ? conf?.footerBuilder!() : null) ?? defaultFooter);
          }
          return viewport;
        },
      );
    }
    return body;
  }

  /// 判断是否需要更新滚动物理效果
  ///
  /// 比较当前配置和已有物理效果的参数，决定是否需要更新
  ///
  /// **返回值**：
  /// - true：需要更新物理效果
  /// - false：不需要更新物理效果
  bool _ifNeedUpdatePhysics() {
    RefreshConfiguration? conf = RefreshConfiguration.of(context);
    if (conf == null || _physics == null) {
      return false;
    }

    return conf.topHitBoundary != _physics!.topHitBoundary ||
        _physics!.bottomHitBoundary != conf.bottomHitBoundary ||
        conf.maxOverScrollExtent != _physics!.maxOverScrollExtent ||
        _physics!.maxUnderScrollExtent != conf.maxUnderScrollExtent ||
        _physics!.dragSpeedRatio != conf.dragSpeedRatio ||
        _physics!.enableScrollWhenRefreshCompleted != conf.enableScrollWhenRefreshCompleted;
  }

  /// 设置是否可以拖动
  ///
  /// **参数**：
  /// - [canDrag]：是否允许拖动
  void setCanDrag(bool canDrag) {
    if (_canDrag == canDrag) {
      return;
    }
    setState(() {
      _canDrag = canDrag;
    });
  }

  @override
  void didUpdateWidget(SmartRefresher oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果控制器发生变化，复制状态
    if (widget.controller != oldWidget.controller) {
      widget.controller.headerMode!.value = oldWidget.controller.headerMode!.value;
      widget.controller.footerMode!.value = oldWidget.controller.footerMode!.value;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 如果需要更新物理效果，切换更新标志
    if (_ifNeedUpdatePhysics()) {
      _updatePhysics = !_updatePhysics;
    }
  }

  @override
  void initState() {
    super.initState();
    // 如果设置了初始刷新，在渲染完成后触发刷新
    if (widget.controller.initialRefresh) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // 检查 mounted 状态，避免在 build 前就 dispose 导致的错误
        // 这种情况主要发生在 TabBarView 中
        if (mounted) widget.controller.requestRefresh();
      });
    }
    // 绑定状态到控制器
    widget.controller._bindState(this);
  }

  @override
  void dispose() {
    // 解绑控制器
    widget.controller._detachPosition();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final RefreshConfiguration? configuration = RefreshConfiguration.of(context);
    Widget? body;

    // 使用 builder 或子组件构建刷新视图
    if (widget.builder != null) {
      body = widget.builder!(
          context, _getScrollPhysics(configuration, const AlwaysScrollableScrollPhysics()) as RefreshPhysics);
    } else {
      List<Widget>? slivers = _buildSliversByChild(context, widget.child, configuration);
      body = _buildBodyBySlivers(widget.child, slivers, configuration);
    }

    // 如果没有全局配置，创建默认配置
    if (configuration == null) {
      body = RefreshConfiguration(child: body!);
    }

    // 使用 LayoutBuilder 获取视口高度
    return LayoutBuilder(
      builder: (c2, cons) {
        viewportExtent = cons.biggest.height;
        return body!;
      },
    );
  }
}

/// 控制 SmartRefresher 的刷新和加载状态
///
/// 用于手动触发刷新、加载更多，以及控制刷新/加载状态的结束
///
/// **核心功能**：
/// - 手动触发下拉刷新：[requestRefresh]
/// - 手动触发上拉加载：[requestLoading]
/// - 结束刷新状态：[refreshCompleted], [refreshFailed], [refreshToIdle]
/// - 结束加载状态：[loadComplete], [loadFailed], [loadNoData]
///
/// **使用示例**：
/// ```dart
/// // 创建控制器
/// final _refreshController = RefreshController(initialRefresh: false);
///
/// // 手动触发刷新
/// _refreshController.requestRefresh();
///
/// // 结束刷新（成功）
/// _refreshController.refreshCompleted();
///
/// // 结束刷新（失败）
/// _refreshController.refreshFailed();
///
/// // 结束加载更多（成功）
/// _refreshController.loadComplete();
///
/// // 结束加载更多（无数据）
/// _refreshController.loadNoData();
///
/// // 重置无数据状态
/// _refreshController.resetNoData();
/// ```
///
/// 相关组件：
/// * [SmartRefresher]：使用此控制器的刷新组件
class RefreshController {
  SmartRefresherState? _refresherState;

  /// 头部状态通知器
  RefreshNotifier<RefreshStatus>? headerMode;

  /// 底部状态通知器
  RefreshNotifier<LoadStatus>? footerMode;

  /// 可滚动组件的位置信息
  ///
  /// 注意：在构建完成前，position 为 null
  /// 只有当 header 或 footer 回调 onPositionUpdated 时才会获取到值
  ScrollPosition? position;

  /// 获取当前头部状态
  RefreshStatus? get headerStatus => headerMode?.value;

  /// 获取当前底部状态
  LoadStatus? get footerStatus => footerMode?.value;

  /// 是否正在刷新
  bool get isRefresh => headerMode?.value == RefreshStatus.refreshing;

  /// 是否正在加载更多
  bool get isLoading => footerMode?.value == LoadStatus.loading;

  /// 是否在初始化时自动触发刷新
  final bool initialRefresh;

  /// 创建刷新控制器
  ///
  /// **参数**：
  /// - [initialRefresh]：初始化时是否自动触发刷新，默认为 false
  /// - [initialRefreshStatus]：头部初始状态，默认为 RefreshStatus.idle
  /// - [initialLoadStatus]：底部初始状态，默认为 LoadStatus.idle
  RefreshController({this.initialRefresh = false, RefreshStatus? initialRefreshStatus, LoadStatus? initialLoadStatus}) {
    this.headerMode = RefreshNotifier(initialRefreshStatus ?? RefreshStatus.idle);
    this.footerMode = RefreshNotifier(initialLoadStatus ?? LoadStatus.idle);
  }

  /// 绑定 SmartRefresher 状态
  ///
  /// **内部方法，请勿直接调用**
  void _bindState(SmartRefresherState state) {
    assert(_refresherState == null, "不要将一个 RefreshController 用于多个 SmartRefresher，这会导致意外错误，尤其是在 TabBarView 中");
    _refresherState = state;
  }

  /// 当指示器构建完成时回调，捕获可滚动组件的内部位置
  ///
  /// **内部方法，请勿直接调用**
  void onPositionUpdated(ScrollPosition newPosition) {
    position?.isScrollingNotifier.removeListener(_listenScrollEnd);
    position = newPosition;
    position!.isScrollingNotifier.addListener(_listenScrollEnd);
  }

  /// 解绑位置信息
  ///
  /// **内部方法，请勿直接调用**
  void _detachPosition() {
    _refresherState = null;
    position?.isScrollingNotifier.removeListener(_listenScrollEnd);
  }

  /// 查找指示器元素
  ///
  /// **内部方法，请勿直接调用**
  StatefulElement? _findIndicator(BuildContext context, Type elementType) {
    StatefulElement? result;
    context.visitChildElements((Element e) {
      if (elementType == RefreshIndicator) {
        if (e.widget is RefreshIndicator) {
          result = e as StatefulElement?;
        }
      } else {
        if (e.widget is LoadIndicator) {
          result = e as StatefulElement?;
        }
      }

      result ??= _findIndicator(e, elementType);
    });
    return result;
  }

  /// 监听滚动结束事件
  ///
  /// 当滚动超出边缘并停止时，触发回弹效果
  ///
  /// **内部方法，请勿直接调用**
  void _listenScrollEnd() {
    if (position != null && position!.outOfRange) {
      position?.activity?.applyNewDimensions();
    }
  }

  /// 手动触发下拉刷新
  ///
  /// **参数**：
  /// - [needMove]：是否需要动画滚动到刷新位置，默认为 true
  /// - [needCallback]：是否需要调用 onRefresh 回调，默认为 true
  /// - [duration]：动画持续时间，默认为 500 毫秒
  /// - [curve]：动画曲线，默认为 Curves.linear
  ///
  /// **返回值**：
  /// - Future<void>：刷新动画完成后的回调
  ///
  /// **使用示例**：
  /// ```dart
  /// // 手动触发刷新
  /// _refreshController.requestRefresh();
  ///
  /// // 带自定义动画的刷新
  /// _refreshController.requestRefresh(
  ///   duration: Duration(milliseconds: 800),
  ///   curve: Curves.easeInOut,
  /// );
  /// ```
  Future<void>? requestRefresh(
      {bool needMove = true,
      bool needCallback = true,
      Duration duration = const Duration(milliseconds: 500),
      Curve curve = Curves.linear}) {
    assert(position != null, '请不要在构建完成前调用 requestRefresh()，请在 UI 渲染后调用');
    if (isRefresh) return Future.value();

    StatefulElement? indicatorElement = _findIndicator(position!.context.storageContext, RefreshIndicator);
    if (indicatorElement == null || _refresherState == null) return null;

    (indicatorElement.state as RefreshIndicatorState).floating = true;

    if (needMove && _refresherState!.mounted) {
      _refresherState!.setCanDrag(false);
    }

    if (needMove) {
      return Future.delayed(const Duration(milliseconds: 50)).then((_) async {
        // - 0.0001 是为了兼容 NestedScrollView
        await position?.animateTo(position!.minScrollExtent - 0.0001, duration: duration, curve: curve).then((_) {
          if (_refresherState != null && _refresherState!.mounted) {
            _refresherState!.setCanDrag(true);
            if (needCallback) {
              headerMode!.value = RefreshStatus.refreshing;
            } else {
              headerMode!.setValueWithNoNotify(RefreshStatus.refreshing);
              if (indicatorElement.state.mounted) {
                (indicatorElement.state as RefreshIndicatorState).setState(() {});
              }
            }
          }
        });
      });
    } else {
      Future.value().then((_) {
        headerMode!.value = RefreshStatus.refreshing;
      });
    }
    return null;
  }

  /// 手动触发上拉加载更多
  ///
  /// **参数**：
  /// - [needMove]：是否需要动画滚动到加载位置，默认为 true
  /// - [needCallback]：是否需要调用 onLoading 回调，默认为 true
  /// - [duration]：动画持续时间，默认为 300 毫秒
  /// - [curve]：动画曲线，默认为 Curves.linear
  ///
  /// **返回值**：
  /// - Future<void>：加载动画完成后的回调
  ///
  /// **使用示例**：
  /// ```dart
  /// _refreshController.requestLoading();
  /// ```
  Future<void>? requestLoading(
      {bool needMove = true,
      bool needCallback = true,
      Duration duration = const Duration(milliseconds: 300),
      Curve curve = Curves.linear}) {
    assert(position != null, '请不要在构建完成前调用 requestLoading()，请在 UI 渲染后调用');
    if (isLoading) return Future.value();

    StatefulElement? indicatorElement = _findIndicator(position!.context.storageContext, LoadIndicator);
    if (indicatorElement == null || _refresherState == null) return null;

    (indicatorElement.state as LoadIndicatorState).floating = true;

    if (needMove && _refresherState!.mounted) {
      _refresherState!.setCanDrag(false);
    }

    if (needMove) {
      return Future.delayed(const Duration(milliseconds: 50)).then((_) async {
        await position?.animateTo(position!.maxScrollExtent, duration: duration, curve: curve).then((_) {
          if (_refresherState != null && _refresherState!.mounted) {
            _refresherState!.setCanDrag(true);
            if (needCallback) {
              footerMode!.value = LoadStatus.loading;
            } else {
              footerMode!.setValueWithNoNotify(LoadStatus.loading);
              if (indicatorElement.state.mounted) {
                (indicatorElement.state as LoadIndicatorState).setState(() {});
              }
            }
          }
        });
      });
    } else {
      return Future.value().then((_) {
        footerMode!.value = LoadStatus.loading;
      });
    }
  }

  /// 结束刷新（成功）
  ///
  /// 调用后，头部将进入完成状态
  ///
  /// **参数**：
  /// - [resetFooterState]：是否将 footer 状态从 noData 重置为 idle，默认为 false
  ///
  /// **使用示例**：
  /// ```dart
  /// // 刷新成功，结束刷新状态
  /// _refreshController.refreshCompleted();
  ///
  /// // 刷新成功，同时重置 footer 状态
  /// _refreshController.refreshCompleted(resetFooterState: true);
  /// ```
  void refreshCompleted({bool resetFooterState = false}) {
    headerMode?.value = RefreshStatus.completed;

    if (resetFooterState) {
      resetNoData();
    }

    if (position != null) {
      final scrollContext = (position!.context as ScrollableState);
      if (scrollContext.mounted) {
        StatefulElement? indicatorElement = _findIndicator(position!.context.storageContext, LoadIndicator);
        if (indicatorElement != null) {
          final indicatorState = (indicatorElement.state as LoadIndicatorState);
          indicatorState.lastLoadedHeight = 0;
          indicatorState.lastMaxScrollExtend = 0;
        }
      }
    }
  }

  /// 结束刷新（失败）
  ///
  /// 调用后，头部将显示失败状态
  ///
  /// **使用示例**：
  /// ```dart
  /// // 刷新失败，显示失败状态
  /// _refreshController.refreshFailed();
  /// ```
  void refreshFailed() {
    headerMode?.value = RefreshStatus.failed;
  }

  /// 直接结束刷新，不显示成功或失败状态
  ///
  /// 调用后，头部将直接回到 idle 状态并回弹
  ///
  /// **使用示例**：
  /// ```dart
  /// // 直接结束刷新，回到初始状态
  /// _refreshController.refreshToIdle();
  /// ```
  void refreshToIdle() {
    headerMode?.value = RefreshStatus.idle;
  }

  /// 结束加载更多（成功）
  ///
  /// 调用后，底部将进入空闲状态
  ///
  /// **使用示例**：
  /// ```dart
  /// // 加载更多成功，结束加载状态
  /// _refreshController.loadComplete();
  /// ```
  void loadComplete() {
    // 在 UI 更新后更改状态，否则会出现两次加载的 bug
    WidgetsBinding.instance.addPostFrameCallback((_) {
      footerMode?.value = LoadStatus.idle;
    });
  }

  /// 结束加载更多（失败）
  ///
  /// 调用后，底部将显示失败状态
  ///
  /// **使用示例**：
  /// ```dart
  /// // 加载更多失败，显示失败状态
  /// _refreshController.loadFailed();
  /// ```
  void loadFailed() {
    // 在 UI 更新后更改状态，否则会出现两次加载的 bug
    WidgetsBinding.instance.addPostFrameCallback((_) {
      footerMode?.value = LoadStatus.failed;
    });
  }

  /// 结束加载更多（无数据）
  ///
  /// 调用后，底部将进入无数据状态
  ///
  /// **使用示例**：
  /// ```dart
  /// // 加载更多成功，但没有数据返回
  /// _refreshController.loadNoData();
  /// ```
  void loadNoData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      footerMode?.value = LoadStatus.noMore;
    });
  }

  /// 重置底部无数据状态为空闲
  ///
  /// **使用示例**：
  /// ```dart
  /// // 重置无数据状态，允许再次加载
  /// _refreshController.resetNoData();
  /// ```
  void resetNoData() {
    if (footerMode?.value == LoadStatus.noMore) {
      footerMode!.value = LoadStatus.idle;
    }
  }

  /// 释放资源
  ///
  /// 对于某些特殊情况，为了安全起见，你应该调用 dispose()，否则在父组件 dispose 后可能会抛出错误
  ///
  /// **使用示例**：
  /// ```dart
  /// @override
  /// void dispose() {
  ///   _refreshController.dispose();
  ///   super.dispose();
  /// }
  /// ```
  void dispose() {
    headerMode!.dispose();
    footerMode!.dispose();
    headerMode = null;
    footerMode = null;
  }
}

/// 控制子树中 SmartRefresher 组件的行为，用法类似于 [ScrollConfiguration]
///
/// **核心功能**：
/// - 全局设置默认的 header 和 footer 指示器
/// - 配置刷新和加载的行为参数
/// - 调整弹簧动画效果
/// - 控制二级刷新的行为
///
/// **使用示例**：
/// ```dart
/// // 在应用根目录设置全局配置
/// MaterialApp(
///   home: RefreshConfiguration(
///     headerBuilder: () => ClassicHeader(),
///     footerBuilder: () => ClassicFooter(),
///     headerTriggerDistance: 80.0,
///     footerTriggerDistance: 15.0,
///     springDescription: SpringDescription(
///       stiffness: 170,
///       damping: 16,
///       mass: 1.9,
///     ),
///     enableScrollWhenRefreshCompleted: true,
///     enableLoadingWhenFailed: true,
///     enableBallisticLoad: true,
///     child: YourHomePage(),
///   ),
/// );
///
/// // 局部覆盖全局配置
/// RefreshConfiguration.copyAncestor(
///   context: context,
///   headerTriggerDistance: 100.0,
///   child: SmartRefresher(
///     // 这里的 SmartRefresher 将使用局部配置
///   ),
/// );
/// ```
///
/// 相关组件：
/// * [SmartRefresher]：受此配置影响的刷新组件
class RefreshConfiguration extends InheritedWidget {
  /// 子组件树
  @override
  // ignore: overridden_fields
  final Widget child;

  /// 全局默认 header 构建器
  final IndicatorBuilder? headerBuilder;

  /// 全局默认 footer 构建器
  final IndicatorBuilder? footerBuilder;

  /// 自定义弹簧动画配置
  final SpringDescription springDescription;

  /// 当达到触发距离时，是否立即进入刷新状态
  final bool skipCanRefresh;

  /// 当列表数据不足一页时，footer 是否跟随内容
  final ShouldFollowContent? shouldFooterFollowWhenNotFull;

  /// 当列表数据不足一页时，是否隐藏 footer
  final bool hideFooterWhenNotFull;

  /// 刷新完成回弹时，是否允许拖动视口
  final bool enableScrollWhenRefreshCompleted;

  /// 是否通过 BallisticScrollActivity 触发刷新
  final bool enableBallisticRefresh;

  /// 是否通过 BallisticScrollActivity 触发加载
  final bool enableBallisticLoad;

  /// 当 footer 处于 failed 状态时，是否允许触发加载
  final bool enableLoadingWhenFailed;

  /// 当 footer 处于 noMore 状态时，是否允许触发加载
  final bool enableLoadingWhenNoData;

  /// 是否启用智能预加载（基于上一次加载高度的一半进行预加载）
  final bool enableSmartPreload;

  /// 触发刷新的过度滚动距离
  final double headerTriggerDistance;

  /// 触发二级刷新的过度滚动距离
  final double twiceTriggerDistance;

  /// 触发加载的 extentAfter 距离
  final double footerTriggerDistance;

  /// 拖动过度滚动时的速度比例，计算公式：原始物理速度 * dragSpeedRatio
  final double dragSpeedRatio;

  /// 超出边缘时的最大过度滚动距离
  final double? maxOverScrollExtent;

  /// 超出边缘时的最大不足滚动距离
  final double? maxUnderScrollExtent;

  /// 位于顶部边缘的边界，惯性滚动超过此距离时停止
  final double? topHitBoundary;

  /// 位于底部边缘的边界，惯性滚动超过此距离时停止
  final double? bottomHitBoundary;

  /// 是否启用刷新震动反馈
  final bool enableRefreshVibrate;

  /// 是否启用加载更多震动反馈
  final bool enableLoadMoreVibrate;

  /// 创建刷新配置
  ///
  /// **必填参数**：
  /// - [child]：子组件树
  ///
  /// **常用参数**：
  /// - [headerBuilder]：全局默认 header 构建器
  /// - [footerBuilder]：全局默认 footer 构建器
  /// - [headerTriggerDistance]：触发刷新的距离，默认为 80.0
  /// - [enableSmartPreload]：是否启用智能预加载，默认为 true
  /// - [footerTriggerDistance]：触发加载的距离，默认为 15.0
  /// - [springDescription]：弹簧动画配置
  /// - [enableScrollWhenRefreshCompleted]：刷新完成回弹时是否允许滚动
  const RefreshConfiguration(
      {super.key,
      required this.child,
      this.headerBuilder,
      this.footerBuilder,
      this.dragSpeedRatio = 1.0,
      this.shouldFooterFollowWhenNotFull,
      this.enableLoadingWhenNoData = false,
      this.enableSmartPreload = true,
      this.enableBallisticRefresh = false,
      this.springDescription = const SpringDescription(
        mass: 1.0,
        stiffness: 364.72,
        damping: 35.2,
      ),
      this.enableScrollWhenRefreshCompleted = false,
      this.enableLoadingWhenFailed = true,
      this.twiceTriggerDistance = 150.0,
      this.skipCanRefresh = false,
      this.maxOverScrollExtent,
      this.enableBallisticLoad = true,
      this.maxUnderScrollExtent,
      this.headerTriggerDistance = 80.0,
      this.footerTriggerDistance = 15.0,
      this.hideFooterWhenNotFull = false,
      this.enableRefreshVibrate = false,
      this.enableLoadMoreVibrate = false,
      this.topHitBoundary,
      this.bottomHitBoundary})
      : assert(headerTriggerDistance > 0),
        assert(twiceTriggerDistance > 0),
        assert(dragSpeedRatio > 0),
        super(child: child);

  /// 复制祖先节点的 RefreshConfiguration，并可选择性覆盖部分属性
  ///
  /// 如果参数为 null，将自动继承祖先 RefreshConfiguration 的属性，无需手动复制
  ///
  /// **适用场景**：
  /// - 应用中某个 SmartRefresher 需要与其他组件不同的配置
  /// - 局部覆盖全局配置
  ///
  /// **必填参数**：
  /// - [context]：构建上下文，用于查找祖先配置
  /// - [child]：子组件树
  RefreshConfiguration.copyAncestor({
    super.key,
    required BuildContext context,
    required this.child,
    IndicatorBuilder? headerBuilder,
    IndicatorBuilder? footerBuilder,
    double? dragSpeedRatio,
    ShouldFollowContent? shouldFooterFollowWhenNotFull,
    bool? enableBallisticRefresh,
    bool? enableBallisticLoad,
    bool? enableLoadingWhenNoData,
    bool? enableSmartPreload,
    SpringDescription? springDescription,
    bool? enableScrollWhenRefreshCompleted,
    bool? enableLoadingWhenFailed,
    double? twiceTriggerDistance,
    bool? skipCanRefresh,
    double? maxOverScrollExtent,
    double? maxUnderScrollExtent,
    double? topHitBoundary,
    double? bottomHitBoundary,
    double? headerTriggerDistance,
    double? footerTriggerDistance,
    bool? enableRefreshVibrate,
    bool? enableLoadMoreVibrate,
    bool? hideFooterWhenNotFull,
  })  : assert(RefreshConfiguration.of(context) != null,
            "search RefreshConfiguration anscestor return null,please  Make sure that RefreshConfiguration is the ancestor of that element"),
        headerBuilder = headerBuilder ?? RefreshConfiguration.of(context)!.headerBuilder,
        footerBuilder = footerBuilder ?? RefreshConfiguration.of(context)!.footerBuilder,
        dragSpeedRatio = dragSpeedRatio ?? RefreshConfiguration.of(context)!.dragSpeedRatio,
        twiceTriggerDistance = twiceTriggerDistance ?? RefreshConfiguration.of(context)!.twiceTriggerDistance,
        headerTriggerDistance = headerTriggerDistance ?? RefreshConfiguration.of(context)!.headerTriggerDistance,
        footerTriggerDistance = footerTriggerDistance ?? RefreshConfiguration.of(context)!.footerTriggerDistance,
        springDescription = springDescription ?? RefreshConfiguration.of(context)!.springDescription,
        hideFooterWhenNotFull = hideFooterWhenNotFull ?? RefreshConfiguration.of(context)!.hideFooterWhenNotFull,
        maxOverScrollExtent = maxOverScrollExtent ?? RefreshConfiguration.of(context)!.maxOverScrollExtent,
        maxUnderScrollExtent = maxUnderScrollExtent ?? RefreshConfiguration.of(context)!.maxUnderScrollExtent,
        topHitBoundary = topHitBoundary ?? RefreshConfiguration.of(context)!.topHitBoundary,
        bottomHitBoundary = bottomHitBoundary ?? RefreshConfiguration.of(context)!.bottomHitBoundary,
        skipCanRefresh = skipCanRefresh ?? RefreshConfiguration.of(context)!.skipCanRefresh,
        enableScrollWhenRefreshCompleted =
            enableScrollWhenRefreshCompleted ?? RefreshConfiguration.of(context)!.enableScrollWhenRefreshCompleted,
        enableBallisticRefresh = enableBallisticRefresh ?? RefreshConfiguration.of(context)!.enableBallisticRefresh,
        enableBallisticLoad = enableBallisticLoad ?? RefreshConfiguration.of(context)!.enableBallisticLoad,
        enableLoadingWhenNoData = enableLoadingWhenNoData ?? RefreshConfiguration.of(context)!.enableLoadingWhenNoData,
        enableSmartPreload = enableSmartPreload ?? RefreshConfiguration.of(context)!.enableSmartPreload,
        enableLoadingWhenFailed = enableLoadingWhenFailed ?? RefreshConfiguration.of(context)!.enableLoadingWhenFailed,
        enableRefreshVibrate = enableRefreshVibrate ?? RefreshConfiguration.of(context)!.enableRefreshVibrate,
        enableLoadMoreVibrate = enableLoadMoreVibrate ?? RefreshConfiguration.of(context)!.enableLoadMoreVibrate,
        shouldFooterFollowWhenNotFull =
            shouldFooterFollowWhenNotFull ?? RefreshConfiguration.of(context)!.shouldFooterFollowWhenNotFull,
        super(child: child);

  static RefreshConfiguration? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<RefreshConfiguration>();
  }

  @override
  bool updateShouldNotify(RefreshConfiguration oldWidget) {
    return skipCanRefresh != oldWidget.skipCanRefresh ||
        hideFooterWhenNotFull != oldWidget.hideFooterWhenNotFull ||
        dragSpeedRatio != oldWidget.dragSpeedRatio ||
        enableScrollWhenRefreshCompleted != oldWidget.enableScrollWhenRefreshCompleted ||
        enableBallisticRefresh != oldWidget.enableBallisticRefresh ||
        footerTriggerDistance != oldWidget.footerTriggerDistance ||
        headerTriggerDistance != oldWidget.headerTriggerDistance ||
        twiceTriggerDistance != oldWidget.twiceTriggerDistance ||
        maxUnderScrollExtent != oldWidget.maxUnderScrollExtent ||
        oldWidget.maxOverScrollExtent != maxOverScrollExtent ||
        enableBallisticRefresh != oldWidget.enableBallisticRefresh ||
        enableLoadingWhenFailed != oldWidget.enableLoadingWhenFailed ||
        topHitBoundary != oldWidget.topHitBoundary ||
        enableRefreshVibrate != oldWidget.enableRefreshVibrate ||
        enableLoadMoreVibrate != oldWidget.enableLoadMoreVibrate ||
        bottomHitBoundary != oldWidget.bottomHitBoundary;
  }
}

class RefreshNotifier<T> extends ChangeNotifier implements ValueListenable<T> {
  /// Creates a [ChangeNotifier] that wraps this value.
  RefreshNotifier(this._value);
  T _value;

  @override
  T get value => _value;

  set value(T newValue) {
    if (_value == newValue) return;
    _value = newValue;
    notifyListeners();
  }

  void setValueWithNoNotify(T newValue) {
    if (_value == newValue) return;
    _value = newValue;
  }

  @override
  String toString() => '${describeIdentity(this)}($value)';
}
