import 'package:flutter/material.dart';
import 'package:photocurator/common/theme/colors.dart';
import 'package:photocurator/common/bar/view/app_bar.dart';
import 'package:flutter/material.dart';
import 'package:photocurator/common/theme/colors.dart';
import 'package:photocurator/common/bar/view/detail_app_bar.dart';
import 'package:photocurator/common/widgets/photo_item.dart';
import 'package:photocurator/common/widgets/photo_screen_widget.dart';

class LikeScreen extends StatefulWidget {
  const LikeScreen({Key? key}) : super(key: key);

  @override
  _LikeScreenState createState() => _LikeScreenState();
}

class _LikeScreenState extends BasePhotoContent<LikeScreen> {
  @override
  String get viewType => 'PICKED';

  @override
  String get screenTitle => '좋아요';

  // 그룹핑 필요 없으므로 null 반환
  @override
  String? get groupBy => null;
}
