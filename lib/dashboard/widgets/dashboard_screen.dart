import 'package:flutter/material.dart';

import 'package:schulcloud/app/widgets.dart';

class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: MyAppBar(),
      body: Center(child: FlutterLogo()),
    );
  }
}
