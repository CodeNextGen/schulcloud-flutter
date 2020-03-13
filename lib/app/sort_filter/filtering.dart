import 'package:black_hole_flutter/black_hole_flutter.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_text_patterns.dart';

import '../datetime_utils.dart';
import '../utils.dart';
import 'sort_filter.dart';

typedef Test<T, D> = bool Function(T item, D data);
typedef Selector<T, R> = R Function(T item);

abstract class Filter<T, S> {
  const Filter(this.titleGetter) : assert(titleGetter != null);

  S get defaultSelection;

  final L10nStringGetter titleGetter;

  S tryParseWebQuerySorter(Map<String, String> query, String key);

  bool filter(T item, S selection);
  Widget buildWidget(
    BuildContext context,
    S selection,
    DataChangeCallback<S> updater,
  );

  Iterable<T> apply(Iterable<T> items, S selection) {
    if (selection == null) {
      return items;
    }
    return items.where((item) => filter(item, selection));
  }
}

@immutable
class DateRangeFilter<T> extends Filter<T, DateRangeFilterSelection> {
  const DateRangeFilter(
    L10nStringGetter titleGetter, {
    this.defaultSelection = const DateRangeFilterSelection(),
    this.webQueryKey,
    @required this.selector,
  })  : assert(selector != null),
        assert(defaultSelection != null),
        super(titleGetter);

  @override
  final DateRangeFilterSelection defaultSelection;

  final Selector<T, LocalDate> selector;
  final String webQueryKey;

  @override
  DateRangeFilterSelection tryParseWebQuerySorter(
      Map<String, String> query, String key) {
    LocalDate tryParse(String value) {
      if (value == null) {
        return null;
      }
      return LocalDatePattern.iso.parse(value).TryGetValue(null);
    }

    final prefix = webQueryKey ?? key;
    return DateRangeFilterSelection(
      start: tryParse(query['${prefix}From']),
      end: tryParse(query['${prefix}To']),
    );
  }

  @override
  bool filter(T item, DateRangeFilterSelection selection) {
    final date = selector(item);
    final start = selection.start ?? LocalDate.minIsoValue;
    final end = selection.end ?? LocalDate.maxIsoValue;
    return date == null || (start <= date && date <= end);
  }

  @override
  Widget buildWidget(
    BuildContext context,
    DateRangeFilterSelection selection,
    DataChangeCallback<DateRangeFilterSelection> updater,
  ) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _buildDateField(
            date: selection.start,
            hintText: 'from',
            onChanged: (newStart) => updater(selection.withStart(newStart)),
            lastDate: selection.end,
          ),
        ),
        SizedBox(width: 4),
        Text('–'),
        SizedBox(width: 4),
        Expanded(
          child: _buildDateField(
            date: selection.end,
            hintText: 'until',
            onChanged: (newEnd) => updater(selection.withEnd(newEnd)),
            firstDate: selection.start,
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    LocalDate date,
    @required String hintText,
    void Function(LocalDate) onChanged,
    LocalDate firstDate,
    LocalDate lastDate,
  }) {
    return DateTimeField(
      initialValue: date?.toDateTimeUnspecified(),
      format: DateFormat.yMd(),
      onShowPicker: (context, current) => showDatePicker(
        context: context,
        initialDate: date?.toDateTimeUnspecified() ?? DateTime.now(),
        firstDate: firstDate?.toDateTimeUnspecified() ?? DateTime(1900),
        lastDate: lastDate?.toDateTimeUnspecified() ?? DateTime(2100),
      ),
      onChanged: (newDate) => onChanged(newDate?.asLocalDate),
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.calendar_today),
        hintText: hintText,
      ),
    );
  }
}

@immutable
class DateRangeFilterSelection {
  const DateRangeFilterSelection({this.start, this.end})
      : assert(start == null || end == null || start <= end,
            'start must be before end');

  final LocalDate start;
  final LocalDate end;

  DateRangeFilterSelection withStart(LocalDate start) =>
      DateRangeFilterSelection(start: start, end: end);
  DateRangeFilterSelection withEnd(LocalDate end) =>
      DateRangeFilterSelection(start: start, end: end);
}

@immutable
class FlagsFilter<T> extends Filter<T, Map<String, bool>> {
  const FlagsFilter(L10nStringGetter titleGetter, {@required this.filters})
      : assert(filters != null),
        super(titleGetter);

  @override
  Map<String, bool> get defaultSelection {
    return {
      for (final entry in filters.entries)
        entry.key: entry.value.defaultSelection,
    };
  }

  final Map<String, FlagFilter<T>> filters;

  @override
  Map<String, bool> tryParseWebQuerySorter(
      Map<String, String> query, String key) {
    return {
      for (final entry in filters.entries)
        entry.key: entry.value.tryParseWebQuerySorter(query, entry.key),
    };
  }

  @override
  Widget buildWidget(
    BuildContext context,
    Map<String, bool> selection,
    DataChangeCallback<Map<String, bool>> updater,
  ) {
    return ChipGroup(
      children: filters.entries.map((e) {
        final key = e.key;
        final filter = e.value;
        final filterData = selection[key];

        Widget avatar;
        if (filterData == true) {
          avatar = Icon(Icons.check);
        } else if (filterData == false) {
          avatar = Icon(Icons.close);
        }

        return FilterChip(
          avatar: avatar,
          label: Text(filter.titleGetter(context.s)),
          onSelected: (value) {
            final newValue = {
              null: true,
              true: false,
              false: null,
            }[filterData];

            updater(selection.copyWith(key, newValue));
          },
        );
      }).toList(),
    );
  }

  @override
  bool filter(T item, Map<String, bool> selection) =>
      filters.keys.every((k) => filters[k].apply(item, selection[k]));
}

typedef SetFlagFilterCallback<T> = void Function(String key, bool value);

@immutable
class FlagFilter<T> {
  const FlagFilter(
    this.titleGetter, {
    this.defaultSelection,
    this.webQueryKey,
    @required this.selector,
  })  : assert(titleGetter != null),
        assert(selector != null);

  final L10nStringGetter titleGetter;
  final bool defaultSelection;
  final String webQueryKey;
  final Selector<T, bool> selector;

  bool tryParseWebQuerySorter(Map<String, String> query, String key) {
    return {
      'true': true,
      'false': false,
    }[query[webQueryKey ?? key]];
  }

  // ignore: avoid_positional_boolean_parameters
  bool apply(T item, bool selection) {
    if (selection == null) {
      return true;
    }
    return selector(item) == selection;
  }
}

class FlagFilterPreviewChip<T> extends StatelessWidget {
  const FlagFilterPreviewChip({
    Key key,
    @required this.flag,
    @required this.callback,
    @required this.icon,
    @required this.label,
  })  : assert(flag != null),
        assert(callback != null),
        assert(icon != null),
        assert(label != null),
        super(key: key);

  final String flag;
  final SetFlagFilterCallback<T> callback;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon),
      label: Text(label),
      onPressed: () => callback(flag, true),
    );
  }
}
