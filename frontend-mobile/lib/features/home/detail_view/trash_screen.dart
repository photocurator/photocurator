// trash_screen.dart
import 'package:flutter/material.dart';
import 'package:photocurator/common/widgets/photo_screen_widget.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({Key? key}) : super(key: key);

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends BasePhotoScreen<TrashScreen> {
  @override
  String get screenTitle => "휴지통";

  @override
  String get viewType => "TRASH"; // Provider에서 휴지통 이미지 가져옴
}
