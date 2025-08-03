import 'package:an_viewmodel/src/ext/value_notifier_ext.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Builder;
import 'package:flutter/widgets.dart' as widgets;

typedef ErrorBuilder = Widget Function(
    BuildContext context, Object error, StackTrace? stackTrace);
typedef WidgetBuilder = Widget Function(BuildContext context);
typedef ErrorBuilderToSliver = Widget Function(BuildContext context,
    Widget errorWidget, Object error, StackTrace? stackTrace);
typedef LoadingBuilderToSliver = Widget Function(
    BuildContext context, Widget loadingWidget);
typedef ValueBuilder<T> = Widget Function(BuildContext context, T value);
typedef ValueAndChildBuilder<T> = Widget Function(
    BuildContext context, T value, Widget child);
typedef ValueListItemBuilder<T> = Widget Function(
    BuildContext context, T value, int index);

Widget _errorBuilder(
        BuildContext context, Object error, StackTrace? stackTrace) =>
    const SizedBox.shrink();

Widget _loadingBuilder(BuildContext context) =>
    const Center(child: CircularProgressIndicator());

Widget _errorBuilderToSliver(BuildContext context, Widget errorWidget,
        Object error, StackTrace? stackTrace) =>
    SliverToBoxAdapter(child: errorWidget);

Widget _loadingSliverBuilder(BuildContext context, Widget loadingWidget) =>
    SliverFillRemaining(child: loadingWidget);

extension ValueNotifierBuilderExt<T> on ValueListenable<T> {
  /// 快速构建一个ValueListenableBuilder
  /// ignore: non_constant_identifier_names
  Widget Builder({
    required ValueAndChildBuilder<T> builder,
    Widget child = const SizedBox.shrink(),
    Key? key,
  }) {
    return ValueListenableBuilder<T>(
      key: key,
      valueListenable: this,
      builder: (context, value, _) {
        return builder(context, value, child);
      },
    );
  }
}

extension ValueNotifierAsyncBuilderExt<T extends Object>
    on ValueListenable<AsyncData<T>> {
  /// 快速构建一个ValueListenableBuilder
  /// * 内部类型为 AsyncData&lt;T> <br>
  /// * [sliver] 是否对配置信息启用sliver 转换 <br>
  /// ignore: non_constant_identifier_names
  Widget Builder2({
    Key? key,
    required ValueAndChildBuilder<T> builder,
    Widget child = const SizedBox.shrink(),
    ErrorBuilder? errorBuilder,
    WidgetBuilder? loadingBuilder,
    LoadingBuilderToSliver? loadingBuilderToSliver,
    ErrorBuilderToSliver? errorBuilderToSliver,
    bool sliver = false,
  }) {
    return ValueListenableBuilder<AsyncData<T>>(
      key: key,
      valueListenable: this,
      builder: (context, value, _) {
        return value.when(
          loading: () {
            loadingBuilder ??= context.config.loadingBuilder;
            if (sliver) {
              loadingBuilderToSliver ??= context.config.loadingBuilderToSliver;
              return loadingBuilderToSliver!(
                  context, widgets.Builder(builder: loadingBuilder!));
            } else {
              return loadingBuilder!(context);
            }
          },
          error: (error, stackTrace) {
            errorBuilder ??= context.config.errorBuilder;
            if (sliver) {
              errorBuilderToSliver ??= context.config.errorBuilderToSliver;
              return errorBuilderToSliver!(
                  context,
                  widgets.Builder(
                      builder: (context) =>
                          errorBuilder!(context, error, stackTrace)),
                  error,
                  stackTrace);
            } else {
              return errorBuilder!(context, error, stackTrace);
            }
          },
          value: (data) => builder(context, data, child),
        );
      },
      child: child,
    );
  }
}

const ValueNotifierBuilderConfig _defaultConfig = ValueNotifierBuilderConfig(
    errorBuilder: _errorBuilder,
    loadingBuilder: _loadingBuilder,
    errorBuilderToSliver: _errorBuilderToSliver,
    loadingBuilderToSliver: _loadingSliverBuilder,
    child: SizedBox.shrink());

/// 可以配置如何展示 loading 和error 相关
class ValueNotifierBuilderConfig extends InheritedWidget {
  /// 错误布局时如何展示 非sliver
  final ErrorBuilder errorBuilder;

  /// 加载时的布局如何展示 非sliver
  final WidgetBuilder loadingBuilder;

  /// 如何将错误的布局转换为sliver
  final ErrorBuilderToSliver errorBuilderToSliver;

  /// 如何将加载的布局转换为sliver
  final LoadingBuilderToSliver loadingBuilderToSliver;

  const ValueNotifierBuilderConfig({
    super.key,
    required super.child,
    required this.errorBuilder,
    required this.loadingBuilder,
    required this.errorBuilderToSliver,
    required this.loadingBuilderToSliver,
  });

  /// 从当前上下文中合并配置
  static Widget merge({
    Key? key,
    required Widget child,
    ErrorBuilder? errorBuilder,
    WidgetBuilder? loadingBuilder,
    ErrorBuilderToSliver? errorBuilderToSliver,
    LoadingBuilderToSliver? loadingSliverBuilder,
  }) {
    return widgets.Builder(builder: (context) {
      return ValueNotifierBuilderConfig(
        key: key,
        errorBuilder: errorBuilder ?? context.config.errorBuilder,
        loadingBuilder: loadingBuilder ?? context.config.loadingBuilder,
        errorBuilderToSliver:
            errorBuilderToSliver ?? context.config.errorBuilderToSliver,
        loadingBuilderToSliver:
            loadingSliverBuilder ?? context.config.loadingBuilderToSliver,
        child: child,
      );
    });
  }

  static ValueNotifierBuilderConfig of(BuildContext context) {
    final ValueNotifierBuilderConfig? result = context
        .dependOnInheritedWidgetOfExactType<ValueNotifierBuilderConfig>();
    return result ?? _defaultConfig;
  }

  @override
  bool updateShouldNotify(ValueNotifierBuilderConfig oldWidget) {
    return oldWidget.loadingBuilder != loadingBuilder ||
        oldWidget.errorBuilder != errorBuilder ||
        oldWidget.errorBuilderToSliver != errorBuilderToSliver ||
        oldWidget.loadingBuilderToSliver != loadingBuilderToSliver;
  }
}

extension on BuildContext {
  ValueNotifierBuilderConfig get config => ValueNotifierBuilderConfig.of(this);
}

extension ValueNotifierListBuilderExt<T> on ValueListenable<List<T>> {
  /// 快速 从 ValueListenableBuilder 构建一个 ListView
  /// *  内部类型为 List&lt;T>
  /// *  [sliver] 是否对配置信息启用sliver 转换
  /// ignore: non_constant_identifier_names
  Widget BuilderList({
    required ValueListItemBuilder<T> itemBuilder,
    ValueBuilder<int>? separatorBuilder,
    WidgetBuilder? emptyBuilder,
    Key? key,
    bool sliver = false,
  }) {
    return ValueListenableBuilder<List<T>>(
      key: key,
      valueListenable: this,
      builder: (context, value, _) {
        if (emptyBuilder != null && value.isEmpty) return emptyBuilder(context);
        if (sliver) {
          if (separatorBuilder != null) {
            return SliverList.separated(
              itemCount: value.length,
              itemBuilder: (context, index) =>
                  itemBuilder(context, value[index], index),
              separatorBuilder: separatorBuilder,
            );
          }
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => itemBuilder(context, value[index], index),
              childCount: value.length,
            ),
          );
        }
        if (separatorBuilder != null) {
          return ListView.separated(
            itemCount: value.length,
            itemBuilder: (context, index) =>
                itemBuilder(context, value[index], index),
            separatorBuilder: separatorBuilder,
          );
        } else {
          return ListView.builder(
            itemCount: value.length,
            itemBuilder: (context, index) =>
                itemBuilder(context, value[index], index),
          );
        }
      },
    );
  }
}

extension ValueNotifierAsyncListBuilderExt<T>
    on ValueListenable<AsyncData<List<T>>> {
  /// 快速 从 ValueListenableBuilder 构建一个 ListView
  /// *  内部类型为 AsyncData&lt;List&lt;T>>
  /// *  [sliver] 是否对配置信息启用sliver 转换
  /// ignore: non_constant_identifier_names
  Widget BuilderList2({
    Key? key,
    required ValueListItemBuilder<T> itemBuilder,
    ValueBuilder<int>? separatorBuilder,
    WidgetBuilder? emptyBuilder,
    ErrorBuilder? errorBuilder,
    WidgetBuilder? loadingBuilder,
    LoadingBuilderToSliver? loadingBuilderToSliver,
    ErrorBuilderToSliver? errorBuilderToSliver,
    bool sliver = false,
  }) {
    return Builder2(
      key: key,
      errorBuilder: errorBuilder,
      loadingBuilder: loadingBuilder,
      loadingBuilderToSliver: loadingBuilderToSliver,
      errorBuilderToSliver: errorBuilderToSliver,
      sliver: sliver,
      builder: (context, data, _) {
        if (emptyBuilder != null && data.isEmpty) return emptyBuilder(context);
        if (sliver) {
          if (separatorBuilder != null) {
            return SliverList.separated(
              itemCount: data.length,
              itemBuilder: (context, index) =>
                  itemBuilder(context, data[index], index),
              separatorBuilder: separatorBuilder,
            );
          }
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => itemBuilder(context, data[index], index),
              childCount: data.length,
            ),
          );
        }
        if (separatorBuilder != null) {
          return ListView.separated(
            itemCount: data.length,
            itemBuilder: (context, index) =>
                itemBuilder(context, data[index], index),
            separatorBuilder: separatorBuilder,
          );
        } else {
          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) =>
                itemBuilder(context, data[index], index),
          );
        }
      },
    );
  }
}
