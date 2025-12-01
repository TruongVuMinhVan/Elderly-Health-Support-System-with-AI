import 'package:flutter/material.dart';

/// Mixin để tự động reload data khi screen được push/pop hoặc khi app resume
/// 
/// Usage:
/// ```dart
/// class MyScreen extends StatefulWidget {
///   @override
///   _MyScreenState createState() => _MyScreenState();
/// }
/// 
/// class _MyScreenState extends State<MyScreen> with AutoRefreshMixin {
///   @override
///   void initState() {
///     super.initState();
///     _loadData();
///   }
/// 
///   Future<void> _loadData() async {
///     // Load your data here
///   }
/// 
///   @override
///   Future<void> onRefresh() async {
///     await _loadData();
///   }
/// }
/// ```
mixin AutoRefreshMixin<T extends StatefulWidget> on State<T>, RouteAware {
  bool _isFirstLoad = true;
  bool _shouldRefreshOnResume = true;

  /// Override this method to define what should be refreshed
  Future<void> onRefresh();

  /// Set to false if you don't want to auto-refresh when app resumes
  void setShouldRefreshOnResume(bool value) {
    _shouldRefreshOnResume = value;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Register route observer
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      // Get route observer from context (should be provided in MaterialApp)
      final routeObserver = RouteObserver<PageRoute>();
      routeObserver.subscribe(this, route);
    }

    // Auto-refresh on first load (after dependencies are available)
    if (_isFirstLoad) {
      _isFirstLoad = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          onRefresh();
        }
      });
    }
  }

  @override
  void didPopNext() {
    // Called when the top route has been popped off, and this route shows up
    // This means we're coming back to this screen
    if (mounted && _shouldRefreshOnResume) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          onRefresh();
        }
      });
    }
  }

  @override
  void didPushNext() {
    // Called when a new route has been pushed, and this route is no longer visible
    // Do nothing here
  }

  @override
  void didPush() {
    // Called when the current route has been pushed
    // Do nothing here
  }

  @override
  void didPop() {
    // Called when the current route has been popped off
    // Do nothing here
  }

  @override
  void dispose() {
    // Unsubscribe from route observer
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      final routeObserver = RouteObserver<PageRoute>();
      routeObserver.unsubscribe(this);
    }
    super.dispose();
  }
}

/// Simplified version using WidgetsBindingObserver (easier to use)
/// 
/// Usage:
/// ```dart
/// class _MyScreenState extends State<MyScreen> with AutoRefreshMixinSimple {
///   @override
///   void initState() {
///     super.initState();
///     _loadData();
///   }
/// 
///   Future<void> _loadData() async {
///     // Load your data here
///   }
/// 
///   @override
///   Future<void> onRefresh() async {
///     await _loadData();
///   }
/// }
/// ```
mixin AutoRefreshMixinSimple<T extends StatefulWidget> on State<T>, WidgetsBindingObserver {
  bool _isFirstLoad = true;
  bool _shouldRefreshOnResume = true;
  DateTime? _lastRefreshTime;

  /// Override this method to define what should be refreshed
  Future<void> onRefresh();

  /// Set to false if you don't want to auto-refresh when app resumes
  void setShouldRefreshOnResume(bool value) {
    _shouldRefreshOnResume = value;
  }

  /// Check if we should refresh (e.g., if last refresh was more than X seconds ago)
  bool shouldRefresh({Duration? minInterval}) {
    if (_lastRefreshTime == null) return true;
    if (minInterval == null) return true;
    return DateTime.now().difference(_lastRefreshTime!) > minInterval;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Auto-refresh on first load (after dependencies are available)
    if (_isFirstLoad) {
      _isFirstLoad = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          onRefresh().then((_) {
            _lastRefreshTime = DateTime.now();
          });
        }
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Refresh when app resumes (comes back from background)
    if (state == AppLifecycleState.resumed && 
        mounted && 
        _shouldRefreshOnResume &&
        shouldRefresh(minInterval: const Duration(seconds: 5))) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          onRefresh().then((_) {
            _lastRefreshTime = DateTime.now();
          });
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

