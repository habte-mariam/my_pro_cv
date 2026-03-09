import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomeHeader extends StatelessWidget {
  final Color backgroundColor;
  final Color textColor;
  final String userName;
  final String? jobTitle;
  final VoidCallback onProfileTap;

  const HomeHeader({
    super.key,
    required this.backgroundColor,
    required this.textColor,
    required this.userName,
    this.jobTitle,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
          EdgeInsets.only(bottom: 30.h, left: 20.w, right: 20.w, top: 10.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(35.r),
          bottomRight: Radius.circular(35.r),
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: onProfileTap,
            child: CircleAvatar(
              radius: 40.r,
              backgroundColor: textColor.withValues(),
              child: Icon(Icons.person, size: 40.sp, color: textColor),
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            "Hello, $userName",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            jobTitle ?? "Ready to build your CV?",
            style: TextStyle(
              color: textColor.withValues(),
              fontSize: 13.sp,
            ),
          ),
        ],
      ),
    );
  }
}
