import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_cached/flutter_cached.dart';
import 'package:meta/meta.dart';

import '../app.dart';

@immutable
class UserFetcherService {
  const UserFetcherService();

  CacheController<User> fetchUser(Id<User> id, Id<dynamic> parent) =>
      fetchSingle(
        parent: parent,
        makeNetworkCall: (network) => network.get('users/$id'),
        parser: (data) => User.fromJson(data),
      );

  // The token is a JWT token. JWT tokens consist of a header, body and claim
  // (signature), all separated by dots and encoded in base64. For now, we
  // don't verify the claim, but just decode the body.
  Id<User> getIdOfCurrentUser() {
    final token = services.get<StorageService>().token.getValue();
    final encodedBody = token.split('.')[1];
    final body = String.fromCharCodes(base64.decode(encodedBody));
    return Id<User>(json.decode(body)['userId']);
  }

  CacheController<User> fetchCurrentUser() => fetchSingle(
        makeNetworkCall: (network) => network.get('users/${getIdOfCurrentUser()}'),
        parser: (data) => User.fromJson(data),
      );
}