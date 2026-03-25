#--------------------------------------
# Preserve Flutter code
#--------------------------------------
-keep class io.flutter.** { *; }

#--------------------------------------
# To ignore minifyEnabled: true error
# https://github.com/flutter/flutter/issues/19250
# https://github.com/flutter/flutter/issues/37441
#--------------------------------------
-dontwarn io.flutter.embedding.**
-ignorewarnings
-keep class * {
    public private *;
}
