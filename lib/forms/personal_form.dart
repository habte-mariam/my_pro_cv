import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:my_new_cv/auth_service.dart';
import 'package:my_new_cv/database_helper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:location/location.dart' as loc;
import '../cv_model.dart';
import '../main.dart';

class PersonalForm extends StatefulWidget {
  final CvModel cv;
  final VoidCallback? onDataChanged;
  const PersonalForm({super.key, required this.cv, this.onDataChanged});

  @override
  State<PersonalForm> createState() => _PersonalFormState();
}

class _PersonalFormState extends State<PersonalForm> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  final ImagePicker _picker = ImagePicker();
  bool _isLocationLoading = false;
  bool _isAddressEditable = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.cv.firstName);
    _lastNameController = TextEditingController(text: widget.cv.lastName);

    // ገጹ እንደተከፈተ ተጠቃሚው ገብቶ ከሆነ ዳታውን በራሱ እንዲያመጣ እናዝዘዋለን
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkExistingUser();
    });
  }

  Future<void> _checkExistingUser() async {
    final dbHelper = DatabaseHelper.instance;
    final dbData = await dbHelper.getFullProfile();

    if (dbData != null) {
      // 1. መጀመሪያ ከዳታቤዝ የመጣውን እንሞላለን
      setState(() {
        _firstNameController.text = dbData['firstName'] ?? "";
        _lastNameController.text = dbData['lastName'] ?? "";
        widget.cv.firstName = dbData['firstName'] ?? "";
        widget.cv.lastName = dbData['lastName'] ?? "";
        widget.cv.email = dbData['email'] ?? "";
        widget.cv.jobTitle = dbData['jobTitle'] ?? "";
        widget.cv.phone = dbData['phone'] ?? "";
        widget.cv.address = dbData['address'] ?? "";
        widget.cv.nationality = dbData['nationality'] ?? "";
        widget.cv.gender = dbData['gender'] ?? "";
        widget.cv.age = dbData['age'] ?? "";
        widget.cv.profileImagePath = dbData['profileImagePath'] ?? "";
      });
      debugPrint("Loaded from Database. ✅");
    } else {
      // 2. ዳታቤዝ ላይ ከሌለ ከ Google Login ዳታውን እንወስዳለን
      final authService = AuthService();
      final user = authService.currentUser;

      if (user != null) {
        setState(() {
          String fullName = user.userMetadata?['full_name'] ?? "";
          List<String> nameParts = fullName.split(" ");

          widget.cv.firstName = nameParts.isNotEmpty ? nameParts[0] : "";
          widget.cv.lastName =
              nameParts.length > 1 ? nameParts.sublist(1).join(" ") : "";
          widget.cv.email = user.email ?? "";
        });
        debugPrint("DB empty. Loaded from Google login. 🌐");
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        final directory = await getApplicationDocumentsDirectory();
        final String path = directory.path;
        final String fileName =
            'profile_${DateTime.now().millisecondsSinceEpoch}.png';
        final File newImage = await File(image.path).copy('$path/$fileName');

        // 1. መጀመሪያ mounted መሆኑን አረጋግጥ
        if (!mounted) return;

        setState(() {
          widget.cv.profileImagePath = newImage.path;
        });

        final dbHelper = DatabaseHelper.instance;
        final existingProfile = await dbHelper.getFullProfile();

        if (existingProfile != null) {
          String profileId = existingProfile['id'];
          await dbHelper.updateItem('profiles', profileId, {
            'profileImagePath': newImage.path,
          });
          debugPrint("Database updated successfully with new image path. ✅");
        } else {
          await dbHelper.saveProfile(widget.cv.toJson());
          debugPrint("New profile created with image path. ✅");
        }
      }
    } catch (e) {
      debugPrint("Error picking or saving image: $e");

      // 2. እዚህም ጋር Context ከመጠቀምህ በፊት mounted መሆኑን እይ
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update profile picture: $e")),
      );
    }
  }

  // የአሁኑን ቦታ (Address) በራስ-ሰር ለማግኘት
  Future<void> _getCurrentLocation() async {
    loc.Location location = loc.Location();
    bool serviceEnabled;
    LocationPermission permission;

    setState(() => _isLocationLoading = true);

    try {
      serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          List<String> addressParts = [];
          if (place.subLocality != null && place.subLocality!.isNotEmpty) {
            addressParts.add(place.subLocality!);
          }
          if (place.administrativeArea != null &&
              place.administrativeArea!.isNotEmpty) {
            addressParts.add(place.administrativeArea!);
          }
          if (place.country != null && place.country!.isNotEmpty) {
            addressParts.add(place.country!);
          }
          widget.cv.address = addressParts.join(", ");
        });
      }
    } catch (e) {
      debugPrint("Error getting location: $e");
    } finally {
      setState(() => _isLocationLoading = false);
    }
  }

  DateTime? _selectedBirthDate;

  void _calculateAndSetAge(DateTime birthDate) {
    // Normalize: እዚህ ጋር setState መጠራት አለበት UI-ው እንዲቀየር
    setState(() {
      _selectedBirthDate = birthDate;

      DateTime today = DateTime.now();
      int age = today.year - birthDate.year;

      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }

      widget.cv.age = age.toString();
    });
  }

  void _showIPhoneDatePicker(BuildContext context) {
    final initialDate = _selectedBirthDate ??
        DateTime.now().subtract(const Duration(days: 365 * 20));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // ከርቭ እንዲታይ
      builder: (BuildContext builder) {
        return Container(
          // ቁመቱን ከ 3 ወደ 3.5 ዝቅ በማድረግ ትንሽ አሳጥረነዋል
          height: MediaQuery.of(context).size.height / 3.5,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
            children: [
              // የ "Done" ባር ቁመት እንዲያንስ
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                decoration: BoxDecoration(
                  border:
                      Border(bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Select Birth Date",
                        style: TextStyle(
                            fontSize: 18.sp, color: Colors.grey[600])),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text("Done",
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15.sp)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoTheme(
                  data: CupertinoThemeData(
                    textTheme: CupertinoTextThemeData(
                      dateTimePickerTextStyle: TextStyle(
                        color: Colors.black,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: initialDate,
                    minimumYear: 1950,
                    maximumYear: DateTime.now().year,
                    onDateTimeChanged: (DateTime newDate) {
                      _calculateAndSetAge(newDate);
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _isSaving = false;
  bool _isFormValid() {
    return widget.cv.firstName.trim().isNotEmpty &&
        widget.cv.lastName.trim().isNotEmpty &&
        widget.cv.jobTitle.trim().isNotEmpty;
  }

  Future<void> _savePersonalData() async {
    // መጀመሪያ ቼክ እናደርጋለን
    if (!_isFormValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill required fields!"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      // ዳታቤዝ ላይ 'profiles' ቴብል ውስጥ ሴቭ ያደርጋል
      int result =
          await DatabaseHelper.instance.saveProfile(widget.cv.toJson());

      if (result != -1) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Personal Details Saved Successfully! ✅"),
              backgroundColor: Colors.green,
            ),
          );
        }
        if (widget.onDataChanged != null) widget.onDataChanged!();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Save failed: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).colorScheme.primary;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(20.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ፕሮፋይል ፒክቸር
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 55.r,
                  backgroundColor: themeColor.withValues(
                      alpha: 0.1), // alpha እዚህ ጋር አስፈላጊ ነው
                  backgroundImage: widget.cv.profileImagePath.isNotEmpty &&
                          File(widget.cv.profileImagePath).existsSync()
                      ? FileImage(File(widget.cv.profileImagePath))
                      : null,
                  child: (widget.cv.profileImagePath.isEmpty ||
                          !File(widget.cv.profileImagePath).existsSync())
                      ? Icon(
                          Icons.person,
                          size: 50.sp,
                          color: themeColor,
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 18.r,
                      backgroundColor: themeColor,
                      child: Icon(Icons.camera_alt,
                          size: 18.sp, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 25.h),
          SizedBox(height: 10.h),
          _buildSectionTitle(context, "Basic Details"),

          // First Name
          _buildTextField(
            context,
            "First Name", // * እዚህ አያስፈልግም፣ ፋንክሽኑ ራሱ ይጨምረዋል
            widget.cv.firstName,
            (v) => widget.cv.firstName =
                v!, // setState እዚህ አያስፈልግም (Typing ላይ እንዳይዘል)
            isOptional: false,
            key: ValueKey("fn_${widget.cv.firstName}"),
          ),

          // Last Name
          _buildTextField(
            context,
            "Last Name",
            widget.cv.lastName,
            (v) => widget.cv.lastName = v!,
            isOptional: false,
            key: ValueKey("ln_${widget.cv.lastName}"),
          ),

          // Professional Title
          _buildTextField(context, "Professional Title", widget.cv.jobTitle,
              (v) => widget.cv.jobTitle = v!,
              icon: Icons.work_outline,
              key: ValueKey("title_${widget.cv.jobTitle}"),
              isOptional: false,
              type: TextInputType.text),

          _buildSectionTitle(context, "Contact Information"),
          _buildTextField(context, "Email Address", widget.cv.email,
              (v) => widget.cv.email = v!,
              key: ValueKey("email_${widget.cv.email}"),
              type: TextInputType.emailAddress,
              icon: Icons.email_outlined),

          _buildPhoneField(context, "Phone Number", widget.cv.phone,
              (v) => widget.cv.phone = v),

          _buildPhoneField(context, "Alternative Phone (Optional)",
              widget.cv.phone2, (v) => widget.cv.phone2 = v,
              isOptional: true),

          _buildSectionTitle(context, "Online Profiles (Optional)"),
          _buildTextField(context, "Portfolio Link", widget.cv.portfolio,
              (v) => widget.cv.portfolio = v!,
              key: ValueKey("portfolio_${widget.cv.portfolio}"),
              type: TextInputType.url,
              isOptional: true,
              icon: Icons.language,
              showPaste: true),
          _buildTextField(context, "LinkedIn URL", widget.cv.linkedin,
              (v) => widget.cv.linkedin = v!,
              key: ValueKey("linkedin_${widget.cv.linkedin}"),
              type: TextInputType.url,
              isOptional: true,
              icon: Icons.link,
              showPaste: true),

          _buildSectionTitle(context, "Additional Info"),
          _buildAddressField(context),
          _buildTextField(context, "Nationality", widget.cv.nationality,
              (v) => widget.cv.nationality = v!),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildTextField(
                  context,
                  "Age",
                  widget.cv.age, // እዚህ ጋር ያለው መረጃ እንዲታይ
                  (v) => widget.cv.age = v!,
                  icon: Icons.calendar_month_outlined,
                  readOnly: true,
                  // --- ቁልፉ እዚህ ጋር ነው ---
                  // ቁልፉ በየጊዜው ሲቀየር TextField-ኡ ጽሁፉን ያድሳል
                  key: Key("age_${widget.cv.age}"),
                  onTap: () => _showIPhoneDatePicker(context),
                ),
              ),
              SizedBox(width: 15.w),
              Expanded(child: _buildGenderDropdown(context)),
            ],
          ),
          // ቦታ እንዲሁም የጾታ መረጃ እንደተሞላ እናዝዘዋለን
          _buildSaveButton(themeColor),
          SizedBox(height: 30.h),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsets.only(top: 20.h, bottom: 12.h),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
            letterSpacing: 1.1),
      ),
    );
  }

  Widget _buildTextField(BuildContext context, String label,
      String initialValue, Function(String?) onChanged,
      {TextInputType type = TextInputType.text,
      bool isOptional = false,
      IconData? icon,
      bool readOnly = false,
      VoidCallback? onTap,
      bool showPaste = false,
      Key? key}) {
    final themeColor = Theme.of(context).colorScheme.primary;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: TextFormField(
        key: key,
        initialValue: initialValue,
        keyboardType: type,
        readOnly: readOnly,
        onTap: onTap,
        onChanged: onChanged,
        validator: (value) {
          if (!isOptional && (value == null || value.trim().isEmpty)) {
            return 'Required';
          }
          return null;
        },
        autovalidateMode: AutovalidateMode.onUserInteraction,
        style: TextStyle(
            color: Colors.black, fontWeight: FontWeight.w500, fontSize: 13.sp),
        decoration: InputDecoration(
          labelText: isOptional ? label : "$label*",
          labelStyle: TextStyle(color: Colors.grey[700], fontSize: 12.sp),
          errorStyle: TextStyle(color: Colors.redAccent, fontSize: 10.sp),
          prefixIcon:
              icon != null ? Icon(icon, color: themeColor, size: 20.sp) : null,
          filled: true,
          fillColor: const Color(0xFFF8F9FA),
          contentPadding:
              EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: BorderSide(color: themeColor, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
          suffixIcon: showPaste
              ? IconButton(
                  icon: Icon(Icons.content_paste_rounded,
                      color: themeColor, size: 18.sp),
                  onPressed: () async {
                    ClipboardData? data = await Clipboard.getData('text/plain');
                    if (data?.text != null) {
                      onChanged(data!.text);
                    }
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildAddressField(BuildContext context) {
    final themeColor = Theme.of(context).colorScheme.primary;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: TextFormField(
        key: ValueKey(widget.cv.address),
        initialValue: widget.cv.address,
        readOnly: !_isAddressEditable,
        onChanged: (v) => widget.cv.address = v,
        // የጽሁፉን ከለር ጥቁር በማድረግ ግልጽ እንዲሆን እናደርጋለን
        style:
            const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: "Address (City, Country)",
          labelStyle: TextStyle(color: Colors.grey[700]),
          prefixIcon: Icon(Icons.location_on_outlined, color: themeColor),

          // --- ከለሩ እንዳይጋርድ የተጨመረ ---
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),

          // የሳጥኑ ጠርዞች
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: themeColor, width: 2),
          ),
          // ----------------------------

          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_isAddressEditable)
                TextButton.icon(
                  onPressed: _isLocationLoading ? null : _getCurrentLocation,
                  icon: _isLocationLoading
                      ? const SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(Icons.gps_fixed, size: 18, color: themeColor),
                  label: Text("Auto-fill",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: themeColor)),
                ),
              IconButton(
                icon: Icon(
                    _isAddressEditable ? Icons.check_circle : Icons.edit_note,
                    color:
                        _isAddressEditable ? Colors.green : Colors.grey[600]),
                onPressed: () =>
                    setState(() => _isAddressEditable = !_isAddressEditable),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneField(BuildContext context, String label,
      String initialValue, Function(String) onChanged,
      {bool isOptional = false}) {
    final themeColor = Theme.of(context).colorScheme.primary;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: IntlPhoneField(
        initialValue: initialValue.isNotEmpty ? initialValue : null,
        style:
            const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),

        // የሀገር መለያው (Dropdown) ክፍል ዲዛይን
        dropdownTextStyle: const TextStyle(color: Colors.black),
        pickerDialogStyle: PickerDialogStyle(
          searchFieldInputDecoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: 'Search country',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),

        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[700]),

          // --- ከለሩ እንዳይጋርድ የተጨመረ ---
          filled: true,
          fillColor: Colors.white,

          contentPadding:
              EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),

          // የሳጥኑ ጠርዞች (Border)
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: themeColor, width: 2),
          ),
          // ----------------------------
        ),
        initialCountryCode: 'ET',
        onChanged: (phone) => onChanged(phone.completeNumber),
      ),
    );
  }

  Widget _buildGenderDropdown(BuildContext context) {
    final themeColor = Theme.of(context).colorScheme.primary;

    return ValueListenableBuilder<Map<String, dynamic>>(
      valueListenable: appSettingsNotifier,
      builder: (context, settings, child) {
        String currentFont = settings['fontFamily'] ?? 'JetBrains Mono';

        // እዚህ ጋር በ widget.cv.gender ውስጥ ያለውን ዋጋ እናጣራለን
        // ባዶ ከሆነ ወይም በዝርዝሩ ውስጥ ከሌለ "Select" እንዲሆን እናደርጋለን
        List<String> options = ["Select", "Male", "Female"];
        String currentValue =
            options.contains(widget.cv.gender) ? widget.cv.gender : "Select";

        return Container(
          margin: EdgeInsets.only(bottom: 12.h),
          child: DropdownButtonFormField<String>(
            value: currentValue,
            dropdownColor: Colors.white,
            style: TextStyle(
                color: Colors.black,
                fontFamily: currentFont, // ሴቲንግ ላይ የተመረጠው ፎንት
                fontSize: 13.sp,
                fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              labelText: "Gender",
              labelStyle: TextStyle(
                  color: Colors.grey[700],
                  fontFamily: currentFont,
                  fontSize: 12.sp),
              prefixIcon:
                  Icon(Icons.person_outline, color: themeColor, size: 20.sp),
              filled: true,
              fillColor: const Color(0xFFF8F9FA),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: BorderSide(color: Colors.grey.shade300, width: 1.2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: BorderSide(color: themeColor, width: 1.5),
              ),
            ),
            items: options
                .map((g) => DropdownMenuItem(
                    value: g,
                    child: Text(g,
                        style: TextStyle(
                            color: g == "Select" ? Colors.grey : Colors.black,
                            fontFamily: currentFont,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w400))))
                .toList(),
            onChanged: (v) {
              if (v != null) {
                setState(() {
                  // ተጠቃሚው "Select" ካለ ዳታቤዝ ላይ ባዶ እንዲሆን እናደርጋለን
                  widget.cv.gender = (v == "Select") ? "" : v;
                });
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildSaveButton(Color themeColor) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 20.h),
      child: ElevatedButton(
        onPressed: _isSaving ? null : _savePersonalData,
        style: ElevatedButton.styleFrom(
          backgroundColor: themeColor, // ሁልጊዜ የራሱ ከለር እንዲኖረው
          disabledBackgroundColor: Colors.grey[300],
          minimumSize: Size(double.infinity, 50.h),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                "Save Personal Details",
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
