// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
import 'package:flutter/widgets.dart';

import '../internals/indicator_wrap.dart';
import '../smart_refresher.dart';

/// 自定义头部构建器
///
/// 用于构建自定义的刷新头部，根据不同的刷新状态显示不同的UI
/// - [context]: 上下文
/// - [mode]: 当前刷新状态
/// - 返回值: 构建好的自定义头部组件
typedef HeaderBuilder = Widget Function(BuildContext context, RefreshStatus? mode);

/// 自定义底部构建器
///
/// 用于构建自定义的加载底部，根据不同的加载状态显示不同的UI
/// - [context]: 上下文
/// - [mode]: 当前加载状态
/// - 返回值: 构建好的自定义底部组件
typedef FooterBuilder = Widget Function(BuildContext context, LoadStatus? mode);
/// 自定义头部刷新指示器
///
/// 允许开发者完全自定义刷新头部的UI和行为
///
/// 主要功能：
/// - 通过builder自定义UI
/// - 支持刷新状态回调
/// - 支持偏移量变化回调
/// - 支持刷新开始和结束回调
///
/// 示例用法：
/// ```dart
/// CustomHeader(
///   builder: (context, mode) {
///     return Container(
///       height: 50.0,
///       alignment: Alignment.center,
///       child: Text(mode.toString()),
///     );
///   },
///   onModeChange: (mode) {
///     print('刷新状态变化: $mode');
///   },
/// )
/// ```
class CustomHeader extends RefreshIndicator {
  /// 头部构建器
  ///
  /// 根据刷新状态构建自定义UI
  final HeaderBuilder builder;

  /// 准备刷新回调
  ///
  /// 当刷新即将开始时调用
  final AsyncVoidCallback? readyToRefresh;

  /// 结束刷新回调
  ///
  /// 当刷新即将结束时调用
  final AsyncVoidCallback? endRefresh;

  /// 偏移量变化回调
  ///
  /// 当刷新头部的偏移量发生变化时调用
  final OffsetCallback? onOffsetChange;

  /// 模式变化回调
  ///
  /// 当刷新状态发生变化时调用
  final ModeChangeCallback<RefreshStatus>? onModeChange;

  /// 重置值回调
  ///
  /// 当刷新值重置时调用
  final VoidCallback? onResetValue;

  /// 构造函数
  ///
  /// - [builder]: 必须参数，自定义UI构建器
  /// - [readyToRefresh]: 准备刷新回调
  /// - [endRefresh]: 结束刷新回调
  /// - [onOffsetChange]: 偏移量变化回调
  /// - [onModeChange]: 模式变化回调
  /// - [onResetValue]: 重置值回调
  /// - [height]: 头部高度
  /// - [completeDuration]: 刷新完成后显示的持续时间
  /// - [refreshStyle]: 刷新样式
  const CustomHeader({
    super.key,
    required this.builder,
    this.readyToRefresh,
    this.endRefresh,
    this.onOffsetChange,
    this.onModeChange,
    this.onResetValue,
    super.height,
    super.completeDuration = const Duration(milliseconds: 600),
    super.refreshStyle,
  });

  @override
  State<CustomHeader> createState() {
    return _CustomHeaderState();
  }
}

class _CustomHeaderState extends RefreshIndicatorState<CustomHeader> {
  /// 偏移量变化回调处理
  ///
  /// 当偏移量变化时，先调用外部回调，再调用父类方法
  @override
  void onOffsetChange(double offset) {
    if (widget.onOffsetChange != null) {
      widget.onOffsetChange!(offset);
    }
    super.onOffsetChange(offset);
  }

  /// 模式变化回调处理
  ///
  /// 当模式变化时，先调用外部回调，再调用父类方法
  @override
  void onModeChange(RefreshStatus? mode) {
    if (widget.onModeChange != null) {
      widget.onModeChange!(mode);
    }
    super.onModeChange(mode);
  }

  /// 准备刷新回调处理
  ///
  /// 当准备刷新时，先调用外部回调，再调用父类方法
  @override
  Future<void> readyToRefresh() {
    if (widget.readyToRefresh != null) {
      return widget.readyToRefresh!();
    }
    return super.readyToRefresh();
  }

  /// 结束刷新回调处理
  ///
  /// 当结束刷新时，先调用外部回调，再调用父类方法
  @override
  Future<void> endRefresh() {
    if (widget.endRefresh != null) {
      return widget.endRefresh!();
    }
    return super.endRefresh();
  }

  /// 构建内容
  ///
  /// 使用外部传入的builder构建自定义UI
  @override
  Widget buildContent(BuildContext context, RefreshStatus? mode) {
    return widget.builder(context, mode);
  }
}

/// 自定义底部加载指示器
///
/// 允许开发者完全自定义加载底部的UI和行为
///
/// 主要功能：
/// - 通过builder自定义UI
/// - 支持加载状态回调
/// - 支持偏移量变化回调
/// - 支持加载开始和结束回调
///
/// 示例用法：
/// ```dart
/// CustomFooter(
///   builder: (context, mode) {
///     return Container(
///       height: 50.0,
///       alignment: Alignment.center,
///       child: Text(mode.toString()),
///     );
///   },
///   onModeChange: (mode) {
///     print('加载状态变化: $mode');
///   },
/// )
/// ```
///
/// 相关组件：
/// - [CustomHeader]: 自定义头部刷新指示器
class CustomFooter extends LoadIndicator {
  /// 底部构建器
  ///
  /// 根据加载状态构建自定义UI
  final FooterBuilder builder;

  /// 偏移量变化回调
  ///
  /// 当加载底部的偏移量发生变化时调用
  final OffsetCallback? onOffsetChange;

  /// 模式变化回调
  ///
  /// 当加载状态发生变化时调用
  final ModeChangeCallback<LoadStatus>? onModeChange;

  /// 准备加载回调
  ///
  /// 当加载即将开始时调用
  final AsyncVoidCallback? readyLoading;

  /// 结束加载回调
  ///
  /// 当加载即将结束时调用
  final AsyncVoidCallback? endLoading;

  /// 构造函数
  ///
  /// - [builder]: 必须参数，自定义UI构建器
  /// - [onOffsetChange]: 偏移量变化回调
  /// - [onModeChange]: 模式变化回调
  /// - [readyLoading]: 准备加载回调
  /// - [endLoading]: 结束加载回调
  /// - [height]: 底部高度
  /// - [loadStyle]: 加载样式
  /// - [onClick]: 点击回调
  const CustomFooter({
    super.key,
    required this.builder,
    this.onOffsetChange,
    this.onModeChange,
    this.readyLoading,
    this.endLoading,
    super.height,
    super.loadStyle,
    super.onClick,
  });

  @override
  State<CustomFooter> createState() {
    return _CustomFooterState();
  }
}

class _CustomFooterState extends LoadIndicatorState<CustomFooter> {
  /// 偏移量变化回调处理
  ///
  /// 当偏移量变化时，先调用外部回调，再调用父类方法
  @override
  void onOffsetChange(double offset) {
    if (widget.onOffsetChange != null) {
      widget.onOffsetChange!(offset);
    }
    super.onOffsetChange(offset);
  }

  /// 模式变化回调处理
  ///
  /// 当模式变化时，先调用外部回调，再调用父类方法
  @override
  void onModeChange(LoadStatus? mode) {
    if (widget.onModeChange != null) {
      widget.onModeChange!(mode);
    }
    super.onModeChange(mode);
  }

  /// 准备加载回调处理
  ///
  /// 当准备加载时，先调用外部回调，再调用父类方法
  @override
  Future<void> readyToLoad() {
    if (widget.readyLoading != null) {
      return widget.readyLoading!();
    }
    return super.readyToLoad();
  }

  /// 结束加载回调处理
  ///
  /// 当结束加载时，先调用外部回调，再调用父类方法
  @override
  Future<void> endLoading() {
    if (widget.endLoading != null) {
      return widget.endLoading!();
    }
    return super.endLoading();
  }

  /// 构建内容
  ///
  /// 使用外部传入的builder构建自定义UI
  @override
  Widget buildContent(BuildContext context, LoadStatus? mode) {
    return widget.builder(context, mode);
  }
}
