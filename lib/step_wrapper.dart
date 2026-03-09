import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_new_cv/cv_model.dart';
import 'package:my_new_cv/templates/template_picker_screen.dart';

class StepWrapper extends StatelessWidget {
  final int currentStep;
  final String title;
  final Widget child;
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final int totalSteps;
  final CvModel cvModel; // 👈 ሞዴሉ እዚህ መታወጅ አለበት

  const StepWrapper({
    super.key,
    required this.currentStep,
    required this.title,
    required this.child,
    required this.onNext,
    required this.cvModel, // 👈 በ constructor ውስጥ ይካተታል
    this.onBack,
    this.totalSteps = 7,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: onBack != null
            ? IconButton(
                icon: Icon(Icons.arrow_back_ios_new,
                    color: Colors.black, size: 20.sp),
                onPressed: onBack,
              )
            : null,
        title: Text(
          title,
          style: TextStyle(
            color: Colors.black,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(40.h),
          child: _buildProgressIndicator(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: child,
            ),
          ),
          // 👈 እዚህ ጋር BuildContext ማስተላለፍ አለብህ
          _buildBottomBar(context),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
      child: Row(
        children: List.generate(totalSteps, (index) {
          int stepNum = index + 1;
          bool isCompleted = stepNum < currentStep;
          bool isActive = stepNum == currentStep;

          return Expanded(
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 28.r,
                  height: 28.r,
                  decoration: BoxDecoration(
                    color: isActive || isCompleted
                        ? Colors.teal
                        : Colors.grey[200],
                    shape: BoxShape.circle,
                    border: isActive
                        ? Border.all(
                            color: Colors.teal
                                .withValues(alpha: 0.2), // 👈 withValues ተጠቀም
                            width: 4.w)
                        : null,
                  ),
                  child: Center(
                    child: isCompleted
                        ? Icon(Icons.check, size: 16.sp, color: Colors.white)
                        : Text(
                            "$stepNum",
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              color: isActive ? Colors.white : Colors.grey[600],
                            ),
                          ),
                  ),
                ),
                if (index < totalSteps - 1)
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 3.h,
                      margin: EdgeInsets.symmetric(horizontal: 4.w),
                      decoration: BoxDecoration(
                        color: isCompleted ? Colors.teal : Colors.grey[200],
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    // 👈 context እዚህ ይገባል
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 15.h, 20.w, 30.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05), // 👈 withValues ተጠቀም
            offset: const Offset(0, -5),
            blurRadius: 20,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: ElevatedButton(
          onPressed: () {
            if (currentStep == totalSteps) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TemplatePickerScreen(cvModel: cvModel),
                ),
              );
            } else {
              onNext();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            minimumSize: Size(double.infinity, 54.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            elevation: 0,
          ),
          child: Text(
            currentStep == totalSteps ? "GENERATE CV" : "CONTINUE",
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
        ),
      ),
    );
  }
}
