import 'package:get/get.dart';
import 'package:clubsy/data/classes/friend_model.dart';
import 'package:clubsy/services/api_client.dart';
import 'package:clubsy/services/friend_service.dart';

class FriendController extends GetxController {
  final FriendService _service;

  /// [service] is injectable so tests don't need real HTTP.
  FriendController({FriendService? service})
    : _service = service ?? FriendService();

  final friends = <FriendEntry>[].obs;
  final incoming = <FriendEntry>[].obs;
  final outgoing = <FriendEntry>[].obs;
  final isLoading = false.obs;
  final error = RxnString();

  /// Set after a request is sent; deliberately identical for every username.
  final notice = RxnString();

  /// Shown as a badge on the Profile entry.
  int get pendingCount => incoming.length;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      final overview = await _service.getFriends();
      friends.assignAll(overview.friends);
      incoming.assignAll(overview.incoming);
      outgoing.assignAll(overview.outgoing);
      error.value = null;
    } on ApiException catch (e) {
      error.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  /// Returns whether the request was accepted by the server. The notice never
  /// says whether the username exists.
  Future<bool> sendRequest(String input) async {
    final username = input.trim().replaceFirst(RegExp(r'^@'), '');
    if (username.isEmpty) return false;
    notice.value = null;
    try {
      await _service.sendRequest(username);
      notice.value = 'If that username exists, a request has been sent.';
      error.value = null;
      await load();
      return true;
    } on ApiException catch (e) {
      error.value = e.message;
      return false;
    }
  }

  Future<void> accept(FriendEntry entry) =>
      _act(() => _service.accept(entry.id));
  Future<void> decline(FriendEntry entry) =>
      _act(() => _service.decline(entry.id));
  Future<void> cancel(FriendEntry entry) =>
      _act(() => _service.cancel(entry.id));
  Future<void> unfriend(FriendEntry entry) =>
      _act(() => _service.unfriend(entry.id));

  Future<void> _act(Future<void> Function() call) async {
    String? failure;
    try {
      await call();
    } on ApiException catch (e) {
      failure = e.message;
    }
    await load();
    if (failure != null) error.value = failure;
  }
}
