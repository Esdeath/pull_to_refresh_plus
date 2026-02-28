import 'package:example/refresh_footer.dart';
import 'package:example/refresh_header.dart';
import 'package:flutter/material.dart';
import 'package:pull_to_refresh_plus/pull_to_refresh.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  List<int> _items = List.generate(20, (index) => index);

  void _onRefresh() async {
    // 模拟网络请求
    await Future.delayed(const Duration(milliseconds: 1500));
    // 清空数据并重新生成
    setState(() {
      _items = List.generate(20, (index) => index);
    });
    // 结束刷新状态
    _refreshController.refreshCompleted();
  }

  void _onLoading() async {
    // 模拟网络请求
    await Future.delayed(const Duration(milliseconds: 1500));
    // 添加新数据
    setState(() {
      final int length = _items.length;
      _items.addAll(List.generate(20, (index) => length + index));
    });
    // 结束加载状态
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
        appBar: AppBar(
          title: const Text('Pull to Refresh Plus'),
        ),
        body: SmartRefresher(
          controller: _refreshController,
          enablePullDown: true,
          enablePullUp: true,
          onRefresh: _onRefresh,
          onLoading: _onLoading,
          header: const RefreshDefaultHeader(),
          footer: const RefreshDefaultFooter(),
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
