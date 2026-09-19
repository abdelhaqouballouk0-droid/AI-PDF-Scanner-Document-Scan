# AI PDF Scanner - Document Scan (Flutter)

Application Flutter (iOS + Android) reproduisant les écrans fournis : scan de documents,
gestion de fichiers, outils PDF (fusion, division, compression, protection...), conversion,
signature électronique et assistant IA (résumé / chat / classement automatique).

Les dossiers `android/` et `ios/` ont été générés (`flutter create .`) et le projet est
vérifié : `flutter analyze` et `flutter test` passent sans erreur, et un APK debug Android
compile (`flutter build apk --debug`). iOS ne peut être compilé que depuis macOS/Xcode
(non testé depuis cet environnement Windows) — voir la section 3 pour la configuration
`Info.plist`/`Podfile` déjà en place.

## 1. Prérequis

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (canal stable, ≥ 3.24) installé et dans le `PATH`
- [VS Code](https://code.visualstudio.com/) + extension **Flutter** (installe l'extension Dart automatiquement)
- Android Studio (SDK + un émulateur, ou un téléphone Android en mode développeur) et/ou
  Xcode (pour iOS, macOS uniquement)
- `flutter doctor` sans erreur bloquante

## 2. Premier lancement

```bash
cd ai_pdf_scanner

# Installe les dépendances
flutter pub get

# Génère les icônes d'app à partir de assets/icon/app_icon.png
flutter pub run flutter_launcher_icons

# Lance l'app (émulateur/simulateur ou appareil branché)
flutter run
```

Ouvre ensuite le dossier dans VS Code (`code .`) : la palette de commandes propose
"Flutter: Select Device" et le bouton ▶️ lance l'app avec hot reload.

## 3. Permissions (déjà configurées)

### Android — `android/app/src/main/AndroidManifest.xml`

Les permissions caméra/photos/stockage sont déjà déclarées, et `minSdkVersion` est **24**
(valeur par défaut du template Flutter actuel, suffisante pour ML Kit).

### iOS — `ios/Runner/Info.plist`

Les clés `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription` et
`NSPhotoLibraryAddUsageDescription` sont déjà présentes. La plateforme minimale iOS est
**15.0** (`IPHONEOS_DEPLOYMENT_TARGET` dans `ios/Runner.xcodeproj`), au-dessus du minimum
13.0 requis par VisionKit. Le `Podfile` n'existe que sur macOS : lance `cd ios && pod
install` une fois sur une machine avec Xcode avant le premier build iOS.

## 4. Ce qui est réellement fonctionnel (pas de mock)

| Fonctionnalité | Implémentation |
|---|---|
| Scan de documents (détection de bords, multi-pages) | `cunning_document_scanner` (ML Kit Document Scanner / VisionKit natifs) |
| Visionneuse PDF, recherche, zoom | `syncfusion_flutter_pdfviewer` |
| Annoter (surligner / souligner / barrer) | API annotation `SfPdfViewer` sur sélection de texte |
| Fusionner / diviser / réorganiser / supprimer / pivoter / extraire des pages | `syncfusion_flutter_pdf` (reconstruction réelle du PDF page par page) |
| Compresser un PDF | Rastérisation PDFium (`printing`) + réencodage JPEG (`image`) |
| Protéger / déverrouiller (mot de passe) | Chiffrement AES via `syncfusion_flutter_pdf` |
| Image → PDF, PDF → JPG | `pdf` + `printing` (100% local) |
| Image en texte (OCR) | `google_mlkit_text_recognition`, 100% sur l'appareil |
| Signature électronique (dessiner, enregistrer, apposer sur un PDF) | `signature` + tampon d'image réel via `syncfusion_flutter_pdf` |
| Bibliothèque de fichiers, import, renommer, supprimer, partager | `path_provider`, `file_picker`, `share_plus` |

## 5. Ce qui nécessite une configuration externe (pas de mock non plus, mais pas 100% local)

- **Assistant IA (Résumé / Chat / Classement)** — appelle un endpoint compatible
  OpenAI (`POST {base_url}/chat/completions`). Fonctionne avec OpenAI, Groq,
  OpenRouter, Together.ai ou une instance locale [Ollama](https://ollama.com) en mode
  compatible OpenAI. Configure l'URL, le modèle et la clé API dans
  **Réglages → Assistant IA** de l'app (par défaut : `http://10.0.2.2:11434/v1`,
  c'est-à-dire un Ollama local vu depuis l'émulateur Android).
- **Word ↔ PDF et Excel ↔ PDF** — un vrai moteur de mise en page Office n'existe pas
  côté mobile ; ces deux conversions appellent un serveur configurable (voir
  `ConversionService.officeConversionContract` dans
  `lib/services/conversion_service.dart`). N'importe quel service exposant
  `POST {url}/convert?to=pdf|docx|xlsx` (champ multipart `file`, réponse = fichier brut)
  convient : un [Gotenberg](https://gotenberg.dev/) auto-hébergé (LibreOffice headless)
  ou une API comme CloudConvert/ConvertAPI. Configure l'URL dans
  **Réglages → Conversion Word / Excel**.

Sans configuration, ces écrans affichent un message clair invitant à ouvrir les Réglages
plutôt que d'échouer silencieusement.

## 6. Architecture du code

```
lib/
  main.dart, app.dart          Point d'entrée, thème, ProviderScope (Riverpod)
  theme/                       Couleurs et thème Material 3
  models/                      DocumentFile, DocumentType, SignatureModel, ChatMessage
  services/                    Toute la logique réelle (scan, PDF, conversion, OCR, IA, signature, stockage)
  providers/                   État Riverpod (StateNotifier) qui orchestre les services
  screens/
    home/                      Écran d'accueil
    files/                     Bibliothèque de fichiers (aussi utilisé en mode "sélecteur")
    scanner/                   Relecture/organisation des pages juste après un scan
    viewer/                    Visionneuse PDF + barre d'outils (Éditer/Annoter/Signer/Convertir/Tout)
    tools/                     Fusion, division, compression, protection, conversion, OCR, organisation
    signature/                 Bibliothèque de signatures
    ai_assistant/              Résumé / Chat / Classement
    settings/                  Configuration IA + conversion
    shell/                     Barre de navigation principale
  widgets/                     Composants réutilisables (boutons, listes, aide "ouvrir un fichier")
```

## 7. État des dépendances (versions de packages)

`pubspec.yaml` pointe vers des versions récentes, résolues et vérifiées avec
`flutter analyze` (0 problème) et un build Android debug réussi :

- `syncfusion_flutter_pdf` / `syncfusion_flutter_pdfviewer` / `syncfusion_flutter_core` :
  `^34.2.8`. Les versions `26.x` d'origine échouaient au build Android (leur script Gradle
  utilise `jcenter()`, retiré des dépôts pris en charge par les versions actuelles de
  l'Android Gradle Plugin). Depuis cette version, Syncfusion ne demande plus de clé de
  licence (`SyncfusionLicense.registerLicense` est dépréciée et a été retirée de
  `main.dart`) : aucune configuration à faire pour le bandeau d'évaluation.
- `share_plus: ^13.0.0` et `file_picker: ^13.1.0` : API mise à jour dans le code
  (`SharePlus.instance.share(ShareParams(...))`, `FilePicker.pickFile()` /
  `FilePicker.pickFiles()` qui retournent directement `PlatformFile`/`List<PlatformFile>`
  au lieu d'un `FilePickerResult?` nullable).
- `flutter_riverpod: ^2.6.1` (pas la 3.x) : le code utilise l'API `StateNotifier` de
  Riverpod 2, volontairement conservée pour éviter une réécriture de tous les providers.
- `cunning_document_scanner` nécessite Google Play Services sur l'émulateur Android
  (utilise un émulateur avec Play Store, pas une image "Google APIs" seule).

## 8. Build CI/CD avec Codemagic

`codemagic.yaml` (racine du projet) définit deux workflows, prêts à l'emploi dès que le
dépôt est connecté sur [codemagic.io](https://codemagic.io) :

- **android-workflow** : `flutter analyze` + `flutter test`, puis build d'un APK et d'un
  App Bundle (`.aab`). Fonctionne tel quel (signature debug) pour de la distribution
  interne/QA. Pour un vrai build signé Play Store, crée dans Codemagic un groupe de
  variables d'environnement nommé `android_keystore` contenant :
  - `CM_KEYSTORE` — ton fichier `.jks` encodé en base64 (`base64 -w0 release-keystore.jks`)
  - `CM_KEYSTORE_PASSWORD`, `CM_KEY_ALIAS`, `CM_KEY_PASSWORD`

  Le script les convertit automatiquement en `android/key.properties` (voir
  `android/key.properties.example` pour le format, et `android/app/build.gradle.kts` pour
  la logique de signature — bascule sur les clés debug si `key.properties` est absent).
  Pour publier directement sur le Play Store, décommente le bloc `google_play:` dans
  `codemagic.yaml` et connecte un compte de service Google Play dans Codemagic
  (Teams → Integrations → Google Play).

- **ios-workflow** : nécessite une clé API connectée côté Codemagic (Teams → Integrations
  → Developer Portal), avec accès à une app enregistrée sous le bundle ID
  `com.ouballouk.aipdfscanner`. Le nom de la clé dans Codemagic doit correspondre à la
  valeur `app_store_connect` de `codemagic.yaml` (actuellement `Codemagic`). Sans cette
  intégration, le build iOS échoue à l'étape de signature.

Ces deux étapes (compte de service Google Play, clé API App Store Connect) nécessitent tes
propres identifiants développeur et se configurent uniquement depuis le dashboard
Codemagic — impossible à automatiser depuis ce dépôt.

## 9. Prochaines étapes suggérées

- Brancher un vrai fournisseur IA (clé OpenAI/Groq) et un serveur Gotenberg pour activer
  Word/Excel ↔ PDF sans limitation.
- Ajouter des tests (`flutter test`) sur `PdfToolsService` (merge/split/rotate) avec des
  PDF de test dans `test/fixtures/`.
- Remplacer le thème par défaut par la charte graphique finale si besoin (`lib/theme/app_theme.dart`).
