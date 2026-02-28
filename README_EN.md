# pull_to_refresh_simple

A powerful Flutter pull-to-refresh and pull-up-to-load-more widget with multiple customizable indicator styles.

English | [简体中文](README.md)

## Features

- ✅ Support pull-down refresh and pull-up load more
- ✅ Built-in multiple indicator styles (Classic, Material, WaterDrop)
- ✅ Support fully customizable Header and Footer
- ✅ Support ListView, GridView, CustomScrollView and other scrollable widgets
- ✅ Support global configuration
- ✅ Support internationalization
- ✅ Complete state management

## Installation

Add dependency to your `pubspec.yaml`:

```yaml
dependencies:
  pull_to_refresh_simple: ^3.0.1
```

Then run:

```bash
flutter pub get
```

## Basic Usage

### 1. Import the package

```dart
import 'package:pull_to_refresh_simple/pull_to_refresh.dart';
```

### 2. Create RefreshController

```dart
final RefreshController _refreshController = RefreshController(initialRefresh: false);
```

### 3. Use SmartRefresher widget

```dart
SmartRefresher(
  controller: _refreshController,
  enablePullDown: true,  // Enable pull-down refresh
  enablePullUp: true,    // Enable pull-up load
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

### 4. Implement refresh and load callbacks

```dart
void _onRefresh() async {
  // Execute refresh logic
  await fetchData();
  // End refresh
  _refreshController.refreshCompleted();
}

void _onLoading() async {
  // Execute load more logic
  await loadMoreData();
  // End loading
  _refreshController.loadComplete();
}
```

### 5. Dispose resources

```dart
@override
void dispose() {
  _refreshController.dispose();
  super.dispose();
}
```

## Complete Example

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

## Built-in Indicators

### Header Indicators

#### 1. ClassicHeader

Classic pull-down refresh indicator, supports custom text and icons.

```dart
SmartRefresher(
  header: const ClassicHeader(
    idleText: 'Pull down to refresh',
    releaseText: 'Release to refresh',
    refreshingText: 'Refreshing...',
    completeText: 'Refresh completed',
    failedText: 'Refresh failed',
  ),
  // ...
)
```

#### 2. MaterialClassicHeader

Material Design style refresh indicator.

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

Material style indicator with water drop effect.

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

### Footer Indicators

#### ClassicFooter

Classic pull-up load indicator.

```dart
SmartRefresher(
  footer: const ClassicFooter(
    idleText: 'Pull up to load',
    loadingText: 'Loading...',
    noDataText: 'No more data',
    failedText: 'Load failed',
    canLoadingText: 'Release to load',
  ),
  // ...
)
```

## Custom Indicators

### Custom Header

Use `CustomHeader` to create fully customized pull-down refresh indicators:

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
        // Offset change callback
      },
      onModeChange: (mode) {
        // State change callback
      },
      builder: (context, mode) {
        // Return different UI based on different states
        if (mode == RefreshStatus.refreshing) {
          return const CircularProgressIndicator();
        } else if (mode == RefreshStatus.completed) {
          return const Text('Refresh completed');
        } else {
          return const Text('Pull down to refresh');
        }
      },
    );
  }
}
```

### Custom Footer

Use `CustomFooter` to create fully customized pull-up load indicators:

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
        // State change callback
      },
      builder: (context, mode) {
        if (mode == LoadStatus.loading) {
          return const CircularProgressIndicator();
        } else if (mode == LoadStatus.noMore) {
          return const Text('No more data');
        } else {
          return const Text('Pull up to load');
        }
      },
    );
  }
}
```

## RefreshController API

### Refresh Methods

```dart
// Manually trigger refresh
_refreshController.requestRefresh();

// Refresh successful
_refreshController.refreshCompleted();

// Refresh failed
_refreshController.refreshFailed();

// End refresh directly (without showing success or failure state)
_refreshController.refreshToIdle();
```

### Load Methods

```dart
// Manually trigger loading
_refreshController.requestLoading();

// Load successful
_refreshController.loadComplete();

// Load failed
_refreshController.loadFailed();

// No more data
_refreshController.loadNoData();

// Reset no data state
_refreshController.resetNoData();
```

### State Properties

```dart
// Current header status
RefreshStatus? status = _refreshController.headerStatus;

// Current footer status
LoadStatus? status = _refreshController.footerStatus;

// Is refreshing
bool isRefreshing = _refreshController.isRefresh;

// Is loading
bool isLoading = _refreshController.isLoading;
```

## Global Configuration

Use `RefreshConfiguration` to provide global configuration for all SmartRefresher widgets in the subtree:

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

### Configuration Parameters

| Parameter                        | Type              | Default | Description                                                        |
| -------------------------------- | ----------------- | ------- | ------------------------------------------------------------------ |
| headerBuilder                    | IndicatorBuilder? | -       | Global default Header builder                                      |
| footerBuilder                    | IndicatorBuilder? | -       | Global default Footer builder                                      |
| headerTriggerDistance            | double            | 80.0    | Distance to trigger refresh                                        |
| footerTriggerDistance            | double            | 15.0    | Distance to trigger load                                           |
| dragSpeedRatio                   | double            | 1.0     | Drag speed ratio                                                   |
| maxOverScrollExtent              | double?           | -       | Maximum over scroll distance                                       |
| maxUnderScrollExtent             | double?           | -       | Maximum under scroll distance                                      |
| enableScrollWhenRefreshCompleted | bool              | false   | Whether to allow scrolling when refresh completes and bounces back |
| enableLoadingWhenFailed          | bool              | true    | Whether to allow loading in failed state                           |
| enableLoadingWhenNoData          | bool              | false   | Whether to allow loading when no data                              |
| enableBallisticLoad              | bool              | true    | Whether to trigger loading through BallisticScrollActivity         |
| enableSmartPreload               | bool              | true    | Whether to enable smart preload                                    |
| hideFooterWhenNotFull            | bool              | false   | Whether to hide Footer when content is less than one page          |

## State Enums

### RefreshStatus (Refresh State)

| Status     | Description                                               |
| ---------- | --------------------------------------------------------- |
| idle       | Initial state, not dragged                                |
| canRefresh | Drag distance is sufficient, release will trigger refresh |
| refreshing | Refreshing                                                |
| completed  | Refresh completed                                         |
| failed     | Refresh failed                                            |

### LoadStatus (Load State)

| Status     | Description                                            |
| ---------- | ------------------------------------------------------ |
| idle       | Initial state, can trigger load                        |
| canLoading | Drag distance is sufficient, release will trigger load |
| loading    | Loading                                                |
| noMore     | No more data                                           |
| failed     | Load failed                                            |

## Refresh Styles

### RefreshStyle (Header Display Style)

| Style    | Description                                                            |
| -------- | ---------------------------------------------------------------------- |
| follow   | Indicator always follows content movement                              |
| unFollow | Indicator follows content movement, stops following after reaching top |
| behind   | Indicator size scales with boundary distance, displayed behind content |
| front    | Similar to Flutter native RefreshIndicator, displayed above content    |

### LoadStyle (Footer Display Style)

| Style           | Description                             |
| --------------- | --------------------------------------- |
| showAlways      | Always occupies layout space            |
| hideAlways      | Never occupies layout space             |
| showWhenLoading | Only occupies layout space when loading |

## Notes

1. **Must end state**: In `onRefresh` and `onLoading` callbacks, you must call the corresponding end methods (such as `refreshCompleted()`, `loadComplete()`), otherwise it will remain in refresh or load state.

2. **Controller lifecycle**: Remember to call `_refreshController.dispose()` in the `dispose()` method to release resources.

3. **One Controller per SmartRefresher**: Do not use the same RefreshController for multiple SmartRefresher widgets, this will cause unexpected errors.

4. **Avoid nested scrolling**: If the child contains scrollable widgets, it is recommended to use CustomScrollView or SmartRefresher.builder constructor.

## FAQ

### 1. Refresh/Load state cannot end?

Make sure to call the corresponding end methods in `onRefresh` and `onLoading` callbacks.

### 2. How to disable pull-down refresh or pull-up load?

Set `enablePullDown: false` or `enablePullUp: false`.

### 3. How to manually trigger refresh?

Call `_refreshController.requestRefresh()` method.

### 4. How to show "No more data"?

Call `_refreshController.loadNoData()` method.

### 5. How to reset "No more data" state?

Call `_refreshController.resetNoData()` method.

## License

MIT License

---

**Other Languages**: [简体中文](README.md)
