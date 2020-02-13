import 'package:flutter_cached/flutter_cached.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:schulcloud/app/app.dart';
import 'package:schulcloud/course/course.dart';
import 'package:schulcloud/generated/generated.dart';

import 'file_browser.dart';
import 'page_route.dart';

class FilesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: ListView(
          padding: MediaQuery.of(context).padding +
              const EdgeInsets.symmetric(vertical: 16),
          children: <Widget>[
            _CoursesList(),
            _UserFiles(),
          ],
        ),
      ),
    );
  }
}

class _CoursesList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(context.s.file_files_course),
        ),
        CachedRawBuilder(
          controller: services.get<StorageService>().root.courses.controller
            ..fetch(),
          builder: (context, update) {
            return GridView.extent(
              primary: false,
              shrinkWrap: true,
              maxCrossAxisExtent: 300,
              childAspectRatio: 3.2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: <Widget>[
                for (var course in update.data ?? [])
                  _CourseCard(course: course),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({Key key, this.course}) : super(key: key);

  final Course course;

  void _showCourseFiles(BuildContext context) {
    Navigator.of(context).push(FileBrowserPageRoute(
      builder: (context) => FileBrowser(owner: course),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return FlatMaterial(
      onTap: () => _showCourseFiles(context),
      child: SizedBox(
        height: 48,
        child: Row(
          children: <Widget>[
            Icon(Icons.folder, color: course.color),
            SizedBox(width: 8),
            Expanded(child: Text(course.name)),
          ],
        ),
      ),
    );
  }
}

class _UserFiles extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(context.s.file_files_my),
        ),
        CachedRawBuilder(
          controller: services.get<StorageService>().currentUserId.controller
            ..fetch(),
          builder: (context, update) {
            return update.hasData
                ? FileBrowser(owner: update.data, isEmbedded: true)
                : Container();
          },
        ),
      ],
    );
  }
}

class FlatMaterial extends StatelessWidget {
  const FlatMaterial({
    Key key,
    @required this.onTap,
    @required this.child,
  }) : super(key: key);

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: child,
        ),
      ),
    );
  }
}
