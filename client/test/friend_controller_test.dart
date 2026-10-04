import 'package:flutter_test/flutter_test.dart';

import 'package:clubsy/data/classes/admin_report_model.dart';
import 'package:clubsy/data/classes/friend_model.dart';
import 'package:clubsy/services/api_client.dart';
import 'package:clubsy/services/friend_service.dart';
import 'package:clubsy/src/core/controllers/friend_controller.dart';

FriendEntry entry(String id, String username) =>
    FriendEntry(id: id, userId: 'u-$id', username: username, name: 'N $id');

class FakeFriendService implements FriendService {
  FriendsOverview overview = const FriendsOverview();
  final calls = <String>[];
  ApiException? failWith;

  Future<void> _record(String call) async {
    calls.add(call);
    if (failWith != null) throw failWith!;
  }

  @override
  Future<FriendsOverview> getFriends() async => overview;

  @override
  Future<void> sendRequest(String username) => _record('send:$username');

  @override
  Future<void> accept(String id) => _record('accept:$id');

  @override
  Future<void> decline(String id) => _record('decline:$id');

  @override
  Future<void> cancel(String id) => _record('cancel:$id');

  @override
  Future<void> unfriend(String id) => _record('unfriend:$id');

  List<FriendEntry> blocked = [];

  @override
  Future<List<FriendEntry>> getBlocked() async => blocked;

  @override
  Future<void> block(String userId) => _record('block:$userId');

  @override
  Future<void> unblock(String userId) => _record('unblock:$userId');

  @override
  Future<void> report(String userId, String reason, {String? details}) =>
      _record('report:$userId:$reason:$details');
}

void main() {
  late FakeFriendService service;
  late FriendController controller;

  setUp(() {
    service = FakeFriendService();
    controller = FriendController(service: service);
  });

  test('load fills the three lists and the pending badge count', () async {
    service.overview = FriendsOverview(
      friends: [entry('a', 'amy')],
      incoming: [entry('b', 'bob'), entry('c', 'cat')],
      outgoing: [entry('d', 'dan')],
    );
    await controller.load();
    expect(controller.friends.single.label, '@amy');
    expect(controller.pendingCount, 2);
    expect(controller.outgoing.single.id, 'd');
  });

  test(
    'sendRequest strips @ and whitespace and gives a neutral notice',
    () async {
      expect(await controller.sendRequest('  @Bob_1 '), isTrue);
      expect(service.calls, ['send:Bob_1']);
      expect(controller.notice.value, contains('If that username exists'));
    },
  );

  test('sendRequest ignores a blank username', () async {
    expect(await controller.sendRequest(' @ '), isFalse);
    expect(service.calls, isEmpty);
  });

  test('sendRequest surfaces a server error and sets no notice', () async {
    service.failWith = ApiException(
      400,
      "You can't send a friend request to yourself",
    );
    expect(await controller.sendRequest('me'), isFalse);
    expect(controller.error.value, contains('yourself'));
    expect(controller.notice.value, isNull);
  });

  test(
    'accept, decline, cancel and unfriend call the matching endpoint',
    () async {
      final e = entry('x', 'xan');
      await controller.accept(e);
      await controller.decline(e);
      await controller.cancel(e);
      await controller.unfriend(e);
      expect(service.calls, [
        'accept:x',
        'decline:x',
        'cancel:x',
        'unfriend:x',
      ]);
    },
  );

  test('a failed action keeps the error and still reloads', () async {
    service.failWith = ApiException(404, 'Friend request not found');
    service.overview = FriendsOverview(incoming: [entry('z', 'zed')]);
    await controller.accept(entry('z', 'zed'));
    expect(controller.error.value, 'Friend request not found');
    expect(controller.incoming, hasLength(1));
  });

  test('block goes by user id then refreshes the blocked list', () async {
    service.blocked = [entry('x', 'xan')];
    await controller.block(entry('x', 'xan'));
    expect(service.calls, ['block:u-x']);
    expect(controller.blocked.single.label, '@xan');
  });

  test('unblock calls the endpoint and refreshes the blocked list', () async {
    service.blocked = [entry('x', 'xan')];
    await controller.loadBlocked();
    expect(controller.blocked, hasLength(1));
    service.blocked = [];
    await controller.unblock(entry('x', 'xan'));
    expect(service.calls, ['unblock:u-x']);
    expect(controller.blocked, isEmpty);
  });

  test('report sends trimmed details and reports a failure', () async {
    expect(
      await controller.report(entry('x', 'xan'), 'SPAM', details: ' junk '),
      isTrue,
    );
    expect(service.calls, ['report:u-x:SPAM:junk']);
    service.failWith = ApiException(404, 'User not found');
    expect(await controller.report(entry('x', 'xan'), 'SPAM'), isFalse);
    expect(controller.error.value, 'User not found');
  });

  test('AdminReport carries the flag and open count from the server', () {
    final r = AdminReport.fromMap({
      'id': 'r1',
      'reason': 'HARASSMENT',
      'details': null,
      'status': 'OPEN',
      'openReports': 3,
      'flagged': true,
      'reporter': {'id': 'a', 'username': 'amy', 'name': 'Amy'},
      'reportedUser': {'id': 'b', 'username': null, 'name': 'Bo'},
    });
    expect(r.flagged, isTrue);
    expect(r.openReports, 3);
    expect(r.reasonLabel, 'Harassment');
    expect(r.reportedLabel, 'Bo');
    expect(r.reporterLabel, '@amy');
  });

  test('FriendEntry falls back to the name when there is no username', () {
    final e = FriendEntry.fromMap({
      'id': 'f',
      'user': {'id': 'u', 'username': null, 'name': 'Sam'},
    });
    expect(e.label, 'Sam');
  });
}
