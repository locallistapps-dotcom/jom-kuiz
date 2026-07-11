/// Centralized route paths and names, so screens/widgets never hardcode
/// route strings inline.
abstract final class AppRoutes {
  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';

  // ── Parent ────────────────────────────────────────────────────────────────
  static const String dashboard = '/dashboard';
  static const String settings = '/settings';
  static const String editProfile = '/parent/edit-profile';
  static const String security = '/parent/security';

  // ── Teacher ───────────────────────────────────────────────────────────────
  static const String teacherDashboard = '/teacher/dashboard';

  // ── Child Login ───────────────────────────────────────────────────────────
  static const String childLogin = '/child-login';

  // ── Children Management (parent) ──────────────────────────────────────────
  static const String childrenList = '/parent/children';
  static const String addChild = '/parent/children/add';
  static const String editChild = '/parent/children/edit';
  static const String childManagement = '/parent/children/manage';

  // ── Child ─────────────────────────────────────────────────────────────────
  static const String childDashboard = '/child/dashboard';
  static const String childProfile = '/child/profile';
  static const String childEditProfile = '/child/edit-profile';
  static const String childLinkedParent = '/child/linked-parent';
  static const String childHomework = '/child/homework';
  static const String childHomeworkDetail = '/child/homework/detail';
  static const String childQuiz = '/child/quiz';
  static const String childQuizDetail = '/child/quiz/detail';
  static const String childAchievements = '/child/achievements';

  // ── Student Study Flow (Subject → Chapter → Topic → Quiz) ────────────────
  static const String studentStudySubjects = '/child/study/subjects';
  static const String studentStudyChapters = '/child/study/chapters';
  static const String studentStudyTopics = '/child/study/topics';

  // ── Subject ───────────────────────────────────────────────────────────────
  static const String subject = '/subject';

  // ── Year ──────────────────────────────────────────────────────────────────
  static const String year = '/year';

  // ── Chapter ───────────────────────────────────────────────────────────────
  static const String chapter = '/chapter';

  // ── Topic ─────────────────────────────────────────────────────────────────
  static const String topic = '/topic';

  // ── Question Bank ─────────────────────────────────────────────────────────
  static const String questionBank = '/question-bank';

  // ── Quiz Engine ───────────────────────────────────────────────────────────
  static const String quizEngine = '/quiz-engine';

  // ── Quiz Result ───────────────────────────────────────────────────────────
  static const String quizResult = '/quiz-result';

  // ── Performance Summary ───────────────────────────────────────────────────
  static const String performanceSummary = '/performance';

  // ── Subscription ──────────────────────────────────────────────────────────
  static const String subscription = '/subscription';
  static const String packageDetail = '/subscription/package-detail';
  static const String purchasedSubjects = '/subscription/purchased-subjects';
  static const String lockedSubjects = '/subscription/locked-subjects';

  // ── Referral ──────────────────────────────────────────────────────────────
  static const String referral = '/referral';

  // ── Reward Wallet ─────────────────────────────────────────────────────────
  static const String rewardWallet = '/reward-wallet';

  // ── Payment ───────────────────────────────────────────────────────────────
  static const String payment = '/payment';
  static const String paymentCheckout = '/payment/checkout';
  static const String paymentStatus = '/payment/status';
  static const String paymentHistory = '/payment/history';

  // ── Admin CMS ─────────────────────────────────────────────────────────────
  static const String adminCms = '/admin';

  /// Admin-only enhanced question management screen.
  static const String adminQuestions = '/admin/questions';

  /// Admin-only CMS content management screen (full CRUD).
  static const String adminContent = '/admin/content';

  /// Admin-only Subscription Package CRUD screen.
  static const String adminPackages = '/admin/packages';

  /// Admin-only Subscriber & Subject Access viewer.
  static const String adminSubscriptions = '/admin/subscriptions';
  static const String adminSubjectAccess = '/admin/subject-access';

  /// Admin-only Payment transactions viewer.
  static const String adminPayments = '/admin/payments';

  // ── Route names ───────────────────────────────────────────────────────────
  static const String splashName = 'splash';
  static const String loginName = 'login';
  static const String registerName = 'register';
  static const String forgotPasswordName = 'forgotPassword';
  static const String resetPasswordName = 'resetPassword';
  static const String dashboardName = 'dashboard';
  static const String settingsName = 'settings';
  static const String editProfileName = 'editProfile';
  static const String securityName = 'security';
  static const String teacherDashboardName = 'teacherDashboard';
  static const String childDashboardName = 'childDashboard';
  static const String childProfileName = 'childProfile';
  static const String childEditProfileName = 'childEditProfile';
  static const String childLinkedParentName = 'childLinkedParent';
  static const String childHomeworkName = 'childHomework';
  static const String childHomeworkDetailName = 'childHomeworkDetail';
  static const String childQuizName = 'childQuiz';
  static const String childQuizDetailName = 'childQuizDetail';
  static const String childAchievementsName = 'childAchievements';
  static const String subjectName = 'subject';
  static const String yearName = 'year';
  static const String chapterName = 'chapter';
  static const String topicName = 'topic';
  static const String questionBankName = 'questionBank';
  static const String quizEngineName = 'quizEngine';
  static const String quizResultName = 'quizResult';
  static const String performanceSummaryName = 'performanceSummary';
  static const String subscriptionName = 'subscription';
  static const String packageDetailName = 'packageDetail';
  static const String purchasedSubjectsName = 'purchasedSubjects';
  static const String lockedSubjectsName = 'lockedSubjects';
  static const String referralName = 'referral';
  static const String rewardWalletName = 'rewardWallet';
  static const String paymentName = 'payment';
  static const String paymentCheckoutName = 'paymentCheckout';
  static const String paymentStatusName = 'paymentStatus';
  static const String paymentHistoryName = 'paymentHistory';
  static const String adminCmsName = 'adminCms';
  static const String adminQuestionsName = 'adminQuestions';
  static const String adminContentName = 'adminContent';
  static const String adminPackagesName = 'adminPackages';
  static const String adminSubscriptionsName = 'adminSubscriptions';
  static const String adminSubjectAccessName = 'adminSubjectAccess';
  static const String adminPaymentsName = 'adminPayments';

  // ── Student Study Flow names ───────────────────────────────────────────────
  static const String studentStudySubjectsName = 'studentStudySubjects';
  static const String studentStudyChaptersName = 'studentStudyChapters';
  static const String studentStudyTopicsName = 'studentStudyTopics';

  // ── Route names (child/parent management) ─────────────────────────────────
  static const String childLoginName = 'childLogin';
  static const String childrenListName = 'childrenList';
  static const String addChildName = 'addChild';
  static const String editChildName = 'editChild';
  static const String childManagementName = 'childManagement';

  /// Routes reachable while signed out.
  static const List<String> publicRoutes = <String>[
    splash,
    login,
    register,
    forgotPassword,
    resetPassword,
  ];

  /// Routes accessible only by users with role `'admin'`.
  /// Every route that starts with `/admin` is enforced by [RouteGuard].
  static const Set<String> adminRoutes = <String>{
    adminCms,
    adminQuestions,
    adminContent,
    adminPackages,
    adminSubscriptions,
    adminSubjectAccess,
    adminPayments,
  };
}
