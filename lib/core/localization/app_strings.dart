import '../../models/prayer_time_model.dart';
import '../../models/quran_progress_models.dart';

enum AppLanguage { english, arabic, kurdish }

class AppStrings {
  const AppStrings(this.language);

  final AppLanguage language;

  bool get isRtl => language != AppLanguage.english;

  String get appName => switch (language) {
    AppLanguage.english => 'Quran Noor',
    AppLanguage.arabic => 'Quran Noor',
    AppLanguage.kurdish => 'Quran Noor',
  };

  String get navHome => switch (language) {
    AppLanguage.english => 'Home',
    AppLanguage.arabic => 'الرئيسية',
    AppLanguage.kurdish => 'سەرەتا',
  };

  String get navQuran => switch (language) {
    AppLanguage.english => 'Quran',
    AppLanguage.arabic => 'القرآن',
    AppLanguage.kurdish => 'قورئان',
  };

  String get navZikir => switch (language) {
    AppLanguage.english => 'Zikir',
    AppLanguage.arabic => 'الذكر',
    AppLanguage.kurdish => 'زکرەکانم',
  };

  String get navPrayer => switch (language) {
    AppLanguage.english => 'Prayer',
    AppLanguage.arabic => 'الصلاة',
    AppLanguage.kurdish => 'بانگ',
  };

  String get navSettings => switch (language) {
    AppLanguage.english => 'Settings',
    AppLanguage.arabic => 'الإعدادات',
    AppLanguage.kurdish => 'ڕێکخستنەکان',
  };

  String get greeting => switch (language) {
    AppLanguage.english => 'Assalamu alaikum',
    AppLanguage.arabic => 'السلام عليكم',
    AppLanguage.kurdish => 'السلام عليكم',
  };

  String get overviewIntro => switch (language) {
    AppLanguage.english =>
      'Practice recitation, keep prayer times close, and move through the Quran with less friction.',
    AppLanguage.arabic =>
      'تدرّب على التلاوة، وابقَ قريباً من أوقات الصلاة، وتنقّل في القرآن بسهولة أكبر.',
    AppLanguage.kurdish =>
      'لە ئەپی قورئان ڕاهێنان بکە و فێری خوێندەوەی قورئانی پیرۆز بە، بە ئاسانترین ڕێگا .',
  };

  String get todayFocus => switch (language) {
    AppLanguage.english => 'Today\'s focus',
    AppLanguage.arabic => 'تركيز اليوم',
    AppLanguage.kurdish => 'کاتەکانی ئەمڕۆ',
  };

  String get prepareRecitation => switch (language) {
    AppLanguage.english => 'Prepare your next recitation session',
    AppLanguage.arabic => 'استعد لجلسة التلاوة القادمة',
    AppLanguage.kurdish => 'خۆت بۆ دانیشتنی داهاتووی تلاوەت ئامادە بکە',
  };

  String nextPrayerAt(String prayer, String time) => switch (language) {
    AppLanguage.english => '$prayer at $time',
    AppLanguage.arabic => '$prayer عند $time',
    AppLanguage.kurdish => '$prayer لە $time',
  };

  String get enableLocationHint => switch (language) {
    AppLanguage.english =>
      'Choose your prayer city in settings, and enable location when you want to use the live Qibla compass.',
    AppLanguage.arabic =>
      'اختر مدينة الصلاة من الإعدادات، وفعّل الموقع عندما تريد استخدام بوصلة القبلة الحية.',
    AppLanguage.kurdish =>
      'شاری بانگ لە ڕێکخستنەکان هەڵبژێرە، و شوێن چالاک بکە کاتێک دەتەوێت کومپاسی زیندووی قیبلە بەکاربهێنیت.',
  };

  String nextPrayerBeginsIn(String countdown) => switch (language) {
    AppLanguage.english =>
      'Next prayer begins in $countdown. Jump back into recitation before the time window closes.',
    AppLanguage.arabic =>
      'تبدأ الصلاة القادمة بعد $countdown. ارجع إلى التلاوة قبل انتهاء الوقت.',
    AppLanguage.kurdish => 'بانگی داهاتوو دوای $countdown دەست پێدەکات.',
  };

  String get openQuran => switch (language) {
    AppLanguage.english => 'Open Quran',
    AppLanguage.arabic => 'افتح القرآن',
    AppLanguage.kurdish => 'قورئان بکەرەوە',
  };

  String get godNamesTitle => switch (language) {
    AppLanguage.english => 'Names of Allah',
    AppLanguage.arabic => 'أسماء الله الحسنى',
    AppLanguage.kurdish => 'ناوە جوانەکانی خوای گەورە',
  };

  String get openGodNames => switch (language) {
    AppLanguage.english => 'Open names',
    AppLanguage.arabic => 'افتح الأسماء',
    AppLanguage.kurdish => 'ناوەکان بکەرەوە',
  };

  String get godNamesHomeBody => switch (language) {
    AppLanguage.english =>
      'Browse the 99 beautiful names with Arabic, Kurdish, and English meanings in one place.',
    AppLanguage.arabic =>
      'تصفّح الأسماء الحسنى مع العربية والكردية والإنجليزية في شاشة واحدة.',
    AppLanguage.kurdish =>
      '٩٩ ناوە پیرۆزەکانی خوای گەورە بە هەر سێ زمانی کوردی ، ئینگلیزی، عەرەبی  لەگەڵ تەفسیرەکانیان.',
  };

  String get godNamesHeroSubtitle => switch (language) {
    AppLanguage.english =>
      'A searchable collection of the 99 beautiful names with layered meanings across three languages.',
    AppLanguage.arabic =>
      'مجموعة قابلة للبحث تضم الأسماء الحسنى مع معانٍ مترابطة عبر ثلاث لغات.',
    AppLanguage.kurdish =>
      'دەتوانی لەرێگای ئەو سێرچەی خوارە گەڕان بکەیت بۆ ناوە پیرۆزەکانی خوای گەورە ، وە لەگەل بینینی واتا و پەیامەکەیان.',
  };

  String godNamesCountLabel(int count) => switch (language) {
    AppLanguage.english => '$count names',
    AppLanguage.arabic => '$count اسماً',
    AppLanguage.kurdish => '$count ناو',
  };

  String get godNamesSearchHint => switch (language) {
    AppLanguage.english =>
      'Search by Arabic, transliteration, English, or Kurdish',
    AppLanguage.arabic =>
      'ابحث بالعربية أو باللفظ اللاتيني أو بالإنجليزية أو بالكردية',
    AppLanguage.kurdish =>
      'بە عەرەبی، خوێندنەوەی لاتینی، ئینگلیزی یان کوردی بگەڕێ',
  };

  String get godNamesNoResults => switch (language) {
    AppLanguage.english => 'No names matched this search.',
    AppLanguage.arabic => 'لا توجد أسماء تطابق هذا البحث.',
    AppLanguage.kurdish => 'هیچ ناوێک لەگەڵ ئەم گەڕانە ناگونجێت.',
  };

  String get godNamesArabicMeaningLabel => switch (language) {
    AppLanguage.english => 'Arabic meaning',
    AppLanguage.arabic => 'المعنى العربي',
    AppLanguage.kurdish => 'واتای عەرەبی',
  };

  String get godNamesEnglishMeaningLabel => switch (language) {
    AppLanguage.english => 'English meaning',
    AppLanguage.arabic => 'المعنى الإنجليزي',
    AppLanguage.kurdish => 'واتای ئینگلیزی',
  };

  String get godNamesKurdishMeaningLabel => switch (language) {
    AppLanguage.english => 'Kurdish meaning',
    AppLanguage.arabic => 'المعنى الكردي',
    AppLanguage.kurdish => 'واتای کوردی',
  };

  String get godNamesDetailsLabel => switch (language) {
    AppLanguage.english => 'View details',
    AppLanguage.arabic => 'عرض التفاصيل',
    AppLanguage.kurdish => 'بینینی وردەکاری',
  };

  String get godNamesRetryLabel => switch (language) {
    AppLanguage.english => 'Retry',
    AppLanguage.arabic => 'إعادة المحاولة',
    AppLanguage.kurdish => 'دووبارە هەوڵبدە',
  };

  String get godNamesLoadFailed => switch (language) {
    AppLanguage.english => 'Could not load the Names of Allah right now.',
    AppLanguage.arabic => 'تعذر تحميل أسماء الله الحسنى الآن.',
    AppLanguage.kurdish =>
      'ئێستا نەتوانرا ناوە جوانەکانی خوای گەورە بهێنرێن ڵەسێرڤەر.',
  };

  String get prayerTimes => switch (language) {
    AppLanguage.english => 'Prayer times',
    AppLanguage.arabic => 'أوقات الصلاة',
    AppLanguage.kurdish => 'کاتەکانی بانگ',
  };

  String get overview => switch (language) {
    AppLanguage.english => 'Overview',
    AppLanguage.arabic => 'نظرة عامة',
    AppLanguage.kurdish => 'پوختە',
  };

  String get overviewSubtitle => switch (language) {
    AppLanguage.english => 'A quick read on what is ready right now.',
    AppLanguage.arabic => 'نظرة سريعة على ما هو جاهز الآن.',
    AppLanguage.kurdish => 'پوختەی ئیستا',
  };

  String get surahsLoaded => switch (language) {
    AppLanguage.english => 'Surahs loaded',
    AppLanguage.arabic => 'السور المحمّلة',
    AppLanguage.kurdish => 'سوورەتە بەردەستەکان',
  };

  String get ayahsAvailable => switch (language) {
    AppLanguage.english => 'Ayahs available',
    AppLanguage.arabic => 'الآيات المتاحة',
    AppLanguage.kurdish => 'ئایەتە بەردەستەکان',
  };

  String get prayerAlerts => switch (language) {
    AppLanguage.english => 'Prayer alerts',
    AppLanguage.arabic => 'تنبيهات الصلاة',
    AppLanguage.kurdish => 'ئاگادارکردنەوەی بانگ',
  };

  String get onLabel => switch (language) {
    AppLanguage.english => 'On',
    AppLanguage.arabic => 'مفعل',
    AppLanguage.kurdish => 'چالاک',
  };

  String get offLabel => switch (language) {
    AppLanguage.english => 'Off',
    AppLanguage.arabic => 'متوقف',
    AppLanguage.kurdish => 'ناچالاک',
  };

  String get quickActions => switch (language) {
    AppLanguage.english => 'Quick actions',
    AppLanguage.arabic => 'إجراءات سريعة',
    AppLanguage.kurdish => 'کردارە خێراکان',
  };

  String get quickActionsSubtitle => switch (language) {
    AppLanguage.english => 'Shortcuts into the parts of the app you use most.',
    AppLanguage.arabic => 'اختصارات إلى الأجزاء التي تستخدمها أكثر.',
    AppLanguage.kurdish => 'ئەو بەشانەی زۆرتر بەکار دێن.',
  };

  String get startRecitationSession => switch (language) {
    AppLanguage.english => 'Start a recitation session',
    AppLanguage.arabic => 'ابدأ جلسة تلاوة',
    AppLanguage.kurdish => 'دەستکردن بە خوێندنەوە',
  };

  String get startRecitationSubtitle => switch (language) {
    AppLanguage.english =>
      'Browse the surah library and open any ayah for listening or microphone practice.',
    AppLanguage.arabic =>
      'تصفّح مكتبة السور وافتح أي آية للاستماع أو التدريب بالميكروفون.',
    AppLanguage.kurdish =>
      'دەتوانی گوێ بگری لەهەر ئایەتێک یان ڕاهێنان کردن لەرێگای کردنەوی مایکرۆفۆن .',
  };

  String get checkPrayerReadiness => switch (language) {
    AppLanguage.english => 'Check prayer readiness',
    AppLanguage.arabic => 'تحقق من جاهزية الصلاة',
    AppLanguage.kurdish => 'بینینی کاتەکانی بانگی ئەمڕۆ',
  };

  String get checkPrayerReadinessSubtitle => switch (language) {
    AppLanguage.english =>
      'Review today\'s prayer schedule and notification status.',
    AppLanguage.arabic => 'راجع جدول الصلاة اليوم وحالة التنبيهات.',
    AppLanguage.kurdish => 'خشتەی بانگی ئەمڕۆ و دۆخی ئاگادارکردنەوەکان ببینە.',
  };

  String get quranLibrary => switch (language) {
    AppLanguage.english => 'Quran Library',
    AppLanguage.arabic => 'مكتبة القرآن',
    AppLanguage.kurdish => 'قورئانی پیرۆز',
  };

  String get quranLibrarySubtitle => switch (language) {
    AppLanguage.english =>
      'Browse the surahs, listen to the recitation, and start microphone practice ayah by ayah.',
    AppLanguage.arabic =>
      'تصفّح السور، واستمع إلى التلاوة، وابدأ التدريب بالميكروفون آية آية.',
    AppLanguage.kurdish =>
      'تەواوی قورئانی پیرۆز بەردەستە بۆ خوێندنەوە و ڕاهێنان .',
  };

  String get memorizationModeTitle => switch (language) {
    AppLanguage.english => 'Memorization Mode',
    AppLanguage.arabic => 'وضع الحفظ',
    AppLanguage.kurdish => 'لەبەرکردنی قورئانی پیرۆز',
  };

  String get memorizationModeSubtitle => switch (language) {
    AppLanguage.english =>
      'Follow a clear flow: start a new lesson, continue saved progress, fix weak points, and finish each surah with confidence.',
    AppLanguage.arabic =>
      'اتبع مساراً واضحاً: ابدأ درساً جديداً، وواصل التقدم المحفوظ، وراجع المواضع الضعيفة، ثم أتم السورة بثقة.',
    AppLanguage.kurdish =>
      'بە ڕێگایەکی ڕوون کار بکە: دەرسێکی نوێ دەست پێ بکە، لە شوێنی پاشەکەوتکراو بەردەوام بە، خاڵە لاوازەکان چاک بکەوە، و سورەتەکە تەواو بکە.',
  };

  String get memorizationWorkflowTitle => switch (language) {
    AppLanguage.english => 'How memorization works',
    AppLanguage.arabic => 'كيف يعمل مسار الحفظ',
    AppLanguage.kurdish => ' ڕێبەری لەبەرکردن  چۆن کار دەکات',
  };

  String get memorizationWorkflowBody => switch (language) {
    AppLanguage.english =>
      'Start reciting from memory. Correct words unlock the mushaf, mistakes are saved for review, and finished surahs stay marked as memorized.',
    AppLanguage.arabic =>
      'ابدأ التلاوة من الحفظ. الكلمات الصحيحة تكشف النص، والأخطاء تُحفظ للمراجعة، والسور المكتملة تبقى معلَّمة كمحفوظة.',
    AppLanguage.kurdish =>
      'لەبەرەوە دەست بە خوێندنەوە بکە. وشە دروستەکان دەقەکە دەردەخەن، هەڵەکان بۆ پێداچوونەوە هەڵدەگیرێن، و سورەتە تەواوبووەکان وەک لەبەرکراو نیشان دەدرێن.',
  };

  String memorizationStageLabel(MemorizationWorkflowStage stage) =>
      switch (stage) {
        MemorizationWorkflowStage.newLesson => switch (language) {
          AppLanguage.english => 'New lesson',
          AppLanguage.arabic => 'درس جديد',
          AppLanguage.kurdish => 'دەرسێکی نوێ',
        },
        MemorizationWorkflowStage.continueLesson => switch (language) {
          AppLanguage.english => 'Continue lesson',
          AppLanguage.arabic => 'واصل الدرس',
          AppLanguage.kurdish => 'بەردەوامبە لە دەرسەکە',
        },
        MemorizationWorkflowStage.needsPractice => switch (language) {
          AppLanguage.english => 'Needs practice',
          AppLanguage.arabic => 'يحتاج مراجعة',
          AppLanguage.kurdish => 'پێویستی بە ڕاهێنان هەیە',
        },
        MemorizationWorkflowStage.memorized => switch (language) {
          AppLanguage.english => 'Memorized',
          AppLanguage.arabic => 'محفوظة',
          AppLanguage.kurdish => 'لەبەرکراوە',
        },
      };

  String memorizationStageSummary(
    MemorizationWorkflowStage stage, {
    required int revealedWords,
    required int totalWords,
    int? lastMistakeWordIndex,
  }) => switch (stage) {
    MemorizationWorkflowStage.newLesson => switch (language) {
      AppLanguage.english => 'Start this surah from the beginning.',
      AppLanguage.arabic => 'ابدأ هذه السورة من البداية.',
      AppLanguage.kurdish => 'ئەم سورەتە لە سەرەتاوە دەست پێ بکە.',
    },
    MemorizationWorkflowStage.continueLesson => switch (language) {
      AppLanguage.english =>
        totalWords > 0
            ? 'Resume from word $revealedWords of $totalWords.'
            : 'Resume from your saved lesson progress.',
      AppLanguage.arabic =>
        totalWords > 0
            ? 'تابع من الكلمة $revealedWords من أصل $totalWords.'
            : 'تابع من موضع الدرس المحفوظ.',
      AppLanguage.kurdish =>
        totalWords > 0
            ? 'لە وشەی $revealedWords لە کۆی $totalWords بەردەوام بە.'
            : 'لە شوێنی پاشەکەوتکراوی دەرسەکە بەردەوام بە.',
    },
    MemorizationWorkflowStage.needsPractice => switch (language) {
      AppLanguage.english =>
        lastMistakeWordIndex == null
            ? 'Review the last weak section before moving on.'
            : 'Practice again from word ${lastMistakeWordIndex + 1}.',
      AppLanguage.arabic =>
        lastMistakeWordIndex == null
            ? 'راجع آخر موضع ضعيف قبل المتابعة.'
            : 'أعد التدريب من الكلمة ${lastMistakeWordIndex + 1}.',
      AppLanguage.kurdish =>
        lastMistakeWordIndex == null
            ? 'پێش بەردەوامبوون، دوا بەشی لاواز دوبارە ڕاهێنان بکە.'
            : 'دووبارە لە وشەی ${lastMistakeWordIndex + 1} ڕاهێنان بکە.',
    },
    MemorizationWorkflowStage.memorized => switch (language) {
      AppLanguage.english =>
        'This surah is marked memorized. Review it any time.',
      AppLanguage.arabic => 'هذه السورة معلّمة كمحفوظة. راجعها في أي وقت.',
      AppLanguage.kurdish =>
        'ئەم سورەتە وەک لەبەرکراو نیشان دراوە. هەرکاتێک دەتوانیت بیپێداچوونەوە.',
    },
  };

  String get openMemorizationMode => switch (language) {
    AppLanguage.english => 'Open memorization mode',
    AppLanguage.arabic => 'افتح وضع الحفظ',
    AppLanguage.kurdish => 'کردنەوەی بەشی لەبەرکردن',
  };

  String get memorizationStartRecitation => switch (language) {
    AppLanguage.english => 'Start recitation',
    AppLanguage.arabic => 'ابدأ التلاوة',
    AppLanguage.kurdish => 'دەستپێکردنی خوێندنەوە',
  };

  String get memorizationStopRecitation => switch (language) {
    AppLanguage.english => 'Stop recitation',
    AppLanguage.arabic => 'أوقف التلاوة',
    AppLanguage.kurdish => 'وەستاندنی خوێندنەوە',
  };

  String get memorizationListening => switch (language) {
    AppLanguage.english => 'Listening',
    AppLanguage.arabic => 'قيد الاستماع',
    AppLanguage.kurdish => 'گوێگرتن',
  };

  String get memorizationStopped => switch (language) {
    AppLanguage.english => 'Stopped',
    AppLanguage.arabic => 'متوقف',
    AppLanguage.kurdish => 'وەستاو',
  };

  String get memorizationTapToStart => switch (language) {
    AppLanguage.english => 'Tap to begin',
    AppLanguage.arabic => 'اضغط للبدء',
    AppLanguage.kurdish => 'کلیک بکە بۆ دەستپێکردن',
  };

  String memorizationProgressLabel(int revealed, int total) =>
      switch (language) {
        AppLanguage.english => 'Progress: $revealed / $total words',
        AppLanguage.arabic => 'التقدم: $revealed / $total كلمة',
        AppLanguage.kurdish => 'پێشکەوتن: $revealed / $total وشە',
      };

  String get memorizationMistakeTitle => switch (language) {
    AppLanguage.english => 'Mistake detected',
    AppLanguage.arabic => 'تم اكتشاف خطأ',
    AppLanguage.kurdish => 'هەڵە دۆزرایەوە',
  };

  String get memorizationExpectedWordLabel => switch (language) {
    AppLanguage.english => 'Expected word',
    AppLanguage.arabic => 'الكلمة الصحيحة',
    AppLanguage.kurdish => 'وشەی ڕاست',
  };

  String get memorizationSpokenWordLabel => switch (language) {
    AppLanguage.english => 'You said',
    AppLanguage.arabic => 'قلت',
    AppLanguage.kurdish => 'تۆ گوتت',
  };

  String get memorizationRetry => switch (language) {
    AppLanguage.english => 'Retry',
    AppLanguage.arabic => 'أعد المحاولة',
    AppLanguage.kurdish => 'دووبارە هەوڵ بدە',
  };

  String get memorizationContinue => switch (language) {
    AppLanguage.english => 'Continue',
    AppLanguage.arabic => 'متابعة',
    AppLanguage.kurdish => 'بەردەوام بە',
  };

  String get memorizationCompletedTitle => switch (language) {
    AppLanguage.english => 'Surah memorized',
    AppLanguage.arabic => 'تمت السورة',
    AppLanguage.kurdish => 'سورەتەکە  تەواوبوو',
  };

  String get memorizationCompletedBody => switch (language) {
    AppLanguage.english =>
      'Excellent. This surah is now marked as memorized and ready for review.',
    AppLanguage.arabic =>
      'أحسنت. هذه السورة معلّمة الآن كمحفوظة وجاهزة للمراجعة.',
    AppLanguage.kurdish =>
      'دەست خۆش. ئەم سورەتە ئێستا وەک لەبەرکراو نیشان دراوە و ئامادەی پێداچوونەوەیە.',
  };

  String get memorizationSavedCheckpointTitle => switch (language) {
    AppLanguage.english => 'Saved lesson',
    AppLanguage.arabic => 'درس محفوظ',
    AppLanguage.kurdish => 'دەرسێکی هەڵگیراو',
  };

  String memorizationSavedCheckpointBody(
    int revealed,
    int total,
  ) => switch (language) {
    AppLanguage.english =>
      'Resume from word $revealed of $total, or restart this surah from the beginning.',
    AppLanguage.arabic =>
      'تابع من الكلمة $revealed من أصل $total، أو ابدأ هذه السورة من جديد.',
    AppLanguage.kurdish =>
      'لە وشەی $revealed لە $total بەردەوام بە، یان ئەم سورەتە لە سەرەتاوە دووبارە دەست پێ بکە.',
  };

  String get memorizationResumeLesson => switch (language) {
    AppLanguage.english => 'Continue lesson',
    AppLanguage.arabic => 'واصل الدرس',
    AppLanguage.kurdish => 'بەردەوامبە لە دەرسەکە',
  };

  String get memorizationPracticeWeakPoint => switch (language) {
    AppLanguage.english => 'Practice weak point',
    AppLanguage.arabic => 'تدرّب على الموضع الضعيف',
    AppLanguage.kurdish => 'ڕاهێنان لە خاڵی لاواز',
  };

  String get memorizationStartFromBeginning => switch (language) {
    AppLanguage.english => 'Start from beginning',
    AppLanguage.arabic => 'ابدأ من البداية',
    AppLanguage.kurdish => 'لە سەرەتاوە دەست پێ بکە',
  };

  String get memorizationReviewFromBeginning => switch (language) {
    AppLanguage.english => 'Review from beginning',
    AppLanguage.arabic => 'راجع من البداية',
    AppLanguage.kurdish => 'لە سەرەتاوە پێداچوونەوە بکە',
  };

  String get memorizationErrorTitle => switch (language) {
    AppLanguage.english => 'Memorization error',
    AppLanguage.arabic => 'خطأ في الحفظ',
    AppLanguage.kurdish => 'هەڵەی حەفظ',
  };

  String get surahs => switch (language) {
    AppLanguage.english => 'Surahs',
    AppLanguage.arabic => 'السور',
    AppLanguage.kurdish => 'سوورەت',
  };

  String get ayahs => switch (language) {
    AppLanguage.english => 'Ayahs',
    AppLanguage.arabic => 'الآيات',
    AppLanguage.kurdish => 'ئایەت',
  };

  String get searchSurahHint => switch (language) {
    AppLanguage.english => 'Search by surah number, English, or Arabic name',
    AppLanguage.arabic => 'ابحث برقم السورة أو الاسم الإنجليزي أو العربي',
    AppLanguage.kurdish =>
      'بە ژمارەی سوورەت یان ناوی ئینگلیزی یان عەرەبی بگەڕێ',
  };

  String get allSurahs => switch (language) {
    AppLanguage.english => 'All surahs',
    AppLanguage.arabic => 'كل السور',
    AppLanguage.kurdish => 'هەموو سوورەتەکان',
  };

  String get favoriteSurahsTitle => switch (language) {
    AppLanguage.english => 'Favorite Surahs',
    AppLanguage.arabic => 'السور المفضلة',
    AppLanguage.kurdish => 'سوورەتە دڵخوازەکان',
  };

  String get favoriteSurahsSubtitle => switch (language) {
    AppLanguage.english => 'Quick access to the surahs you revisit most.',
    AppLanguage.arabic => 'وصول سريع إلى السور التي تعود إليها كثيراً.',
    AppLanguage.kurdish => 'دەستگەیشتنی خێرا بۆ ئەو سوورەتانەی دڵخوازتن .',
  };

  String resultsFor(String query) => switch (language) {
    AppLanguage.english => 'Results for "$query"',
    AppLanguage.arabic => 'نتائج "$query"',
    AppLanguage.kurdish => 'ئەنجامەکانی "$query"',
  };

  String surahCountLabel(int count) => switch (language) {
    AppLanguage.english => '$count surah${count == 1 ? '' : 's'} available',
    AppLanguage.arabic => '$count سورة متاحة',
    AppLanguage.kurdish => '$count سوورەت بەردەستە',
  };

  String ayahCountInline(int count) => switch (language) {
    AppLanguage.english => '$count ayahs',
    AppLanguage.arabic => '$count آية',
    AppLanguage.kurdish => '$count ئایەت',
  };

  String noSurahMatches(String query) => switch (language) {
    AppLanguage.english => 'No surahs matched "$query".',
    AppLanguage.arabic => 'لا توجد سور تطابق "$query".',
    AppLanguage.kurdish => 'هیچ سوورەتێک لەگەڵ "$query" ناگونجێت.',
  };

  String get searchTryAnother => switch (language) {
    AppLanguage.english => 'Try a different surah number or search term.',
    AppLanguage.arabic => 'جرّب رقماً أو عبارة بحث مختلفة.',
    AppLanguage.kurdish => 'ژمارەیەکی تر یان وشەیەکی تری گەڕان تاقی بکەرەوە.',
  };

  String get retry => switch (language) {
    AppLanguage.english => 'Retry',
    AppLanguage.arabic => 'إعادة المحاولة',
    AppLanguage.kurdish => 'دووبارە هەوڵبدە',
  };

  String get prayerTitle => prayerTimes;

  String get prayerSubtitle => switch (language) {
    AppLanguage.english =>
      'Live prayer timing based on your current location, with optional notifications for every prayer.',
    AppLanguage.arabic =>
      'أوقات صلاة مباشرة حسب موقعك الحالي، مع تنبيهات اختيارية لكل صلاة.',
    AppLanguage.kurdish =>
      'کاتەکانی بانگ بۆ تەواوی شارەکانی کوردستان و جیهان بەردەستە .',
  };

  String get hijriSuffix => switch (language) {
    AppLanguage.english => 'AH',
    AppLanguage.arabic => 'هـ',
    AppLanguage.kurdish => 'هـ',
  };

  String get nextPrayer => switch (language) {
    AppLanguage.english => 'Next prayer',
    AppLanguage.arabic => 'الصلاة القادمة',
    AppLanguage.kurdish => 'بانگی داهاتوو',
  };

  String beginsIn(String countdown) => switch (language) {
    AppLanguage.english => 'Begins in $countdown',
    AppLanguage.arabic => 'تبدأ بعد $countdown',
    AppLanguage.kurdish => 'دوای $countdown دەست پێدەکات',
  };

  String get settings => switch (language) {
    AppLanguage.english => 'Settings',
    AppLanguage.arabic => 'الإعدادات',
    AppLanguage.kurdish => 'ڕێکخستن',
  };

  String get prayerNotifications => switch (language) {
    AppLanguage.english => 'Prayer notifications',
    AppLanguage.arabic => 'تنبيهات الصلاة',
    AppLanguage.kurdish => 'ئاگادارکردنەوەی بانگ',
  };

  String get prayerNotificationsSubtitle => switch (language) {
    AppLanguage.english => 'Notify me when each prayer time begins',
    AppLanguage.arabic => 'أخبرني عند دخول وقت كل صلاة',
    AppLanguage.kurdish => 'کاتێک هەر بانگێک دەست پێدەکات ئاگادارم بکەرەوە .',
  };

  String prayerNotificationTitle(String prayerName) => switch (language) {
    AppLanguage.english => '$prayerName Prayer Time',
    AppLanguage.arabic => 'موعد صلاة $prayerName',
    AppLanguage.kurdish => 'کاتی نوێژی $prayerName',
  };

  String prayerNotificationBody(String prayerName) => switch (language) {
    AppLanguage.english => 'It\'s time to pray $prayerName.',
    AppLanguage.arabic => 'حان وقت صلاة $prayerName.',
    AppLanguage.kurdish => 'کاتی نوێژی $prayerName هاتووە.',
  };

  String get prayerSettingsTitle => switch (language) {
    AppLanguage.english => 'Prayer settings',
    AppLanguage.arabic => 'إعدادات الصلاة',
    AppLanguage.kurdish => 'ڕێکخستنەکانی بانگ',
  };

  String get prayerSettingsSubtitle => switch (language) {
    AppLanguage.english => 'manage notifications.',
    AppLanguage.arabic => 'اختر  وأدر تنبيهات الصلاة.',
    AppLanguage.kurdish => 'ئاگادارکردنەوەکان ڕێکبخە.',
  };

  String madhabLabel(PrayerMadhab madhab) => switch (madhab) {
    PrayerMadhab.shafi => switch (language) {
      AppLanguage.english => 'Shafi',
      AppLanguage.arabic => 'شافعي',
      AppLanguage.kurdish => 'شافیعی',
    },
    PrayerMadhab.hanafi => switch (language) {
      AppLanguage.english => 'Hanafi',
      AppLanguage.arabic => 'حنفي',
      AppLanguage.kurdish => 'حەنەفی',
    },
  };

  String get todaysSchedule => switch (language) {
    AppLanguage.english => 'Today\'s schedule',
    AppLanguage.arabic => 'جدول اليوم',
    AppLanguage.kurdish => 'کاتەکانی ئەمڕۆ',
  };

  String get highlightedPrayerHint => switch (language) {
    AppLanguage.english => 'Highlighted prayer is the next one coming up.',
    AppLanguage.arabic => 'الصلاة المظللة هي الصلاة القادمة.',
    AppLanguage.kurdish => 'بانگی هایلایتکراو ، بانگی داهاتووە.',
  };

  String get qiblaSectionTitle => switch (language) {
    AppLanguage.english => 'Qibla compass',
    AppLanguage.arabic => 'بوصلة القبلة',
    AppLanguage.kurdish => 'ئاراستای نوێژ',
  };

  String get qiblaSectionSubtitle => switch (language) {
    AppLanguage.english =>
      'Open the live compass to find the prayer direction from your current location.',
    AppLanguage.arabic =>
      'افتح البوصلة الحية لمعرفة اتجاه الصلاة من موقعك الحالي.',
    AppLanguage.kurdish => 'دەستنیشانکردنی ئاراستەی نوێژ لەڕێگای کومپاس.',
  };

  String qiblaBearingLabel(int degrees, String direction) => switch (language) {
    AppLanguage.english => 'Qibla at $degrees° $direction',
    AppLanguage.arabic => 'القبلة عند $degrees° $direction',
    AppLanguage.kurdish => 'قیبلە لە $degrees° $direction',
  };

  String get openQiblaCompass => switch (language) {
    AppLanguage.english => 'Open compass',
    AppLanguage.arabic => 'افتح البوصلة',
    AppLanguage.kurdish => 'کردنەوەی کومپاس',
  };

  String get qiblaCompassTitle => switch (language) {
    AppLanguage.english => 'Qibla Compass',
    AppLanguage.arabic => 'بوصلة القبلة',
    AppLanguage.kurdish => 'دەستنیشانکردنی ئاڕاستەی نوێژ',
  };

  String get qiblaCompassSubtitle => switch (language) {
    AppLanguage.english =>
      'Use your current location to see the Qibla bearing toward the Kaaba.',
    AppLanguage.arabic =>
      'استخدم موقعك الحالي لمعرفة زاوية القبلة باتجاه الكعبة.',
    AppLanguage.kurdish => 'بە شوێنی ئێستا ئاراستەی قیبلە بۆ کەعبە ببینە.',
  };

  String get qiblaLabel => switch (language) {
    AppLanguage.english => 'Qibla',
    AppLanguage.arabic => 'القبلة',
    AppLanguage.kurdish => 'قیبلە',
  };

  String get qiblaAligned => switch (language) {
    AppLanguage.english => 'You are facing the Qibla.',
    AppLanguage.arabic => 'أنت الآن باتجاه القبلة.',
    AppLanguage.kurdish => 'ئێستا ڕوو لە قیبلەیت.',
  };

  String qiblaTurnBy(int degrees) => switch (language) {
    AppLanguage.english => 'Turn by about $degrees° to align.',
    AppLanguage.arabic => 'استدر حوالي $degrees° حتى تصطف.',
    AppLanguage.kurdish => 'نزیکەی $degrees° بگۆڕە بۆ هاوتەرازبوون.',
  };

  String get qiblaCompassUnavailable => switch (language) {
    AppLanguage.english => 'Compass heading is unavailable on this device.',
    AppLanguage.arabic => 'اتجاه البوصلة غير متاح على هذا الجهاز.',
    AppLanguage.kurdish => 'ئاراستەی کومپاس لەم ئامێرەدا بەردەست نییە.',
  };

  String compassHeadingLabel(int degrees) => switch (language) {
    AppLanguage.english => 'Heading $degrees°',
    AppLanguage.arabic => 'اتجاه الجهاز $degrees°',
    AppLanguage.kurdish => 'ئاراستەی ئامێر $degrees°',
  };

  String qiblaBearingShort(int degrees) => switch (language) {
    AppLanguage.english => 'Qibla $degrees°',
    AppLanguage.arabic => 'القبلة $degrees°',
    AppLanguage.kurdish => 'قیبلە $degrees°',
  };

  String get qiblaCompassHint => switch (language) {
    AppLanguage.english =>
      'Use the shown angle with your location to align yourself before you start Salah.',
    AppLanguage.arabic =>
      'استخدم الزاوية الظاهرة مع موقعك لتحديد اتجاهك قبل بدء الصلاة.',
    AppLanguage.kurdish =>
      'ئاراستەی پیشاندراو لەگەڵ شوێنەکەت بەکاربهێنە بۆ دیاریکردنی قیبلە پێش نوێژ.',
  };

  String get upNext => switch (language) {
    AppLanguage.english => 'Up next',
    AppLanguage.arabic => 'التالي',
    AppLanguage.kurdish => 'داهاتوو',
  };

  String get scheduledToday => switch (language) {
    AppLanguage.english => 'Scheduled today',
    AppLanguage.arabic => 'مجدول اليوم',
    AppLanguage.kurdish => 'بۆ ئەمڕۆ دیاریکراوە',
  };

  String get onboardingTitle => switch (language) {
    AppLanguage.english => 'Set up your Quran companion',
    AppLanguage.arabic => 'أكمِل إعداد رفيقك القرآني',
    AppLanguage.kurdish => 'ئامادەکردنی بەرنامە بۆ دواتر',
  };

  String get onboardingSubtitle => switch (language) {
    AppLanguage.english =>
      'A quick first-run setup for language, prayer location, and prayer reminders.',
    AppLanguage.arabic =>
      'إعداد سريع لأول تشغيل لاختيار اللغة وموقع الصلاة وتذكيرات الصلاة.',
    AppLanguage.kurdish =>
      'ڕێکخستنێکی خێرا بۆ یەکەم جار بۆ زمان، شوێنی بانگ و ئاگادارکردنەوەی نوێژ.',
  };

  String get onboardingLanguageTitle => switch (language) {
    AppLanguage.english => 'Choose your language',
    AppLanguage.arabic => 'اختر لغتك',
    AppLanguage.kurdish => 'زمانەکەت هەڵبژێرە',
  };

  String get onboardingLanguageSubtitle => switch (language) {
    AppLanguage.english =>
      'Pick the interface language you want to use across the app.',
    AppLanguage.arabic => 'اختر لغة الواجهة التي تريد استخدامها في التطبيق.',
    AppLanguage.kurdish =>
      'ئەو زمانەی ڕووکار هەڵبژێرە کە دەتەوێت لە هەموو ئەپەکەدا بەکاریبهێنیت.',
  };

  String get onboardingLocationTitle => switch (language) {
    AppLanguage.english => 'Set your prayer location',
    AppLanguage.arabic => 'حدّد موقع الصلاة',
    AppLanguage.kurdish => 'شوێنی بانگ دیاری بکە',
  };

  String get onboardingLocationSubtitle => switch (language) {
    AppLanguage.english =>
      'Use your live location or choose a saved city for the prayer timetable.',
    AppLanguage.arabic =>
      'استخدم موقعك المباشر أو اختر مدينة محفوظة لجدول أوقات الصلاة.',
    AppLanguage.kurdish =>
      'یان شوێنی ڕاستەوخۆ بەکاربهێنە یان شارێکی هەڵگیراو بۆ خشتەی کاتەکانی بانگ هەڵبژێرە.',
  };

  String get onboardingLiveLocationCardTitle => switch (language) {
    AppLanguage.english => 'Use live location',
    AppLanguage.arabic => 'استخدم الموقع المباشر',
    AppLanguage.kurdish => 'شوێنی ڕاستەوخۆ بەکاربهێنە',
  };

  String get onboardingLiveLocationCardBody => switch (language) {
    AppLanguage.english =>
      'Best when you move between places and want location-based prayer times and Qibla.',
    AppLanguage.arabic =>
      'الخيار الأفضل إذا كنت تتنقل وتريد أوقات صلاة واتجاه قبلة حسب موقعك.',
    AppLanguage.kurdish =>
      'باشترین هەڵبژاردەیە ئەگەر دەگوازیتەوە و دەتەوێت کاتەکانی بانگ و قیبلە بە شوێنەکەت بێت.',
  };

  String get onboardingCityCardTitle => switch (language) {
    AppLanguage.english => 'Choose a prayer city',
    AppLanguage.arabic => 'اختر مدينة للصلاة',
    AppLanguage.kurdish => 'شاری بانگ هەڵبژێرە',
  };

  String get onboardingCityCardBody => switch (language) {
    AppLanguage.english =>
      'Use a fixed city if you want a stable timetable without asking for location every time.',
    AppLanguage.arabic =>
      'استخدم مدينة ثابتة إذا كنت تريد جدولاً مستقراً من دون طلب الموقع كل مرة.',
    AppLanguage.kurdish =>
      'شارێکی جێگیر هەڵبژێرە ئەگەر دەتەوێت خشتەیەکی جێگیرت هەبێت بێ داوای شوێن لە هەموو جارێک.',
  };

  String get onboardingNotificationsTitle => switch (language) {
    AppLanguage.english => 'Prayer reminders',
    AppLanguage.arabic => 'تذكيرات الصلاة',
    AppLanguage.kurdish => 'ئاگادارکردنەوەی نوێژ',
  };

  String get onboardingNotificationsSubtitle => switch (language) {
    AppLanguage.english =>
      'Turn prayer notifications on now, or leave them off and enable them later.',
    AppLanguage.arabic =>
      'فعّل إشعارات الصلاة الآن أو اتركها مغلقة وفعّلها لاحقاً.',
    AppLanguage.kurdish =>
      'ئاگادارکردنەوەی نوێژ ئێستا چالاک بکە یان بێجێیبهێڵە و دواتر چالاکی بکە.',
  };

  String get onboardingNotificationsHint => switch (language) {
    AppLanguage.english =>
      'The app will ask for notification permission only if you turn this on.',
    AppLanguage.arabic =>
      'سيطلب التطبيق إذن الإشعارات فقط إذا فعّلت هذا الخيار.',
    AppLanguage.kurdish =>
      'ئەپەکە تەنها ئەگەر ئەمە چالاک بکەیت داوای مۆڵەتی ئاگادارکردنەوە دەکات.',
  };

  String get onboardingSettingsHint => switch (language) {
    AppLanguage.english => 'You can change any of these later in Settings.',
    AppLanguage.arabic => 'يمكنك تغيير كل هذه الخيارات لاحقاً من الإعدادات.',
    AppLanguage.kurdish =>
      'دەتوانیت دواتر هەموو ئەمانە لە ڕێکخستنەکاندا بگۆڕیت.',
  };

  String get onboardingBackLabel => switch (language) {
    AppLanguage.english => 'Back',
    AppLanguage.arabic => 'رجوع',
    AppLanguage.kurdish => 'گەڕانەوە',
  };

  String get onboardingContinueLabel => switch (language) {
    AppLanguage.english => 'Continue',
    AppLanguage.arabic => 'متابعة',
    AppLanguage.kurdish => 'بەردەوام بە',
  };

  String get onboardingFinishLabel => switch (language) {
    AppLanguage.english => 'Finish setup',
    AppLanguage.arabic => 'إنهاء الإعداد',
    AppLanguage.kurdish => 'تەواوکردنی ڕێکخستن',
  };

  String get settingsTitle => settings;

  String get settingsSubtitle => switch (language) {
    AppLanguage.english =>
      'Choose live location or a prayer city, interface language, and basic app options.',
    AppLanguage.arabic =>
      'اختر الموقع المباشر أو مدينة الصلاة ولغة الواجهة وبعض خيارات التطبيق الأساسية.',
    AppLanguage.kurdish => 'لەم بەشە دەتوانی زمان، شوێن بگۆڕت .',
  };

  String get citySectionTitle => switch (language) {
    AppLanguage.english => 'Prayer city',
    AppLanguage.arabic => 'مدينة الصلاة',
    AppLanguage.kurdish => 'شوێنی بانگ',
  };

  String get citySectionSubtitle => switch (language) {
    AppLanguage.english =>
      'Use live location for prayer times or choose a city. Default city is Erbil.',
    AppLanguage.arabic =>
      'استخدم الموقع المباشر لأوقات الصلاة أو اختر مدينة. المدينة الافتراضية هي أربيل.',
    AppLanguage.kurdish =>
      'یان شوێنی ڕاستەوخۆ بۆ کاتەکانی بانگ بەکاربهێنە یان شارێک هەڵبژێرە. شاری بنەڕەتی هەولێرە.',
  };

  String get useDeviceLocation => switch (language) {
    AppLanguage.english => 'Use live location for prayer times',
    AppLanguage.arabic => 'استخدم الموقع المباشر لأوقات الصلاة',
    AppLanguage.kurdish => 'شوێنی ڕاستەوخۆ بۆ کاتەکانی بانگ بەکاربهێنە',
  };

  String get livePrayerLocationTitle => switch (language) {
    AppLanguage.english => 'Live prayer location',
    AppLanguage.arabic => 'موقع الصلاة المباشر',
    AppLanguage.kurdish => 'شوێنی زیندووی بانگ',
  };

  String get selectedCity => switch (language) {
    AppLanguage.english => 'Selected city',
    AppLanguage.arabic => 'المدينة المختارة',
    AppLanguage.kurdish => 'شاری هەڵبژێردراو',
  };

  String get cityDownloadsHint => switch (language) {
    AppLanguage.english =>
      'Exact Bang city tables are cached for offline use after download.',
    AppLanguage.arabic =>
      'يتم حفظ جداول بانغ الدقيقة محلياً لتعمل دون إنترنت بعد التحميل.',
    AppLanguage.kurdish =>
      'خشتەی وردی شارەکانی بانگ دوای داگرتن بۆ کاری ئوفلاین لۆکاڵی هەڵدەگیرێت.',
  };

  String get languageSectionTitle => switch (language) {
    AppLanguage.english => 'Language',
    AppLanguage.arabic => 'اللغة',
    AppLanguage.kurdish => 'زمان',
  };

  String get reciterSectionTitle => switch (language) {
    AppLanguage.english => 'Reciters',
    AppLanguage.arabic => 'القراء',
    AppLanguage.kurdish => 'قارییەکان',
  };

  String get reciterSectionSubtitle => switch (language) {
    AppLanguage.english =>
      'Download a reciter once, save it on the device, then switch playback without fetching again.',
    AppLanguage.arabic =>
      'حمّل القارئ مرة واحدة واحفظه على الجهاز، ثم بدّل التلاوة لاحقاً دون تنزيل جديد.',
    AppLanguage.kurdish =>
      'قارییەک یەکجار دابگرە و لەسەر ئامێرەکە هەڵیبگرە، پاشان بێ دووبارە داگرتن بۆی بگۆڕە.',
  };

  String get reciterAutoCacheHint => switch (language) {
    AppLanguage.english =>
      'Each surah audio is cached the first time you open it, then reused locally on the next visit.',
    AppLanguage.arabic =>
      'يتم حفظ صوت كل سورة محلياً أول مرة تفتحها، ثم يُعاد استخدامه من الجهاز في الزيارات التالية.',
    AppLanguage.kurdish =>
      'دەنگی هەر سوورەتێک یەکەم جار کە دادەگیرێت لۆکاڵی هەڵدەگیرێت و دواتر لەسەر ئامێرەکەوە دوبارە بەکاردێت.',
  };

  String cachedSurahCountLabel(int count) => switch (language) {
    AppLanguage.english => '$count surahs cached',
    AppLanguage.arabic => 'تم حفظ $count سورة',
    AppLanguage.kurdish => '$count سوورەت هەڵگیراون',
  };

  String get selectedReciterSectionTitle => switch (language) {
    AppLanguage.english => 'Selected reciter',
    AppLanguage.arabic => 'القارئ المختار',
    AppLanguage.kurdish => 'قاریی هەڵبژێردراو',
  };

  String get downloadReciterLabel => switch (language) {
    AppLanguage.english => 'Download',
    AppLanguage.arabic => 'تحميل',
    AppLanguage.kurdish => 'داگرتن',
  };

  String get useReciterLabel => switch (language) {
    AppLanguage.english => 'Use',
    AppLanguage.arabic => 'استخدام',
    AppLanguage.kurdish => 'بەکاربهێنە',
  };

  String get selectedReciterLabel => switch (language) {
    AppLanguage.english => 'Selected',
    AppLanguage.arabic => 'محدد',
    AppLanguage.kurdish => 'هەڵبژێردراو',
  };

  String get reciterDownloadedLabel => switch (language) {
    AppLanguage.english => 'Downloaded for offline playback.',
    AppLanguage.arabic => 'تم تنزيله للتشغيل دون إنترنت.',
    AppLanguage.kurdish => 'بۆ لێدانی ئۆفلاین داگیراوە.',
  };

  String get reciterStreamingLabel => switch (language) {
    AppLanguage.english =>
      'Current fallback reciter streams until you download it.',
    AppLanguage.arabic => 'القارئ الحالي يعمل بالبث إلى أن تقوم بتنزيله.',
    AppLanguage.kurdish => 'ئەم قارییەی ئێستا ستریم دەکرێت تا دایدەگریت.',
  };

  String get reciterNeedsDownloadLabel => switch (language) {
    AppLanguage.english => 'Download once to switch to this reciter.',
    AppLanguage.arabic => 'حمّله مرة واحدة حتى تتمكن من التبديل إليه.',
    AppLanguage.kurdish => 'یەکجار دایبگرە تاکو بتوانیت بۆی بگۆڕیت.',
  };

  String get downloadingReciterLabel => switch (language) {
    AppLanguage.english => 'Downloading...',
    AppLanguage.arabic => 'جارٍ التحميل...',
    AppLanguage.kurdish => 'خەریکی داگرتنە...',
  };

  String reciterDownloadProgress(int completed, int total) =>
      switch (language) {
        AppLanguage.english => '$completed of $total files saved',
        AppLanguage.arabic => 'تم حفظ $completed من أصل $total ملفاً',
        AppLanguage.kurdish => '$completed لە $total فایل هەڵگیراون',
      };

  String get reciterDownloadFailed => switch (language) {
    AppLanguage.english => 'Reciter download failed. Try again.',
    AppLanguage.arabic => 'فشل تنزيل القارئ. حاول مرة أخرى.',
    AppLanguage.kurdish => 'داگرتنی قارییەکە سەرکەوتوو نەبوو. دووبارە هەوڵبدە.',
  };

  String downloadingSurahAudioLabel(String reciterName) => switch (language) {
    AppLanguage.english => 'Saving $reciterName audio for this surah...',
    AppLanguage.arabic => 'جارٍ حفظ صوت $reciterName لهذه السورة...',
    AppLanguage.kurdish => 'دەنگی $reciterName بۆ ئەم سوورەتە هەڵدەگیرێت...',
  };

  String surahAudioReadyLabel(String reciterName) => switch (language) {
    AppLanguage.english =>
      '$reciterName audio is saved locally for this surah.',
    AppLanguage.arabic => 'تم حفظ صوت $reciterName محلياً لهذه السورة.',
    AppLanguage.kurdish =>
      'دەنگی $reciterName بۆ ئەم سوورەتە لۆکاڵی هەڵگیراوە.',
  };

  String get languageSectionSubtitle => switch (language) {
    AppLanguage.english => 'Switch the app interface language.',
    AppLanguage.arabic => 'بدّل لغة واجهة التطبيق.',
    AppLanguage.kurdish => 'زمانی ڕووکارى ئەپەکە بگۆڕە.',
  };

  String get appearanceSectionTitle => switch (language) {
    AppLanguage.english => 'Appearance',
    AppLanguage.arabic => 'المظهر',
    AppLanguage.kurdish => 'ڕووکار',
  };

  String get appearanceSectionSubtitle => switch (language) {
    AppLanguage.english => 'Switch between light and dark mode.',
    AppLanguage.arabic => 'بدّل بين الوضع الفاتح والداكن.',
    AppLanguage.kurdish => 'گۆڕین دۆخی ڕووناک و تاریک .',
  };

  String get darkModeTitle => switch (language) {
    AppLanguage.english => 'Dark mode',
    AppLanguage.arabic => 'الوضع الداكن',
    AppLanguage.kurdish => 'دۆخی تاریک',
  };

  String get darkModeSubtitle => switch (language) {
    AppLanguage.english => 'Use the dark theme for the whole app.',
    AppLanguage.arabic => 'استخدم المظهر الداكن للتطبيق بالكامل.',
    AppLanguage.kurdish => 'ڕووکارى تاریک بۆ تەواوی ئەپەکە بەکاربهێنە.',
  };

  String get aboutSectionTitle => switch (language) {
    AppLanguage.english => 'About app',
    AppLanguage.arabic => 'حول التطبيق',
    AppLanguage.kurdish => 'دەربارەی بەرنامە',
  };

  String get openAboutPage => switch (language) {
    AppLanguage.english => 'Open about page',
    AppLanguage.arabic => 'فتح صفحة حول التطبيق',
    AppLanguage.kurdish => 'کردنەوەی پەڕەی دەربارە',
  };

  String get aboutSectionBody => switch (language) {
    AppLanguage.english =>
      'Quran Noor helps with recitation practice and displays exact Bang prayer times for supported Kurdistan cities with offline cache after download.',
    AppLanguage.arabic =>
      'يساعدك Quran Noor على التدريب على التلاوة ويعرض أوقات بانغ الدقيقة للمدن المدعومة في كردستان مع حفظها للعمل دون إنترنت بعد التحميل.',
    AppLanguage.kurdish =>
      'Quran Noor یارمەتیت دەدات لە فێربوون و خوێندنەوەی قورئانی پیرۆز، و کاتەکانی بانگ بۆ شارە پشتیوانیکراوەکانی کوردستان لەبەردەست دەخات. ',
  };

  String get locationAccessRequired => switch (language) {
    AppLanguage.english =>
      'Location access is only needed for live prayer times and the live Qibla compass.',
    AppLanguage.arabic =>
      'يحتاج التطبيق إلى الوصول للموقع فقط لأوقات الصلاة المباشرة وبوصلة القبلة الحية.',
    AppLanguage.kurdish => 'دەستنیشانکردنی ئاراستەی نوێژ لەڕێگای کومپاس.',
  };

  String get prayerLoadFailed => switch (language) {
    AppLanguage.english => 'Prayer times could not be loaded.',
    AppLanguage.arabic => 'تعذر تحميل أوقات الصلاة.',
    AppLanguage.kurdish => 'نەتوانرا کاتەکانی بانگ باربکرێن.',
  };

  String get openLocationSettings => switch (language) {
    AppLanguage.english => 'Open Location Settings',
    AppLanguage.arabic => 'افتح إعدادات الموقع',
    AppLanguage.kurdish => 'ڕێکخستنەکانی شوێن بکەرەوە',
  };

  String get openAppSettings => switch (language) {
    AppLanguage.english => 'Open App Settings',
    AppLanguage.arabic => 'افتح إعدادات التطبيق',
    AppLanguage.kurdish => 'ڕێکخستنەکانی ئەپ بکەرەوە',
  };

  String get aboutExactCache => switch (language) {
    AppLanguage.english =>
      'Bang monthly city timetables are saved on the device for offline reuse.',
    AppLanguage.arabic =>
      'يتم حفظ الجداول الشهرية لمدن بانغ على الجهاز لاستخدامها دون إنترنت.',
    AppLanguage.kurdish =>
      'خشتە مانگانەکانی شارەکانی بانگ , هەڵدەگیرێن بۆ بەکارهێنانی ئوفلاین.',
  };

  String get aboutHighlightsTitle => switch (language) {
    AppLanguage.english => 'What this app offers',
    AppLanguage.arabic => 'ما الذي يقدمه هذا التطبيق',
    AppLanguage.kurdish => 'ئەم بەرنامەیە چی پێشکەش دەکات',
  };

  String get aboutHighlightsSubtitle => switch (language) {
    AppLanguage.english =>
      'Focused tools for recitation, prayer time, and daily remembrance.',
    AppLanguage.arabic => 'أدوات مركزة للتلاوة وأوقات الصلاة والذكر اليومي.',
    AppLanguage.kurdish =>
      'ئامرازە سەرنجڕاکێشەکان بۆ خوێندنەوە، کاتی نوێژ و زیکری ڕۆژانە.',
  };

  String get aboutHighlightRecitationTitle => switch (language) {
    AppLanguage.english => 'Recitation practice',
    AppLanguage.arabic => 'تمرين التلاوة',
    AppLanguage.kurdish => 'ڕاهێنانی خوێندنەوە',
  };

  String get aboutHighlightRecitationBody => switch (language) {
    AppLanguage.english =>
      'Listen ayah by ayah, compare your recitation, and keep your last reading point.',
    AppLanguage.arabic =>
      'استمع آية بآية، وقارن تلاوتك، واحتفظ بآخر موضع قراءة.',
    AppLanguage.kurdish =>
      'ئایەت بە ئایەت گوێبگرە، خوێندنەوەت بەراورد بکە، و دوا شوێنی خوێندنەوەت بەئاسانی بدۆزەرەوە .',
  };

  String get aboutHighlightPrayerTitle => switch (language) {
    AppLanguage.english => 'Prayer support',
    AppLanguage.arabic => 'یارمەتی نوێژ',
    AppLanguage.kurdish => 'پشتگیری نوێژ',
  };

  String get aboutHighlightPrayerBody => switch (language) {
    AppLanguage.english =>
      'Get accurate prayer times, Bang city schedules, and offline saved timetables.',
    AppLanguage.arabic =>
      'احصل على أوقات صلاة دقيقة، وجداول مدن بانغ، والجداول المحفوظة دون إنترنت.',
    AppLanguage.kurdish =>
      'کاتە دروستەکانی نوێژ، خشتەی شارەکانی بانگ، و خشتە پاشەکەوتکراوەکانی ئۆفلاین وەربگرە.',
  };

  String get aboutHighlightZikirTitle => switch (language) {
    AppLanguage.english => 'Daily adhkar',
    AppLanguage.arabic => 'الأذكار اليومية',
    AppLanguage.kurdish => 'زیکری ڕۆژانە',
  };

  String get aboutHighlightZikirBody => switch (language) {
    AppLanguage.english =>
      'Track tasbih sets, resume counters, and schedule remembrance reminders.',
    AppLanguage.arabic =>
      'تابع مجموعات التسبيح، وواصل العدادات، وجدول تذكيرات الذكر.',
    AppLanguage.kurdish =>
      'زیکری بەیانیان، ئێوارن، پێش خەوتن ،لەگەڵ بیرخستنەوەیان .',
  };

  String get aboutContactTitle => switch (language) {
    AppLanguage.english => 'Contact',
    AppLanguage.arabic => 'التواصل',
    AppLanguage.kurdish => 'پەیوەندی',
  };

  String get aboutContactSubtitle => switch (language) {
    AppLanguage.english => 'Questions, feedback, or support requests.',
    AppLanguage.arabic => 'للأسئلة أو الملاحظات أو طلبات الدعم.',
    AppLanguage.kurdish => 'بۆ پرسیار، تێبینی، یان داواکاری یارمەتی.',
  };

  String get contactPhoneLabel => switch (language) {
    AppLanguage.english => 'Phone',
    AppLanguage.arabic => 'تەلەفۆن',
    AppLanguage.kurdish => 'تەلەفۆن',
  };

  String get contactEmailLabel => switch (language) {
    AppLanguage.english => 'Email',
    AppLanguage.arabic => 'ئیمەیڵ',
    AppLanguage.kurdish => 'ئیمەیڵ',
  };

  String get contactFacebookLabel => switch (language) {
    AppLanguage.english => 'Facebook',
    AppLanguage.arabic => 'فەیسبوک',
    AppLanguage.kurdish => 'فەیسبوک',
  };

  String get aboutDeveloperCredit => switch (language) {
    AppLanguage.english => 'Created and developed by Eng. Imran Mohammed',
    AppLanguage.arabic => 'تم إنشاء التطبيق وتطويره بواسطة المهندس عمران محمد',
    AppLanguage.kurdish =>
      'ئەم بەرنامەیە لەلایەن ئەندازیار عیمران محمدەوە دروست کراوە و گەشەپێدراوە',
  };

  String aboutVersionLabel(String version) => switch (language) {
    AppLanguage.english => 'Version $version',
    AppLanguage.arabic => 'الإصدار $version',
    AppLanguage.kurdish => 'وەشانی $version',
  };

  String get recitationMode => switch (language) {
    AppLanguage.english => 'Recitation mode',
    AppLanguage.arabic => 'وضع التلاوة',
    AppLanguage.kurdish => 'دۆخی خوێندنەوە',
  };

  String get recitationModeLenient => switch (language) {
    AppLanguage.english => 'Lenient',
    AppLanguage.arabic => 'مرن',
    AppLanguage.kurdish => 'ئاسای',
  };

  String get recitationModeStrict => switch (language) {
    AppLanguage.english => 'Strict',
    AppLanguage.arabic => 'دقيق',
    AppLanguage.kurdish => 'ورد',
  };

  String get recitationModeTajweed => switch (language) {
    AppLanguage.english => 'Tajweed',
    AppLanguage.arabic => 'تجويد',
    AppLanguage.kurdish => 'تەجوید',
  };

  String surahAyahCount(int ayahCount, int surahNumber) => switch (language) {
    AppLanguage.english => '$ayahCount ayahs in Surah $surahNumber',
    AppLanguage.arabic => '$ayahCount آية في السورة $surahNumber',
    AppLanguage.kurdish => '$ayahCount ئایەت لە سوورەتی $surahNumber',
  };

  String get ayahsTitle => switch (language) {
    AppLanguage.english => 'Ayahs',
    AppLanguage.arabic => 'الآيات',
    AppLanguage.kurdish => 'ئایەتەکان',
  };

  String get searchAyahHint => switch (language) {
    AppLanguage.english => 'Search ayah number or text',
    AppLanguage.arabic => 'ابحث برقم الآية أو النص',
    AppLanguage.kurdish => 'بە ژمارەی ئایەت یان دەق بگەڕێ',
  };

  String get clearAyahSearchLabel => switch (language) {
    AppLanguage.english => 'Clear search',
    AppLanguage.arabic => 'مسح البحث',
    AppLanguage.kurdish => 'پاککردنەوەی گەڕان',
  };

  String get noAyahMatches => switch (language) {
    AppLanguage.english => 'No ayahs matched this search.',
    AppLanguage.arabic => 'لا توجد آيات تطابق هذا البحث.',
    AppLanguage.kurdish => 'هیچ ئایەتێک لەگەڵ ئەم گەڕانە ناگونجێت.',
  };

  String get searchAyahTryAnother => switch (language) {
    AppLanguage.english => 'Try a different ayah number or search phrase.',
    AppLanguage.arabic => 'جرّب رقم آية آخر أو عبارة بحث مختلفة.',
    AppLanguage.kurdish =>
      'ژمارەی ئایەتێکی تر یان دەقێکی تری گەڕان تاقی بکەرەوە.',
  };

  String get ayahScreenSubtitle => switch (language) {
    AppLanguage.english =>
      'Use the speaker to hear the reference and the microphone to compare your recitation.',
    AppLanguage.arabic =>
      'استخدم السماعة لسماع التلاوة المرجعية والميكروفون لمقارنة تلاوتك.',
    AppLanguage.kurdish => 'سپیکەر بەکاربهێنە بۆ گوێگرتن ',
  };

  String ayahNumberLabel(int ayahNumber) => switch (language) {
    AppLanguage.english => 'Ayah $ayahNumber',
    AppLanguage.arabic => 'الآية $ayahNumber',
    AppLanguage.kurdish => 'ئایەتی $ayahNumber',
  };

  String get listen => switch (language) {
    AppLanguage.english => 'Listen',
    AppLanguage.arabic => 'استماع',
    AppLanguage.kurdish => 'گوێ بگرە',
  };

  String get pauseAudioLabel => switch (language) {
    AppLanguage.english => 'Pause audio',
    AppLanguage.arabic => 'إيقاف الصوت مؤقتاً',
    AppLanguage.kurdish => 'ڕاگرتنی دەنگ',
  };

  String get resumeAudioLabel => switch (language) {
    AppLanguage.english => 'Resume audio',
    AppLanguage.arabic => 'متابعة الصوت',
    AppLanguage.kurdish => 'بەردەوامبوونی دەنگ',
  };

  String get read => switch (language) {
    AppLanguage.english => 'Read',
    AppLanguage.arabic => 'اقرأ',
    AppLanguage.kurdish => 'بخوێنەوە',
  };

  String get stop => switch (language) {
    AppLanguage.english => 'Stop',
    AppLanguage.arabic => 'إيقاف',
    AppLanguage.kurdish => 'بوەستە',
  };

  String get autoReadingPrompt => switch (language) {
    AppLanguage.english => 'Do you want auto reading?',
    AppLanguage.arabic => 'هل تريد التلاوة التلقائية؟',
    AppLanguage.kurdish => ' خوێندەوەی خۆکار؟',
  };

  String get stopAutoReading => switch (language) {
    AppLanguage.english => 'Stop auto reading',
    AppLanguage.arabic => 'إيقاف التلاوة التلقائية',
    AppLanguage.kurdish => 'وەستاندنی خوێندنەوەی خۆکار ؟',
  };

  String get rawTranscript => switch (language) {
    AppLanguage.english => 'Raw transcript',
    AppLanguage.arabic => 'النص الخام',
    AppLanguage.kurdish => 'دەقی خاو',
  };

  String get tajweedTranscript => switch (language) {
    AppLanguage.english => 'Tajweed transcript',
    AppLanguage.arabic => 'نص التجويد',
    AppLanguage.kurdish => 'دەقی تەجوید',
  };

  String get quranCorrectedTranscript => switch (language) {
    AppLanguage.english => 'Quran-corrected transcript',
    AppLanguage.arabic => 'النص المصحح قرآنياً',
    AppLanguage.kurdish => 'دەقی ڕاستکراوی قورئانی',
  };

  String localizedDhikrLabel({
    required String id,
    required String arabicText,
    required String transliteration,
  }) {
    if (language == AppLanguage.arabic) {
      return arabicText;
    }
    final normalizedTransliteration = transliteration.trim();
    if (normalizedTransliteration.isNotEmpty) {
      return normalizedTransliteration;
    }
    return arabicText;
  }

  String? localizedDhikrMeaning({required String id, String? fallback}) {
    final translated = switch (id) {
      'subhanallah' => switch (language) {
        AppLanguage.english => 'Glory be to Allah',
        AppLanguage.arabic => 'تنزيه لله عن كل نقص',
        AppLanguage.kurdish => 'پاکی و بێ کەموکوڕی بۆ خوای گەورە',
      },
      'alhamdulillah' => switch (language) {
        AppLanguage.english => 'All praise is for Allah',
        AppLanguage.arabic => 'كل الحمد والثناء لله',
        AppLanguage.kurdish => 'هەموو ستایش و سوپاس بۆ خوای گەورەیە',
      },
      'allahu_akbar' => switch (language) {
        AppLanguage.english => 'Allah is the Greatest',
        AppLanguage.arabic => 'الله أعظم من كل شيء',
        AppLanguage.kurdish => 'خوا گەورەترە لە هەموو شتێک',
      },
      'astaghfirullah' => switch (language) {
        AppLanguage.english => 'I seek forgiveness from Allah',
        AppLanguage.arabic => 'أطلب المغفرة من الله',
        AppLanguage.kurdish => 'داوای لێخۆشبوون لە خوای گەورە دەکەم',
      },
      'la_ilaha_illallah' => switch (language) {
        AppLanguage.english => 'There is no god but Allah',
        AppLanguage.arabic => 'لا معبود بحق إلا الله',
        AppLanguage.kurdish => 'هیچ پەرستراوێکی بەحق نییە جگە لە خوا',
      },
      _ => fallback?.trim(),
    };
    if (translated == null || translated.isEmpty) {
      return null;
    }
    return translated;
  }

  String localizedDhikrSetTitle(String id, String fallback) {
    return switch (id) {
      'after_salah' => switch (language) {
        AppLanguage.english => 'After Salah Tasbih',
        AppLanguage.arabic => 'تسبيح بعد الصلاة',
        AppLanguage.kurdish => 'تەسبیح دوای نوێژ',
      },
      _ => fallback,
    };
  }

  String localizedDhikrSetSubtitle(String id, String fallback) {
    return switch (id) {
      'after_salah' => switch (language) {
        AppLanguage.english =>
          'Move through the well-known post-prayer remembrance set.',
        AppLanguage.arabic =>
          'تنقّل في مجموعة الأذكار المعروفة التي تُقال بعد الصلاة.',
        AppLanguage.kurdish => 'بە نۆرە لە زیکرە ناسراوەکانی دوای نوێژ بڕۆ.',
      },
      _ => fallback,
    };
  }

  String get zikirReminderNotificationTitle => switch (language) {
    AppLanguage.english => 'Daily Zikir Reminder',
    AppLanguage.arabic => 'تذكير الذكر اليومي',
    AppLanguage.kurdish => 'بیرخستنەوەی ڕۆژانەی زیکر',
  };

  String get zikirReminderUnavailable => switch (language) {
    AppLanguage.english => 'Zikir reminders are not available right now.',
    AppLanguage.arabic => 'تذكيرات الذكر غير متاحة الآن.',
    AppLanguage.kurdish => 'ئێستا بیرخستنەوەی زیکر بەردەست نییە.',
  };

  String zikirReminderNotificationBody(String spoken, String arabicText) {
    final display = spoken == arabicText ? arabicText : '$spoken • $arabicText';
    return switch (language) {
      AppLanguage.english => 'Remember to say $display',
      AppLanguage.arabic => 'تذكّر أن تقول $display',
      AppLanguage.kurdish => 'بیرت بێت بڵێیت $display',
    };
  }

  String zikirPresetReminderNotificationBody(String title) =>
      switch (language) {
        AppLanguage.english => 'It is time for $title',
        AppLanguage.arabic => 'حان وقت $title',
        AppLanguage.kurdish => 'کاتی $title هاتووە',
      };

  String get zikirTitle => switch (language) {
    AppLanguage.english => 'Zikir',
    AppLanguage.arabic => 'الذكر',
    AppLanguage.kurdish => 'زیکرەکانم',
  };

  String get zikirSubtitle => switch (language) {
    AppLanguage.english =>
      'Keep a calm digital tasbih close for daily remembrance, post-prayer adhkar, and custom dhikr goals.',
    AppLanguage.arabic =>
      'احتفظ بمسبحة رقمية هادئة للأذكار اليومية، وأذكار ما بعد الصلاة، والأهداف الخاصة بك.',
    AppLanguage.kurdish =>
      'دەتوانی بەشی ئاگادارکردنەوی زیکرەکانم چالاک بکەی بۆ وەبیرهێنانەوەی زیکرەکانت.',
  };

  String get zikirHeroBody => switch (language) {
    AppLanguage.english =>
      'Tap with presence, keep your rhythm, and let the counter remember where you paused.',
    AppLanguage.arabic =>
      'سبّح بحضور قلب، وحافظ على إيقاعك، ودع العداد يتذكر موضع توقفك.',
    AppLanguage.kurdish =>
      ' «وه‌ زۆر یادی خوا بكه‌ن». ئه‌م ده‌سته‌واژه‌یه‌ فه‌رمانێكی ئیلاهییه‌ بۆ ئیمانداران تاكو به‌رده‌وام و له‌ هه‌موو كاتێكدا ته‌سبیحات و یادی خوای گه‌وره‌ بكه‌ن بۆ به‌ده‌ستهێنانی سه‌رفرازی .',
  };

  String get vibrationFeedback => switch (language) {
    AppLanguage.english => 'Vibration feedback',
    AppLanguage.arabic => 'الاهتزاز عند اللمس',
    AppLanguage.kurdish => 'لەرینەوەی مۆبایل لەکاتی زیکر کردن ',
  };

  String get vibrationFeedbackSubtitle => switch (language) {
    AppLanguage.english => 'Use gentle haptics on each tap.',
    AppLanguage.arabic => 'استخدم اهتزازاً خفيفاً مع كل ضغطة.',
    AppLanguage.kurdish => 'لە هەر لێدانێکدا دەنگێیکی نەرم هەستێدەکەیت.',
  };

  String get zikirReminderTitle => switch (language) {
    AppLanguage.english => 'Zikir reminders',
    AppLanguage.arabic => 'تذكيرات الذكر',
    AppLanguage.kurdish => 'بیرخستنەوەی زیکر',
  };

  String get zikirReminderSubtitle => switch (language) {
    AppLanguage.english =>
      'Create multiple reminder rules with daily times, weekdays, or prayer-based triggers.',
    AppLanguage.arabic =>
      'أنشئ عدة قواعد تذكير بأوقات يومية أو أيام محددة أو بعد الصلوات.',
    AppLanguage.kurdish =>
      'چەند یاسای بیرخستنەوە دابنێ بە کاتی ڕۆژانە، ڕۆژە دیاریکراوەکان یان دوای نوێژ.',
  };

  String get addZikirReminder => switch (language) {
    AppLanguage.english => 'Add reminder',
    AppLanguage.arabic => 'إضافة تذكير',
    AppLanguage.kurdish => 'زیادکردنی بیرخستنەوە',
  };

  String get openZikirCollectionLabel => switch (language) {
    AppLanguage.english => 'Open collection',
    AppLanguage.arabic => 'فتح المجموعة',
    AppLanguage.kurdish => 'کردنەوەی کۆمەڵە',
  };

  String zikirItemsCountLabel(int count) => switch (language) {
    AppLanguage.english => '$count items',
    AppLanguage.arabic => '$count عناصر',
    AppLanguage.kurdish => '$count دانە',
  };

  String get zikirReminderEmpty => switch (language) {
    AppLanguage.english =>
      'No zikir reminders yet. Add one to keep your adhkar on schedule.',
    AppLanguage.arabic =>
      'لا توجد تذكيرات للذكر بعد. أضف واحداً لتنظيم أذكارك.',
    AppLanguage.kurdish =>
      'هێشتا هیچ بیرخستنەوەیەکی زیکر نییە. یەکێک زیاد بکە بۆ ڕێکخستنی زیکرەکانت.',
  };

  String get editZikirReminder => switch (language) {
    AppLanguage.english => 'Edit reminder',
    AppLanguage.arabic => 'تعديل التذكير',
    AppLanguage.kurdish => 'دەستکاریکردنی بیرخستنەوە',
  };

  String get zikirReminderTargetTypeLabel => switch (language) {
    AppLanguage.english => 'Reminder target type',
    AppLanguage.arabic => 'نوع هدف التذكير',
    AppLanguage.kurdish => 'جۆری ئامانجی بیرخستنەوە',
  };

  String get zikirReminderTargetSingle => switch (language) {
    AppLanguage.english => 'Single dhikr',
    AppLanguage.arabic => 'ذكر واحد',
    AppLanguage.kurdish => 'زیکرێکی تاک',
  };

  String get zikirReminderTargetPreset => switch (language) {
    AppLanguage.english => 'Adhkar set',
    AppLanguage.arabic => 'مجموعة أذكار',
    AppLanguage.kurdish => 'کۆمەڵە زیکر',
  };

  String get zikirReminderPhraseLabel => switch (language) {
    AppLanguage.english => 'Reminder target',
    AppLanguage.arabic => 'هدف التذكير',
    AppLanguage.kurdish => 'ئامانجی بیرخستنەوە',
  };

  String get zikirReminderScheduleTypeLabel => switch (language) {
    AppLanguage.english => 'Schedule type',
    AppLanguage.arabic => 'نوع الجدولة',
    AppLanguage.kurdish => 'جۆری خشتەی کات',
  };

  String get zikirReminderScheduleDaily => switch (language) {
    AppLanguage.english => 'Daily time',
    AppLanguage.arabic => 'وقت يومي',
    AppLanguage.kurdish => 'کاتی ڕۆژانە',
  };

  String get zikirReminderScheduleAfterPrayer => switch (language) {
    AppLanguage.english => 'After prayer',
    AppLanguage.arabic => 'بعد الصلاة',
    AppLanguage.kurdish => 'دوای نوێژ',
  };

  String get zikirReminderTimeLabel => switch (language) {
    AppLanguage.english => 'Reminder time',
    AppLanguage.arabic => 'وقت التذكير',
    AppLanguage.kurdish => 'کاتی بیرخستنەوە',
  };

  String get zikirReminderWeekdaysLabel => switch (language) {
    AppLanguage.english => 'Days',
    AppLanguage.arabic => 'الأيام',
    AppLanguage.kurdish => 'ڕۆژەکان',
  };

  String get zikirReminderPrayersLabel => switch (language) {
    AppLanguage.english => 'Prayers',
    AppLanguage.arabic => 'الصلوات',
    AppLanguage.kurdish => 'نوێژەکان',
  };

  String get zikirReminderOffsetLabel => switch (language) {
    AppLanguage.english => 'Minutes after prayer',
    AppLanguage.arabic => 'الدقائق بعد الصلاة',
    AppLanguage.kurdish => 'خولەک دوای نوێژ',
  };

  String get zikirReminderTimeButton => switch (language) {
    AppLanguage.english => 'Pick time',
    AppLanguage.arabic => 'اختر الوقت',
    AppLanguage.kurdish => 'کات هەڵبژێرە',
  };

  String get zikirReminderWeekdaysRequired => switch (language) {
    AppLanguage.english => 'Select at least one day.',
    AppLanguage.arabic => 'اختر يوماً واحداً على الأقل.',
    AppLanguage.kurdish => 'لانیکەم یەک ڕۆژ هەڵبژێرە.',
  };

  String get zikirReminderPrayersRequired => switch (language) {
    AppLanguage.english => 'Select at least one prayer.',
    AppLanguage.arabic => 'اختر صلاة واحدة على الأقل.',
    AppLanguage.kurdish => 'لانیکەم یەک نوێژ هەڵبژێرە.',
  };

  String get zikirReminderTimeRequired => switch (language) {
    AppLanguage.english => 'Choose a reminder time first.',
    AppLanguage.arabic => 'اختر وقت التذكير أولاً.',
    AppLanguage.kurdish => 'سەرەتا کاتی بیرخستنەوە هەڵبژێرە.',
  };

  String get zikirReminderNeedsPrayerTimes => switch (language) {
    AppLanguage.english =>
      'Prayer times are not ready yet for after-prayer reminders.',
    AppLanguage.arabic => 'أوقات الصلاة غير جاهزة بعد لتذكيرات ما بعد الصلاة.',
    AppLanguage.kurdish =>
      'کاتەکانی نوێژ هێشتا ئامادە نین بۆ بیرخستنەوەی دوای نوێژ.',
  };

  String get zikirReminderUnscheduledLabel => switch (language) {
    AppLanguage.english => 'Unscheduled',
    AppLanguage.arabic => 'غير مجدول',
    AppLanguage.kurdish => 'خشتەنەکراوە',
  };

  String get allDaysLabel => switch (language) {
    AppLanguage.english => 'Every day',
    AppLanguage.arabic => 'كل يوم',
    AppLanguage.kurdish => 'هەموو ڕۆژێک',
  };

  String weekdayShortLabel(int weekday) => switch (weekday) {
    DateTime.monday => switch (language) {
      AppLanguage.english => 'Mon',
      AppLanguage.arabic => 'الاث',
      AppLanguage.kurdish => 'دووشەمە',
    },
    DateTime.tuesday => switch (language) {
      AppLanguage.english => 'Tue',
      AppLanguage.arabic => 'الث',
      AppLanguage.kurdish => 'شێ شەم',
    },
    DateTime.wednesday => switch (language) {
      AppLanguage.english => 'Wed',
      AppLanguage.arabic => 'الأر',
      AppLanguage.kurdish => 'چوار شەمە',
    },
    DateTime.thursday => switch (language) {
      AppLanguage.english => 'Thu',
      AppLanguage.arabic => 'الخ',
      AppLanguage.kurdish => 'پێنج شەمە',
    },
    DateTime.friday => switch (language) {
      AppLanguage.english => 'Fri',
      AppLanguage.arabic => 'الجم',
      AppLanguage.kurdish => 'هەینی ',
    },
    DateTime.saturday => switch (language) {
      AppLanguage.english => 'Sat',
      AppLanguage.arabic => 'السب',
      AppLanguage.kurdish => 'شەمە',
    },
    DateTime.sunday => switch (language) {
      AppLanguage.english => 'Sun',
      AppLanguage.arabic => 'الأح',
      AppLanguage.kurdish => 'یەک شەم',
    },
    _ => '',
  };

  String zikirReminderDailySummary(String days, String time) =>
      switch (language) {
        AppLanguage.english => '$days at $time',
        AppLanguage.arabic => '$days عند $time',
        AppLanguage.kurdish => '$days لە $time',
      };

  String zikirReminderAfterPrayerSummary(
    String prayers,
    int offsetMinutes,
    String days,
  ) => switch (language) {
    AppLanguage.english => '$prayers +$offsetMinutes min • $days',
    AppLanguage.arabic => '$prayers +$offsetMinutes دقيقة • $days',
    AppLanguage.kurdish => '$prayers +$offsetMinutes خولەک • $days',
  };

  String get saveZikirReminder => switch (language) {
    AppLanguage.english => 'Save reminder',
    AppLanguage.arabic => 'حفظ التذكير',
    AppLanguage.kurdish => 'پاشەکەوتکردنی بیرخستنەوە',
  };

  String get deleteZikirReminderTitle => switch (language) {
    AppLanguage.english => 'Delete reminder?',
    AppLanguage.arabic => 'حذف التذكير؟',
    AppLanguage.kurdish => 'سڕینەوەی بیرخستنەوە؟',
  };

  String get deleteZikirReminderBody => switch (language) {
    AppLanguage.english =>
      'This will remove the reminder rule and all of its scheduled notifications.',
    AppLanguage.arabic =>
      'سيؤدي هذا إلى حذف قاعدة التذكير وكل الإشعارات المرتبطة بها.',
    AppLanguage.kurdish =>
      'ئەمە یاسای بیرخستنەوە و هەموو ئاگادارکردنەوە خشتەکراوەکان دەسڕێتەوە.',
  };

  String get readingReciterTitle => switch (language) {
    AppLanguage.english => 'Reciter for this reading session',
    AppLanguage.arabic => 'القارئ لجلسة القراءة هذه',
    AppLanguage.kurdish => 'قاریی بۆ ئەم دانیشتنی خوێندنەوەیە',
  };

  String get readingReciterSubtitle => switch (language) {
    AppLanguage.english =>
      'Switch reciter here while listening. Your choice updates the app default too.',
    AppLanguage.arabic =>
      'بدّل القارئ من هنا أثناء الاستماع، وسيتم تحديث الاختيار الافتراضي في التطبيق أيضاً.',
    AppLanguage.kurdish =>
      'لەێرەوە قارییەکە بگۆڕە لەکاتی گوێگرتندا، هەمان هەڵبژاردن دەبێتە بنەڕەت بۆ ئەپەکەش.',
  };

  String get downloadCurrentSurahAudioLabel => switch (language) {
    AppLanguage.english => 'Download this surah',
    AppLanguage.arabic => 'تنزيل هذه السورة',
    AppLanguage.kurdish => 'داگرتنی ئەم سوورەتە',
  };

  String get currentPlaybackLabel => switch (language) {
    AppLanguage.english => 'Now playing',
    AppLanguage.arabic => 'يُتلى الآن',
    AppLanguage.kurdish => 'ئێستا لێدەدرێت',
  };

  String get jumpToCurrentAyahLabel => switch (language) {
    AppLanguage.english => 'Jump to ayah',
    AppLanguage.arabic => 'اذهب إلى الآية',
    AppLanguage.kurdish => 'بڕۆ بۆ ئایەت',
  };

  String get reminderPermissionDenied => switch (language) {
    AppLanguage.english =>
      'Notification permission was not granted. Enable notifications in system settings.',
    AppLanguage.arabic =>
      'لم يتم منح إذن الإشعارات. فعّل الإشعارات من إعدادات النظام.',
    AppLanguage.kurdish =>
      'مۆڵەتی ئاگادارکردنەوە نەدرا. لە ڕێکخستنەکانی سیستەمدا ئاگادارکردنەوە چالاک بکە.',
  };

  String get zikirPresetsTitle => switch (language) {
    AppLanguage.english => 'Tasbih sets',
    AppLanguage.arabic => 'مجموعات التسبيح',
    AppLanguage.kurdish => 'کۆمەڵە زیکرەکان',
  };

  String get zikirPresetsSubtitle => switch (language) {
    AppLanguage.english =>
      'Structured remembrance flows that advance automatically.',
    AppLanguage.arabic => 'مسارات ذكر منظّمة تنتقل تلقائياً بين الأذكار.',
    AppLanguage.kurdish => 'ئەو زیکرانەی کە دوای ، نوێژ دەخوێنرێن .',
  };

  String get zikirCommonTitle => switch (language) {
    AppLanguage.english => 'Common dhikr',
    AppLanguage.arabic => 'أذكار شائعة',
    AppLanguage.kurdish => 'ئەو زیکرانەی زۆر دەخوێنرین  ',
  };

  String get zikirCommonSubtitle => switch (language) {
    AppLanguage.english =>
      'Open any phrase and keep counting from where you last stopped.',
    AppLanguage.arabic => 'افتح أي ذكر وتابع العد من آخر موضع توقفت عنده.',
    AppLanguage.kurdish =>
      'ئەو زیکرانەی لەسەر زمان ئاسانن ، وە لە ڕۆژی دوای لەسەر تەرازوو گرانن . ',
  };

  String get customZikirTitle => switch (language) {
    AppLanguage.english => 'Custom dhikr',
    AppLanguage.arabic => 'ذكر مخصص',
    AppLanguage.kurdish => 'زیکری تایبەت',
  };

  String get customZikirSubtitle => switch (language) {
    AppLanguage.english => 'Add your own phrase and target count.',
    AppLanguage.arabic => 'أضف ذكرك الخاص وحدد العدد المستهدف.',
    AppLanguage.kurdish => 'زیکری  خۆت زیاد بکە و ژمارەی ئامانج دیاری بکە.',
  };

  String get addCustomZikir => switch (language) {
    AppLanguage.english => 'Add custom',
    AppLanguage.arabic => 'إضافة ذكر',
    AppLanguage.kurdish => 'زیادکردنی زیکر',
  };

  String get customZikirEmpty => switch (language) {
    AppLanguage.english =>
      'No custom dhikr yet. Add one to create a personal tasbih goal.',
    AppLanguage.arabic => 'لا يوجد ذكر مخصص بعد. أضف واحداً لإنشاء هدفك الخاص.',
    AppLanguage.kurdish => ' هێشتا هیج زیکرێکت زیاد نەکردوە.',
  };

  String get customZikirFormSubtitle => switch (language) {
    AppLanguage.english =>
      'Create a phrase, optional transliteration, and a target you want to complete.',
    AppLanguage.arabic =>
      'أنشئ العبارة، واللفظ اللاتيني إن رغبت، والعدد الذي تريد إكماله.',
    AppLanguage.kurdish =>
      'دەقەکە و خوێندنەوەی لاتینی ئەگەر دەتەوێت و ژمارەی ئامانج دیاری بکە.',
  };

  String get customPhraseLabel => switch (language) {
    AppLanguage.english => 'Dhikr phrase',
    AppLanguage.arabic => 'نص الذكر',
    AppLanguage.kurdish => 'دەقی زیکر',
  };

  String get customPhraseValidation => switch (language) {
    AppLanguage.english => 'Enter the dhikr phrase first.',
    AppLanguage.arabic => 'أدخل نص الذكر أولاً.',
    AppLanguage.kurdish => 'سەرەتا دەقی زیکر بنووسە.',
  };

  String get customTransliterationLabel => switch (language) {
    AppLanguage.english => 'Transliteration',
    AppLanguage.arabic => 'اللفظ اللاتيني',
    AppLanguage.kurdish => 'ترانسلیتەرەیشن',
  };

  String get customMeaningLabel => switch (language) {
    AppLanguage.english => 'Meaning (optional)',
    AppLanguage.arabic => 'المعنى (اختياري)',
    AppLanguage.kurdish => 'واتا (ئیختیاری)',
  };

  String get customTargetLabel => switch (language) {
    AppLanguage.english => 'Target count',
    AppLanguage.arabic => 'العدد المستهدف',
    AppLanguage.kurdish => 'ژمارەی ئامانج',
  };

  String get customTargetValidation => switch (language) {
    AppLanguage.english => 'Enter a target greater than zero.',
    AppLanguage.arabic => 'أدخل عدداً أكبر من صفر.',
    AppLanguage.kurdish => 'ژمارەیەک لە سەر صفر زیاتر بنووسە.',
  };

  String get saveCustomZikir => switch (language) {
    AppLanguage.english => 'Save dhikr',
    AppLanguage.arabic => 'حفظ الذكر',
    AppLanguage.kurdish => 'پاشەکەوتکردنی زیکر',
  };

  String get deleteCustomZikir => switch (language) {
    AppLanguage.english => 'Delete',
    AppLanguage.arabic => 'حذف',
    AppLanguage.kurdish => 'سڕینەوە',
  };

  String get deleteCustomZikirTitle => switch (language) {
    AppLanguage.english => 'Delete custom dhikr?',
    AppLanguage.arabic => 'حذف الذكر المخصص؟',
    AppLanguage.kurdish => 'سڕینەوەی زیکری تایبەت؟',
  };

  String get deleteCustomZikirBody => switch (language) {
    AppLanguage.english =>
      'This will remove the custom dhikr and its saved counter progress.',
    AppLanguage.arabic =>
      'سيؤدي هذا إلى حذف الذكر المخصص وتقدم العداد المحفوظ له.',
    AppLanguage.kurdish =>
      'ئەمە زیکری تایبەت و هەموو پێشکەوتنی ژماردنی پاشەکەوتکراوی دەسڕێتەوە.',
  };

  String get cancelLabel => switch (language) {
    AppLanguage.english => 'Cancel',
    AppLanguage.arabic => 'إلغاء',
    AppLanguage.kurdish => 'هەڵوەشاندنەوە',
  };

  String get resumeLabel => switch (language) {
    AppLanguage.english => 'Resume',
    AppLanguage.arabic => 'متابعة',
    AppLanguage.kurdish => 'بەردەوامبوون',
  };

  String get resumeWhereStoppedTitle => switch (language) {
    AppLanguage.english => 'Resume where you stopped',
    AppLanguage.arabic => 'المتابعة من حيث توقفت',
    AppLanguage.kurdish => 'بەردەوامبە لەو شوێنەی وەستایت',
  };

  String get resumeLastReadLabel => switch (language) {
    AppLanguage.english => 'Resume last read',
    AppLanguage.arabic => 'متابعة آخر موضع قراءة',
    AppLanguage.kurdish => 'بەردەوامبە لە دوا خوێندراو',
  };

  String get continueMemorizationLabel => switch (language) {
    AppLanguage.english => 'Continue memorization',
    AppLanguage.arabic => 'متابعة الحفظ',
    AppLanguage.kurdish => 'بەردەوامبوون لە حەفظ',
  };

  String get continueZikirSetLabel => switch (language) {
    AppLanguage.english => 'Continue tasbih set',
    AppLanguage.arabic => 'متابعة مجموعة التسبيح',
    AppLanguage.kurdish => 'بەردەوامبوون لە کۆمەڵەی تەسبیح',
  };

  String get continueZikirLabel => switch (language) {
    AppLanguage.english => 'Continue dhikr',
    AppLanguage.arabic => 'متابعة الذكر',
    AppLanguage.kurdish => 'بەردەوامبوون لە زیکر',
  };

  String get savedProgressTitle => switch (language) {
    AppLanguage.english => 'Saved progress',
    AppLanguage.arabic => 'التقدم المحفوظ',
    AppLanguage.kurdish => 'کۆتا کردار کە ئەنجام دران ',
  };

  String get savedProgressSubtitle => switch (language) {
    AppLanguage.english =>
      'Jump back into your last reading or memorization session.',
    AppLanguage.arabic => 'ارجع إلى آخر جلسة قراءة أو حفظ.',
    AppLanguage.kurdish => 'گەڕانەوە بۆ کۆتا کردار کە ئەنجامت داوە .',
  };

  String get openAyahLabel => switch (language) {
    AppLanguage.english => 'Open ayah',
    AppLanguage.arabic => 'افتح الآية',
    AppLanguage.kurdish => 'ئایەت بکەرەوە',
  };

  String get recentPracticeTitle => switch (language) {
    AppLanguage.english => 'Recent practice',
    AppLanguage.arabic => 'الممارسة الأخيرة',
    AppLanguage.kurdish => 'ڕاهێنانی دوایی',
  };

  String get recentPracticeSubtitle => switch (language) {
    AppLanguage.english =>
      'Your latest Quran recitation and memorization sessions.',
    AppLanguage.arabic => 'أحدث جلسات التلاوة والحفظ الخاصة بك.',
    AppLanguage.kurdish => 'دوایین دانیشتنەکانی تلاوەت و حەفظی تۆ.',
  };

  String surahFallbackLabel(int surahNumber) => switch (language) {
    AppLanguage.english => 'Surah $surahNumber',
    AppLanguage.arabic => 'سورة $surahNumber',
    AppLanguage.kurdish => 'سوورەتی $surahNumber',
  };

  String memorizationWordProgress(int revealedWords) => switch (language) {
    AppLanguage.english => 'Word $revealedWords',
    AppLanguage.arabic => 'الكلمة $revealedWords',
    AppLanguage.kurdish => 'وشەی $revealedWords',
  };

  String recentMemorizationSessionSummary(String surahLabel, int wordNumber) =>
      switch (language) {
        AppLanguage.english =>
          '$surahLabel • Memorization checkpoint $wordNumber',
        AppLanguage.arabic => '$surahLabel • نقطة حفظ $wordNumber',
        AppLanguage.kurdish => '$surahLabel • خاڵی حەفظ $wordNumber',
      };

  String recentRecitationSessionSummary(String surahLabel, int ayahNumber) =>
      switch (language) {
        AppLanguage.english => '$surahLabel • Ayah $ayahNumber',
        AppLanguage.arabic => '$surahLabel • الآية $ayahNumber',
        AppLanguage.kurdish => '$surahLabel • ئایەت $ayahNumber',
      };

  String get savedStopPointTooltip => switch (language) {
    AppLanguage.english => 'Saved stop point',
    AppLanguage.arabic => 'موضع التوقف المحفوظ',
    AppLanguage.kurdish => 'شوێنی وەستانی پاشەکەوتکراو',
  };

  String get markStopPointTooltip => switch (language) {
    AppLanguage.english => 'Mark stop point',
    AppLanguage.arabic => 'حدد موضع التوقف',
    AppLanguage.kurdish => 'شوێنی وەستان دیاری بکە',
  };

  String get youStoppedHereLabel => switch (language) {
    AppLanguage.english => 'You stopped here',
    AppLanguage.arabic => 'توقفت هنا',
    AppLanguage.kurdish => 'لەێرە وەستایت',
  };

  String get targetLabel => switch (language) {
    AppLanguage.english => 'Target',
    AppLanguage.arabic => 'الهدف',
    AppLanguage.kurdish => 'ئامانج',
  };

  String progressInline(int current, int target) => switch (language) {
    AppLanguage.english => '$current / $target',
    AppLanguage.arabic => '$current / $target',
    AppLanguage.kurdish => '$current / $target',
  };

  String get tasbihTitle => switch (language) {
    AppLanguage.english => 'Tasbih Counter',
    AppLanguage.arabic => 'عداد التسبيح',
    AppLanguage.kurdish => 'ژمێرەری تەسبیح',
  };

  String get tasbihPresetTitle => switch (language) {
    AppLanguage.english => 'Tasbih Set',
    AppLanguage.arabic => 'مجموعة التسبيح',
    AppLanguage.kurdish => 'کۆمەڵەی تەسبیح',
  };

  String get zikirMissing => switch (language) {
    AppLanguage.english => 'This dhikr entry is missing.',
    AppLanguage.arabic => 'هذا الذكر غير متوفر.',
    AppLanguage.kurdish => 'ئەم زیکرە بەردەست نییە.',
  };

  String stepIndicator(int current, int total) => switch (language) {
    AppLanguage.english => 'Step $current of $total',
    AppLanguage.arabic => 'المرحلة $current من $total',
    AppLanguage.kurdish => 'هەنگاو $current لە $total',
  };

  String nextDhikrMessage(String name) => switch (language) {
    AppLanguage.english => 'Moving to $name.',
    AppLanguage.arabic => 'الانتقال إلى $name.',
    AppLanguage.kurdish => 'چوون بۆ $name.',
  };

  String get tasbihCompletedMessage => switch (language) {
    AppLanguage.english => 'Tasbih set completed.',
    AppLanguage.arabic => 'اكتملت مجموعة التسبيح.',
    AppLanguage.kurdish => 'کۆمەڵە تەسبیحەکە تەواو بوو.',
  };

  String get counterLabel => switch (language) {
    AppLanguage.english => 'Current count',
    AppLanguage.arabic => 'العدد الحالي',
    AppLanguage.kurdish => 'ژمارەی ئێستا',
  };

  String get completedLabel => switch (language) {
    AppLanguage.english => 'Completed',
    AppLanguage.arabic => 'اكتمل',
    AppLanguage.kurdish => 'تەواو بوو',
  };

  String get tapToCount => switch (language) {
    AppLanguage.english => 'Tap to count',
    AppLanguage.arabic => 'اضغط للعد',
    AppLanguage.kurdish => 'بۆ ژماردن لێبدە',
  };

  String get tasbihCompletedBody => switch (language) {
    AppLanguage.english =>
      'You completed this remembrance set. Reset anytime to begin another round.',
    AppLanguage.arabic =>
      'أكملت هذه المجموعة من الأذكار. أعد الضبط متى شئت لتبدأ مرة أخرى.',
    AppLanguage.kurdish =>
      'ئەم کۆمەڵە زیکرە تەواو کرد. هەر کات دەتەوێت ڕیسێت بکە و دووبارە دەست پێبکە.',
  };

  String get undoLabel => switch (language) {
    AppLanguage.english => 'Undo',
    AppLanguage.arabic => 'تراجع',
    AppLanguage.kurdish => 'گەڕانەوە',
  };

  String get resetCounterLabel => switch (language) {
    AppLanguage.english => 'Reset',
    AppLanguage.arabic => 'إعادة الضبط',
    AppLanguage.kurdish => 'ڕیسێت',
  };

  String languageLabel(AppLanguage value) => switch (value) {
    AppLanguage.english => switch (language) {
      AppLanguage.english => 'English',
      AppLanguage.arabic => 'الإنجليزية',
      AppLanguage.kurdish => 'ئینگلیزی',
    },
    AppLanguage.arabic => switch (language) {
      AppLanguage.english => 'Arabic',
      AppLanguage.arabic => 'العربية',
      AppLanguage.kurdish => 'عەرەبی',
    },
    AppLanguage.kurdish => switch (language) {
      AppLanguage.english => 'Kurdish',
      AppLanguage.arabic => 'الكردية',
      AppLanguage.kurdish => 'کوردی',
    },
  };

  String prayerLabel(PrayerName prayer) => switch (prayer) {
    PrayerName.fajr => switch (language) {
      AppLanguage.english => 'Fajr',
      AppLanguage.arabic => 'الفجر',
      AppLanguage.kurdish => 'بەیانی',
    },
    PrayerName.sunrise => switch (language) {
      AppLanguage.english => 'Sunrise',
      AppLanguage.arabic => 'الشروق',
      AppLanguage.kurdish => 'ڕۆژهەڵاتن',
    },
    PrayerName.dhuhr => switch (language) {
      AppLanguage.english => 'Dhuhr',
      AppLanguage.arabic => 'الظهر',
      AppLanguage.kurdish => 'نیوەڕۆ',
    },
    PrayerName.asr => switch (language) {
      AppLanguage.english => 'Asr',
      AppLanguage.arabic => 'العصر',
      AppLanguage.kurdish => 'عەسر',
    },
    PrayerName.maghrib => switch (language) {
      AppLanguage.english => 'Maghrib',
      AppLanguage.arabic => 'المغرب',
      AppLanguage.kurdish => 'مەغریب',
    },
    PrayerName.isha => switch (language) {
      AppLanguage.english => 'Isha',
      AppLanguage.arabic => 'العشاء',
      AppLanguage.kurdish => 'عیشاء',
    },
  };

  String localizedCityName(BangCityOption city) => switch (language) {
    AppLanguage.english => city.englishName,
    AppLanguage.arabic => city.arabicName,
    AppLanguage.kurdish => city.kurdishName,
  };
}
