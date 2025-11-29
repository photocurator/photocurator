import 'package:flutter/material.dart';
import 'package:photocurator/common/widgets/photo_screen_widget.dart';

class TrashScreen extends StatefulWidget {
  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends BasePhotoScreen<TrashScreen> {
  @override
  String get viewType => 'TRASH';

  @override
  String get screenTitle => '휴지통';
}
