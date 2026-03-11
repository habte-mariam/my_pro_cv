import 'package:path/path.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform, debugPrint;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('cv_pro_final5.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    String path;

    if (kIsWeb) {
      // 1. ዌብ ላይ ከሆንክ ፋብሪካውን ቀይር
      databaseFactory = databaseFactoryFfiWeb;
      // 2. ዌብ ላይ path አያስፈልግም፣ ስሙን ብቻ ተጠቀም
      path = filePath;
    } else {
      // ዴስክቶፕ ከሆነ
      if (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux) {
        databaseFactory = databaseFactoryFfi;
      }
      // 3. ሞባይል ላይ ከሆንክ መደበኛውን path ተጠቀም
      final dbPath = await getDatabasesPath();
      path = join(dbPath, filePath);
    }

    return await openDatabase(
      path,
      version: 22,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  Future _onConfigure(Database db) async {
    // በዌብ ላይ PRAGMA foreign_keys ላይሰራ ስለሚችል በ try-catch ማሰር ይመረጣል
    try {
      await db.execute('PRAGMA foreign_keys = ON');
    } catch (e, stackTrace) {
      // 'print'ን በ 'debugPrint' ይተኩ
      debugPrint("Foreign keys config skipped: $e");
      debugPrint(stackTrace.toString()); // ለበለጠ መረጃ
    }
  }

  Future _createDB(Database db, int version) async {
    // 1. Profile Table
    await db.execute('''
      CREATE TABLE profiles (
        profileid TEXT PRIMARY KEY,
        firstName TEXT, lastName TEXT, jobTitle TEXT,
        gender TEXT, age TEXT, email TEXT, 
        phone TEXT, phone2 TEXT, address TEXT,
        nationality TEXT, summary TEXT, profileImagePath TEXT,
        linkedin TEXT, portfolio TEXT, layoutOrder TEXT, 
        createdAt TEXT, updatedAt TEXT
      )
    ''');

    // 2. Education Table
    await db.execute('''
      CREATE TABLE education (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        profileid TEXT, school TEXT, degree TEXT, field TEXT,
        gradYear TEXT, cgpa TEXT, project TEXT,
        FOREIGN KEY (profileid) REFERENCES profiles (profileid) ON DELETE CASCADE
      )
    ''');

    // 3. Experience Table
    await db.execute('''
      CREATE TABLE experience (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        profileid TEXT, companyName TEXT, jobTitle TEXT,
        startDate TEXT, endDate TEXT, duration TEXT, jobDescription TEXT, achievements TEXT,
        isCurrentlyWorking INTEGER,
        FOREIGN KEY (profileid) REFERENCES profiles (profileid) ON DELETE CASCADE
      )
    ''');

    // 4. User References Table
    await db.execute('''
      CREATE TABLE user_references (
        id INTEGER PRIMARY KEY AUTOINCREMENT, 
        profileid TEXT, 
        name TEXT, 
        job TEXT, 
        organization TEXT, 
        phone TEXT, 
        email TEXT, 
        FOREIGN KEY (profileid) REFERENCES profiles (profileid) ON DELETE CASCADE
      )
    ''');

    // 5. Skills, Languages, Certificates
    await db.execute(
        'CREATE TABLE skills (id INTEGER PRIMARY KEY AUTOINCREMENT, profileid TEXT, name TEXT, level TEXT, FOREIGN KEY (profileid) REFERENCES profiles (profileid) ON DELETE CASCADE)');
    await db.execute(
        'CREATE TABLE languages (id INTEGER PRIMARY KEY AUTOINCREMENT, profileid TEXT, name TEXT, level TEXT, FOREIGN KEY (profileid) REFERENCES profiles (profileid) ON DELETE CASCADE)');
    await db.execute(
        'CREATE TABLE certificates (id INTEGER PRIMARY KEY AUTOINCREMENT, profileid TEXT, certName TEXT, organization TEXT, year TEXT, FOREIGN KEY (profileid) REFERENCES profiles (profileid) ON DELETE CASCADE)');

    // 6. Settings Table
    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY,
        themeColor INTEGER,
        language TEXT,
        password TEXT,
        fontSize TEXT,
        fontFamily TEXT,
        templateIndex INTEGER
      )
    ''');

    // 7. Saved CVs Table
    await db.execute('''
      CREATE TABLE saved_cvs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fileName TEXT, filePath TEXT, createdDate TEXT
      )
    ''');

    // Initial Settings
    await db.insert('settings', {
      'id': 1,
      'themeColor': 0xFF1E293B,
      'language': 'English',
      'password': '',
      'fontSize': 'Medium',
      'fontFamily': 'Times New Roman',
      'templateIndex': 0
    });
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 17) {
      try {
        // 'job' የሚለው በ CREATE TABLE ላይ ስላለ 'jobTitle' ሳይሆን 'job' መሆኑን አረጋግጥ
        await db.execute(
            "ALTER TABLE user_references ADD COLUMN job TEXT DEFAULT ''");
        // organization ቀድሞውኑ በ CREATE ላይ ካለ እዚህ መጨመር አያስፈልግም
      } catch (e, stackTrace) {
        debugPrint("v17 upgrade error: $e");
        debugPrint(stackTrace.toString()); // ስህተቱ የትኛው መስመር ላይ እንደሆነ ያሳያል
      }
    }
    if (oldVersion < 18) {
      try {
        await db.execute(
            "ALTER TABLE experience ADD COLUMN duration TEXT DEFAULT ''");
      } catch (e, stackTrace) {
        debugPrint("v18 upgrade error: $e");
        debugPrint(stackTrace.toString());
      }
    }
  }

  Future<int> saveProfile(Map<String, dynamic> data) async {
    final db = await instance.database;
    final cleanData = Map<String, dynamic>.from(data);

    // 🔍 UUID-ን በትክክል መለየት (Supabase 'id' ወይም 'profileid' ሊል ይችላል)
    final String? cloudUuid = (data['profileid'] ?? data['id'])?.toString();
    final String userEmail = data['email']?.toString() ?? '';

    final keysToRemove = [
      'education',
      'experience',
      'skills',
      'languages',
      'certificates',
      'user_references',
      'lastUpdated',
      'id'
    ];
    for (var key in keysToRemove) {
      cleanData.remove(key);
    }

    // ✅ UUID መኖሩን እና ለ SQLite መሰጠቱን እናረጋግጥ
    if (cloudUuid != null && cloudUuid.isNotEmpty) {
      cleanData['profileid'] = cloudUuid;
    }

    if (cleanData['layoutOrder'] is List) {
      cleanData['layoutOrder'] = (cleanData['layoutOrder'] as List).join(',');
    }

    try {
      // መጀመሪያ በኢሜይል እንፈልግ
      final existing = await db.query('profiles',
          where: 'email = ?', whereArgs: [userEmail], limit: 1);

      if (existing.isNotEmpty) {
        debugPrint(
            "Updating profile for email: $userEmail with UUID: $cloudUuid");
        // 💡 እዚህ ጋር 'whereArgs' ላይ ኢሜይሉን ተጠቅመን UUID-ን ጨምሮ ሁሉንም እናድሳለን
        return await db.update('profiles', cleanData,
            where: 'email = ?', whereArgs: [userEmail]);
      } else {
        debugPrint("Inserting new profile for email: $userEmail");
        return await db.insert('profiles', cleanData);
      }
    } catch (e) {
      debugPrint("Local Save Error: $e");
      return -1;
    }
  }

// 📝 የ CV ማጠቃለያን (Summary) ብቻ ለብቻው ለማዘመን
  Future<int> updateProfileSummary(String profileid, String summaryText) async {
    final db = await instance.database;
    try {
      return await db.update(
        'profiles',
        {'summary': summaryText},
        where: 'profileid = ?',
        whereArgs: [profileid],
      );
    } catch (e) {
      debugPrint("Update Summary Error: $e");
      return -1;
    }
  }

  Future<Map<String, dynamic>> getSettings() async {
    final db = await instance.database;
    try {
      final res = await db.query('settings', where: 'id = 1');
      if (res.isNotEmpty) return res.first;
    } catch (e) {
      debugPrint("Settings fetch error: $e");
    }

    return {
      'themeColor': 0xFF1E293B,
      'language': 'English',
      'fontSize': 'Medium',
      'fontFamily': 'JetBrains Mono',
      'password': '',
      'templateIndex': 0
    };
  }

  Future<void> saveSettings(Map<String, dynamic> data) async {
    final db = await instance.database;
    await db.insert('settings', {'id': 1, ...data},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- CV History ---
  Future<int> insertSavedCv(String fileName, String filePath) async {
    final db = await instance.database;
    return await db.insert('saved_cvs', {
      'fileName': fileName,
      'filePath': filePath,
      'createdDate': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getSavedCvs() async =>
      (await instance.database).query('saved_cvs', orderBy: 'createdDate DESC');

  Future<void> deleteCv(int id) async {
    final db = await instance.database;
    await db.delete('saved_cvs', where: 'id = ?', whereArgs: [id]);
  }

  // --- Generic Add/Delete/Update ---
  Future<int> addEducation(Map<String, dynamic> data) async =>
      (await instance.database).insert('education', data);
  Future<int> addExperience(Map<String, dynamic> data) async =>
      (await instance.database).insert('experience', data);
  Future<int> addSkill(Map<String, dynamic> data) async =>
      (await instance.database).insert('skills', data);
  Future<int> addLanguage(Map<String, dynamic> data) async =>
      (await instance.database).insert('languages', data);
  Future<int> addCertificate(Map<String, dynamic> data) async =>
      (await instance.database).insert('certificates', data);
  Future<int> addReference(Map<String, dynamic> data) async =>
      (await instance.database).insert('user_references', data);

  Future<int> deleteItem(String table, String id) async =>
      (await instance.database).delete(table, where: 'id = ?', whereArgs: [id]);
  Future<int> updateItem(
          String table, String id, Map<String, dynamic> data) async =>
      (await instance.database)
          .update(table, data, where: 'id = ?', whereArgs: [id]);

  // --- Clear Methods ---
  Future<void> clearEducation(String pId) async => (await instance.database)
      .delete('education', where: 'profileid = ?', whereArgs: [pId]);
  Future<void> clearExperience(String pId) async => (await instance.database)
      .delete('experience', where: 'profileid = ?', whereArgs: [pId]);
  Future<void> clearSkills(String pId) async => (await instance.database)
      .delete('skills', where: 'profileid = ?', whereArgs: [pId]);
  Future<void> clearLanguages(String pId) async => (await instance.database)
      .delete('languages', where: 'profileid = ?', whereArgs: [pId]);
  Future<void> clearCertificates(String pId) async => (await instance.database)
      .delete('certificates', where: 'profileid = ?', whereArgs: [pId]);
  Future<void> clearReferences(String pId) async => (await instance.database)
      .delete('user_references', where: 'profileid = ?', whereArgs: [pId]);

  // --- Clear Methods ማሻሻያ ---
  Future<void> clearAll() async {
    final db = await instance.database;

    // ሁሉንም በአንድ ላይ ማጽዳት (Transaction ቢሆን ይመረጣል)
    await db.transaction((txn) async {
      await txn.delete('profiles');
      await txn.delete('education');
      await txn.delete('experience');
      await txn.delete('skills');
      await txn.delete('languages');
      await txn.delete('certificates');
      await txn.delete('user_references');
      await txn.delete('saved_cvs');
      await txn.delete('profiles');

      // ሴቲንግን ወደ መጀመሪያው ሁኔታ (Default) መመለስ
      await txn.update(
          'settings',
          {
            'themeColor': 0xFF1E293B,
            'fontSize': 'Medium',
            'fontFamily': 'JetBrains Mono',
            'templateIndex': 0,
            'password': '',
          },
          where: 'id = 1');
    });
  }

  void _fixMapping(String table, Map<String, dynamic> map) {
    // 1. የቁልፎችን ስም (Key Names) ማስተካከል
    _renameKey(map, 'firstname', 'firstName');
    _renameKey(map, 'lastname', 'lastName');
    _renameKey(map, 'jobtitle', 'jobTitle');
    _renameKey(map, 'profileimagepath', 'profileImagePath');

    if (table == 'experience') {
      _renameKey(map, 'companyname', 'companyName');
      _renameKey(map, 'startdate', 'startDate');
      _renameKey(map, 'enddate', 'endDate');
      _renameKey(map, 'jobdescription', 'jobDescription');
      _renameKey(map, 'iscurrentlyworking', 'isCurrentlyWorking');

      var isWorking = map['isCurrentlyWorking'];
      map['isCurrentlyWorking'] = (isWorking == true || isWorking == 1) ? 1 : 0;
    } else if (table == 'education') {
      _renameKey(map, 'gradyear', 'gradYear');
    } else if (table == 'certificates') {
      _renameKey(map, 'certname', 'certName');
    }

    // 2. Null ወደ ባዶ String መቀየር
    map.keys.toList().forEach((key) {
      if (map[key] == null) {
        map[key] = (key == 'isCurrentlyWorking') ? 0 : '';
      }
    });
  }

// Helper function ለስም መቀየር
  void _renameKey(Map<String, dynamic> map, String oldKey, String newKey) {
    if (map.containsKey(oldKey)) {
      map[newKey] = map.remove(oldKey);
    }
  }

  // 🔄 ዋናው የ Sync ፋንክሽን
  Future<void> syncFullDataToLocal(Map<String, dynamic> fullData) async {
    final db = await instance.database;

    await db.transaction((txn) async {
      // 1. UUID መለየት
      final String cloudUuid =
          (fullData['profileid'] ?? fullData['id'])?.toString() ?? '';
      if (cloudUuid.isEmpty) return;

      // 2. ፕሮፋይሉን ማዘጋጀት
      final cleanProfile = Map<String, dynamic>.from(fullData);
      final skipKeys = [
        'education',
        'experience',
        'skills',
        'languages',
        'certificates',
        'user_references',
        'id',
        'lastUpdated',
        'createdAt',
        'updatedAt'
      ];
      for (var key in skipKeys) {
        cleanProfile.remove(key);
      }

      _fixMapping('profiles', cleanProfile);
      cleanProfile['profileid'] = cloudUuid;

      // LayoutOrder list ከሆነ ወደ String ቀይረው
      if (cleanProfile['layoutOrder'] is List) {
        cleanProfile['layoutOrder'] =
            (cleanProfile['layoutOrder'] as List).join(',');
      }

      await txn.insert('profiles', cleanProfile,
          conflictAlgorithm: ConflictAlgorithm.replace);

      // 3. ዝርዝሮችን ማመሳሰል
      final tablesToSync = [
        'education',
        'experience',
        'skills',
        'languages',
        'certificates',
        'user_references'
      ];

      for (var table in tablesToSync) {
        await txn.delete(table, where: 'profileid = ?', whereArgs: [cloudUuid]);

        if (fullData[table] != null && fullData[table] is List) {
          for (var item in fullData[table]) {
            final map = Map<String, dynamic>.from(item);
            map.remove('id'); // SQLite auto-increment ይጠቀማል
            map['profileid'] = cloudUuid;

            _fixMapping(table, map); // <--- እዚህ ጋር ስሞቹን ያስተካክላል

            try {
              await txn.insert(table, map);
              debugPrint("✅ Synced $table record to SQLite");
            } catch (e) {
              debugPrint("❌ SQLite Insert Error ($table): $e");
            }
          }
        }
      }
      debugPrint("Full Data Sync Completed for $cloudUuid ✅");
    });
  }

  // 📖 ዳታውን ሙሉ በሙሉ ማንበቢያ
  Future<Map<String, dynamic>?> getFullProfile({String? email}) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> res;

    if (email != null && email.isNotEmpty) {
      res = await db.query('profiles',
          where: 'email = ?', whereArgs: [email.trim()], limit: 1);
    } else {
      res = await db.query('profiles', limit: 1);
    }

    if (res.isEmpty) return null;

    Map<String, dynamic> data = Map<String, dynamic>.from(res.first);
    String actualUuid = data['profileid']?.toString() ?? "";

    final tables = [
      'education',
      'experience',
      'skills',
      'languages',
      'certificates',
      'user_references'
    ];
    for (var table in tables) {
      final results = await db
          .query(table, where: 'profileid = ?', whereArgs: [actualUuid]);
      data[table] = results;
      debugPrint("Local DB: Found ${results.length} records for $table");
    }

    return data;
  }
}
