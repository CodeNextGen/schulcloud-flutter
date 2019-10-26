import 'dart:convert';

import 'package:flutter_cached/flutter_cached.dart';
import 'package:flutter/foundation.dart';
import 'package:schulcloud/app/app.dart';

import 'data.dart';

class Bloc {
  CacheController<List<Article>> articles;

  Bloc({@required NetworkService network})
      : assert(network != null),
        articles = HiveCacheController<Article>(
          parentKey: 'articles',
          fetcher: () async {
            var response = await network.get('news?');
            var body = json.decode(response.body);

            return [
              for (var data in body['data'] as List<dynamic>)
                Article(
                  id: Id<Article>(data['_id']),
                  title: data['title'],
                  authorId: data['creatorId'],
                  author: Author(
                    id: Id<Author>(data['creator']['_id']),
                    name:
                        '${data['creator']['firstName']} ${data['creator']['lastName']}',
                  ),
                  section: 'Section',
                  published: DateTime.parse(data['displayAt']),
                  content: removeHtmlTags(data['content']),
                ),
            ];
          },
        );
}
