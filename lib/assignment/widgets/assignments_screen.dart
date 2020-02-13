import 'package:flutter_cached/flutter_cached.dart';
import 'package:collection/collection.dart' show groupBy;
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:schulcloud/app/app.dart';
import 'package:schulcloud/course/course.dart';
import 'package:schulcloud/generated/generated.dart';
import 'package:time_machine/time_machine.dart';

import '../data.dart';
import 'assignment_details_screen.dart';

class AssignmentsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CachedBuilder<List<Assignment>>(
        controller: services.get<StorageService>().root.assignments.controller,
        errorBannerBuilder: (_, error, st) => ErrorBanner(error, st),
        errorScreenBuilder: (_, error, st) => ErrorScreen(error, st),
        builder: (context, assignments) {
          final assignmentsByDueDate = groupBy<Assignment, LocalDate>(
            assignments,
            (a) => a.dueDate.inLocalZone().localDateTime.calendarDate,
          );

          final dates = assignmentsByDueDate.keys.toList()
            ..sort((a, b) => b.compareTo(a));
          return ListView(
            children: [
              for (final date in dates) ...[
                ListTile(title: Text(date.longString)),
                for (final assignment in assignmentsByDueDate[date])
                  AssignmentCard(assignment: assignment),
              ],
            ],
          );
        },
      ),
    );
  }
}

class AssignmentCard extends StatelessWidget {
  const AssignmentCard({@required this.assignment})
      : assert(assignment != null);

  final Assignment assignment;

  void _showAssignmentDetailsScreen(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => AssignmentDetailsScreen(assignment: assignment),
    ));
  }

  void _showCourseDetailScreen(BuildContext context, Course course) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => CourseDetailsScreen(course: course),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      child: InkWell(
        enableFeedback: true,
        onTap: () => _showAssignmentDetailsScreen(context),
        child: Padding(
          padding: EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (assignment.dueDate.isBefore(Instant.now()))
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    Icon(Icons.flag, color: Colors.red),
                    Text(
                      context.s.assignment_assignmentsScreen_overdue,
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              Text(
                assignment.name,
                style: Theme.of(context).textTheme.headline,
              ),
              Html(data: limitString(assignment.description, 200)),
              CachedRawBuilder<Course>(
                controller: assignment.courseId.controller,
                builder: (_, update) {
                  if (!update.hasData) {
                    return Container();
                  }

                  final course = update.data;
                  return ActionChip(
                    backgroundColor: course.color,
                    avatar: Icon(Icons.school),
                    label: Text(course.name),
                    onPressed: () => _showCourseDetailScreen(context, course),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
