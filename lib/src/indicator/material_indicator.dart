// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
import 'package:flutter/material.dart' hide RefreshIndicator, RefreshIndicatorState;

import '../internals/indicator_wrap.dart';
import '../smart_refresher.dart';

/// 滚动拖动手势可以超出RefreshIndicator位移的倍数
///
/// 最大位移 = _kDragSizeFactorLimit * 触发位移
const double _kDragSizeFactorLimit = 1.5;

/// 经典Material风格刷新头部
///
/// 基于Flutter内置的RefreshIndicator实现，提供Material Design风格的刷新指示器
///
/// 主要功能：
/// - 支持Material Design风格的刷新动画
/// - 可自定义颜色、背景色、距离等属性
/// - 支持语义化标签
/// - 支持前端刷新样式
///
/// 示例用法：
/// ```dart
/// MaterialClassicHeader(
///   color: Colors.blue,
///   backgroundColor: Colors.white,
///   distance: 50.0,
/// )
/// ```
class MaterialClassicHeader extends RefreshIndicator {
  /// 语义化标签
  ///
  /// 用于屏幕阅读器等辅助技术
  final String? semanticsLabel;

  /// 语义化值
  ///
  /// 用于屏幕阅读器等辅助技术
  final String? semanticsValue;

  /// 刷新指示器的颜色
  ///
  /// 控制刷新动画的颜色
  final Color? color;

  /// 刷新时距离顶部的距离
  ///
  /// 刷新动画触发后，指示器距离顶部的距离
  final double distance;

  /// 背景颜色
  ///
  /// 指示器的背景颜色
  final Color? backgroundColor;

  /// 构造函数
  ///
  /// - [key]: 组件key
  /// - [height]: 指示器高度，默认80.0
  /// - [semanticsLabel]: 语义化标签
  /// - [semanticsValue]: 语义化值
  /// - [color]: 刷新指示器颜色
  /// - [offset]: 偏移量
  /// - [distance]: 刷新时距离顶部的距离，默认50.0
  /// - [backgroundColor]: 背景颜色
  const MaterialClassicHeader({
    super.key,
    super.height = 80.0,
    this.semanticsLabel,
    this.semanticsValue,
    this.color,
    this.distance = 50.0,
    this.backgroundColor,
    super.offset,
  }) : super(
          refreshStyle: RefreshStyle.front,
        );

  @override
  State<MaterialClassicHeader> createState() {
    return _MaterialClassicHeaderState();
  }
}

class _MaterialClassicHeaderState extends RefreshIndicatorState<MaterialClassicHeader> with TickerProviderStateMixin {
  ScrollPosition? _position;
  Animation<Offset>? _positionFactor;
  Animation<Color?>? _valueColor;
  late AnimationController _scaleFactor;
  late AnimationController _positionController;
  late AnimationController _valueAni;

  @override
  void initState() {
    super.initState();

    // 初始化值动画控制器
    _valueAni = AnimationController(
      vsync: this,
      value: 0.0, 
      lowerBound: 0.0,
      upperBound: 1.0,
      duration: const Duration(milliseconds: 500),
    );

    // 添加值变化监听器
    _valueAni.addListener(() {
      // 只有在挂载且滚动位置在顶部时才更新UI，避免频繁setState影响性能
      if (mounted && _position!.pixels <= 0) {
        setState(() {});
      }
    });

    // 初始化位置控制器
    _positionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // 初始化缩放控制器
    _scaleFactor = AnimationController(
      vsync: this,
      value: 1.0,
      lowerBound: 0.0,
      upperBound: 1.0,
      duration: const Duration(milliseconds: 300),
    );

    // 初始化位置因子动画
    _positionFactor = _positionController.drive(
      Tween<Offset>(
        begin: const Offset(0.0, -1.0),
        end: Offset(0.0, widget.height / 44.0),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant MaterialClassicHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    _position = Scrollable.of(context).position;
  }

  @override
  Widget buildContent(BuildContext context, RefreshStatus? mode) {
    return _buildIndicator(widget.backgroundColor ?? Colors.white);
  }

  Widget _buildIndicator(Color outerColor) {
    return SlideTransition(
      position: _positionFactor!,
      child: ScaleTransition(
        scale: _scaleFactor,
        child: Align(
          alignment: Alignment.topCenter,
          child: RefreshProgressIndicator(
            semanticsLabel: widget.semanticsLabel ?? MaterialLocalizations.of(context).refreshIndicatorSemanticLabel,
            semanticsValue: widget.semanticsValue,
            value: floating ? null : _valueAni.value,
            valueColor: _valueColor,
            backgroundColor: outerColor,
          ),
        ),
      ),
    );
  }

  @override
  void onOffsetChange(double offset) {
    // 只有非浮动模式下才响应偏移量变化
    if (!floating) {
      // 计算偏移比例
      final double offsetRatio = offset / configuration!.headerTriggerDistance;
      _valueAni.value = offsetRatio;
      _positionController.value = offsetRatio;
    }
  }

  @override
  void onModeChange(RefreshStatus? mode) {
    super.onModeChange(mode);

    // 刷新模式下的处理
    if (mode == RefreshStatus.refreshing) {
      // 设置位置和缩放值
      _positionController.value = widget.distance / widget.height;
      _scaleFactor.value = 1;
    }
  }

  @override
  void resetValue() {
    super.resetValue();

    // 重置所有动画值
    _scaleFactor.value = 1.0;
    _positionController.value = 0.0;
    _valueAni.value = 0.0;
  }

  @override
  void didChangeDependencies() {
    final ThemeData theme = Theme.of(context);
    _position = Scrollable.of(context).position;
    _valueColor = _positionController.drive(
      ColorTween(
        begin: (widget.color ?? theme.primaryColor).withValues(alpha: 0.0),
        end: (widget.color ?? theme.primaryColor).withValues(alpha: 1.0),
      ).chain(CurveTween(curve: const Interval(0.0, 1.0 / _kDragSizeFactorLimit))),
    );
    super.didChangeDependencies();
  }

  @override
  Future<void> readyToRefresh() {
    // 准备刷新时，执行位置动画
    return _positionController.animateTo(widget.distance / widget.height);
  }

  @override
  Future<void> endRefresh() {
    // 结束刷新时，执行缩放动画
    return _scaleFactor.animateTo(0.0);
  }

  @override
  void dispose() {
    // 释放所有动画控制器资源
    _valueAni.dispose();
    _scaleFactor.dispose();
    _positionController.dispose();
    super.dispose();
  }
}

/// 水滴效果Material刷新头部
///
/// 在[MaterialClassicHeader]基础上添加了水滴动画效果
///
/// 示例用法：
/// ```dart
/// WaterDropMaterialHeader(
///   color: Colors.blue,
///   distance: 60.0,
/// )
/// ```
class WaterDropMaterialHeader extends MaterialClassicHeader {
  /// 构造函数
  ///
  /// - [key]: 组件key
  /// - [semanticsLabel]: 语义化标签
  /// - [semanticsValue]: 语义化值
  /// - [distance]: 刷新时距离顶部的距离，默认60.0
  /// - [offset]: 偏移量
  /// - [color]: 刷新指示器颜色，默认白色
  /// - [backgroundColor]: 背景颜色
  const WaterDropMaterialHeader({
    super.key,
    super.height = 80.0,
    super.semanticsLabel,
    super.semanticsValue,
    super.distance = 60.0,
    Color super.color = Colors.white,
    super.backgroundColor,
    super.offset,
  });

  @override
  State<WaterDropMaterialHeader> createState() {
    return _WaterDropMaterialHeaderState();
  }
}

class _WaterDropMaterialHeaderState extends RefreshIndicatorState<WaterDropMaterialHeader>
    with TickerProviderStateMixin {
  ScrollPosition? _position;
  Animation<Offset>? _positionFactor;
  Animation<Color?>? _valueColor;
  late AnimationController _scaleFactor;
  late AnimationController _positionController;
  late AnimationController _valueAni;
  AnimationController? _bezierController;
  bool _showWater = false;

  @override
  void initState() {
    super.initState();

    // 初始化值动画控制器
    _valueAni = AnimationController(
      vsync: this,
      value: 0.0,
      lowerBound: 0.0,
      upperBound: 1.0,
      duration: const Duration(milliseconds: 500),
    );

    // 添加值变化监听器
    _valueAni.addListener(() {
      // 只有在挂载且滚动位置在顶部时才更新UI，避免频繁setState影响性能
      if (mounted && (_position?.pixels ?? 0.0) <= 0) {
        setState(() {});
      }
    });

    // 初始化位置控制器
    _positionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // 初始化缩放控制器
    _scaleFactor = AnimationController(
      vsync: this,
      value: 1.0,
      lowerBound: 0.0,
      upperBound: 1.0,
      duration: const Duration(milliseconds: 300),
    );

    // 初始化贝塞尔曲线控制器
    _bezierController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      upperBound: 1.5,
      lowerBound: 0.0,
      value: 0.0,
    );

    // 初始化位置因子动画
    _positionFactor = _positionController.drive(
      Tween<Offset>(
        begin: const Offset(0.0, -0.5),
        end: const Offset(0.0, 1.5),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant WaterDropMaterialHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    _position = Scrollable.of(context).position;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final ThemeData theme = Theme.of(context);
    _position = Scrollable.of(context).position;
    _valueColor = _positionController.drive(
      ColorTween(
        begin: (widget.color ?? theme.primaryColor).withValues(alpha: 0.0),
        end: (widget.color ?? theme.primaryColor).withValues(alpha: 1.0),
      ).chain(
        CurveTween(
          curve: const Interval(0.0, 1.0 / _kDragSizeFactorLimit),
        ),
      ),
    );
  }

  Widget _buildIndicator(Color outerColor) {
    return SlideTransition(
      position: _positionFactor!,
      child: ScaleTransition(
        scale: _scaleFactor,
        child: Align(
          alignment: Alignment.topCenter,
          child: RefreshProgressIndicator(
            semanticsLabel: widget.semanticsLabel ?? MaterialLocalizations.of(context).refreshIndicatorSemanticLabel,
            semanticsValue: widget.semanticsValue,
            value: floating ? null : _valueAni.value,
            valueColor: _valueColor,
            backgroundColor: outerColor,
          ),
        ),
      ),
    );
  }

  @override
  void onOffsetChange(double offset) {
    // 限制偏移量最大值为80.0
    offset = offset > 80.0 ? 80.0 : offset;

    // 只有非浮动模式下才响应偏移量变化
    if (!floating) {
      // 计算贝塞尔曲线值
      final double bezierValue = offset / configuration!.headerTriggerDistance;
      _bezierController!.value = bezierValue;

      // 更新值控制器和位置控制器
      _valueAni.value = bezierValue;
      _positionController.value = bezierValue * 0.3;

      // 计算缩放值，偏移量小于40时不显示，大于40时逐渐显示
      _scaleFactor.value = offset < 40.0 ? 0.0 : (bezierValue - 0.5) * 2 + 0.5;
    }
  }

  @override
  void onModeChange(RefreshStatus? mode) {
    super.onModeChange(mode);

    // 刷新模式下的处理
    if (mode == RefreshStatus.refreshing) {
      // 设置位置和缩放值
      _positionController.value = widget.distance / widget.height;
      _scaleFactor.value = 1;
    }
  }

  @override
  void resetValue() {
    super.resetValue();

    // 重置所有动画值
    _scaleFactor.value = 1.0;
    _positionController.value = 0.0;
    _valueAni.value = 0.0;
    _bezierController!.reset();
  }

  @override
  Future<void> readyToRefresh() {
    // 设置贝塞尔曲线初始值和水滴显示状态
    _bezierController!.value = 1.01;
    _showWater = true;

    // 执行贝塞尔曲线动画
    _bezierController!.animateTo(
      1.5,
      curve: Curves.bounceOut,
      duration: const Duration(milliseconds: 550),
    );

    // 执行位置动画，并在动画结束后隐藏水滴
    return _positionController
        .animateTo(
      widget.distance / widget.height,
      curve: Curves.bounceOut,
      duration: const Duration(milliseconds: 550),
    )
        .then((_) {
      _showWater = false;
    });
  }

  @override
  Future<void> endRefresh() {
    // 结束刷新时隐藏水滴
    _showWater = false;
    return _scaleFactor.animateTo(0.0);
  }

  @override
  void dispose() {
    // 释放所有动画控制器资源
    _valueAni.dispose();
    _scaleFactor.dispose();
    _positionController.dispose();
    _bezierController!.dispose();
    super.dispose();
  }

  @override
  Widget buildContent(BuildContext context, RefreshStatus? mode) {
    return SizedBox(
      height: 100.0,
      child: Stack(
        children: <Widget>[
          CustomPaint(
            painter: _BezierPainter(
                listener: _bezierController, color: widget.backgroundColor ?? Theme.of(context).primaryColor),
            child: Container(),
          ),
          CustomPaint(
            painter: _showWater
                ? _WaterPainter(
                    ratio: widget.distance / widget.height,
                    color: widget.backgroundColor ?? Theme.of(context).primaryColor,
                    listener: _positionFactor)
                : null,
            child: _buildIndicator(widget.backgroundColor ?? Theme.of(context).primaryColor),
          )
        ],
      ),
    );
  }
}

/// 水滴效果绘制器
class _WaterPainter extends CustomPainter {
  /// 水滴颜色
  final Color? color;

  /// 动画监听器
  final Animation<Offset>? listener;

  /// 当前偏移量
  Offset get offset => listener!.value;

  /// 比例
  final double? ratio;

  /// 构造函数
  _WaterPainter({this.color, this.listener, this.ratio}) : super(repaint: listener);

  @override
  void paint(Canvas canvas, Size size) {
    // 创建画笔
    final Paint paint = Paint()..color = color!;

    // 创建路径
    final Path path = Path();

    // 计算水滴中心点
    final double centerX = size.width / 2;
    final double centerY = offset.dy * 100.0 + 20.0;

    // 绘制水滴形状
    path.moveTo(centerX - 20.0, centerY);
    path.conicTo(centerX, centerY - 70.0 * (ratio! - offset.dy), centerX + 20.0, centerY, 10.0 * (ratio! - offset.dy));

    // 绘制路径
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WaterPainter oldDelegate) {
    // 当对象不同或偏移量变化时需要重绘
    return this != oldDelegate || offset != oldDelegate.offset;
  }
}

/// 贝塞尔曲线绘制器
class _BezierPainter extends CustomPainter {
  /// 动画控制器
  final AnimationController? listener;

  /// 绘制颜色
  final Color? color;

  /// 当前值
  double get value => listener!.value;

  /// 构造函数
  _BezierPainter({this.listener, this.color}) : super(repaint: listener);

  @override
  void paint(Canvas canvas, Size size) {
    // 创建画笔
    final Paint paint = Paint()..color = color!;

    // 计算中心点
    final double centerX = size.width / 2;

    // 根据不同的值绘制不同的贝塞尔曲线
    if (value < 0.5) {
      // 值较小时，绘制简单的贝塞尔曲线
      final Path path = Path();
      path.moveTo(0.0, 0.0);
      path.quadraticBezierTo(centerX, 70.0 * value, size.width, 0.0);
      canvas.drawPath(path, paint);
    } else if (value <= 1.0) {
      // 值在0.5到1.0之间时，绘制复杂的贝塞尔曲线
      final Path path = Path();
      final double offsetY = 60.0 * (value - 0.5) + 20.0;

      path.moveTo(0.0, 0.0);
      path.quadraticBezierTo(centerX + 40.0 * (value - 0.5), 40.0 - 40.0 * value, centerX - 10.0, offsetY);
      path.lineTo(centerX + 10.0, offsetY);
      path.quadraticBezierTo(centerX - 40.0 * (value - 0.5), 40.0 - 40.0 * value, size.width, 0.0);
      path.moveTo(size.width, 0.0);
      path.lineTo(0.0, 0.0);

      canvas.drawPath(path, paint);
    } else {
      // 值大于1.0时，绘制收敛的贝塞尔曲线
      final Path path = Path();
      path.moveTo(0.0, 0.0);
      path.conicTo(centerX, 60.0 * (1.5 - value), size.width, 0.0, 5.0);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_BezierPainter oldDelegate) {
    // 当对象不同或值变化时需要重绘
    return this != oldDelegate || oldDelegate.value != value;
  }
}
