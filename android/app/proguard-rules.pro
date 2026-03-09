# ሁሉንም የ ota_update ክላሶች ከጥፋት መከላከል
-keep class com.shoutit.ota.** { *; }
-keep class sk.shoutit.ota.** { *; }
-keep class androidx.core.content.FileProvider { *; }

# ለ አንድሮይድ ፋይል ማጋራት አስፈላጊ የሆኑ ነገሮች
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# BouncyCastle እና iText ስህተት እንዳያመጡ መከልከል
-dontwarn org.bouncycastle.**
-keep class org.bouncycastle.** { *; }

-dontwarn com.itextpdf.**
-keep class com.itextpdf.** { *; }

-keepattributes Signature,Annotation,InnerClasses

-keep class com.sqlite.** { *; }
-keep class io.supabase.** { *; }