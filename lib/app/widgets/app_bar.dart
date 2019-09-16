import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'menu.dart';
import 'schulcloud_app.dart';

/// A custom version of an app bar intended to be displayed at the bottom of
/// the screen. You can also also [register] and [unregister] actions on the
/// [_MyAppBarState]. The [MyAppBarActions] does that.
class MyAppBar extends StatefulWidget {
  final void Function(Screen route) onNavigate;
  final Stream<Screen> activeScreenStream;
  final List<Widget> actions;

  MyAppBar({
    @required this.onNavigate,
    @required this.activeScreenStream,
    this.actions = const [],
  })  : assert(onNavigate != null),
        assert(actions != null);

  @override
  _MyAppBarState createState() => _MyAppBarState();
}

class _MyAppBarState extends State<MyAppBar> {
  final _actionsByState = <State<MyAppBarActions>, List<Widget>>{};
  final _actions = <Widget>[];

  void register(State<MyAppBarActions> state, List<Widget> actions) {
    _actions.addAll(actions);
    _actionsByState[state] = actions;
  }

  void unregister(State<MyAppBarActions> state) {
    final actionsToRemove = _actionsByState.remove(state);
    _actions.removeWhere(actionsToRemove.contains);
  }

  Future<void> _showMenu(BuildContext context) async {
    Screen target = await Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, __, ___) =>
          Menu(activeScreenStream: widget.activeScreenStream),
      opaque: false,
      maintainState: true,
      transitionsBuilder: _customDialogTransitionBuilder,
    ));
    if (target != null) {
      widget.onNavigate(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).primaryColor,
      elevation: 12,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.center,
        child: IconTheme(
          data: IconThemeData(color: Colors.white),
          child: Row(
            children: <Widget>[
              IconButton(
                icon: Icon(Icons.menu),
                onPressed: () => _showMenu(context),
              ),
              Spacer(),
              ...widget.actions,
            ],
          ),
        ),
      ),
    );
  }
}

/// A widget that adds actions to the enclosing [MyAppBar].
class MyAppBarActions extends StatefulWidget {
  final List<Widget> actions;
  final Widget child;

  MyAppBarActions({@required this.actions, @required this.child})
      : assert(actions != null),
        assert(child != null);

  _MyAppBarActionsState createState() => _MyAppBarActionsState();
}

class _MyAppBarActionsState extends State<MyAppBarActions> {
  _MyAppBarState _findEnclosingMyAppBar() =>
      context.ancestorStateOfType(TypeMatcher<MyAppBar>());

  @override
  void initState() {
    super.initState();
    _findEnclosingMyAppBar().register(this, widget.actions);
  }

  @override
  void dispose() {
    _findEnclosingMyAppBar().unregister(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

Widget _customDialogTransitionBuilder(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return Stack(
    children: <Widget>[
      FadeTransition(
        opacity: animation,
        child: GestureDetector(
          onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
          child: Container(color: Colors.black45),
        ),
      ),
      SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutQuad,
        )),
        child: Align(alignment: Alignment.bottomCenter, child: child),
      ),
    ],
  );
}
