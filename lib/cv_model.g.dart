// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cv_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************
CvModel _$CvModelFromJson(Map<String, dynamic> json) => CvModel(
      profileid: json['profileid'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      jobTitle: json['jobTitle'] as String? ?? '',
      portfolio: json['portfolio'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      phone2: json['phone2'] as String? ?? '',
      address: json['address'] as String? ?? '',
      age: json['age'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      nationality: json['nationality'] as String? ?? '',
      linkedin: json['linkedin'] as String? ?? '',
      profileImagePath: json['profileImagePath'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      education: (json['education'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
      experience: (json['experience'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
      skills: (json['skills'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
      languages: (json['languages'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
      certificates: (json['certificates'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
      user_references: (json['user_references'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
      rawLayoutOrder: json['layoutOrder'] ??
          'Summary,Experience,Education,Skills,Hobbies,Certificates,Languages,References',
    );

Map<String, dynamic> _$CvModelToJson(CvModel instance) => <String, dynamic>{
      'profileid': instance.profileid,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'jobTitle': instance.jobTitle,
      'portfolio': instance.portfolio,
      'email': instance.email,
      'phone': instance.phone,
      'phone2': instance.phone2,
      'address': instance.address,
      'age': instance.age,
      'gender': instance.gender,
      'nationality': instance.nationality,
      'linkedin': instance.linkedin,
      'profileImagePath': instance.profileImagePath,
      'summary': instance.summary,
      'education': instance.education,
      'experience': instance.experience,
      'skills': instance.skills,
      'languages': instance.languages,
      'certificates': instance.certificates,
      'user_references': instance.user_references,
      'layoutOrder': instance.rawLayoutOrder,
    };
