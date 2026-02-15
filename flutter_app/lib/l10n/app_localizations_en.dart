// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get welcome_playBtn => 'PLAY';

  @override
  String get welcome_signUpBtn => 'SIGN-UP';

  @override
  String get welcome_signInBtn => 'LOG IN';

  @override
  String get home_categoryBtn => 'CATEGORY';

  @override
  String get home_physicalBtn => 'PHYSICAL';

  @override
  String get home_languageBtn => 'LANGUAGE';

  @override
  String get home_calculationBtn => 'CALCULATION';

  @override
  String get home_cannotBtn => 'Cannot load popular activities';

  @override
  String get home_nonewBtn => 'No new activities available';

  @override
  String get home_popularactivityBtn => 'POPULAR ACTIVITIES';

  @override
  String get home_newactivityBtn => 'NEW ACTIVITIES';

  @override
  String get home_viewallBtn => 'View All';

  @override
  String get home_searchBtn => 'SEARCH';

  @override
  String get home_bannerLanguage => 'LANGUAGE TRAINING';

  @override
  String get home_bannerCalculate => 'CALCULATE';

  @override
  String get home_bannerProblems => 'PROBLEMS SOLVE';

  @override
  String get home_filterTitle => 'FILTER ACTIVITIES';

  @override
  String get home_filterCategory => 'CATEGORY';

  @override
  String get home_filterLevel => 'LEVEL';

  @override
  String get home_filterAll => 'ALL';

  @override
  String get home_filterEasy => 'EASY';

  @override
  String get home_filterMedium => 'MEDIUM';

  @override
  String get home_filterHard => 'HARD';

  @override
  String get home_suggested => 'SUGGESTED';

  @override
  String get parentprofile_postBtn => 'POST';

  @override
  String get register_backBtn => 'BACK';

  @override
  String get register_signuptoBtn => 'SIGN-UP TO';

  @override
  String get register_facebookBtn => 'CONTINUE WITH FACEBOOK';

  @override
  String get register_googleBtn => 'CONTINUE WITH GOOGLE';

  @override
  String get register_nextBtn => 'NEXT';

  @override
  String get register_registerBtn => 'REGISTER';

  @override
  String get register_additionalBtn => 'ADDITIONAL INFORMATION';

  @override
  String register_namesurnamechildBtn(Object index) {
    return 'NAME & SURNAME (CHILDREN) $index';
  }

  @override
  String get register_birthdayBtn => 'BIRTHDAY : DD/MM/YYYY';

  @override
  String get register_okBtn => 'OK';

  @override
  String get register_pls => 'Please fill in all the information in the list. ';

  @override
  String get register_finish => 'Successfully registered!';

  @override
  String get register_relation => 'RELATION';

  @override
  String get register_pickbirthday => 'Choose birthday';

  @override
  String get register_Anerroroccurredplstry =>
      'An error occurred. Please try again.';

  @override
  String register_Anerroroccurred(Object index) {
    return 'An error occurred: $index';
  }

  @override
  String register_sus(Object index) {
    return 'Registration successful! Added $index child.';
  }

  @override
  String register_submitterror(Object index) {
    return 'Submit error: $index';
  }

  @override
  String register_requiredinformation(Object index) {
    return 'Please fill in all the required information (name, date of birth, relationship) in the list. $index';
  }

  @override
  String get login_backBtn => 'BACK';

  @override
  String get login_facebookBtn => 'CONTINUE WITH FACEBOOK';

  @override
  String get login_googleBtn => 'CONTINUE WITH GOOGLE';

  @override
  String get setting_backBtn => 'BACK';

  @override
  String get setting_settingBtn => 'SETTING';

  @override
  String get setting_personalBtn => 'PERSONAL INFORMATION';

  @override
  String get setting_generalBtn => 'GENERAL';

  @override
  String get setting_profileBtn => 'PROFILE';

  @override
  String get setting_childBtn => 'CHILD';

  @override
  String get setting_notificationBtn => 'NOTIFICATIONS';

  @override
  String get setting_thaiBtn => 'THAI';

  @override
  String get setting_englishBtn => 'ENGLISH';

  @override
  String get setting_logoutBtn => 'LOG OUT';

  @override
  String get namesetting_changenameBtn => 'CHANGE NAME';

  @override
  String get namesetting_enternewnameBtn => 'ENTER NEW NAME';

  @override
  String get namesetting_hint => 'Type your name...';

  @override
  String get namesetting_saveBtn => 'SAVE';

  @override
  String get profilesetting_nameBtn => 'NAME';

  @override
  String get profilesetting_deleteaccoutBtn => 'DELETE ACCOUNT';

  @override
  String get profileSet_deleteDialogTitle => 'DELETE ACCOUNT?';

  @override
  String get profilesetting_areusureBtn =>
      'Are you sure you want to delete your account? This action cannot be undone.';

  @override
  String get profilesetting_cancelBtn => 'CANCEL';

  @override
  String get profilesetting_deleteBtn => 'DELETE';

  @override
  String get childprofile_mathGame => 'MATH GAME';

  @override
  String get childprofile_workoutGame => 'WORK OUT GAME';

  @override
  String get childsetting_childsettingBtn => 'CHILD SETTING';

  @override
  String get childsetting_scoreBtn => 'SCORE';

  @override
  String get childsetting_viewprofileBtn => 'VIEW PROFILE';

  @override
  String get childsetting_manageBtn => 'MANAGE';

  @override
  String get childgallery_title => 'MY GALLERY';

  @override
  String get childgallery_empty => 'NO POSTS YET';

  @override
  String get history_timesSuffix => 'TIMES';

  @override
  String get result_title => 'PLAYING RESULT';

  @override
  String get result_timeUsedTitle => 'TIME USED';

  @override
  String get redemption_playBtn => 'PLAY';

  @override
  String get redemption_rewardIceCream => 'ICE CREAM';

  @override
  String get redemption_rewardPlaytime => '1 HR PLAYTIME';

  @override
  String get redemption_rewardToy => 'NEW TOY';

  @override
  String get redemption_rewardStickers => 'STICKERS';

  @override
  String get redemption_historyPlayedDefault => 'Played Ping Pong';

  @override
  String get redemption_historyRedeemedDefault => 'Redeemed Ice Cream';

  @override
  String get dialog_deleteTitle => 'Delete Profile?';

  @override
  String get dialog_deleteContent =>
      'Are you sure you want to delete this profile? This action cannot be undone.';

  @override
  String get dialog_confirmDelete => 'DELETE';

  @override
  String get dialog_cancel => 'CANCEL';

  @override
  String get dialog_saveSuccess => 'Saved successfully!';

  @override
  String get notificationsetting_notificationBtn => 'NOTIFICATIONS';

  @override
  String get notificationsetting_allnotificationBtn => 'ALL NOTIFICATIONS';

  @override
  String get notificationsetting_postBtn => 'POST';

  @override
  String get notificationsetting_likeBtn => 'LIKE';

  @override
  String get notificationsetting_commentBtn => 'COMMENT';

  @override
  String get videodetail_activitynameBtn => 'ACTIVITY NAME';

  @override
  String get videodetail_nameBtn => 'name';

  @override
  String get videodetail_DescriptionBtn => 'DESCRIPTION';

  @override
  String get videodetail_descriptionBtn => 'description';

  @override
  String get videodetail_howtoplayBtn => 'HOW TO PLAY / INSTRUCTIONS:';

  @override
  String get videodetail_contentBtn => 'content';

  @override
  String get videodetail_startBtn => 'START';

  @override
  String get videodetail_addBtn => 'ADD';

  @override
  String get videodetail_videoNotAvailable =>
      'Video Not Available (HTML Content Missing)';

  @override
  String get videodetail_activityNameLabel => 'ACTIVITY NAME:';

  @override
  String get videodetail_descriptionLabel => 'DESCRIPTION:';

  @override
  String get videodetail_howToPlayLabel => 'HOW TO PLAY / INSTRUCTIONS:';

  @override
  String get videodetail_categoryPrefix => 'Category: ';

  @override
  String get videodetail_difficultyPrefix => 'Difficulty: ';

  @override
  String get videodetail_maxScorePrefix => 'Max Score: ';

  @override
  String get addchild_namesurnameBtn => 'NAME & SURNAME (CHILDREN)';

  @override
  String get addchild_errorName => 'Please enter a name';

  @override
  String get addchild_birthdayBtn => 'BIRTHDAY : DD/MM/YYYY';

  @override
  String get addchild_okBtn => 'OK';

  @override
  String get childnamesetting_editnameBtn => 'EDIT NAME';

  @override
  String get childnamesetting_saveBtn => 'SAVE';

  @override
  String get managechild_manageprofileBtn => 'MANAGE PROFILE';

  @override
  String get managechild_nameBtn => 'NAME';

  @override
  String get managechild_medalsandredemptionBtn => 'MEDALS & REDEMPTION';

  @override
  String get managechild_deleteprofileBtn => 'DELETE PROFILE';

  @override
  String get dairyactivity_playhistoryBtn => 'PLAYING HISTORY';

  @override
  String get dairyactivity_timeBtn => 'time';

  @override
  String get dairyactivity_medalsBtn => 'medals';

  @override
  String get medalredemption_addrewardBtn => 'ADD AGREEMENT';

  @override
  String get medalredemption_rewardnameBtn => 'Agreement Name';

  @override
  String get medalredemption_costBtn => 'Cost (Points)';

  @override
  String get medalredemption_cancelBtn => 'CANCEL';

  @override
  String get medalredemption_addBtn => 'ADD';

  @override
  String get medalredemption_redemptionBtn => 'AGREEMENTS';

  @override
  String get medalredemption_activitiesBtn => 'ACTIVITIES';

  @override
  String get medalredemption_currentscoreBtn => 'CURRENT SCORE';

  @override
  String get medalredemption_rewardshopBtn => 'AGREEMENTS';

  @override
  String get medalredemption_successfullyBtn => 'Successfully Redeemed';

  @override
  String get agreement_typeTime => 'Time';

  @override
  String get agreement_typeItem => 'Item';

  @override
  String get agreement_typePrivilege => 'Privilege';

  @override
  String get agreement_typeFamily => 'Family';

  @override
  String get agreement_selectType => 'Select Agreement Type';

  @override
  String get agreement_confirmTitle => 'Confirm Agreement';

  @override
  String agreement_confirmMsg(int cost, String name) {
    return 'Use $cost points to redeem \"$name\"?';
  }

  @override
  String get agreement_confirmBtn => 'CONFIRM';

  @override
  String get agreement_sessionActive => 'Session Active';

  @override
  String get agreement_timeRemaining => 'Time Remaining';

  @override
  String get agreement_startTimer => 'START';

  @override
  String get agreement_stopTimer => 'STOP';

  @override
  String get agreement_endSession => 'END SESSION';

  @override
  String get agreement_sessionComplete => 'Session Complete!';

  @override
  String get agreement_behaviorTitle => 'How was the behavior?';

  @override
  String get agreement_behaviorGood => 'Good';

  @override
  String get agreement_behaviorOk => 'OK';

  @override
  String get agreement_behaviorBad => 'Needs Improvement';

  @override
  String agreement_bonusMsg(int points) {
    return 'Bonus: +$points points';
  }

  @override
  String agreement_deductMsg(int points) {
    return 'Deduction: -$points points';
  }

  @override
  String get agreement_noChange => 'No point change';

  @override
  String agreement_notEnoughPoints(int needed) {
    return 'Not enough points! Need $needed more.';
  }

  @override
  String get agreement_durationLabel => 'Duration (minutes)';

  @override
  String get agreement_emptyList => 'No agreements yet';

  @override
  String get agreement_emptyHint => 'Tap + to create a new agreement';

  @override
  String get physical_snackNoEvidence =>
      'Please attach video or image evidence.';

  @override
  String physical_snackInvalidScore(int maxScore) {
    return 'Please set a valid score (1 to $maxScore).';
  }

  @override
  String get physical_dialogSubmitTitle => 'Submission Complete!';

  @override
  String get physical_dialogSubmitContent =>
      'Your evidence has been submitted for approval.';

  @override
  String get physical_dialogOkBtn => 'OK';

  @override
  String physical_snackSubmitError(String error) {
    return 'Submission Error: $error';
  }

  @override
  String get physical_dialogEnterScoreTitle => 'Enter Score';

  @override
  String physical_dialogEnterScoreHint(int maxScore) {
    return 'Enter score (1-$maxScore)';
  }

  @override
  String get physical_dialogCancelBtn => 'Cancel';

  @override
  String physical_snackInvalidInput(int maxScore) {
    return 'Please enter a valid score (0-$maxScore)';
  }

  @override
  String get physical_stopBtn => 'STOP';

  @override
  String get physical_startBtn => 'START';

  @override
  String get physical_takePhotoBtn => 'TAKE PHOTO';

  @override
  String get physical_medalsScoreLabel => 'MEDALS / SCORE';

  @override
  String get physical_diaryLabel => 'DIARY';

  @override
  String get physical_diaryHint => 'Enter notes here...';

  @override
  String get physical_imageEvidenceLabel => 'IMAGE EVIDENCE';

  @override
  String get physical_videoEvidenceLabel => 'VIDEO EVIDENCE';

  @override
  String get physical_timeLabel => 'TIME';

  @override
  String get physical_submittingBtn => 'Submitting...';

  @override
  String get physical_finishBtn => 'FINISH';

  @override
  String get physical_addChildren => 'Add Children';

  @override
  String get physical_addChildrenDesc => 'Select children to play together';

  @override
  String physical_childrenAdded(int count) {
    return '+$count children';
  }

  @override
  String get physical_currentChild => 'Currently playing';

  @override
  String get physical_confirm => 'Confirm';

  @override
  String get languagedetail_titlePrefix => 'LANGUAGE: ';

  @override
  String get languagedetail_categoryPrefix => 'CATEGORY: ';

  @override
  String get languagedetail_activityTitleLabel => 'ACTIVITY TITLE';

  @override
  String get languagedetail_descriptionLabel => 'DESCRIPTION';

  @override
  String get languagedetail_difficultyPrefix => 'Difficulty: ';

  @override
  String get languagedetail_maxScorePrefix => 'Max Score: ';

  @override
  String get languagedetail_startBtn => 'START';

  @override
  String get itemintro_recordToEnable => 'Record to enable playback';

  @override
  String get itemintro_listenExampleBtn => 'LISTEN TO EXAMPLE';

  @override
  String get itemintro_practiceNowBtn => 'PRACTICE NOW';

  @override
  String get itemintro_submitBtn => 'SUBMIT';

  @override
  String get itemintro_playsection => 'PLAY SECTION';

  @override
  String get itemintro_record => 'RECORD';

  @override
  String get itemintro_casttotv => 'CAST TO TV';

  @override
  String get itemintro_airplay => 'AIRPLAY';

  @override
  String get itemintro_previous => '< PREVIOUS';

  @override
  String get itemintro_next => 'NEXT >';

  @override
  String get itemintro_finish => 'FINISH >';

  @override
  String get itemintro_Videonotavailable => 'Video not available';

  @override
  String get record_loading => 'Loading...';

  @override
  String get record_finishBtn => 'FINISH';

  @override
  String get record_errorMic => 'Microphone error or permission denied';

  @override
  String get record_statusRecording => 'Recording...';

  @override
  String get record_statusIdle => 'Press mic to record';

  @override
  String get result_activityCompletedDefault => 'ACTIVITY COMPLETED';

  @override
  String get result_greatJobTitle => 'GREAT JOB!';

  @override
  String get result_totalScoreLabel => 'Total Score';

  @override
  String get result_timeSpentLabel => 'Time Spent';

  @override
  String get result_retryBtn => 'RETRY';

  @override
  String get result_backToActivitiesBtn => 'BACK TO ACTIVITIES';

  @override
  String get result_returnHomeBtn => 'RETURN HOME';

  @override
  String result_timeFormat(int minutes, int seconds) {
    return '$minutes min $seconds sec';
  }

  @override
  String get calculate_title => 'CALCULATE';

  @override
  String get calculate_plusBtn => 'PLUS +';

  @override
  String get calculate_minusBtn => 'MINUS -';

  @override
  String get calculate_multiplyBtn => 'MULTIPLY *';

  @override
  String get calculate_divideBtn => 'DEVIDE /';

  @override
  String get calculate_mixBtn => 'MIX + - * /';

  @override
  String get calculate_problemsSolveBtn => 'PROBLEMS SOLVE';

  @override
  String get languagehub_searchHint => 'search...';

  @override
  String get languagehub_trainingTitle => 'LANGUAGE TRAINING';

  @override
  String get languagehub_listeningSpeakingTitle => 'LISTENING AND SPEAKING';

  @override
  String get languagehub_easyBtn => 'EASY';

  @override
  String get languagehub_mediumBtn => 'MEDIUM';

  @override
  String get languagehub_difficultBtn => 'DIFFICULT';

  @override
  String get plus_castToTvBtn => 'CAST TO TV';

  @override
  String get plus_answerBtn => 'ANSWER';

  @override
  String get problemdetail_title => 'PROBLEMS SOLVE';

  @override
  String get problemdetail_castToTvBtn => 'CAST TO TV';

  @override
  String get problemdetail_answerBtn => 'ANSWER';

  @override
  String get problemanswer_title => 'ANSWER';

  @override
  String get problemanswer_defaultQuestion =>
      'THERE ARE 6 CATS IN THE FIELD.\nANOTHER 2 CATS WALK INTO THE FIELD.\nHOW MANY CATS ARE THERE IN TOTAL ?';

  @override
  String get problemanswer_defaultAnswer => 'THERE ARE 8 CATS IN TOTAL.';

  @override
  String get problemplaying_finishBtn => 'FINISH';

  @override
  String get createpost_sharesus => 'Post shared successfully!';

  @override
  String get createpost_error => 'An error occurred:';

  @override
  String get createpost_newpost => 'New post';

  @override
  String get createpost_share => 'Share';

  @override
  String get createpost_picksomepicture => 'Tap to select a picture';

  @override
  String get createpost_changepic => 'Change picture';

  @override
  String get createpost_writecaption => 'Write a caption...';

  @override
  String get languagelist_snackNotConnected =>
      'This flow is not connected to activities yet.';

  @override
  String get common_categoryLabel => 'Category';

  @override
  String get common_difficultyLabel => 'Difficulty';

  @override
  String get common_maxScoreLabel => 'Max Score';

  @override
  String get common_categoryLanguage => 'Language';

  @override
  String get common_categoryPhysical => 'Physical';

  @override
  String get common_categoryCalculate => 'Calculate';

  @override
  String get common_activityLanguage => 'Language Activity';

  @override
  String get common_activityPhysical => 'Physical Activity';

  @override
  String get common_activityCalculate => 'Calculation Activity';

  @override
  String get common_difficultyEasy => 'Easy';

  @override
  String get common_difficultyMedium => 'Medium';

  @override
  String get common_difficultyHard => 'Hard';

  @override
  String get createActivity_title => 'CREATE ACTIVITY';

  @override
  String get createActivity_selectCategory => 'Select Category';

  @override
  String get createActivity_physical => 'Physical';

  @override
  String get createActivity_calculate => 'Calculate';

  @override
  String get createActivity_name => 'Activity Name';

  @override
  String get createActivity_description => 'Description';

  @override
  String get createActivity_content => 'How to Play / Instructions';

  @override
  String get createActivity_difficulty => 'Difficulty';

  @override
  String get createActivity_maxScore => 'Max Score';

  @override
  String get createActivity_videoUrl => 'Video URL (TikTok)';

  @override
  String get createActivity_addQuestion => 'Add Question';

  @override
  String get createActivity_question => 'Question';

  @override
  String get createActivity_answer => 'Answer';

  @override
  String get createActivity_solution => 'Solution / Explanation';

  @override
  String get createActivity_score => 'Score';

  @override
  String get createActivity_submit => 'CREATE';

  @override
  String get createActivity_success => 'Activity created successfully!';

  @override
  String get createActivity_error => 'Failed to create activity';

  @override
  String get createActivity_nameRequired => 'Please enter an activity name';

  @override
  String get createActivity_contentRequired => 'Please enter instructions';

  @override
  String get createActivity_needQuestions => 'Please add at least one question';

  @override
  String createActivity_questionNo(int index) {
    return 'Question $index';
  }

  @override
  String get createActivity_removeQuestion => 'Remove';

  @override
  String get createActivity_creating => 'Creating...';

  @override
  String get profile_myActivities => 'MY ACTIVITIES';

  @override
  String get profile_noActivities => 'No activities yet';

  @override
  String get profile_editActivity => 'Edit Activity';

  @override
  String get profile_deleteActivity => 'Delete Activity';

  @override
  String profile_deleteConfirm(String name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String get profile_deleteSuccess => 'Activity deleted';

  @override
  String get profile_updateSuccess => 'Activity updated';

  @override
  String get profile_save => 'SAVE';

  @override
  String get profile_manage => 'MANAGE';

  @override
  String get share_title => 'SHARE RESULT';

  @override
  String get share_asImage => 'Image';

  @override
  String get share_asText => 'Text';

  @override
  String get share_greatJob => 'GREAT JOB!';

  @override
  String get share_keepTrying => 'KEEP TRYING!';

  @override
  String share_textTemplate(String activityName, int score, int maxScore) {
    return 'I scored $score/$maxScore on \"$activityName\" in Skill Wallet Kool!';
  }

  @override
  String get common_loginFailed => 'Login failed. Please try again.';

  @override
  String common_errorGeneric(String msg) {
    return 'Error: $msg';
  }

  @override
  String get common_processing => 'Processing...';

  @override
  String get common_retry => 'Retry';

  @override
  String get common_cancel => 'Cancel';

  @override
  String get common_close => 'Close';

  @override
  String get calculate_restartTitle => 'Restart?';

  @override
  String get calculate_restartMsg => 'Time and answers will be reset';

  @override
  String get calculate_restartBtn => 'Restart';

  @override
  String calculate_solutionTitle(int index) {
    return 'Answer #$index';
  }

  @override
  String get calculate_questionLabel => 'Question:';

  @override
  String get calculate_answerLabel => 'Answer:';

  @override
  String get calculate_pressStart => 'Press START button to begin timing';

  @override
  String get calculate_questionsAfterTimer =>
      'Questions will appear after timing completes';

  @override
  String calculate_failedPickFile(String error) {
    return 'Failed to pick file: $error';
  }

  @override
  String get calculate_childIdNotFound =>
      'Child ID not found. Please login again.';

  @override
  String calculate_errorCompleting(String error) {
    return 'Error completing activity: $error';
  }

  @override
  String get itemintro_videoLoading => 'Please wait. Video is loading...';

  @override
  String get itemintro_timingIncomplete =>
      'Timing data for this sentence is incomplete';

  @override
  String itemintro_videoPlayError(String error) {
    return 'Cannot play video: $error';
  }

  @override
  String get itemintro_micPermission => 'Please allow microphone access';

  @override
  String itemintro_recordStartError(String error) {
    return 'Cannot start recording: $error';
  }

  @override
  String get itemintro_recordTooShort =>
      'Recording too short. Please try again';

  @override
  String itemintro_evalResult(int score, String text) {
    return 'Evaluation result: $score% - \"$text\"';
  }

  @override
  String itemintro_questError(String error) {
    return 'Error completing quest: $error';
  }

  @override
  String get itemintro_playbackFailed => 'Failed to play back recording.';

  @override
  String get record_micDenied => 'Microphone permission denied.';

  @override
  String get record_recordingFailed => 'Recording failed.';

  @override
  String get record_playbackFailed => 'Failed to play audio.';

  @override
  String get record_noValidAudio => 'Error: No valid audio recorded.';

  @override
  String record_aiError(String error) {
    return 'AI Error: $error';
  }

  @override
  String get medals_noActivityHistory => 'No activity history';

  @override
  String get medals_noHistory => 'No history';

  @override
  String get post_noComments => 'No comments yet. Be the first!';

  @override
  String get namesetting_saveFailed => 'Cannot save name. Please try again.';

  @override
  String get activityCard_selectChild => 'Please select a child';

  @override
  String get activityCard_selectChildMsg =>
      'You must select a child before playing activities';

  @override
  String get activityCard_goSelect => 'Go select child';

  @override
  String get childsetting_addSuccess => 'Child added successfully';

  @override
  String get childsetting_deleteSuccess => 'Child deleted successfully';

  @override
  String get childsetting_selectSuccess => 'Child selected successfully';

  @override
  String get childsetting_noChildren => 'No children in system';

  @override
  String get childsetting_addChild => 'Add child';

  @override
  String get childsetting_active => 'ACTIVE';

  @override
  String get childsetting_select => 'SELECT';

  @override
  String get common_selectSource => 'Select Source';

  @override
  String get common_camera => 'Camera';

  @override
  String get common_gallery => 'Gallery';

  @override
  String get common_ok => 'OK';

  @override
  String get common_submit => 'SUBMIT';

  @override
  String get common_addImage => 'Add Image';

  @override
  String get common_addVideo => 'Add Video';

  @override
  String get common_videoAdded => 'Video Added';

  @override
  String get common_image => 'IMAGE';

  @override
  String get common_video => 'VIDEO';

  @override
  String get common_howToPlay => 'HOW TO PLAY';

  @override
  String get common_questions => 'QUESTIONS';

  @override
  String get common_evidence => 'EVIDENCE';

  @override
  String get common_finish => 'FINISH';

  @override
  String get common_start => 'START';

  @override
  String get common_restart => 'RESTART';

  @override
  String get common_done => 'done';

  @override
  String get common_submitting => 'Submitting...';

  @override
  String get common_score => 'Score';

  @override
  String get calculate_noAnswer => 'No answer available';

  @override
  String get calculate_answer => 'ANSWER';

  @override
  String get calculate_answerAgain => 'ANSWER AGAIN';

  @override
  String get calculate_stopBeforeAnswer => 'Stop timer before answering';

  @override
  String calculate_yourAnswer(String answer) {
    return 'Your answer: $answer';
  }

  @override
  String get calculate_typeAnswer => 'Type your answer...';

  @override
  String get calculate_diaryNotes => 'DIARY / NOTES';

  @override
  String get calculate_writeNotes => 'Write your notes here...';

  @override
  String get calculate_noQuestions => 'No questions available';

  @override
  String get calculate_confirmFinishTitle => 'Finish?';

  @override
  String get calculate_confirmFinishMsg =>
      'Are you sure you want to finish? You cannot restart the timer.';

  @override
  String get calculate_descriptionLabel => 'DESCRIPTION';

  @override
  String get calculate_solutionLabel => 'Solution:';

  @override
  String get calculate_correct => 'CORRECT';

  @override
  String get calculate_incorrect => 'INCORRECT';

  @override
  String get record_title => 'RECORD';

  @override
  String itemintro_segmentOf(int current, int total) {
    return 'Segment $current of $total';
  }

  @override
  String get itemintro_speak => 'SPEAK';

  @override
  String get itemintro_point => 'POINT';

  @override
  String get itemintro_completed => 'COMPLETED';

  @override
  String get itemintro_pausePlayback => 'PAUSE PLAYBACK...';

  @override
  String get itemintro_listenRecording => 'LISTEN TO YOUR RECORDING';

  @override
  String get itemintro_recordToPlayback => 'Record to enable playback';

  @override
  String get videodetail_previewNotAvailable => 'Video Preview Not Available';

  @override
  String get videodetail_openInBrowser => 'Open in Browser to Watch';

  @override
  String get videodetail_openTiktok => 'OPEN TIKTOK';

  @override
  String get videodetail_noVideoUrl => 'No video URL available';

  @override
  String get languagehub_appTitle => 'KRATON';

  @override
  String get languagehub_fillInBlanksTitle => 'FILL IN THE BLANKS';

  @override
  String get problemplaying_title => 'PROBLEMS SOLVE';

  @override
  String get problemplaying_resultsTitle => 'PLAYING RESULTS';

  @override
  String get problemplaying_medalsLabel => 'MEDALS';

  @override
  String get problemplaying_diaryLabel => 'DIARY';

  @override
  String get problemplaying_diaryHint => 'Write something...';

  @override
  String get problemplaying_imageLabel => 'IMAGE';

  @override
  String get problemplaying_timeLabel => 'TIME';

  @override
  String get problemplaying_answerBtn => 'ANSWER';

  @override
  String get result_resultTitle => 'RESULT';

  @override
  String get result_totalScoreTitle => 'TOTAL SCORE';

  @override
  String get result_keepTryingTitle => 'KEEP TRYING!';

  @override
  String get result_timeSpentPrefix => 'TIME SPENT: ';

  @override
  String get result_playAgainBtn => 'PLAY AGAIN';

  @override
  String get plus_title => 'PLUS +';

  @override
  String get plus_questionTitle => 'QUESTION';

  @override
  String get plus_startBtn => 'START';

  @override
  String get answerplus_title => 'ANSWER PLUS +';

  @override
  String get answerplus_questionLabel => 'QUESTION';

  @override
  String get answerplus_answerLabel => 'ANSWER';
}
