import 'package:flutter/material.dart';

// Global navigator key to use for navigation from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Navigation service to handle navigation from anywhere in the app
/// without requiring a BuildContext
class NavigationService extends ChangeNotifier {
  static final NavigationService _instance = NavigationService._internal();

  // Singleton instance
  static NavigationService get instance => _instance;

  NavigationService._internal();

  // Track the current route
  String _currentRoute = '';

  /// Get the current active route
  String get currentRoute => _currentRoute;

  /// Update the current route and notify listeners
  void _updateCurrentRoute(String route) {
    _currentRoute = route;
    notifyListeners();
  }

  /// Navigate to a new route with a delay if the Navigator isn't ready
  Future<T?> navigateTo<T>(String routeName, {Object? arguments}) async {
    _updateCurrentRoute(routeName);
    if (navigatorKey.currentState == null) {
      // Delay navigation until the Navigator is ready
      await Future.delayed(const Duration(milliseconds: 100));
      if (navigatorKey.currentState != null) {
        return navigatorKey.currentState!.pushNamed<T>(routeName, arguments: arguments);
      } else {
        debugPrint('NavigationService: Navigator not ready for $routeName');
        return null;
      }
    }
    return navigatorKey.currentState!.pushNamed<T>(routeName, arguments: arguments);
  }

  /// Replace the current route with a new one
  Future<T?> replaceTo<T>(String routeName, {Object? arguments}) async {
    _updateCurrentRoute(routeName);
    if (navigatorKey.currentState == null) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (navigatorKey.currentState != null) {
        return navigatorKey.currentState!.pushReplacementNamed<T, dynamic>(
          routeName,
          arguments: arguments,
        );
      } else {
        debugPrint('NavigationService: Navigator not ready for $routeName');
        return null;
      }
    }
    return navigatorKey.currentState!.pushReplacementNamed<T, dynamic>(
      routeName,
      arguments: arguments,
    );
  }

  /// Go back to the previous route
  void goBack<T>([T? result]) {
    if (navigatorKey.currentState == null) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (navigatorKey.currentState != null && navigatorKey.currentState!.canPop()) {
          navigatorKey.currentState!.pop<T>(result);
        }
      });
      return;
    }
    if (navigatorKey.currentState!.canPop()) {
      navigatorKey.currentState!.pop<T>(result);
    }
  }

  /// Navigate to a route and remove all previous routes
  Future<T?> navigateToAndRemoveUntil<T>(String routeName, {Object? arguments}) async {
    _updateCurrentRoute(routeName);
    if (navigatorKey.currentState == null) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (navigatorKey.currentState != null) {
        return navigatorKey.currentState!.pushNamedAndRemoveUntil<T>(
          routeName,
          (route) => false,
          arguments: arguments,
        );
      } else {
        debugPrint('NavigationService: Navigator not ready for $routeName');
        return null;
      }
    }
    return navigatorKey.currentState!.pushNamedAndRemoveUntil<T>(
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }
}