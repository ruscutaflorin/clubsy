import 'package:get/get.dart';
import 'package:clubsy/data/classes/club_model.dart';
import 'package:clubsy/services/admin_service.dart';
import 'package:clubsy/services/api_client.dart';

enum AdminClubFilter { all, pending, approved }

class AdminController extends GetxController {
  final AdminService _service;

  AdminController({AdminService? service})
    : _service = service ?? AdminService();

  final clubs = <ClubModel>[].obs;
  final filter = AdminClubFilter.all.obs;
  final isLoading = false.obs;
  final loadError = RxnString();

  /// Last approve/unapprove failure, shown by the page after a rollback.
  final actionError = RxnString();

  /// QR data URLs by club id.
  final qrCodes = <String, String>{}.obs;

  int get allCount => clubs.length;
  int get pendingCount => clubs.where((c) => !c.isApproved).length;
  int get approvedCount => clubs.where((c) => c.isApproved).length;

  List<ClubModel> get filtered => switch (filter.value) {
    AdminClubFilter.all => clubs.toList(),
    AdminClubFilter.pending => clubs.where((c) => !c.isApproved).toList(),
    AdminClubFilter.approved => clubs.where((c) => c.isApproved).toList(),
  };

  Future<void> load() async {
    isLoading.value = true;
    loadError.value = null;
    try {
      clubs.assignAll(await _service.listAllClubs());
    } on ApiException catch (e) {
      loadError.value = e.message;
    } catch (_) {
      loadError.value = 'Something went wrong, please try again';
    } finally {
      isLoading.value = false;
    }
  }

  /// Flips approval immediately and rolls back if the server refuses.
  Future<bool> setApproved(String id, bool approved) async {
    final index = clubs.indexWhere((c) => c.id == id);
    if (index < 0) return false;
    final previous = clubs[index];
    actionError.value = null;
    clubs[index] = _withApproval(previous, approved);
    try {
      if (approved) {
        await _service.approve(id);
      } else {
        await _service.unapprove(id);
      }
      return true;
    } catch (e) {
      final i = clubs.indexWhere((c) => c.id == id);
      if (i >= 0) clubs[i] = previous;
      actionError.value = e is ApiException
          ? e.message
          : 'Something went wrong, please try again';
      return false;
    }
  }

  Future<String> loadQr(String id) async {
    final qr = await _service.getQr(id);
    qrCodes[id] = qr;
    return qr;
  }

  Future<String> rotateQr(String id) async {
    final qr = await _service.rotateQr(id);
    qrCodes[id] = qr;
    return qr;
  }

  ClubModel _withApproval(ClubModel c, bool approved) =>
      ClubModel.fromMap({...c.toMap(), 'isApproved': approved});
}
