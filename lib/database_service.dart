import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'cv_model.dart';
import 'database_helper.dart';
import 'dart:async';

class DatabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;
  User? get _currentUser => _supabase.auth.currentUser;

  /// 1. ወደ ክላውድ መጫን (Sync to Cloud)
  Future<void> saveCompleteCv(CvModel cvData) async {
    final user = _currentUser;
    if (user == null) return;

    try {
      debugPrint("Sync: Starting sync to Cloud...");

      // ለ Supabase Profiles Table የሚሆን ዳታ ማዘጋጀት
      final Map<String, dynamic> profileMap = {
        'profileid': user.id, // UUID
        'firstName': cvData.firstName,
        'lastName': cvData.lastName,
        'jobTitle': cvData.jobTitle,
        'portfolio': cvData.portfolio,
        'email': user.email, // ከ Auth የሚገኝ
        'phone': cvData.phone,
        'phone2': cvData.phone2,
        'address': cvData.address,
        'age': cvData.age,
        'gender': cvData.gender,
        'nationality': cvData.nationality,
        'linkedin': cvData.linkedin,
        'profileImagePath': cvData.profileImagePath,
        'summary': cvData.summary,
        'lastUpdated': DateTime.now().toUtc().toIso8601String(),
      };

      // RPC ጥሪ - Schemaውን መሰረት ያደረገ
      await _supabase.rpc('save_complete_cv', params: {
        'p_id': user.id,
        'p_data': profileMap,
        'p_education': cvData.education,
        'p_references': cvData.user_references,
        // experience ውስጥ boolean ስላለ map አድርገን እንልካለን
        'p_experience': cvData.experience.map((e) {
          final map = Map<String, dynamic>.from(e);
          // SQLite int (0/1) ን ወደ Postgres Boolean መቀየር
          map['isCurrentlyWorking'] = e['isCurrentlyWorking'] == 1;
          return map;
        }).toList(),
        'p_skills': cvData.skills,
        'p_languages': cvData.languages,
        'p_certificates': cvData.certificates,
      });

      debugPrint("Sync: Complete CV data synced to Cloud ✅");
    } catch (e) {
      debugPrint("Supabase RPC Error: $e");
      rethrow;
    }
  }

  Future<void> deleteUserCv() async {
    final user = _currentUser;
    if (user == null) return;

    try {
      await _supabase.from('profiles').delete().eq('id', user.id);
      debugPrint("CV deleted from Cloud successfully ✅");
    } catch (e) {
      debugPrint("Supabase Delete Error: $e");
      rethrow;
    }
  }

  Future<void> syncLocalToCloud() async {
    try {
      final localData = await DatabaseHelper.instance.getFullProfile();
      if (localData != null &&
          localData['firstName'] != null &&
          localData['firstName'].toString().isNotEmpty) {
        CvModel cv = CvModel();
        cv.fromMap(localData);
        await saveCompleteCv(cv);
        debugPrint("Local data synced to Cloud successfully ✅");
      } else {
        debugPrint("No valid local data to sync.");
      }
    } catch (e) {
      debugPrint("Error syncing local data to Cloud: $e");
      rethrow;
    }
  }

  Future<CvModel?> fetchUserCv() async {
    final user = _currentUser;
    if (user == null) return null;

    try {
      debugPrint("Fetching from Cloud for user: ${user.id}");

      // 1. ከ Supabase ዋናውን ፕሮፋይል ማምጣት
      final profileRes = await _supabase
          .from('profiles')
          .select()
          .eq('profileid', user.id)
          .maybeSingle();

      if (profileRes == null) return null;

      // 2. ሁሉንም ዝርዝር ዳታዎች በአንድ ጊዜ ማምጣት
      final results = await Future.wait([
        _supabase.from('education').select().eq('profileid', user.id),
        _supabase.from('experience').select().eq('profileid', user.id),
        _supabase.from('skills').select().eq('profileid', user.id),
        _supabase.from('languages').select().eq('profileid', user.id),
        _supabase.from('certificates').select().eq('profileid', user.id),
        _supabase.from('user_references').select().eq('profileid', user.id),
      ]);

      // 3. ጥቅል Map ማዘጋጀት
      Map<String, dynamic> fullDataMap = Map<String, dynamic>.from(profileRes);
      fullDataMap['education'] = results[0];
      fullDataMap['experience'] = results[1];
      fullDataMap['skills'] = results[2];
      fullDataMap['languages'] = results[3];
      fullDataMap['certificates'] = results[4];
      fullDataMap['user_references'] = results[5];

      // 4. 🔴 ወሳኝ ማሻሻያ፡ መጀመሪያ ሎካል ዳታቤዝ ላይ ሴቭ እናድርግ
      await DatabaseHelper.instance.syncFullDataToLocal(fullDataMap);

      // 5. 🟢 ዳታውን መልሰን ከ SQLite እናንብበው (ይህ IDዎች በትክክል እንዲመጡ ያደርጋል)
      final localData = await DatabaseHelper.instance.getFullProfile();

      if (localData != null) {
        CvModel cv = CvModel();
        cv.fromMap(localData);
        cv.profileid = user.id; // የ Supabase UIDን እንስጠው

        debugPrint("Data fully synced and re-loaded from SQLite ✅");
        return cv;
      }

      return null;
    } catch (e) {
      debugPrint("Supabase Fetch Error: $e");
      return null;
    }
  }
}
