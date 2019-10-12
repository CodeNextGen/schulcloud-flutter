import 'dart:convert';

import 'package:cached_listview/cached_listview.dart';
import 'package:flutter/foundation.dart';
import 'package:schulcloud/app/app.dart';
import 'package:schulcloud/courses/courses.dart';
import 'package:repository/repository.dart';

import 'data.dart';

class Bloc {
  CacheController<Homework> homework;
  CacheController<Submission> submissions;

  Bloc({@required NetworkService network, @required UserService user})
      : assert(network != null),
        assert(user != null),
        homework = HiveCacheController<Homework>(
          name: 'homework',
          fetcher: () async {
            var response = await network.get('homework');
            var body = json.decode(response.body);

            return [
              for (var data in body['data'] as List<dynamic>)
                Homework(
                  id: Id(data['_id']),
                  schoolId: data['schoolId'],
                  teacherId: data['teacherId'],
                  name: data['name'],
                  description: data['description'],
                  availableDate: DateTime.tryParse(data['availableDate']) ??
                      DateTime.now(),
                  dueDate: DateTime.parse(data['dueDate']),
                  course: Course(
                    id: Id<Course>(data['courseId']['_id']),
                    name: data['courseId']['name'],
                    description: data['courseId']['description'] ??
                        'No description provided',
                    teachers: [
                      for (String id in data['courseId']['teacherIds'])
                        await user.getUser(Id<User>(id)),
                    ],
                    color: hexStringToColor(data['courseId']['color']),
                  ),
                  lessonId: Id(data['lessonId'] ?? ''),
                  private: data['private'],
                ),
            ];
          },
        ),
        submissions = HiveCacheController<Submission>(
          name: 'submissions',
          fetcher: () async {
            var response = await network.get('submissions');
            var body = json.decode(response.body);

            return [
              for (var data in body['data'] as List<dynamic>)
                Submission(
                  id: Id(data['_id']),
                  schoolId: data['schoolId'],
                  homeworkId: Id(data['homeworkId']),
                  studentId: Id(data['studentId']),
                  comment: data['comment'],
                  grade: data['grade'],
                  gradeComment: data['gradeComment'],
                ),
            ];
          },
        );

  Stream<Submission> getSubmissionForHomework(Id<Homework> homeworkId) async* {
    yield await submissions.updates
        .where((update) => update.hasData)
        .map((update) => update.data)
        .map((all) => all.firstWhere(
              (submission) => submission.homeworkId == homeworkId,
              orElse: () => null,
            ))
        .firstWhere((submission) => submission != null);
  }
}
