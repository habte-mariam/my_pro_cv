import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'database_helper.dart';

class ProfileService {
  static final _supabase = Supabase.instance.client;

  static Future<Map<String, dynamic>?> searchAndSyncByEmail(
      String email) async {
    try {
      debugPrint("Searching in Supabase for: $email...");

      // 1. መጀመሪያ ከ Supabase ትኩስ ዳታ መኖሩን ማረጋገጥ
      final response = await _supabase.from('profiles').select('''
            *,
            education(*),
            experience(*),
            skills(*),
            languages(*),
            certificates(*),
            user_references(*)
          ''').ilike('email', email.trim()).maybeSingle();

      if (response != null) {
        debugPrint("Data found in Supabase! Syncing to Local... ☁️");

        // 2. ዳታውን ማስተካከል (Boolean to Int ወዘተ)
        final processedData = _sanitizeSupabaseData(response);

        // 3. ወደ Local SQLite ሴቭ ማድረግ (ይህ የድሮውን ያድሳል)
        await DatabaseHelper.instance.syncFullDataToLocal(processedData);

        // 4. አሁን ከ SQLite ሙሉውን (በ _fixMapping የተስተካከለውን) ዳታ ማንበብ
        return await DatabaseHelper.instance.getFullProfile(email: email);
      }

      // 5. Supabase ላይ ከሌለ (ለምሳሌ ኢንተርኔት ከሌለ) Local ላይ ያለውን መሞከር
      debugPrint("No profile found in Supabase. Checking Local SQLite...");
      return await DatabaseHelper.instance.getFullProfile(email: email);
    } catch (e) {
      debugPrint("Search/Sync Error: $e");
      // ኤረር ካለ (ለምርሳል ኢንተርኔት ከጠፋ) በትንሹ Local ላይ ያለውን ለማሳየት መሞከር
      return await DatabaseHelper.instance.getFullProfile(email: email);
    }
  }

  // 🛠️ ዳታውን ለ SQLite 'int' እና 'String' ፎርማት የሚያስተካክል ረዳት
  static Map<String, dynamic> _sanitizeSupabaseData(Map<String, dynamic> data) {
    final Map<String, dynamic> sanitized = Map<String, dynamic>.from(data);

    // 1. Experience ውስጥ ያለውን boolean ወደ int መቀየር
    if (sanitized['experience'] != null && sanitized['experience'] is List) {
      sanitized['experience'] = (sanitized['experience'] as List).map((exp) {
        final expMap = Map<String, dynamic>.from(exp);
        // Supabase boolean (true/false) -> SQLite int (1/0)
        expMap['isCurrentlyWorking'] =
            (expMap['isCurrentlyWorking'] == true) ? 1 : 0;
        return expMap;
      }).toList();
    }

    // 2. ID-ዎችን ማስተካከል (Supabase 'profileid' ነው የሚጠቀመው)
    final String uuid = sanitized['profileid']?.toString() ?? "";
    sanitized['id'] = uuid;

    return sanitized;
  }
}
