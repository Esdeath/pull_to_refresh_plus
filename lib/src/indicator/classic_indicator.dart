// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide RefreshIndicator, RefreshIndicatorState;
import '../../pull_to_refresh_plus.dart';



/// 图标相对于文本的位置枚举
///
/// 用于控制刷新/加载指示器中图标的位置
/// - left: 图标在文本左侧
/// - right: 图标在文本右侧
/// - top: 图标在文本上方
/// - bottom: 图标在文本下方
enum IconPosition { left, right, top, bottom }

/// 外部包装构建器
///
/// 用于自定义指示器的外部容器，例如添加背景色、内边距等
/// - [child]: 指示器的核心内容
/// - 返回值: 包装后的完整指示器组件
typedef OuterBuilder = Widget Function(Widget child);

/// 经典头部刷新指示器
///
/// 这是最常用的刷新指示器，结合了文本和图标，支持多种刷新状态
///
/// 主要功能：
/// - 支持多种刷新状态显示（空闲、可刷新、刷新中、完成、失败、二级刷新）
/// - 可自定义文本、图标、间距和位置
/// - 支持国际化文本
/// - 支持外部容器自定义
///
/// 示例用法：
/// ```dart
/// ClassicHeader(
///   idleText: "下拉刷新",
///   releaseText: "释放刷新",
///   refreshingText: "刷新中...",
///   completeText: "刷新完成",
///   failedText: "刷新失败",
///   iconPos: IconPosition.left,
///   spacing: 10.0,
/// )
/// ```
///
/// 相关组件：
/// - [ClassicFooter]: 经典底部加载指示器
class ClassicHeader extends RefreshIndicator {
  /// 外部包装构建器
  ///
  /// 用于自定义指示器的外部容器，例如添加背景色、内边距等
  /// 示例：
  /// ```dart
  /// outerBuilder: (child) {
  ///   return Container(
  ///     color: Colors.red,
  ///     padding: EdgeInsets.all(10.0),
  ///     child: child,
  ///   );
  /// }
  /// ```
  final OuterBuilder? outerBuilder;

  /// 刷新状态文本配置
  /// - [releaseText]: 释放刷新时显示的文本
  /// - [idleText]: 空闲状态时显示的文本
  /// - [refreshingText]: 刷新中显示的文本
  /// - [completeText]: 刷新完成显示的文本
  /// - [failedText]: 刷新失败显示的文本
  final String? releaseText, idleText, refreshingText, completeText, failedText;

  /// 刷新状态图标配置
  /// - [releaseIcon]: 释放刷新时显示的图标
  /// - [idleIcon]: 空闲状态时显示的图标
  /// - [refreshingIcon]: 刷新中显示的图标
  /// - [completeIcon]: 刷新完成显示的图标
  /// - [failedIcon]: 刷新失败显示的图标
  final Widget? releaseIcon, idleIcon, refreshingIcon, completeIcon, failedIcon;

  /// 图标和文本之间的间距
  final double spacing;

  /// 图标相对于文本的位置
  final IconPosition iconPos;

  /// 文本样式
  final TextStyle textStyle;

  const ClassicHeader({
    super.key,
    super.refreshStyle,
    super.height,
    super.completeDuration = const Duration(milliseconds: 600),
    this.outerBuilder,
    this.textStyle = const TextStyle(color: Colors.grey),
    this.releaseText,
    this.refreshingText,
    this.completeText,
    this.failedText,
    this.idleText,
    this.iconPos = IconPosition.left,
    this.spacing = 15.0,
    this.refreshingIcon,
    this.failedIcon = const Icon(Icons.error, color: Colors.grey),
    this.completeIcon = const Icon(Icons.done, color: Colors.grey),
    this.idleIcon = const Icon(Icons.arrow_downward, color: Colors.grey),
    this.releaseIcon = const Icon(Icons.refresh, color: Colors.grey),
  });

  @override
  State<ClassicHeader> createState() {
    return _ClassicHeaderState();
  }
}

class _ClassicHeaderState extends RefreshIndicatorState<ClassicHeader> {
  /// 根据刷新状态构建显示文本
  Widget _buildText(RefreshStatus? mode) {
    // 获取刷新文本配置，如果没有则使用默认英文配置
    RefreshString strings = RefreshLocalizations.of(context)?.currentLocalization ?? EnRefreshString();

    // 根据不同的刷新状态返回对应的文本
    String displayText;
    switch (mode) {
      case RefreshStatus.canRefresh:
        displayText = widget.releaseText ?? strings.canRefreshText!;
        break;
      case RefreshStatus.completed:
        displayText = widget.completeText ?? strings.refreshCompleteText!;
        break;
      case RefreshStatus.failed:
        displayText = widget.failedText ?? strings.refreshFailedText!;
        break;
      case RefreshStatus.refreshing:
        displayText = widget.refreshingText ?? strings.refreshingText!;
        break;
      case RefreshStatus.idle:
        displayText = widget.idleText ?? strings.idleRefreshText!;
        break;

      default:
        displayText = "";
    }

    return Text(displayText, style: widget.textStyle);
  }

  /// 根据刷新状态构建显示图标
  Widget _buildIcon(RefreshStatus? mode) {
    Widget? displayIcon;

    // 根据不同的刷新状态返回对应的图标
    switch (mode) {
      case RefreshStatus.canRefresh:
        displayIcon = widget.releaseIcon;
        break;
      case RefreshStatus.idle:
        displayIcon = widget.idleIcon;
        break;
      case RefreshStatus.completed:
        displayIcon = widget.completeIcon;
        break;
      case RefreshStatus.failed:
        displayIcon = widget.failedIcon;
        break;
      case RefreshStatus.refreshing:
        // 如果没有自定义刷新图标，则显示默认的加载指示器
        displayIcon = widget.refreshingIcon ??
            SizedBox(
              width: 25.0,
              height: 25.0,
              child: defaultTargetPlatform == TargetPlatform.iOS
                  ? const CupertinoActivityIndicator()
                  : const CircularProgressIndicator(strokeWidth: 2.0),
            );
        break;
      default:
        displayIcon = widget.failedIcon;
    }

    // 如果图标为null，则返回空容器
    return displayIcon ?? Container();
  }

  /// 是否需要反转所有内容
  ///
  /// 默认为false，不需要反转
  @override
  bool needReverseAll() {
    return false;
  }

  /// 构建指示器内容
  ///
  /// 根据当前刷新状态构建完整的指示器UI
  /// - [context]: 上下文
  /// - [mode]: 当前刷新状态
  /// - 返回值: 构建好的指示器组件
  @override
  Widget buildContent(BuildContext context, RefreshStatus? mode) {
    // 构建文本和图标
    Widget textWidget = _buildText(mode);
    Widget iconWidget = _buildIcon(mode);

    // 组合文本和图标
    List<Widget> children = <Widget>[iconWidget, textWidget];

    // 构建核心容器
    final Widget container = Wrap(
      spacing: widget.spacing, // 图标和文本的间距
      textDirection: widget.iconPos == IconPosition.left ? TextDirection.ltr : TextDirection.rtl, // 文本方向
      direction: widget.iconPos == IconPosition.bottom || widget.iconPos == IconPosition.top
          ? Axis.vertical // 垂直排列
          : Axis.horizontal, // 水平排列
      crossAxisAlignment: WrapCrossAlignment.center, // 交叉轴对齐方式
      verticalDirection: widget.iconPos == IconPosition.bottom ? VerticalDirection.up : VerticalDirection.down, // 垂直方向
      alignment: WrapAlignment.center, // 主轴对齐方式
      children: children,
    );

    // 如果有外部构建器，则使用外部构建器包装
    // 否则使用默认的SizedBox包装，设置固定高度
    return widget.outerBuilder != null
        ? widget.outerBuilder!(container)
        : SizedBox(
            height: widget.height,
            child: Center(child: container),
          );
  }
}

/// 经典底部加载指示器
///
/// 这是最常用的加载指示器，结合了文本和图标，支持多种加载状态
///
/// 主要功能：
/// - 支持多种加载状态显示（空闲、可加载、加载中、完成、失败、无更多数据）
/// - 可自定义文本、图标、间距和位置
/// - 支持国际化文本
/// - 支持外部容器自定义
///
/// 示例用法：
/// ```dart
/// ClassicFooter(
///   idleText: "上拉加载更多",
///   canLoadingText: "释放加载",
///   loadingText: "加载中...",
///   noDataText: "没有更多数据",
///   failedText: "加载失败",
///   iconPos: IconPosition.left,
///   spacing: 10.0,
/// )
/// ```
///
/// 相关组件：
/// - [ClassicHeader]: 经典头部刷新指示器
class ClassicFooter extends LoadIndicator {
  /// 外部包装构建器
  ///
  /// 用于自定义指示器的外部容器，例如添加背景色、内边距等
  /// 示例：
  /// ```dart
  /// outerBuilder: (child) {
  ///   return Container(
  ///     color: Colors.red,
  ///     padding: EdgeInsets.all(10.0),
  ///     child: child,
  ///   );
  /// }
  /// ```
  final OuterBuilder? outerBuilder;

  /// 加载状态文本配置
  /// - [idleText]: 空闲状态时显示的文本
  /// - [loadingText]: 加载中显示的文本
  /// - [noDataText]: 无更多数据时显示的文本
  /// - [failedText]: 加载失败显示的文本
  /// - [canLoadingText]: 可加载时显示的文本
  final String? idleText, loadingText, noDataText, failedText, canLoadingText;

  /// 加载状态图标配置
  /// - [idleIcon]: 空闲状态时显示的图标
  /// - [loadingIcon]: 加载中显示的图标
  /// - [noMoreIcon]: 无更多数据时显示的图标
  /// - [failedIcon]: 加载失败显示的图标
  /// - [canLoadingIcon]: 可加载时显示的图标
  final Widget? idleIcon, loadingIcon, noMoreIcon, failedIcon, canLoadingIcon;

  /// 图标和文本之间的间距
  final double spacing;

  /// 图标相对于文本的位置
  final IconPosition iconPos;

  /// 文本样式
  final TextStyle textStyle;

  /// 加载完成后显示的持续时间
  ///
  /// 注意：此属性仅在 LoadStyle.ShowWhenLoading 模式下生效
  final Duration completeDuration;

  const ClassicFooter({
    super.key,
    super.onClick,
    super.loadStyle,
    super.height,
    this.outerBuilder,
    this.textStyle = const TextStyle(color: Colors.grey),
    this.loadingText,
    this.noDataText,
    this.noMoreIcon,
    this.idleText,
    this.failedText,
    this.canLoadingText,
    this.failedIcon = const Icon(Icons.error, color: Colors.grey),
    this.iconPos = IconPosition.left,
    this.spacing = 15.0,
    this.completeDuration = const Duration(milliseconds: 300),
    this.loadingIcon,
    this.canLoadingIcon = const Icon(Icons.autorenew, color: Colors.grey),
    this.idleIcon = const Icon(Icons.arrow_upward, color: Colors.grey),
  });

  @override
  State<ClassicFooter> createState() {
    return _ClassicFooterState();
  }
}

class _ClassicFooterState extends LoadIndicatorState<ClassicFooter> {
  /// 根据加载状态构建显示文本
  Widget _buildText(LoadStatus? mode) {
    // 获取刷新文本配置，如果没有则使用默认英文配置
    RefreshString strings = RefreshLocalizations.of(context)?.currentLocalization ?? EnRefreshString();

    // 根据不同的加载状态返回对应的文本
    String displayText;
    switch (mode) {
      case LoadStatus.loading:
        displayText = widget.loadingText ?? strings.loadingText!;
        break;
      case LoadStatus.noMore:
        displayText = widget.noDataText ?? strings.noMoreText!;
        break;
      case LoadStatus.failed:
        displayText = widget.failedText ?? strings.loadFailedText!;
        break;
      case LoadStatus.canLoading:
        displayText = widget.canLoadingText ?? strings.canLoadingText!;
        break;
      case LoadStatus.idle:
      default:
        displayText = widget.idleText ?? strings.idleLoadingText!;
    }

    return Text(displayText, style: widget.textStyle);
  }

  /// 根据加载状态构建显示图标
  Widget _buildIcon(LoadStatus? mode) {
    Widget? displayIcon;

    // 根据不同的加载状态返回对应的图标
    switch (mode) {
      case LoadStatus.loading:
        // 如果没有自定义加载图标，则显示默认的加载指示器
        displayIcon = widget.loadingIcon ??
            SizedBox(
              width: 25.0,
              height: 25.0,
              child: defaultTargetPlatform == TargetPlatform.iOS
                  ? const CupertinoActivityIndicator()
                  : const CircularProgressIndicator(strokeWidth: 2.0),
            );
        break;
      case LoadStatus.noMore:
        displayIcon = widget.noMoreIcon;
        break;
      case LoadStatus.failed:
        displayIcon = widget.failedIcon;
        break;
      case LoadStatus.canLoading:
        displayIcon = widget.canLoadingIcon;
        break;
      case LoadStatus.idle:
      default:
        displayIcon = widget.idleIcon;
    }

    // 如果图标为null，则返回空容器
    return displayIcon ?? Container();
  }

  /// 结束加载
  ///
  /// 加载完成后调用，用于控制加载完成状态的显示时间
  @override
  Future<void> endLoading() {
    // 延迟指定时间后结束加载，让用户有时间看到加载完成状态
    return Future.delayed(widget.completeDuration);
  }

  /// 构建指示器内容
  ///
  /// 根据当前加载状态构建完整的指示器UI
  /// - [context]: 上下文
  /// - [mode]: 当前加载状态
  /// - 返回值: 构建好的指示器组件
  @override
  Widget buildContent(BuildContext context, LoadStatus? mode) {
    // 构建文本和图标
    Widget textWidget = _buildText(mode);
    Widget iconWidget = _buildIcon(mode);

    // 组合文本和图标
    List<Widget> children = <Widget>[iconWidget, textWidget];

    // 构建核心容器
    final Widget container = Wrap(
      spacing: widget.spacing, // 图标和文本的间距
      textDirection: widget.iconPos == IconPosition.left ? TextDirection.ltr : TextDirection.rtl, // 文本方向
      direction: widget.iconPos == IconPosition.bottom || widget.iconPos == IconPosition.top
          ? Axis.vertical // 垂直排列
          : Axis.horizontal, // 水平排列
      crossAxisAlignment: WrapCrossAlignment.center, // 交叉轴对齐方式
      verticalDirection: widget.iconPos == IconPosition.bottom ? VerticalDirection.up : VerticalDirection.down, // 垂直方向
      alignment: WrapAlignment.center, // 主轴对齐方式
      children: children,
    );

    // 如果有外部构建器，则使用外部构建器包装
    // 否则使用默认的SizedBox包装，设置固定高度
    return widget.outerBuilder != null
        ? widget.outerBuilder!(container)
        : SizedBox(
            height: widget.height,
            child: Center(
              child: container,
            ),
          );
  }
}
