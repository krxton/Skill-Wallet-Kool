import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_th.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('th')
  ];

  /// No description provided for @welcome_playBtn.
  ///
  /// In en, this message translates to:
  /// **'PLAY'**
  String get welcome_playBtn;

  /// No description provided for @welcome_signUpBtn.
  ///
  /// In en, this message translates to:
  /// **'SIGN-UP'**
  String get welcome_signUpBtn;

  /// No description provided for @welcome_signInBtn.
  ///
  /// In en, this message translates to:
  /// **'LOG IN'**
  String get welcome_signInBtn;

  /// No description provided for @home_categoryBtn.
  ///
  /// In en, this message translates to:
  /// **'CATEGORY'**
  String get home_categoryBtn;

  /// No description provided for @home_physicalBtn.
  ///
  /// In en, this message translates to:
  /// **'PHYSICAL'**
  String get home_physicalBtn;

  /// No description provided for @home_languageBtn.
  ///
  /// In en, this message translates to:
  /// **'LANGUAGE'**
  String get home_languageBtn;

  /// No description provided for @home_calculationBtn.
  ///
  /// In en, this message translates to:
  /// **'CALCULATION'**
  String get home_calculationBtn;

  /// No description provided for @home_cannotBtn.
  ///
  /// In en, this message translates to:
  /// **'Cannot load popular activities'**
  String get home_cannotBtn;

  /// No description provided for @home_nonewBtn.
  ///
  /// In en, this message translates to:
  /// **'No new activities available'**
  String get home_nonewBtn;

  /// No description provided for @home_popularactivityBtn.
  ///
  /// In en, this message translates to:
  /// **'POPULAR ACTIVITIES'**
  String get home_popularactivityBtn;

  /// No description provided for @home_newactivityBtn.
  ///
  /// In en, this message translates to:
  /// **'NEW ACTIVITIES'**
  String get home_newactivityBtn;

  /// No description provided for @home_viewallBtn.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get home_viewallBtn;

  /// No description provided for @home_searchBtn.
  ///
  /// In en, this message translates to:
  /// **'SEARCH'**
  String get home_searchBtn;

  /// No description provided for @home_bannerLanguage.
  ///
  /// In en, this message translates to:
  /// **'LANGUAGE TRAINING'**
  String get home_bannerLanguage;

  /// No description provided for @home_bannerCalculate.
  ///
  /// In en, this message translates to:
  /// **'CALCULATE'**
  String get home_bannerCalculate;

  /// No description provided for @home_bannerProblems.
  ///
  /// In en, this message translates to:
  /// **'PROBLEMS SOLVE'**
  String get home_bannerProblems;

  /// No description provided for @parentprofile_postBtn.
  ///
  /// In en, this message translates to:
  /// **'POST'**
  String get parentprofile_postBtn;

  /// No description provided for @register_backBtn.
  ///
  /// In en, this message translates to:
  /// **'BACK'**
  String get register_backBtn;

  /// No description provided for @register_signuptoBtn.
  ///
  /// In en, this message translates to:
  /// **'SIGN-UP TO'**
  String get register_signuptoBtn;

  /// No description provided for @register_facebookBtn.
  ///
  /// In en, this message translates to:
  /// **'CONTINUE WITH FACEBOOK'**
  String get register_facebookBtn;

  /// No description provided for @register_googleBtn.
  ///
  /// In en, this message translates to:
  /// **'CONTINUE WITH GOOGLE'**
  String get register_googleBtn;

  /// No description provided for @register_nextBtn.
  ///
  /// In en, this message translates to:
  /// **'NEXT'**
  String get register_nextBtn;

  /// No description provided for @register_registerBtn.
  ///
  /// In en, this message translates to:
  /// **'REGISTER'**
  String get register_registerBtn;

  /// No description provided for @register_additionalBtn.
  ///
  /// In en, this message translates to:
  /// **'ADDITIONAL INFORMATION'**
  String get register_additionalBtn;

  /// No description provided for @register_namesurnamechildBtn.
  ///
  /// In en, this message translates to:
  /// **'NAME & SURNAME (CHILDREN) {index}'**
  String register_namesurnamechildBtn(Object index);

  /// No description provided for @register_birthdayBtn.
  ///
  /// In en, this message translates to:
  /// **'BIRTHDAY : DD/MM/YYYY'**
  String get register_birthdayBtn;

  /// No description provided for @register_okBtn.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get register_okBtn;

  /// No description provided for @register_pls.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all the information in the list. '**
  String get register_pls;

  /// No description provided for @register_finish.
  ///
  /// In en, this message translates to:
  /// **'Successfully registered!'**
  String get register_finish;

  /// No description provided for @login_backBtn.
  ///
  /// In en, this message translates to:
  /// **'BACK'**
  String get login_backBtn;

  /// No description provided for @login_facebookBtn.
  ///
  /// In en, this message translates to:
  /// **'CONTINUE WITH FACEBOOK'**
  String get login_facebookBtn;

  /// No description provided for @login_googleBtn.
  ///
  /// In en, this message translates to:
  /// **'CONTINUE WITH GOOGLE'**
  String get login_googleBtn;

  /// No description provided for @setting_backBtn.
  ///
  /// In en, this message translates to:
  /// **'BACK'**
  String get setting_backBtn;

  /// No description provided for @setting_settingBtn.
  ///
  /// In en, this message translates to:
  /// **'SETTING'**
  String get setting_settingBtn;

  /// No description provided for @setting_personalBtn.
  ///
  /// In en, this message translates to:
  /// **'PERSONAL INFORMATION'**
  String get setting_personalBtn;

  /// No description provided for @setting_generalBtn.
  ///
  /// In en, this message translates to:
  /// **'GENERAL'**
  String get setting_generalBtn;

  /// No description provided for @setting_profileBtn.
  ///
  /// In en, this message translates to:
  /// **'PROFILE'**
  String get setting_profileBtn;

  /// No description provided for @setting_childBtn.
  ///
  /// In en, this message translates to:
  /// **'CHILD'**
  String get setting_childBtn;

  /// No description provided for @setting_notificationBtn.
  ///
  /// In en, this message translates to:
  /// **'NOTIFICATIONS'**
  String get setting_notificationBtn;

  /// No description provided for @setting_thaiBtn.
  ///
  /// In en, this message translates to:
  /// **'THAI'**
  String get setting_thaiBtn;

  /// No description provided for @setting_englishBtn.
  ///
  /// In en, this message translates to:
  /// **'ENGLISH'**
  String get setting_englishBtn;

  /// No description provided for @setting_logoutBtn.
  ///
  /// In en, this message translates to:
  /// **'LOG OUT'**
  String get setting_logoutBtn;

  /// No description provided for @namesetting_changenameBtn.
  ///
  /// In en, this message translates to:
  /// **'CHANGE NAME'**
  String get namesetting_changenameBtn;

  /// No description provided for @namesetting_enternewnameBtn.
  ///
  /// In en, this message translates to:
  /// **'ENTER NEW NAME'**
  String get namesetting_enternewnameBtn;

  /// No description provided for @namesetting_hint.
  ///
  /// In en, this message translates to:
  /// **'Type your name...'**
  String get namesetting_hint;

  /// No description provided for @namesetting_saveBtn.
  ///
  /// In en, this message translates to:
  /// **'SAVE'**
  String get namesetting_saveBtn;

  /// No description provided for @profilesetting_nameBtn.
  ///
  /// In en, this message translates to:
  /// **'NAME'**
  String get profilesetting_nameBtn;

  /// No description provided for @profilesetting_deleteaccoutBtn.
  ///
  /// In en, this message translates to:
  /// **'DELETE ACCOUNT'**
  String get profilesetting_deleteaccoutBtn;

  /// No description provided for @profileSet_deleteDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'DELETE ACCOUNT?'**
  String get profileSet_deleteDialogTitle;

  /// No description provided for @profilesetting_areusureBtn.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account? This action cannot be undone.'**
  String get profilesetting_areusureBtn;

  /// No description provided for @profilesetting_cancelBtn.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get profilesetting_cancelBtn;

  /// No description provided for @profilesetting_deleteBtn.
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get profilesetting_deleteBtn;

  /// No description provided for @childprofile_mathGame.
  ///
  /// In en, this message translates to:
  /// **'MATH GAME'**
  String get childprofile_mathGame;

  /// No description provided for @childprofile_workoutGame.
  ///
  /// In en, this message translates to:
  /// **'WORK OUT GAME'**
  String get childprofile_workoutGame;

  /// No description provided for @childsetting_childsettingBtn.
  ///
  /// In en, this message translates to:
  /// **'CHILD SETTING'**
  String get childsetting_childsettingBtn;

  /// No description provided for @childsetting_scoreBtn.
  ///
  /// In en, this message translates to:
  /// **'SCORE'**
  String get childsetting_scoreBtn;

  /// No description provided for @childsetting_viewprofileBtn.
  ///
  /// In en, this message translates to:
  /// **'VIEW PROFILE'**
  String get childsetting_viewprofileBtn;

  /// No description provided for @childsetting_manageBtn.
  ///
  /// In en, this message translates to:
  /// **'MANAGE'**
  String get childsetting_manageBtn;

  /// No description provided for @childgallery_title.
  ///
  /// In en, this message translates to:
  /// **'MY GALLERY'**
  String get childgallery_title;

  /// No description provided for @childgallery_empty.
  ///
  /// In en, this message translates to:
  /// **'NO POSTS YET'**
  String get childgallery_empty;

  /// No description provided for @history_timesSuffix.
  ///
  /// In en, this message translates to:
  /// **'TIMES'**
  String get history_timesSuffix;

  /// No description provided for @result_title.
  ///
  /// In en, this message translates to:
  /// **'PLAYING RESULT'**
  String get result_title;

  /// No description provided for @result_timeUsedTitle.
  ///
  /// In en, this message translates to:
  /// **'TIME USED'**
  String get result_timeUsedTitle;

  /// No description provided for @redemption_playBtn.
  ///
  /// In en, this message translates to:
  /// **'PLAY'**
  String get redemption_playBtn;

  /// No description provided for @redemption_rewardIceCream.
  ///
  /// In en, this message translates to:
  /// **'ICE CREAM'**
  String get redemption_rewardIceCream;

  /// No description provided for @redemption_rewardPlaytime.
  ///
  /// In en, this message translates to:
  /// **'1 HR PLAYTIME'**
  String get redemption_rewardPlaytime;

  /// No description provided for @redemption_rewardToy.
  ///
  /// In en, this message translates to:
  /// **'NEW TOY'**
  String get redemption_rewardToy;

  /// No description provided for @redemption_rewardStickers.
  ///
  /// In en, this message translates to:
  /// **'STICKERS'**
  String get redemption_rewardStickers;

  /// No description provided for @redemption_historyPlayedDefault.
  ///
  /// In en, this message translates to:
  /// **'Played Ping Pong'**
  String get redemption_historyPlayedDefault;

  /// No description provided for @redemption_historyRedeemedDefault.
  ///
  /// In en, this message translates to:
  /// **'Redeemed Ice Cream'**
  String get redemption_historyRedeemedDefault;

  /// No description provided for @dialog_deleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Profile?'**
  String get dialog_deleteTitle;

  /// No description provided for @dialog_deleteContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this profile? This action cannot be undone.'**
  String get dialog_deleteContent;

  /// No description provided for @dialog_confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get dialog_confirmDelete;

  /// No description provided for @dialog_cancel.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get dialog_cancel;

  /// No description provided for @dialog_saveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Saved successfully!'**
  String get dialog_saveSuccess;

  /// No description provided for @notificationsetting_notificationBtn.
  ///
  /// In en, this message translates to:
  /// **'NOTIFICATIONS'**
  String get notificationsetting_notificationBtn;

  /// No description provided for @notificationsetting_allnotificationBtn.
  ///
  /// In en, this message translates to:
  /// **'ALL NOTIFICATIONS'**
  String get notificationsetting_allnotificationBtn;

  /// No description provided for @notificationsetting_postBtn.
  ///
  /// In en, this message translates to:
  /// **'POST'**
  String get notificationsetting_postBtn;

  /// No description provided for @notificationsetting_likeBtn.
  ///
  /// In en, this message translates to:
  /// **'LIKE'**
  String get notificationsetting_likeBtn;

  /// No description provided for @notificationsetting_commentBtn.
  ///
  /// In en, this message translates to:
  /// **'COMMENT'**
  String get notificationsetting_commentBtn;

  /// No description provided for @videodetail_activitynameBtn.
  ///
  /// In en, this message translates to:
  /// **'ACTIVITY NAME'**
  String get videodetail_activitynameBtn;

  /// No description provided for @videodetail_nameBtn.
  ///
  /// In en, this message translates to:
  /// **'name'**
  String get videodetail_nameBtn;

  /// No description provided for @videodetail_DescriptionBtn.
  ///
  /// In en, this message translates to:
  /// **'DESCRIPTION'**
  String get videodetail_DescriptionBtn;

  /// No description provided for @videodetail_descriptionBtn.
  ///
  /// In en, this message translates to:
  /// **'description'**
  String get videodetail_descriptionBtn;

  /// No description provided for @videodetail_howtoplayBtn.
  ///
  /// In en, this message translates to:
  /// **'HOW TO PLAY / INSTRUCTIONS:'**
  String get videodetail_howtoplayBtn;

  /// No description provided for @videodetail_contentBtn.
  ///
  /// In en, this message translates to:
  /// **'content'**
  String get videodetail_contentBtn;

  /// No description provided for @videodetail_startBtn.
  ///
  /// In en, this message translates to:
  /// **'START'**
  String get videodetail_startBtn;

  /// No description provided for @videodetail_addBtn.
  ///
  /// In en, this message translates to:
  /// **'ADD'**
  String get videodetail_addBtn;

  /// No description provided for @videodetail_videoNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Video Not Available (HTML Content Missing)'**
  String get videodetail_videoNotAvailable;

  /// No description provided for @videodetail_activityNameLabel.
  ///
  /// In en, this message translates to:
  /// **'ACTIVITY NAME:'**
  String get videodetail_activityNameLabel;

  /// No description provided for @videodetail_descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'DESCRIPTION:'**
  String get videodetail_descriptionLabel;

  /// No description provided for @videodetail_howToPlayLabel.
  ///
  /// In en, this message translates to:
  /// **'HOW TO PLAY / INSTRUCTIONS:'**
  String get videodetail_howToPlayLabel;

  /// No description provided for @videodetail_categoryPrefix.
  ///
  /// In en, this message translates to:
  /// **'Category: '**
  String get videodetail_categoryPrefix;

  /// No description provided for @videodetail_difficultyPrefix.
  ///
  /// In en, this message translates to:
  /// **'Difficulty: '**
  String get videodetail_difficultyPrefix;

  /// No description provided for @videodetail_maxScorePrefix.
  ///
  /// In en, this message translates to:
  /// **'Max Score: '**
  String get videodetail_maxScorePrefix;

  /// No description provided for @addchild_namesurnameBtn.
  ///
  /// In en, this message translates to:
  /// **'NAME & SURNAME (CHILDREN)'**
  String get addchild_namesurnameBtn;

  /// No description provided for @addchild_errorName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name'**
  String get addchild_errorName;

  /// No description provided for @addchild_birthdayBtn.
  ///
  /// In en, this message translates to:
  /// **'BIRTHDAY : DD/MM/YYYY'**
  String get addchild_birthdayBtn;

  /// No description provided for @addchild_okBtn.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get addchild_okBtn;

  /// No description provided for @childnamesetting_editnameBtn.
  ///
  /// In en, this message translates to:
  /// **'EDIT NAME'**
  String get childnamesetting_editnameBtn;

  /// No description provided for @childnamesetting_saveBtn.
  ///
  /// In en, this message translates to:
  /// **'SAVE'**
  String get childnamesetting_saveBtn;

  /// No description provided for @managechild_manageprofileBtn.
  ///
  /// In en, this message translates to:
  /// **'MANAGE PROFILE'**
  String get managechild_manageprofileBtn;

  /// No description provided for @managechild_nameBtn.
  ///
  /// In en, this message translates to:
  /// **'NAME'**
  String get managechild_nameBtn;

  /// No description provided for @managechild_medalsandredemptionBtn.
  ///
  /// In en, this message translates to:
  /// **'MEDALS & REDEMPTION'**
  String get managechild_medalsandredemptionBtn;

  /// No description provided for @managechild_deleteprofileBtn.
  ///
  /// In en, this message translates to:
  /// **'DELETE PROFILE'**
  String get managechild_deleteprofileBtn;

  /// No description provided for @dairyactivity_playhistoryBtn.
  ///
  /// In en, this message translates to:
  /// **'PLAYING HISTORY'**
  String get dairyactivity_playhistoryBtn;

  /// No description provided for @dairyactivity_timeBtn.
  ///
  /// In en, this message translates to:
  /// **'time'**
  String get dairyactivity_timeBtn;

  /// No description provided for @dairyactivity_medalsBtn.
  ///
  /// In en, this message translates to:
  /// **'medals'**
  String get dairyactivity_medalsBtn;

  /// No description provided for @medalredemption_addrewardBtn.
  ///
  /// In en, this message translates to:
  /// **'ADD REWARD'**
  String get medalredemption_addrewardBtn;

  /// No description provided for @medalredemption_rewardnameBtn.
  ///
  /// In en, this message translates to:
  /// **'Reward Name'**
  String get medalredemption_rewardnameBtn;

  /// No description provided for @medalredemption_costBtn.
  ///
  /// In en, this message translates to:
  /// **'Cost (Points)'**
  String get medalredemption_costBtn;

  /// No description provided for @medalredemption_cancelBtn.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get medalredemption_cancelBtn;

  /// No description provided for @medalredemption_addBtn.
  ///
  /// In en, this message translates to:
  /// **'ADD'**
  String get medalredemption_addBtn;

  /// No description provided for @medalredemption_redemptionBtn.
  ///
  /// In en, this message translates to:
  /// **'REDEMPTION'**
  String get medalredemption_redemptionBtn;

  /// No description provided for @medalredemption_activitiesBtn.
  ///
  /// In en, this message translates to:
  /// **'ACTIVITIES'**
  String get medalredemption_activitiesBtn;

  /// No description provided for @medalredemption_currentscoreBtn.
  ///
  /// In en, this message translates to:
  /// **'CURRENT SCORE'**
  String get medalredemption_currentscoreBtn;

  /// No description provided for @medalredemption_rewardshopBtn.
  ///
  /// In en, this message translates to:
  /// **'REWARDS SHOP'**
  String get medalredemption_rewardshopBtn;

  /// No description provided for @medalredemption_successfullyBtn.
  ///
  /// In en, this message translates to:
  /// **'Successfully Redeemed'**
  String get medalredemption_successfullyBtn;

  /// No description provided for @physical_snackNoEvidence.
  ///
  /// In en, this message translates to:
  /// **'Please attach video or image evidence.'**
  String get physical_snackNoEvidence;

  /// No description provided for @physical_snackInvalidScore.
  ///
  /// In en, this message translates to:
  /// **'Please set a valid score (1 to {maxScore}).'**
  String physical_snackInvalidScore(int maxScore);

  /// No description provided for @physical_dialogSubmitTitle.
  ///
  /// In en, this message translates to:
  /// **'Submission Complete!'**
  String get physical_dialogSubmitTitle;

  /// No description provided for @physical_dialogSubmitContent.
  ///
  /// In en, this message translates to:
  /// **'Your evidence has been submitted for approval.'**
  String get physical_dialogSubmitContent;

  /// No description provided for @physical_dialogOkBtn.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get physical_dialogOkBtn;

  /// No description provided for @physical_snackSubmitError.
  ///
  /// In en, this message translates to:
  /// **'Submission Error: {error}'**
  String physical_snackSubmitError(String error);

  /// No description provided for @physical_dialogEnterScoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter Score'**
  String get physical_dialogEnterScoreTitle;

  /// No description provided for @physical_dialogEnterScoreHint.
  ///
  /// In en, this message translates to:
  /// **'Enter score (1-{maxScore})'**
  String physical_dialogEnterScoreHint(int maxScore);

  /// No description provided for @physical_dialogCancelBtn.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get physical_dialogCancelBtn;

  /// No description provided for @physical_snackInvalidInput.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid score (0-{maxScore})'**
  String physical_snackInvalidInput(int maxScore);

  /// No description provided for @physical_stopBtn.
  ///
  /// In en, this message translates to:
  /// **'STOP'**
  String get physical_stopBtn;

  /// No description provided for @physical_startBtn.
  ///
  /// In en, this message translates to:
  /// **'START'**
  String get physical_startBtn;

  /// No description provided for @physical_takePhotoBtn.
  ///
  /// In en, this message translates to:
  /// **'TAKE PHOTO'**
  String get physical_takePhotoBtn;

  /// No description provided for @physical_medalsScoreLabel.
  ///
  /// In en, this message translates to:
  /// **'MEDALS / SCORE'**
  String get physical_medalsScoreLabel;

  /// No description provided for @physical_diaryLabel.
  ///
  /// In en, this message translates to:
  /// **'DIARY'**
  String get physical_diaryLabel;

  /// No description provided for @physical_diaryHint.
  ///
  /// In en, this message translates to:
  /// **'Enter notes here...'**
  String get physical_diaryHint;

  /// No description provided for @physical_imageEvidenceLabel.
  ///
  /// In en, this message translates to:
  /// **'IMAGE EVIDENCE'**
  String get physical_imageEvidenceLabel;

  /// No description provided for @physical_videoEvidenceLabel.
  ///
  /// In en, this message translates to:
  /// **'VIDEO EVIDENCE'**
  String get physical_videoEvidenceLabel;

  /// No description provided for @physical_timeLabel.
  ///
  /// In en, this message translates to:
  /// **'TIME'**
  String get physical_timeLabel;

  /// No description provided for @physical_submittingBtn.
  ///
  /// In en, this message translates to:
  /// **'Submitting...'**
  String get physical_submittingBtn;

  /// No description provided for @physical_finishBtn.
  ///
  /// In en, this message translates to:
  /// **'FINISH'**
  String get physical_finishBtn;

  /// No description provided for @languagedetail_titlePrefix.
  ///
  /// In en, this message translates to:
  /// **'LANGUAGE: '**
  String get languagedetail_titlePrefix;

  /// No description provided for @languagedetail_categoryPrefix.
  ///
  /// In en, this message translates to:
  /// **'CATEGORY: '**
  String get languagedetail_categoryPrefix;

  /// No description provided for @languagedetail_activityTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'ACTIVITY TITLE'**
  String get languagedetail_activityTitleLabel;

  /// No description provided for @languagedetail_descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'DESCRIPTION'**
  String get languagedetail_descriptionLabel;

  /// No description provided for @languagedetail_difficultyPrefix.
  ///
  /// In en, this message translates to:
  /// **'Difficulty: '**
  String get languagedetail_difficultyPrefix;

  /// No description provided for @languagedetail_maxScorePrefix.
  ///
  /// In en, this message translates to:
  /// **'Max Score: '**
  String get languagedetail_maxScorePrefix;

  /// No description provided for @languagedetail_startBtn.
  ///
  /// In en, this message translates to:
  /// **'START'**
  String get languagedetail_startBtn;

  /// No description provided for @itemintro_recordToEnable.
  ///
  /// In en, this message translates to:
  /// **'Record to enable playback'**
  String get itemintro_recordToEnable;

  /// No description provided for @itemintro_listenExampleBtn.
  ///
  /// In en, this message translates to:
  /// **'LISTEN TO EXAMPLE'**
  String get itemintro_listenExampleBtn;

  /// No description provided for @itemintro_practiceNowBtn.
  ///
  /// In en, this message translates to:
  /// **'PRACTICE NOW'**
  String get itemintro_practiceNowBtn;

  /// No description provided for @itemintro_submitBtn.
  ///
  /// In en, this message translates to:
  /// **'SUBMIT'**
  String get itemintro_submitBtn;

  /// No description provided for @record_loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get record_loading;

  /// No description provided for @record_finishBtn.
  ///
  /// In en, this message translates to:
  /// **'FINISH'**
  String get record_finishBtn;

  /// No description provided for @record_errorMic.
  ///
  /// In en, this message translates to:
  /// **'Microphone error or permission denied'**
  String get record_errorMic;

  /// No description provided for @record_statusRecording.
  ///
  /// In en, this message translates to:
  /// **'Recording...'**
  String get record_statusRecording;

  /// No description provided for @record_statusIdle.
  ///
  /// In en, this message translates to:
  /// **'Press mic to record'**
  String get record_statusIdle;

  /// No description provided for @result_activityCompletedDefault.
  ///
  /// In en, this message translates to:
  /// **'ACTIVITY COMPLETED'**
  String get result_activityCompletedDefault;

  /// No description provided for @result_greatJobTitle.
  ///
  /// In en, this message translates to:
  /// **'GREAT JOB!'**
  String get result_greatJobTitle;

  /// No description provided for @result_totalScoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Score'**
  String get result_totalScoreLabel;

  /// No description provided for @result_timeSpentLabel.
  ///
  /// In en, this message translates to:
  /// **'Time Spent'**
  String get result_timeSpentLabel;

  /// No description provided for @result_retryBtn.
  ///
  /// In en, this message translates to:
  /// **'RETRY'**
  String get result_retryBtn;

  /// No description provided for @result_backToActivitiesBtn.
  ///
  /// In en, this message translates to:
  /// **'BACK TO ACTIVITIES'**
  String get result_backToActivitiesBtn;

  /// No description provided for @result_returnHomeBtn.
  ///
  /// In en, this message translates to:
  /// **'RETURN HOME'**
  String get result_returnHomeBtn;

  /// No description provided for @result_timeFormat.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min {seconds} sec'**
  String result_timeFormat(int minutes, int seconds);

  /// No description provided for @calculate_title.
  ///
  /// In en, this message translates to:
  /// **'CALCULATE'**
  String get calculate_title;

  /// No description provided for @calculate_plusBtn.
  ///
  /// In en, this message translates to:
  /// **'PLUS +'**
  String get calculate_plusBtn;

  /// No description provided for @calculate_minusBtn.
  ///
  /// In en, this message translates to:
  /// **'MINUS -'**
  String get calculate_minusBtn;

  /// No description provided for @calculate_multiplyBtn.
  ///
  /// In en, this message translates to:
  /// **'MULTIPLY *'**
  String get calculate_multiplyBtn;

  /// No description provided for @calculate_divideBtn.
  ///
  /// In en, this message translates to:
  /// **'DEVIDE /'**
  String get calculate_divideBtn;

  /// No description provided for @calculate_mixBtn.
  ///
  /// In en, this message translates to:
  /// **'MIX + - * /'**
  String get calculate_mixBtn;

  /// No description provided for @calculate_problemsSolveBtn.
  ///
  /// In en, this message translates to:
  /// **'PROBLEMS SOLVE'**
  String get calculate_problemsSolveBtn;

  /// No description provided for @languagehub_searchHint.
  ///
  /// In en, this message translates to:
  /// **'search...'**
  String get languagehub_searchHint;

  /// No description provided for @languagehub_trainingTitle.
  ///
  /// In en, this message translates to:
  /// **'LANGUAGE TRAINING'**
  String get languagehub_trainingTitle;

  /// No description provided for @languagehub_listeningSpeakingTitle.
  ///
  /// In en, this message translates to:
  /// **'LISTENING AND SPEAKING'**
  String get languagehub_listeningSpeakingTitle;

  /// No description provided for @languagehub_easyBtn.
  ///
  /// In en, this message translates to:
  /// **'EASY'**
  String get languagehub_easyBtn;

  /// No description provided for @languagehub_mediumBtn.
  ///
  /// In en, this message translates to:
  /// **'MEDIUM'**
  String get languagehub_mediumBtn;

  /// No description provided for @languagehub_difficultBtn.
  ///
  /// In en, this message translates to:
  /// **'DIFFICULT'**
  String get languagehub_difficultBtn;

  /// No description provided for @plus_castToTvBtn.
  ///
  /// In en, this message translates to:
  /// **'CAST TO TV'**
  String get plus_castToTvBtn;

  /// No description provided for @plus_answerBtn.
  ///
  /// In en, this message translates to:
  /// **'ANSWER'**
  String get plus_answerBtn;

  /// No description provided for @problemdetail_title.
  ///
  /// In en, this message translates to:
  /// **'PROBLEMS SOLVE'**
  String get problemdetail_title;

  /// No description provided for @problemdetail_castToTvBtn.
  ///
  /// In en, this message translates to:
  /// **'CAST TO TV'**
  String get problemdetail_castToTvBtn;

  /// No description provided for @problemdetail_answerBtn.
  ///
  /// In en, this message translates to:
  /// **'ANSWER'**
  String get problemdetail_answerBtn;

  /// No description provided for @problemanswer_title.
  ///
  /// In en, this message translates to:
  /// **'ANSWER'**
  String get problemanswer_title;

  /// No description provided for @problemanswer_defaultQuestion.
  ///
  /// In en, this message translates to:
  /// **'THERE ARE 6 CATS IN THE FIELD.\nANOTHER 2 CATS WALK INTO THE FIELD.\nHOW MANY CATS ARE THERE IN TOTAL ?'**
  String get problemanswer_defaultQuestion;

  /// No description provided for @problemanswer_defaultAnswer.
  ///
  /// In en, this message translates to:
  /// **'THERE ARE 8 CATS IN TOTAL.'**
  String get problemanswer_defaultAnswer;

  /// No description provided for @problemplaying_finishBtn.
  ///
  /// In en, this message translates to:
  /// **'FINISH'**
  String get problemplaying_finishBtn;

  /// No description provided for @languagelist_snackNotConnected.
  ///
  /// In en, this message translates to:
  /// **'This flow is not connected to activities yet.'**
  String get languagelist_snackNotConnected;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'th'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'th':
      return AppLocalizationsTh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
