import 'package:flutter/material.dart';
import 'package:flutter_cached/flutter_cached.dart';
import 'package:provider/provider.dart';
import 'package:schulcloud/app/app.dart';
import 'package:schulcloud/calendar/bloc.dart';
import 'package:schulcloud/calendar/data.dart';
import 'package:schulcloud/dashboard/widgets/dashboard_card.dart';
import 'package:time_machine/time_machine.dart';

class CalendarDashboardCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Provider.value(
      value: Bloc(
        storage: Provider.of<StorageService>(context),
        network: Provider.of<NetworkService>(context),
        userFetcher: Provider.of<UserFetcherService>(context),
      ),
      child: DashboardCard(
        title: 'Schedule',
        child: Consumer<Bloc>(
          builder: (context, bloc, _) =>
              StreamBuilder<CacheUpdate<List<Event>>>(
            stream: bloc.fetchTodaysEvents(),
            initialData: CacheUpdate(isFetching: false),
            builder: (context, snapshot) {
              assert(snapshot.hasData);

              final update = snapshot.data;
              if (!update.hasData) {
                return Center(
                    child: update.hasError
                        ? Text(update.error.toString())
                        : CircularProgressIndicator());
              }

              final now = Instant.now();
              final events = update.data.where((e) => e.end > now);
              return Column(
                children: events.map((e) => _EventPreview(event: e)).toList(),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _EventPreview extends StatelessWidget {
  const _EventPreview({Key key, @required this.event})
      : assert(event != null),
        super(key: key);

  final Event event;

  @override
  Widget build(BuildContext context) {
    final now = Instant.now();
    final theme = Theme.of(context);
    final hasStarted = event.start <= now;

    Widget widget = ListTile(
      title: Text(
        event.title,
        style: hasStarted ? theme.textTheme.headline : theme.textTheme.subhead,
      ),
      trailing: DefaultTextStyle(
        style: theme.textTheme.caption,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Text(event.location),
            Text(event.localStart.clockTime.toString('t')),
          ],
        ),
      ),
    );

    final durationMicros = event.duration.inMicroseconds;
    if (hasStarted && durationMicros != 0) {
      widget = Column(
        children: <Widget>[
          widget,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LinearProgressIndicator(
              value: now.timeSince(event.start).inMicroseconds / durationMicros,
            ),
          )
        ],
      );
    }
    return widget;
  }
}
