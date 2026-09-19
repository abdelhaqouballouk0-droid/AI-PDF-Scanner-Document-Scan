# google_mlkit_text_recognition's base TextRecognizer references the
# per-script recognizer options classes (Chinese/Devanagari/Japanese/Korean)
# reflectively so it can support them if their optional ML Kit dependencies
# are added. We only use the default (Latin) recognizer, so those classes
# aren't on the classpath — R8 fails the release build without these lines.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
