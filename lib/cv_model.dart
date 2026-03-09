import 'package:json_annotation/json_annotation.dart';

part 'cv_model.g.dart';

enum CvDesign {
  compact,
  modern,
  executive,
  minimalistSplit,
  dynamicPro,
}

@JsonSerializable(explicitToJson: true)
class CvModel {
  @JsonKey(
      name: 'profileid',
      defaultValue: '') // ለ Supabase እና ለ SQLite 'profileid' ወሳኝ ነው
  String id;

  @JsonKey(defaultValue: '')
  String firstName;

  @JsonKey(defaultValue: '')
  String lastName;

  @JsonKey(defaultValue: '')
  String jobTitle;

  @JsonKey(defaultValue: '')
  String portfolio;

  @JsonKey(defaultValue: '')
  String email;

  @JsonKey(defaultValue: '')
  String phone;

  @JsonKey(defaultValue: '')
  String phone2;

  @JsonKey(defaultValue: '')
  String address;

  @JsonKey(defaultValue: '')
  String age;

  @JsonKey(defaultValue: '')
  String gender;

  @JsonKey(defaultValue: '')
  String nationality;

  @JsonKey(defaultValue: '')
  String linkedin;

  @JsonKey(defaultValue: '')
  String profileImagePath;

  @JsonKey(defaultValue: '')
  String summary;

  // Relation Lists
  @JsonKey(defaultValue: [])
  List<Map<String, dynamic>> education;

  @JsonKey(defaultValue: [])
  List<Map<String, dynamic>> experience;

  @JsonKey(defaultValue: [])
  List<Map<String, dynamic>> skills;

  @JsonKey(defaultValue: [])
  List<Map<String, dynamic>> languages;

  @JsonKey(defaultValue: [])
  List<Map<String, dynamic>> certificates;

@JsonKey(name: 'user_references', defaultValue: [])
// ignore: non_constant_identifier_names
List<Map<String, dynamic>> user_references; // ስሙን ወደ ድሮው መልሰው

  // Layout order logic
  @JsonKey(name: 'layoutOrder')
  dynamic rawLayoutOrder;

  CvModel({
    this.id = '',
    this.firstName = '',
    this.lastName = '',
    this.jobTitle = '',
    this.portfolio = '',
    this.email = '',
    this.phone = '',
    this.phone2 = '',
    this.address = '',
    this.age = '',
    this.gender = '',
    this.nationality = '',
    this.linkedin = '',
    this.profileImagePath = '',
    this.summary = '',
    this.education = const [],
    this.experience = const [],
    this.skills = const [],
    this.languages = const [],
    this.certificates = const [],
    // ignore: non_constant_identifier_names
    this.user_references = const [],
    this.rawLayoutOrder =
        'Summary,Experience,Education,Skills,Hobbies,Certificates,Languages,References',
  });

  // Layout order-ን ወደ List መቀየሪያ logic
  List<String> get layoutOrder {
    if (rawLayoutOrder is String) {
      return (rawLayoutOrder as String)
          .split(',')
          .where((s) => s.isNotEmpty)
          .toList();
    } else if (rawLayoutOrder is List) {
      return List<String>.from(rawLayoutOrder);
    }
    return [
      'Summary',
      'Experience',
      'Education',
      'Skills',
      'Hobbies',
      'Certificates',
      'Languages',
      'References'
    ];
  }

  // Enum handling (አማራጭ)
  @JsonKey(includeFromJson: false, includeToJson: false)
  CvDesign? get subDesign => null;

  // --- JSON Serialization ---
  factory CvModel.fromJson(Map<String, dynamic> json) {
    // profileid እና id መምታታት ስለሚችሉ እዚህ ጋር እናስተካክላለን
    if (json['profileid'] != null) json['id'] = json['profileid'];
    return _$CvModelFromJson(json);
  }

  Map<String, dynamic> toJson() => _$CvModelToJson(this);

  // ለ ድሮው ኮድህ compatibility እንዲኖረው (Optional)
  void fromMap(Map<String, dynamic> map) {
    final newModel = CvModel.fromJson(map);
    id = newModel.id;
    firstName = newModel.firstName;
    lastName = newModel.lastName;
    jobTitle = newModel.jobTitle;
    portfolio = newModel.portfolio;
    email = newModel.email;
    phone = newModel.phone;
    phone2 = newModel.phone2;
    address = newModel.address;
    age = newModel.age;
    gender = newModel.gender;
    nationality = newModel.nationality;
    linkedin = newModel.linkedin;
    profileImagePath = newModel.profileImagePath;
    summary = newModel.summary;
    education = newModel.education;
    experience = newModel.experience;
    skills = newModel.skills;
    languages = newModel.languages;
    certificates = newModel.certificates;
    user_references = newModel.user_references;
    rawLayoutOrder = newModel.rawLayoutOrder;
  }
}
