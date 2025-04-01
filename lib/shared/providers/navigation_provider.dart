import 'package:flutter/material.dart';

class NavigationProvider extends ChangeNotifier {
  static final NavigationProvider instance = NavigationProvider._internal();
  PageController? _pageController;
  int _currentIndex = 0;

  NavigationProvider._internal();

  PageController? get pageController => _pageController;
  int get currentIndex => _currentIndex;

  void initialize(PageController controller) {
    _pageController = controller;
  }

  void setCurrentIndex(int index) {
    _currentIndex = index;
    notifyListeners(); // Notify MainNavigationController to update the page
  }
}