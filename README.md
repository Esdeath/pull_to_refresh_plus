# pull_to_refresh_simple

一个功能强大的 Flutter 下拉刷新和上拉加载更多组件，支持多种自定义指示器样式。

[English](README_EN.md) | 简体中文

## 特性

- ✅ 支持下拉刷新和上拉加载更多
- ✅ 内置多种指示器样式（Classic、Material、WaterDrop）
- ✅ 支持完全自定义的 Header 和 Footer
- ✅ 支持 ListView、GridView、CustomScrollView 等多种滚动组件
- ✅ 支持全局配置
- ✅ 支持国际化
- ✅ 完善的状态管理

## 安装

在 `pubspec.yaml` 文件中添加依赖：

```yaml
dependencies:
  pull_to_refresh_simple: ^1.0.0
```

然后运行：

```bash
flutter pub get
```

## 基本用法

### 1. 导入包

```dart
import 'package:pull_to_refresh_simple/pull_to_refresh.dart';
```

### 2. 创建 RefreshController

```dart
final RefreshController _refreshController = RefreshController(initialRefresh: false);
```

### 3. 使用 SmartRefresher 组件

```dart
SmartRefresher(
  controller: _refreshController,
  enablePullDown: true,  // 启用下拉刷新
  enablePullUp: true,    // 启用上拉加载
  onRefresh: _onRefresh,
  onLoading: _onLoading,
  header: const ClassicHeader(),
  footer: const ClassicFooter(),
  child: ListView.builder(
    itemCount: items.length,
    itemBuilder: (context, index) {
      return ListTile(title: Text('Item $index'));
    },
  ),
)
```

### 4. 实现刷新和加载回调

```dart
void _onRefresh() async {
  // 执行刷新逻辑
  await fetchData();
  // 结束刷新
  _refreshController.refreshCompleted();
}

void _onLoading() async {
  // 执行加载更多逻辑
  await loadMoreData();
  // 结束加载
  _refreshController.loadComplete();
}
```

### 5. 释放资源

```dart
@override
void dispose() {
  _refreshController.dispose();
  super.dispose();
}
```

## 完整示例

```dart
import 'package:flutter/material.dart';
import 'package:pull_to_refresh_simple/pull_to_refresh.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final RefreshController _refreshController = RefreshController(initialRefresh: false);
  List<int> _items = List.generate(20, (index) => index);

  void _onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    setState(() {
      _items = List.generate(20, (index) => index);
    });
    _refreshController.refreshCompleted();
  }

  void _onLoading() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    setState(() {
      final int length = _items.length;
      _items.addAll(List.generate(20, (index) => length + index));
    });
    _refreshController.loadComplete();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Pull to Refresh Plus')),
        body: SmartRefresher(
          controller: _refreshController,
          enablePullDown: true,
          enablePullUp: true,
          onRefresh: _onRefresh,
          onLoading: _onLoading,
          header: const ClassicHeader(),
          footer: const ClassicFooter(),
          child: ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: _items.length,
            itemBuilder: (context, index) {
              return Container(
                height: 100,
                margin: const EdgeInsets.only(bottom: 10),
                color: Colors.grey,
                child: Center(
                  child: Text(
                    'Item ${_items[index]}',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
```

## 内置指示器

### Header 指示器

#### 1. ClassicHeader

经典下拉刷新指示器，支持自定义文本和图标。

```dart
SmartRefresher(
  header: const ClassicHeader(
    idleText: '下拉刷新',
    releaseText: '释放刷新',
    refreshingText: '刷新中...',
    completeText: '刷新完成',
    failedText: '刷新失败',
  ),
  // ...
)
```

#### 2. MaterialClassicHeader

Material Design 风格的刷新指示器。

```dart
SmartRefresher(
  header: const MaterialClassicHeader(
    color: Colors.blue,
    backgroundColor: Colors.white,
    distance: 50.0,
  ),
  // ...
)
```

#### 3. WaterDropMaterialHeader

带水滴效果的 Material 风格指示器。

```dart
SmartRefresher(
  header: const WaterDropMaterialHeader(
    color: Colors.white,
    backgroundColor: Colors.blue,
    distance: 60.0,
  ),
  // ...
)
```

### Footer 指示器

#### ClassicFooter

经典上拉加载指示器。

```dart
SmartRefresher(
  footer: const ClassicFooter(
    idleText: '上拉加载',
    loadingText: '加载中...',
    noDataText: '没有更多数据',
    failedText: '加载失败',
    canLoadingText: '释放加载',
  ),
  // ...
)
```

## 自定义指示器

### 自定义 Header

使用 `CustomHeader` 创建完全自定义的下拉刷新指示器：

```dart
class MyCustomHeader extends StatefulWidget {
  const MyCustomHeader({super.key});

  @override
  State<MyCustomHeader> createState() => _MyCustomHeaderState();
}

class _MyCustomHeaderState extends State<MyCustomHeader> {
  @override
  Widget build(BuildContext context) {
    return CustomHeader(
      refreshStyle: RefreshStyle.follow,
      height: 100,
      onOffsetChange: (offset) {
        // 偏移量变化回调
      },
      onModeChange: (mode) {
        // 状态变化回调
      },
      builder: (context, mode) {
        // 根据不同状态返回不同的 UI
        if (mode == RefreshStatus.refreshing) {
          return const CircularProgressIndicator();
        } else if (mode == RefreshStatus.completed) {
          return const Text('刷新完成');
        } else {
          return const Text('下拉刷新');
        }
      },
    );
  }
}
```

### 自定义 Footer

使用 `CustomFooter` 创建完全自定义的上拉加载指示器：

```dart
class MyCustomFooter extends StatefulWidget {
  const MyCustomFooter({super.key});

  @override
  State<MyCustomFooter> createState() => _MyCustomFooterState();
}

class _MyCustomFooterState extends State<MyCustomFooter> {
  @override
  Widget build(BuildContext context) {
    return CustomFooter(
      height: 50,
      onModeChange: (mode) {
        // 状态变化回调
      },
      builder: (context, mode) {
        if (mode == LoadStatus.loading) {
          return const CircularProgressIndicator();
        } else if (mode == LoadStatus.noMore) {
          return const Text('没有更多数据');
        } else {
          return const Text('上拉加载');
        }
      },
    );
  }
}
```

## RefreshController API

### 刷新相关方法

```dart
// 手动触发刷新
_refreshController.requestRefresh();

// 刷新成功
_refreshController.refreshCompleted();

// 刷新失败
_refreshController.refreshFailed();

// 直接结束刷新（不显示成功或失败状态）
_refreshController.refreshToIdle();
```

### 加载相关方法

```dart
// 手动触发加载
_refreshController.requestLoading();

// 加载成功
_refreshController.loadComplete();

// 加载失败
_refreshController.loadFailed();

// 没有更多数据
_refreshController.loadNoData();

// 重置无数据状态
_refreshController.resetNoData();
```

### 状态属性

```dart
// 当前头部状态
RefreshStatus? status = _refreshController.headerStatus;

// 当前底部状态
LoadStatus? status = _refreshController.footerStatus;

// 是否正在刷新
bool isRefreshing = _refreshController.isRefresh;

// 是否正在加载
bool isLoading = _refreshController.isLoading;
```

## 全局配置

使用 `RefreshConfiguration` 为子树中的所有 SmartRefresher 提供全局配置：

```dart
RefreshConfiguration(
  headerBuilder: () => const ClassicHeader(),
  footerBuilder: () => const ClassicFooter(),
  headerTriggerDistance: 80.0,
  footerTriggerDistance: 15.0,
  springDescription: const SpringDescription(
    mass: 1.0,
    stiffness: 364.72,
    damping: 35.2,
  ),
  enableScrollWhenRefreshCompleted: true,
  enableLoadingWhenFailed: true,
  enableBallisticLoad: true,
  child: MaterialApp(
    home: YourHomePage(),
  ),
)
```

### 配置参数说明

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| headerBuilder | IndicatorBuilder? | - | 全局默认 Header 构建器 |
| footerBuilder | IndicatorBuilder? | - | 全局默认 Footer 构建器 |
| headerTriggerDistance | double | 80.0 | 触发刷新的距离 |
| footerTriggerDistance | double | 15.0 | 触发加载的距离 |
| dragSpeedRatio | double | 1.0 | 拖动速度比例 |
| maxOverScrollExtent | double? | - | 最大过度滚动距离 |
| maxUnderScrollExtent | double? | - | 最大不足滚动距离 |
| enableScrollWhenRefreshCompleted | bool | false | 刷新完成回弹时是否允许滚动 |
| enableLoadingWhenFailed | bool | true | 失败状态下是否允许加载 |
| enableLoadingWhenNoData | bool | false | 无数据状态下是否允许加载 |
| enableBallisticLoad | bool | true | 是否通过 BallisticScrollActivity 触发加载 |
| enableSmartPreload | bool | true | 是否启用智能预加载 |
| hideFooterWhenNotFull | bool | false | 内容不满一页时是否隐藏 Footer |

## 状态枚举

### RefreshStatus（刷新状态）

| 状态 | 说明 |
|------|------|
| idle | 初始状态，未被拖动 |
| canRefresh | 拖动距离足够，释放后将触发刷新 |
| refreshing | 刷新中 |
| completed | 刷新完成 |
| failed | 刷新失败 |

### LoadStatus（加载状态）

| 状态 | 说明 |
|------|------|
| idle | 初始状态，可以触发加载 |
| canLoading | 拖动距离足够，释放后将触发加载 |
| loading | 加载中 |
| noMore | 没有更多数据 |
| failed | 加载失败 |

## 刷新样式

### RefreshStyle（Header 显示样式）

| 样式 | 说明 |
|------|------|
| follow | 指示器始终跟随内容移动 |
| unFollow | 指示器跟随内容移动，到达顶部后不再跟随 |
| behind | 指示器大小随边界距离缩放，显示在内容后面 |
| front | 类似 Flutter 原生 RefreshIndicator，显示在内容上方 |

### LoadStyle（Footer 显示样式）

| 样式 | 说明 |
|------|------|
| showAlways | 始终占据布局范围 |
| hideAlways | 始终不占据布局范围 |
| showWhenLoading | 仅在加载状态下占据布局范围 |

## 注意事项

1. **必须结束状态**：在 `onRefresh` 和 `onLoading` 回调中，必须调用相应的结束方法（如 `refreshCompleted()`、`loadComplete()`），否则会一直保持刷新或加载状态。

2. **Controller 生命周期**：记得在 `dispose()` 方法中调用 `_refreshController.dispose()` 释放资源。

3. **一个 Controller 对应一个 SmartRefresher**：不要将同一个 RefreshController 用于多个 SmartRefresher，这会导致意外错误。

4. **避免嵌套滚动**：如果 child 内部包含可滚动组件，建议使用 CustomScrollView 或 SmartRefresher.builder 构造函数。

## 常见问题

### 1. 刷新/加载状态无法结束？

确保在 `onRefresh` 和 `onLoading` 回调中调用了相应的结束方法。

### 2. 如何禁用下拉刷新或上拉加载？

设置 `enablePullDown: false` 或 `enablePullUp: false`。

### 3. 如何手动触发刷新？

调用 `_refreshController.requestRefresh()` 方法。

### 4. 如何显示"没有更多数据"？

调用 `_refreshController.loadNoData()` 方法。

### 5. 如何重置"没有更多数据"状态？

调用 `_refreshController.resetNoData()` 方法。

## 许可证

MIT License

---

**其他语言**: [English](README_EN.md)
