import 'package:flutter/foundation.dart';
import 'package:schulcloud/app/services.dart';
import 'package:schulcloud/core/data.dart';
import 'package:schulcloud/core/data/repositories.dart';
import 'package:schulcloud/core/data/repository.dart';
import 'package:schulcloud/core/data/utils.dart';
import 'package:schulcloud/homework/data/homework.dart';
import 'package:schulcloud/homework/data/repository.dart';

class Bloc {
  final ApiService api;
  Repository<Homework> _homework;
  Repository<Submission> _submissions;

  Bloc({@required this.api})
      : _homework = CachedRepository<Homework>(
          source: HomeworkDownloader(api: api),
          cache: InMemoryStorage(),
        ),
        _submissions = CachedRepository<Submission>(
          source: SubmissionDownloader(api: api),
          cache: InMemoryStorage(),
        );

  Stream<List<Homework>> getHomework() =>
      streamToBehaviorSubject(_homework.fetchAllItems());

  Stream<List<Submission>> listSubmissions() =>
      streamToBehaviorSubject(_submissions.fetchAllItems());

  Stream<Submission> submissionForHomework(Id<Homework> homeworkId) async* {
    var submission;
    await for (var s in _submissions.fetchAllItems()) {
      submission = submission ??
          s.firstWhere((i) => i.homeworkId == homeworkId, orElse: () => null);
      if (submission != null) break;
    }
    yield submission;
  }

  void refresh() => _homework.clear();
}