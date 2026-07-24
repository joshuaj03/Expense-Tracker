import 'package:flutter/material.dart';
import 'package:talker_flutter/talker_flutter.dart';
import '../../../../core/utils/logger.dart';

class DeveloperLogScreen extends StatelessWidget {
  const DeveloperLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TalkerScreen(talker: talker, appBarTitle: 'Developer Log');
  }
}
