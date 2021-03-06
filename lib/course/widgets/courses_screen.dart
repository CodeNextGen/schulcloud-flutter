import 'package:flutter/material.dart';
import 'package:schulcloud/app/app.dart';

import '../data.dart';
import 'course_card.dart';

class CoursesScreen extends SortFilterWidget<Course> {
  CoursesScreen({
    SortFilterSelection<Course> sortFilterSelection,
  }) : super(sortFilterSelection ?? sortFilterConfig.defaultSelection);

  static final sortFilterConfig = SortFilter<Course>(
    sorters: {
      'name': Sorter<Course>.name(
        (s) => s.general_entity_property_name,
        selector: (course) => course.name,
      ),
      'createdAt': Sorter<Course>.simple(
        (s) => s.general_entity_property_createdAt,
        selector: (course) => course.createdAt,
      ),
      'updatedAt': Sorter<Course>.simple(
        (s) => s.general_entity_property_updatedAt,
        selector: (course) => course.updatedAt,
      ),
      'color': Sorter<Course>.simple(
        (s) => s.course_course_property_color,
        selector: (course) => course.color.hsv.hue,
      ),
    },
    defaultSorter: 'name',
    filters: {
      'more': FlagsFilter<Course>(
        (s) => s.general_entity_property_more,
        filters: {
          'isArchived': FlagFilter<Course>(
            (s) => s.general_entity_property_isArchived,
            selector: (course) => course.isArchived,
            defaultSelection: false,
          ),
        },
      ),
    },
  );

  @override
  _CoursesScreenState createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen>
    with SortFilterStateMixin<CoursesScreen, Course> {
  @override
  Widget build(BuildContext context) {
    final s = context.s;

    return Scaffold(
      body: CollectionBuilder.populated<Course>(
        collection: services.storage.root.courses,
        builder: handleLoadingErrorRefreshEmptyFilter(
          appBar: FancyAppBar(
            title: Text(s.course),
            actions: <Widget>[SortFilterIconButton(showSortFilterSheet)],
          ),
          emptyStateBuilder: (context) => EmptyStateScreen(
            text: s.course_coursesScreen_empty,
          ),
          sortFilterSelection: sortFilterSelection,
          filteredEmptyStateBuilder: (context) => SortFilterEmptyState(
            showSortFilterSheet,
            text: s.course_coursesScreen_emptyFiltered,
          ),
          builder: (context, courses, fetch) {
            return CustomScrollView(
              slivers: <Widget>[
                SliverList(
                  delegate: SliverChildBuilderDelegate((_, index) {
                    return Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: CourseCard(courses[index]),
                    );
                  }, childCount: courses.length),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
