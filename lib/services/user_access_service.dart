import 'package:firebase_auth/firebase_auth.dart';

class UserAccessService {
  UserAccessService._();

  static const String administrativeEmail = 'adm@orama.com';

  static String? get currentUserEmail =>
      FirebaseAuth.instance.currentUser?.email?.trim().toLowerCase();

  static bool get isAdministrativeProfile =>
      currentUserEmail == administrativeEmail;

  static bool get canAccessFinancialArea => !isAdministrativeProfile;
}
