import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:logger_flutter/logger_flutter.dart';
import 'package:schulcloud/generated/l10n.dart';

import '../app_config.dart';
import '../routing.dart';
import '../services/navigator_observer.dart';
import '../services/storage.dart';
import '../theming_utils.dart';
import '../utils.dart';

class SchulCloudApp extends StatelessWidget {
  static final navigatorKey = GlobalKey<NavigatorState>();
  static NavigatorState get navigator => navigatorKey.currentState;

  @override
  Widget build(BuildContext context) {
    final appConfig = services.get<AppConfig>();
    return MaterialApp(
      title: appConfig.title,
      theme: appConfig.createThemeData(Brightness.light),
      darkTheme: appConfig.createThemeData(Brightness.dark),
      navigatorKey: navigatorKey,
      initialRoute: services.storage.isSignedIn
          ? appSchemeLink('signedInScreen')
          : services.get<AppConfig>().webUrl('login'),
      onGenerateRoute: router.onGenerateRoute,
      navigatorObservers: [
        LoggingNavigatorObserver(),
        HeroController(),
      ],
      localizationsDelegates: [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
    );
  }
}

class LoggedInScreen extends StatefulWidget {
  @override
  _LoggedInScreenState createState() => _LoggedInScreenState();
}

class _LoggedInScreenState extends State<LoggedInScreen> {
  final _navigatorKeys =
      List.generate(_BottomTab.count, (_) => GlobalKey<NavigatorState>());

  var selectedTabIndex = 0;
  NavigatorState get currentNavigator =>
      _navigatorKeys[selectedTabIndex].currentState;

  void selectTab(int index, {bool popIfAlreadySelected = false}) {
    assert(0 <= index && index <= _BottomTab.count);

    final pop = popIfAlreadySelected && selectedTabIndex == index;
    setState(() {
      selectedTabIndex = index;
      if (pop) {
        currentNavigator.popUntil((route) => route.isFirst);
      }
    });
  }

  /// When the user tries to pop, we first try to pop with the inner navigator.
  /// If that's not possible (we are at a top-level location), we go to the
  /// dashboard. Only if we were already there, we pop (aka close the app).
  Future<bool> _onWillPop() async {
    if (currentNavigator.canPop()) {
      currentNavigator.pop();
      return false;
    } else if (selectedTabIndex != 0) {
      selectTab(0);
      return false;
    } else {
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = context.theme;
    final barColor = theme.bottomAppBarColor;

    return LogConsoleOnShake(
      child: WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
          body: IndexedStack(
            index: selectedTabIndex,
            children: <Widget>[
              for (var i = 0; i < _BottomTab.count; i++)
                Navigator(
                  key: _navigatorKeys[i],
                  initialRoute: _BottomTab.values[i].initialRoute,
                  onGenerateRoute: router.onGenerateRoute,
                  observers: [
                    LoggingNavigatorObserver(),
                    HeroController(),
                  ],
                ),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            selectedItemColor: theme.accentColor,
            unselectedItemColor: theme.mediumEmphasisColor,
            currentIndex: selectedTabIndex,
            onTap: (index) => selectTab(index, popIfAlreadySelected: true),
            items: [
              for (final tab in _BottomTab.values)
                BottomNavigationBarItem(
                  icon: Icon(tab.icon),
                  title: Text(tab.title(s)),
                  backgroundColor: barColor,
                )
            ],
          ),
        ),
      ),
    );
  }
}

@immutable
class _BottomTab {
  const _BottomTab({
    @required this.icon,
    @required this.title,
    @required this.initialRoute,
  })  : assert(icon != null),
        assert(title != null),
        assert(initialRoute != null);

  final IconData icon;
  final L10nStringGetter title;
  final String initialRoute;

  static final values = [dashboard, course, assignment, file, news];
  static int get count => values.length;

  // We don't use relative URLs as they would start with a '/' and hence the
  // navigator automatically populates our initial back stack with '/'.
  static final dashboard = _BottomTab(
    icon: Icons.dashboard,
    title: (s) => s.dashboard,
    initialRoute: services.get<AppConfig>().webUrl('dashboard'),
  );
  static final course = _BottomTab(
    icon: Icons.school,
    title: (s) => s.course,
    initialRoute: services.get<AppConfig>().webUrl('courses'),
  );
  static final assignment = _BottomTab(
    icon: Icons.playlist_add_check,
    title: (s) => s.assignment,
    initialRoute: services.get<AppConfig>().webUrl('homework'),
  );
  static final file = _BottomTab(
    icon: Icons.folder,
    title: (s) => s.file,
    initialRoute: services.get<AppConfig>().webUrl('files'),
  );
  static final news = _BottomTab(
    icon: Icons.new_releases,
    title: (s) => s.news,
    initialRoute: services.get<AppConfig>().webUrl('news'),
  );
}
