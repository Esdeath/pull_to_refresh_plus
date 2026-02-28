// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../smart_refresher.dart';
import 'slivers.dart';

/// 定义通用回调类型
typedef AsyncVoidCallback = Future<void> Function();
typedef OffsetCallback = void Function(double offset);
typedef ModeChangeCallback<T> = void Function(T? mode);

/// 下拉刷新指示器抽象类，实现了iOS和Android风格的下拉刷新效果
abstract class RefreshIndicator extends StatefulWidget {
  /// 刷新显示样式
  final RefreshStyle refreshStyle;

  /// 指示器的视觉高度
  final double height;

  /// 布局偏移量
  final double offset;

  /// 刷新完成或失败时的停留时间
  final Duration completeDuration;

  const RefreshIndicator({
    super.key,
    this.height = 60.0,
    this.offset = 0.0,
    this.completeDuration = const Duration(milliseconds: 500),
    this.refreshStyle = RefreshStyle.follow,
  });
}

/// 上拉加载指示器抽象类，实现了上拉加载更多功能
abstract class LoadIndicator extends StatefulWidget {
  /// 加载更多显示样式
  final LoadStyle loadStyle;

  /// 指示器的视觉高度
  final double height;

  /// 用户点击底部时的回调
  final VoidCallback? onClick;

  const LoadIndicator({
    super.key,
    this.onClick,
    this.loadStyle = LoadStyle.showAlways,
    this.height = 60.0,
  });
}

/// 下拉刷新指示器状态管理类
abstract class RefreshIndicatorState<T extends RefreshIndicator> extends State<T>
    with IndicatorStateMixin<T, RefreshStatus>, RefreshProcessor {
  /// 检查指示器是否在可视范围内
  bool _isInVisual() {
    return _position!.pixels < 0.0;
  }

  /// 计算滚动偏移量
  @override
  double _calculateScrollOffset() {
    final double baseOffset = floating ? _getFloatingOffset() : 0.0;
    return baseOffset - (_position?.pixels ?? 0.0);
  }

  /// 获取浮动状态下的偏移量
  double _getFloatingOffset() {
    return widget.height;
  }

  @override
  void _handleOffsetChange() {
    super._handleOffsetChange();
    final double overscrollPast = _calculateScrollOffset();
    onOffsetChange(overscrollPast);
  }

  /// 根据偏移量分发刷新状态
  @override
  void _dispatchModeByOffset(double offset) {
    // 浮动状态下不处理
    if (floating) return;

    // 偏移量为0时，重置为空闲状态
    if (offset == 0.0) {
      mode = RefreshStatus.idle;
    }

    // FrontStyle下的特殊处理
    if (_position!.extentBefore == 0.0 && widget.refreshStyle == RefreshStyle.front) {
      _position!.context.setIgnorePointer(false);
    }

    // 根据滚动活动类型处理不同的刷新状态
    if (_isActiveScrollActivity()) {
      _handleActiveScroll(offset);
    } else if (activity is BallisticScrollActivity) {
      _handleBallisticScroll();
    }
  }

  /// 判断是否为主动滚动活动
  bool _isActiveScrollActivity() {
    return (configuration!.enableBallisticRefresh && activity!.velocity < 0.0) ||
        activity is DragScrollActivity ||
        activity is DrivenScrollActivity;
  }

  /// 处理主动滚动状态
  void _handleActiveScroll(double offset) {
    // 处理下拉刷新
    if (refresher!.enablePullDown) {
      if (offset >= configuration!.headerTriggerDistance) {
        if (!configuration!.skipCanRefresh) {
          mode = RefreshStatus.canRefresh;
        } else {
          _enterRefreshingState();
        }
      } else {
        mode = RefreshStatus.idle;
      }
    }
  }

  /// 处理弹性滚动状态
  void _handleBallisticScroll() {
    if (mode == RefreshStatus.canRefresh) {
      _enterRefreshingState();
    }
  }

  /// 进入刷新状态
  void _enterRefreshingState() {
    floating = true;
    update();
    readyToRefresh().then((_) {
      if (mounted) {
        mode = RefreshStatus.refreshing;
      }
    });
  }

  /// 处理状态变化
  @override
  void _handleModeChange() {
    if (!mounted) return;

    update();

    final currentMode = mode;
    if (currentMode == null) {
      return;
    }

    switch (currentMode) {
      case RefreshStatus.idle:
      case RefreshStatus.canRefresh:
        _handleIdleOrCanRefresh();
        break;
      case RefreshStatus.completed:
      case RefreshStatus.failed:
        _handleCompleteOrFailed();
        break;
      case RefreshStatus.refreshing:
        _handleRefreshing();
        break;
    }

    onModeChange(mode);
  }

  /// 处理空闲或可刷新状态
  void _handleIdleOrCanRefresh() {
    floating = false;
    resetValue();
    if (mode == RefreshStatus.idle) {
      refresherState!.setCanDrag(true);
    }
  }

  /// 处理完成或失败状态
  void _handleCompleteOrFailed() {
    endRefresh().then((_) {
      if (!mounted) return;

      floating = false;
      if (mode == RefreshStatus.completed || mode == RefreshStatus.failed) {
        refresherState!.setCanDrag(configuration!.enableScrollWhenRefreshCompleted);
      }

      update();

      // 处理两种特殊情况：
      // 1. 用户拖动到刷新状态后，向下滚动使指示器不可见，此时不会回弹
      // 2. FrontStyle下，用户在刷新状态下拖动0~100范围，状态变化后需要重置
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        if (widget.refreshStyle == RefreshStyle.front) {
          if (_isInVisual()) {
            _position!.jumpTo(0.0);
          }
          mode = RefreshStatus.idle;
        } else {
          if (!_isInVisual()) {
            mode = RefreshStatus.idle;
          } else {
            activity!.delegate.goBallistic(0.0);
          }
        }
      });
    });
  }

  /// 处理刷新中状态
  void _handleRefreshing() {
    if (!floating) {
      floating = true;
      readyToRefresh();
    }

    // 触发震动反馈
    if (configuration!.enableRefreshVibrate) {
      HapticFeedback.vibrate();
    }

    // 调用刷新回调
    refresher!.onRefresh?.call();
  }

  /// 准备刷新，可以在此实现动画效果
  @override
  Future<void> readyToRefresh() {
    return Future.value();
  }

  /// 结束刷新，进入完成或失败状态
  @override
  Future<void> endRefresh() {
    return Future.delayed(widget.completeDuration);
  }

  /// 是否需要反转所有内容
  bool needReverseAll() {
    return true;
  }

  /// 重置值，子类可以重写以实现自定义逻辑
  @override
  void resetValue() {}

  @override
  Widget build(BuildContext context) {
    return SliverRefresh(
      paintOffsetY: widget.offset,
      floating: floating,
      refreshIndicatorLayoutExtent: _getFloatingOffset(),
      refreshStyle: widget.refreshStyle,
      child: RotatedBox(
        quarterTurns: needReverseAll() && Scrollable.of(context).axisDirection == AxisDirection.up ? 10 : 0,
        child: buildContent(context, mode),
      ),
    );
  }
}

/// 上拉加载指示器状态管理类
abstract class LoadIndicatorState<T extends LoadIndicator> extends State<T>
    with IndicatorStateMixin<T, LoadStatus>, LoadingProcessor {
  /// 用于判断是否隐藏指示器
  bool _isHide = false;

  /// 是否允许加载
  bool _enableLoading = false;

  /// 上一次的状态
  LoadStatus _lastMode = LoadStatus.idle;

  /// 上一次加载的数据增加的滚动高度
  double lastLoadedHeight = 0.0;

  /// 上一次加载完成后的最大滚动范围
  double lastMaxScrollExtend = 0.0;

  /// 计算滚动偏移量
  @override
  double _calculateScrollOffset() {
    final double overScrollPastEnd = math.max(_position!.pixels - _position!.maxScrollExtent, 0.0);
    return overScrollPastEnd;
  }

  /// 进入加载状态
  void enterLoading() {
    _enableLoading = false;

    setState(() {
      floating = true;
    });

    readyToLoad().then((_) {
      if (mounted) {
        mode = LoadStatus.loading;
      }
    });
  }

  /// 结束加载
  @override
  Future<void> endLoading() {
    return Future.delayed(const Duration(milliseconds: 0));
  }

  /// 完成加载
  void finishLoading() {
    if (!floating) {
      return;
    }

    endLoading().then((_) {
      if (!mounted) {
        return;
      }

      // 临时修复bug：当加载完成时指示器快速消失
      if (mounted) {
        Scrollable.of(context).position.correctBy(0.00001);
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // 更新上一次加载的高度和最大滚动范围
          lastLoadedHeight = _position!.maxScrollExtent - lastMaxScrollExtend;
          lastMaxScrollExtend = _position!.maxScrollExtent;

          // 如果超出范围，触发弹性滚动
          if (_position?.outOfRange == true) {
            activity!.delegate.goBallistic(0);
          }
        }
      });

      setState(() {
        floating = false;
      });
    });
  }

  /// 检查是否可以加载更多
  bool _checkIfCanLoading() {
    // 失败状态下不允许加载
    if (!configuration!.enableLoadingWhenFailed && mode == LoadStatus.failed) {
      return false;
    }

    // 没有更多数据时不允许加载
    if (!configuration!.enableLoadingWhenNoData && mode == LoadStatus.noMore) {
      return false;
    }

    // 非可加载状态且向前滚动时不允许加载
    if (mode != LoadStatus.canLoading && _position!.userScrollDirection == ScrollDirection.forward) {
      return false;
    }

    // 智能预加载：当距离底部小于上一次加载高度的一半时触发
    final bool enableSmartPreload = refresher?.enableSmartPreload ?? configuration!.enableSmartPreload;
    if (enableSmartPreload &&
        lastLoadedHeight > 0 &&
        _position!.maxScrollExtent - _position!.pixels < (lastLoadedHeight * 0.5) &&
        _enableLoading) {
      return true;
    }

    // 传统预加载：当距离底部小于触发距离时触发
    if (_position!.maxScrollExtent - _position!.pixels <= configuration!.footerTriggerDistance &&
        _position!.extentBefore > 2.0 &&
        _enableLoading) {
      return true;
    }

    return false;
  }

  /// 处理状态变化
  @override
  void _handleModeChange() {
    if (!mounted || _isHide) {
      return;
    }

    update();

    final currentMode = mode;
    if (currentMode == null) {
      return;
    }

    switch (currentMode) {
      case LoadStatus.idle:
      case LoadStatus.failed:
      case LoadStatus.noMore:
        _handleIdleFailedOrNoMore();
        break;
      case LoadStatus.loading:
        _handleLoading();
        break;
      case LoadStatus.canLoading:
        // 无需特殊处理
        break;
    }

    _lastMode = currentMode;
    onModeChange(mode);
  }

  /// 处理空闲、失败或没有更多数据状态
  void _handleIdleFailedOrNoMore() {
    // #292,#265,#208
    // 当加载过快时停止缓慢弹跳
    if (_position!.activity!.velocity < 0 &&
        _lastMode == LoadStatus.loading &&
        !_position!.outOfRange &&
        _position is ScrollActivityDelegate) {
      _position!.beginActivity(IdleScrollActivity(_position as ScrollActivityDelegate));
    }

    finishLoading();
  }

  /// 处理加载中状态
  void _handleLoading() {
    if (!floating) {
      enterLoading();
    }

    // 触发震动反馈
    if (configuration!.enableLoadMoreVibrate) {
      HapticFeedback.vibrate();
    }

    // 调用加载回调
    refresher!.onLoading?.call();

    // 根据加载样式设置浮动状态
    if (widget.loadStyle == LoadStyle.showWhenLoading) {
      floating = true;
    }
  }

  /// 根据偏移量分发加载状态
  @override
  void _dispatchModeByOffset(double offset) {
    if (!mounted || _isHide || mode == LoadStatus.loading || floating) {
      return;
    }

    // 初始化加载高度和最大滚动范围
    if (lastLoadedHeight == 0) {
      lastLoadedHeight = _position!.maxScrollExtent;
    }

    if (lastMaxScrollExtend == 0) {
      lastMaxScrollExtend = _position!.maxScrollExtent;
    }

    // 拖动状态下的处理
    if (activity is DragScrollActivity) {
      if (_checkIfCanLoading()) {
        mode = LoadStatus.canLoading;
      } else {
        mode = _lastMode;
      }
    }

    // 弹性滚动状态下的处理
    else if (activity is BallisticScrollActivity) {
      if (configuration!.enableBallisticLoad) {
        if (_checkIfCanLoading()) {
          enterLoading();
        }
      } else if (mode == LoadStatus.canLoading) {
        enterLoading();
      }
    }
  }

  @override
  void _handleOffsetChange() {
    if (_isHide) {
      return;
    }

    super._handleOffsetChange();
    final double overscrollPast = _calculateScrollOffset();
    onOffsetChange(overscrollPast);
  }

  /// 监听滚动结束
  void _listenScrollEnd() {
    if (!_position!.isScrollingNotifier.value) {
      // 用户释放手势时
      if (_isHide || mode == LoadStatus.loading || mode == LoadStatus.noMore) {
        return;
      }

      if (_checkIfCanLoading()) {
        if (activity is IdleScrollActivity) {
          if (configuration!.enableBallisticLoad ||
              (!configuration!.enableBallisticLoad && mode == LoadStatus.canLoading)) {
            enterLoading();
          }
        }
      }
    } else {
      // 滚动中，只有拖动或驱动滚动时才允许加载
      if (activity is DragScrollActivity || activity is DrivenScrollActivity) {
        _enableLoading = true;
      }
    }
  }

  /// 处理滚动位置更新
  @override
  void _onPositionUpdated(ScrollPosition newPosition) {
    _position?.isScrollingNotifier.removeListener(_listenScrollEnd);
    newPosition.isScrollingNotifier.addListener(_listenScrollEnd);
    super._onPositionUpdated(newPosition);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentMode = mode;
    if (currentMode != null) {
      _lastMode = currentMode;
    }
  }

  @override
  void dispose() {
    _position?.isScrollingNotifier.removeListener(_listenScrollEnd);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SliverLoading(
      hideWhenNotFull: configuration!.hideFooterWhenNotFull,
      floating: _getFloatingState(),
      shouldFollowContent: _shouldFollowContent(),
      layoutExtent: widget.height,
      mode: mode,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          _isHide = constraints.biggest.height == 0.0;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              widget.onClick?.call();
            },
            child: buildContent(context, mode),
          );
        },
      ),
    );
  }

  /// 获取浮动状态
  bool _getFloatingState() {
    if (widget.loadStyle == LoadStyle.showAlways) {
      return true;
    } else if (widget.loadStyle == LoadStyle.hideAlways) {
      return false;
    } else {
      return floating;
    }
  }

  /// 判断是否应该跟随内容
  bool _shouldFollowContent() {
    if (configuration!.shouldFooterFollowWhenNotFull != null) {
      return configuration!.shouldFooterFollowWhenNotFull!(mode);
    } else {
      return mode == LoadStatus.noMore;
    }
  }
}

/// 指示器状态混合类，处理位置监听和状态管理
///
/// 帮助实现下拉刷新和上拉加载指示器所需的通用功能
mixin IndicatorStateMixin<T extends StatefulWidget, V> on State<T> {
  /// 刷新控件实例
  SmartRefresher? refresher;

  /// 刷新配置
  RefreshConfiguration? configuration;

  /// 刷新控件状态
  SmartRefresherState? refresherState;

  /// 是否处于浮动状态
  bool _floating = false;

  set floating(bool value) => _floating = value;
  bool get floating => _floating;

  /// 状态通知器
  RefreshNotifier<V?>? _mode;

  set mode(V? value) => _mode?.value = value;
  V? get mode => _mode?.value;

  /// 当前滚动活动
  ScrollActivity? get activity => _position?.activity;

  /// 滚动位置，使用ScrollPosition而不是ScrollController以避免"多个scrollview使用同一个ScrollController"错误
  ScrollPosition? _position;

  /// 更新UI
  void update() {
    if (mounted) {
      setState(() {});
    }
  }

  /// 处理偏移量变化
  void _handleOffsetChange() {
    if (!mounted || _position == null) {
      return;
    }

    final double overscrollPast = _calculateScrollOffset();

    if (overscrollPast < 0.0) {
      return;
    }

    _dispatchModeByOffset(overscrollPast);
  }

  /// 释放监听器资源
  void disposeListener() {
    _mode?.removeListener(_handleModeChange);
    _position?.removeListener(_handleOffsetChange);
    _position = null;
    _mode = null;
  }

  /// 更新监听器
  void _updateListener() {
    configuration = RefreshConfiguration.of(context);
    refresher = SmartRefresher.of(context);
    refresherState = SmartRefresher.ofState(context);

    // 根据类型获取对应的状态通知器
    RefreshNotifier<V>? newMode;
    if (V == RefreshStatus) {
      newMode = refresher?.controller.headerMode as RefreshNotifier<V>?;
    } else if (V == LoadStatus) {
      newMode = refresher?.controller.footerMode as RefreshNotifier<V>?;
    }

    final ScrollPosition newPosition = Scrollable.of(context).position;

    // 更新状态通知器
    if (newMode != _mode) {
      _mode?.removeListener(_handleModeChange);
      _mode = newMode;
      _mode?.addListener(_handleModeChange);
    }

    // 更新滚动位置
    if (newPosition != _position) {
      _position?.removeListener(_handleOffsetChange);
      _onPositionUpdated(newPosition);
      _position = newPosition;
      _position?.addListener(_handleOffsetChange);
    }
  }

  @override
  void initState() {
    super.initState();

    // 初始化刷新状态为空闲
    if (V == RefreshStatus) {
      SmartRefresher.of(context)?.controller.headerMode?.value = RefreshStatus.idle;
    }
  }

  @override
  void dispose() {
    // 1.3.7: 添加asSliver builder后需要注意这里
    disposeListener();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    _updateListener();
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(T oldWidget) {
    // 1.3.7: 添加asSliver builder后需要注意这里
    _updateListener();
    super.didUpdateWidget(oldWidget);
  }

  /// 处理滚动位置更新
  void _onPositionUpdated(ScrollPosition newPosition) {
    refresher?.controller.onPositionUpdated(newPosition);
  }

  /// 处理状态变化，子类必须实现
  void _handleModeChange();

  /// 计算滚动偏移量，子类必须实现
  double _calculateScrollOffset();

  /// 根据偏移量分发状态，子类必须实现
  void _dispatchModeByOffset(double offset);

  /// 构建内容，子类必须实现
  Widget buildContent(BuildContext context, V? mode);
}

/// 下拉刷新处理器接口
///
/// 定义了下拉刷新指示器的回调方法
mixin RefreshProcessor {
  /// 超出边缘偏移量回调
  void onOffsetChange(double offset) {}

  /// 模式变化回调
  void onModeChange(RefreshStatus? mode) {}

  /// 准备进入刷新状态，会等待此函数完成后再调用onRefresh
  Future<void> readyToRefresh() {
    return Future.value();
  }

  /// 准备关闭刷新布局，会在完成后回弹
  Future<void> endRefresh() {
    return Future.value();
  }

  /// 回弹后重置值
  void resetValue() {}
}

/// 上拉加载处理器接口
///
/// 定义了上拉加载指示器的回调方法
mixin LoadingProcessor {
  /// 超出边缘偏移量回调
  void onOffsetChange(double offset) {}

  /// 模式变化回调
  void onModeChange(LoadStatus? mode) {}

  /// 准备进入加载状态，会等待此函数完成后再调用onLoading
  Future<void> readyToLoad() {
    return Future.value();
  }

  /// 准备关闭加载布局，会在完成后回弹
  Future<void> endLoading() {
    return Future.value();
  }

  /// 回弹后重置值
  void resetValue() {}
}
