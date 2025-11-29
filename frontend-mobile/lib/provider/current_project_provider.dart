import 'package:flutter/material.dart';

class CurrentProjectProvider extends ChangeNotifier {
  String? _projectId;

  String? get projectId => _projectId;

  void setProjectId(String id) {
    _projectId = id;
    notifyListeners(); // 변경되면 구독하고 있는 위젯들 rebuild
  }
}
