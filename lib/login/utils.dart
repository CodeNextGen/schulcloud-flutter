import 'package:flutter/widgets.dart';
import 'package:pedantic/pedantic.dart';
import 'package:schulcloud/app/app.dart';

import 'login.dart';

Future<void> logOut(BuildContext context) async {
  // This should probably be awaited, but right now awaiting it
  // leads to the issue that logging out becomes impossible
  unawaited(services.get<StorageService>().clear());

  final navigator = context.rootNavigator..popUntil((route) => route.isFirst);
  unawaited(navigator.pushReplacement(TopLevelPageRoute(
    builder: (_) => LoginScreen(),
  )));
}