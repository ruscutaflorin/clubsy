import 'package:clubsy/data/classes/club_model.dart';
import 'package:clubsy/services/admin_service.dart';
import 'package:clubsy/services/api_client.dart';
import 'package:clubsy/services/auth_service.dart';
import 'package:clubsy/src/core/controllers/admin_controller.dart';
import 'package:clubsy/src/core/controllers/auth_controller.dart';
import 'package:clubsy/src/core/controllers/club_controller.dart';
import 'package:clubsy/src/core/controllers/theme_controller.dart';
import 'package:clubsy/views/pages/admin/admin_club_qr_page.dart';
import 'package:clubsy/views/pages/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

ClubModel club(String id, bool approved) => ClubModel(
  id: id,
  name: 'Club $id',
  address: 'a',
  city: 'Cluj',
  latitude: 1,
  longitude: 1,
  imageUrl: 'https://x/y.png',
  isApproved: approved,
);

class FakeAdminService extends AdminService {
  bool fail = false;
  String qr = 'v1';

  @override
  Future<List<ClubModel>> listAllClubs() async => [
    club('a', true),
    club('b', false),
    club('c', false),
  ];

  @override
  Future<void> approve(String id) async {
    if (fail) throw ApiException(500, 'boom');
  }

  @override
  Future<void> unapprove(String id) async {
    if (fail) throw ApiException(500, 'boom');
  }

  @override
  Future<String> getQr(String id) async => qr;

  @override
  Future<String> rotateQr(String id) async => 'rotated';
}

class RoleAuthService extends AuthService {
  final String role;
  RoleAuthService(this.role);

  Map<String, dynamic> get _user => {'name': 'N', 'email': 'e', 'role': role};

  @override
  Future<bool> isAuthenticated() async => true;

  @override
  Future<Map<String, dynamic>?> getUser() async => _user;

  @override
  Future<Map<String, dynamic>> fetchMe() async => _user;
}

const pngDataUrl =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AdminController', () {
    late FakeAdminService service;
    late AdminController c;

    setUp(() async {
      service = FakeAdminService();
      c = AdminController(service: service);
      await c.load();
    });

    test('filter counts', () {
      expect(c.allCount, 3);
      expect(c.pendingCount, 2);
      expect(c.approvedCount, 1);
      c.filter.value = AdminClubFilter.pending;
      expect(c.filtered.map((x) => x.id), ['b', 'c']);
    });

    test('optimistic approve succeeds', () async {
      expect(await c.setApproved('b', true), isTrue);
      expect(c.pendingCount, 1);
    });

    test('approve rolls back when the service throws', () async {
      service.fail = true;
      expect(await c.setApproved('b', true), isFalse);
      expect(c.clubs.firstWhere((x) => x.id == 'b').isApproved, isFalse);
      expect(c.actionError.value, 'boom');
    });

    test('rotate replaces the stored QR', () async {
      await c.loadQr('a');
      expect(c.qrCodes['a'], 'v1');
      await c.rotateQr('a');
      expect(c.qrCodes['a'], 'rotated');
    });
  });

  group('widgets', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      Get.testMode = true;
    });
    tearDown(Get.reset);

    Future<void> pumpProfile(WidgetTester tester, String role) async {
      Get.put(AuthController(authService: RoleAuthService(role)));
      Get.put(ThemeController());
      Get.put(ClubController());
      await tester.pumpWidget(const MaterialApp(home: ProfilePage()));
      await tester.pump();
      await tester.pump();
    }

    testWidgets('Admin tile hidden for USER', (tester) async {
      await pumpProfile(tester, 'USER');
      expect(find.byKey(const Key('adminTile')), findsNothing);
    });

    testWidgets('Admin tile shown for ADMIN', (tester) async {
      await pumpProfile(tester, 'ADMIN');
      await tester.scrollUntilVisible(find.byKey(const Key('adminTile')), 300);
      expect(find.byKey(const Key('adminTile')), findsOneWidget);
    });

    testWidgets('QR page renders an Image from a data URL', (tester) async {
      final service = FakeAdminService()..qr = pngDataUrl;
      Get.put(AdminController(service: service));
      await tester.pumpWidget(
        MaterialApp(home: AdminClubQrPage(club: club('a', true))),
      );
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const Key('adminQrImage')), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });
  });
}
