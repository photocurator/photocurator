// hide_screen.dart
import 'package:flutter/material.dart';
import 'package:photocurator/common/widgets/photo_screen_widget.dart';
import 'package:photocurator/common/widgets/photo_item.dart';
import 'package:provider/provider.dart';

import '../../../provider/current_project_provider.dart';


class HideScreen extends StatefulWidget {
  const HideScreen({Key? key}) : super(key: key);

  @override
  State<HideScreen> createState() => _HideScreenState();
}

class _HideScreenState extends BasePhotoScreen<HideScreen> {
  @override
  String get screenTitle => "숨긴 사진";

  @override
  String get viewType => "HIDDEN"; // Provider에서 숨긴 사진을 가져옴
}

