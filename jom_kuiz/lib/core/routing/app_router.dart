import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/controllers/session_controller.dart';
import '../../presentation/screens/auth/forgot_password_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_parent_screen.dart';
import '../../presentation/screens/auth/reset_password_screen.dart';
import '../../presentation/screens/child/achievement_screen.dart';
// ignore: unused_import
// Teacher module is implemented but excluded from active navigation.
// Uncomment the GoRoute block below when the Teacher module is activated.
// import '../../presentation/screens/teacher/teacher_dashboard_screen.dart';
import '../../presentation/screens/child/child_dashboard_screen.dart';
import '../../presentation/screens/placeholder/placeholder_screen.dart';
import '../../presentation/screens/admin/admin_cms_screen.dart';
import '../../presentation/screens/admin/admin_content_screen.dart';
import '../../domain/entities/subscription_package.dart';
import '../../presentation/screens/admin/admin_package_screen.dart';
import '../../presentation/screens/admin/admin_payment_screen.dart';
import '../../presentation/screens/admin/admin_question_screen.dart';
import '../../presentation/screens/admin/admin_subject_access_screen.dart';
import '../../presentation/screens/payment/payment_checkout_screen.dart';
import '../../presentation/screens/payment/payment_history_screen.dart';
import '../../presentation/screens/payment/payment_status_screen.dart';
import '../../presentation/screens/subscription/locked_subjects_screen.dart';
import '../../presentation/screens/subscription/package_detail_screen.dart';
import '../../presentation/screens/subscription/purchased_subjects_screen.dart';
import '../../presentation/screens/subscription/subscription_screen.dart';
import '../../presentation/screens/subject/subject_screen.dart';
import '../../presentation/screens/chapter/chapter_screen.dart';
import '../../presentation/screens/question_bank/question_bank_screen.dart';
import '../../presentation/screens/performance/performance_dashboard_screen.dart';
import '../../domain/entities/chapter.dart';
import '../../domain/entities/quiz_engine.dart';
import '../../domain/entities/subject.dart';
import '../../presentation/screens/child/student_chapter_screen.dart';
import '../../presentation/screens/child/student_subject_screen.dart';
import '../../presentation/screens/child/student_topic_screen.dart';
import '../../presentation/screens/quiz_engine/quiz_home_screen.dart';
import '../../presentation/screens/quiz_engine/quiz_result_screen.dart';
import '../../presentation/screens/topic/topic_screen.dart';
import '../../presentation/screens/year/year_screen.dart';
import '../../presentation/screens/child/child_profile_screen.dart';
import '../../presentation/screens/child/edit_child_profile_screen.dart';
import '../../presentation/screens/child/homework_detail_screen.dart';
import '../../presentation/screens/child/homework_list_screen.dart';
import '../../presentation/screens/child/linked_parent_screen.dart';
import '../../presentation/screens/child/quiz_detail_screen.dart';
import '../../presentation/screens/child/quiz_list_screen.dart';
import '../../presentation/screens/dashboard/dashboard_screen.dart';
import '../../presentation/screens/error/not_found_screen.dart';
import '../../presentation/screens/parent/add_child_screen.dart';
import '../../presentation/screens/parent/child_management_screen.dart';
import '../../presentation/screens/parent/children_list_screen.dart';
import '../../presentation/screens/parent/edit_child_screen.dart';
import '../../presentation/screens/parent/edit_profile_screen.dart';
import '../../presentation/screens/parent/security_screen.dart';
import '../../presentation/screens/auth/child_login_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import 'app_routes.dart';
import 'route_guard.dart';

/// Notifies [GoRouter] to re-evaluate [RouteGuard.redirect] whenever
/// [sessionControllerProvider] changes (login, logout, silent refresh).
class _SessionRouterRefreshNotifier extends ChangeNotifier {
  _SessionRouterRefreshNotifier(Ref ref) {
    ref.listen(sessionControllerProvider, (_, __) => notifyListeners());
  }
}

/// Provides the app's single [GoRouter] instance.
///
/// Route guarding is delegated to [RouteGuard.redirect] so auth logic stays
/// out of the route table. All routes except [AppRoutes.publicRoutes] require
/// an authenticated session.
final Provider<GoRouter> appRouterProvider = Provider<GoRouter>((Ref ref) {
  final RouteGuard routeGuard = RouteGuard(ref);
  final _SessionRouterRefreshNotifier refreshNotifier =
      _SessionRouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    refreshListenable: refreshNotifier,
    redirect: routeGuard.redirect,
    routes: <RouteBase>[
      // ── Auth ───────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        name: AppRoutes.splashName,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: AppRoutes.loginName,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: AppRoutes.registerName,
        builder: (context, state) => const RegisterParentScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: AppRoutes.forgotPasswordName,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        name: AppRoutes.resetPasswordName,
        builder: (context, state) {
          final String? token = state.uri.queryParameters['token'];
          return ResetPasswordScreen(resetToken: token);
        },
      ),

      // ── Child Login ─────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.childLogin,
        name: AppRoutes.childLoginName,
        builder: (context, state) => const ChildLoginScreen(),
      ),

      // ── Parent ─────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.dashboard,
        name: AppRoutes.dashboardName,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: AppRoutes.settingsName,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        name: AppRoutes.editProfileName,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.security,
        name: AppRoutes.securityName,
        builder: (context, state) => const SecurityScreen(),
      ),

      // ── Children Management ─────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.childrenList,
        name: AppRoutes.childrenListName,
        builder: (context, state) => const ChildrenListScreen(),
      ),
      GoRoute(
        path: AppRoutes.addChild,
        name: AppRoutes.addChildName,
        builder: (context, state) => const AddChildScreen(),
      ),
      GoRoute(
        path: AppRoutes.editChild,
        name: AppRoutes.editChildName,
        builder: (context, state) {
          final String childId = state.extra as String? ?? '';
          return EditChildScreen(childId: childId);
        },
      ),
      GoRoute(
        path: AppRoutes.childManagement,
        name: AppRoutes.childManagementName,
        builder: (context, state) {
          final String childId = state.extra as String? ?? '';
          return ChildManagementScreen(childId: childId);
        },
      ),

      // ── Teacher (INACTIVE — code preserved, route excluded from navigation) ─
      // GoRoute(
      //   path: AppRoutes.teacherDashboard,
      //   name: AppRoutes.teacherDashboardName,
      //   builder: (context, state) => const TeacherDashboardScreen(),
      // ),

      // ── Child ──────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.childDashboard,
        name: AppRoutes.childDashboardName,
        builder: (context, state) => const ChildDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.childProfile,
        name: AppRoutes.childProfileName,
        builder: (context, state) => const ChildProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.childEditProfile,
        name: AppRoutes.childEditProfileName,
        builder: (context, state) => const EditChildProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.childLinkedParent,
        name: AppRoutes.childLinkedParentName,
        builder: (context, state) => const LinkedParentScreen(),
      ),
      GoRoute(
        path: AppRoutes.childHomework,
        name: AppRoutes.childHomeworkName,
        builder: (context, state) => const HomeworkListScreen(),
      ),
      GoRoute(
        path: AppRoutes.childHomeworkDetail,
        name: AppRoutes.childHomeworkDetailName,
        builder: (context, state) => const HomeworkDetailScreen(),
      ),
      GoRoute(
        path: AppRoutes.childQuiz,
        name: AppRoutes.childQuizName,
        builder: (context, state) => const QuizListScreen(),
      ),
      GoRoute(
        path: AppRoutes.childQuizDetail,
        name: AppRoutes.childQuizDetailName,
        builder: (context, state) => const QuizDetailScreen(),
      ),
      GoRoute(
        path: AppRoutes.childAchievements,
        name: AppRoutes.childAchievementsName,
        builder: (context, state) => const AchievementScreen(),
      ),

      // ── Blueprint Modules (placeholder — replace builder when implemented) ──
      // ── Subject ────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.subject,
        name: AppRoutes.subjectName,
        builder: (context, state) => const SubjectScreen(),
      ),
      // ── Year ───────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.year,
        name: AppRoutes.yearName,
        builder: (context, state) => const YearScreen(),
      ),
      // ── Chapter ─────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.chapter,
        name: AppRoutes.chapterName,
        builder: (context, state) => const ChapterScreen(),
      ),
      // ── Topic ────────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.topic,
        name: AppRoutes.topicName,
        builder: (context, state) => const TopicScreen(),
      ),
      // ── Question Bank ────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.questionBank,
        name: AppRoutes.questionBankName,
        builder: (context, state) => const QuestionBankScreen(),
      ),
      // ── Quiz Engine ──────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.quizEngine,
        name: AppRoutes.quizEngineName,
        builder: (context, state) => const QuizHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.quizResult,
        name: AppRoutes.quizResultName,
        builder: (context, state) {
          final QuizEngineResult result = state.extra as QuizEngineResult;
          return QuizResultScreen(result: result);
        },
      ),
      // ── Student Study Flow ───────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.studentStudySubjects,
        name: AppRoutes.studentStudySubjectsName,
        builder: (context, state) => const StudentSubjectScreen(),
      ),
      GoRoute(
        path: AppRoutes.studentStudyChapters,
        name: AppRoutes.studentStudyChaptersName,
        builder: (context, state) {
          final Subject subject = state.extra as Subject;
          return StudentChapterScreen(subject: subject);
        },
      ),
      GoRoute(
        path: AppRoutes.studentStudyTopics,
        name: AppRoutes.studentStudyTopicsName,
        builder: (context, state) {
          final Map<String, dynamic> extra =
              state.extra as Map<String, dynamic>;
          return StudentTopicScreen(
            chapter: extra['chapter'] as Chapter,
            subjectName: extra['subjectName'] as String,
          );
        },
      ),
      // ── Performance Summary ──────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.performanceSummary,
        name: AppRoutes.performanceSummaryName,
        builder: (context, state) => const PerformanceDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.subscription,
        name: AppRoutes.subscriptionName,
        builder: (context, state) => const SubscriptionScreen(),
      ),
      GoRoute(
        path: AppRoutes.packageDetail,
        name: AppRoutes.packageDetailName,
        builder: (context, state) {
          final SubscriptionPackage package =
              state.extra as SubscriptionPackage;
          return PackageDetailScreen(package: package);
        },
      ),
      GoRoute(
        path: AppRoutes.purchasedSubjects,
        name: AppRoutes.purchasedSubjectsName,
        builder: (context, state) {
          final String parentId = state.extra as String? ?? '';
          return PurchasedSubjectsScreen(parentId: parentId);
        },
      ),
      GoRoute(
        path: AppRoutes.lockedSubjects,
        name: AppRoutes.lockedSubjectsName,
        builder: (context, state) {
          final String parentId = state.extra as String? ?? '';
          return LockedSubjectsScreen(parentId: parentId);
        },
      ),
      GoRoute(
        path: AppRoutes.referral,
        name: AppRoutes.referralName,
        builder: (context, state) =>
            const PlaceholderScreen(moduleName: 'Referral'),
      ),
      GoRoute(
        path: AppRoutes.rewardWallet,
        name: AppRoutes.rewardWalletName,
        builder: (context, state) =>
            const PlaceholderScreen(moduleName: 'Reward Wallet'),
      ),
      GoRoute(
        path: AppRoutes.payment,
        name: AppRoutes.paymentName,
        builder: (context, state) =>
            const PlaceholderScreen(moduleName: 'Payment'),
      ),
      GoRoute(
        path: AppRoutes.paymentCheckout,
        name: AppRoutes.paymentCheckoutName,
        builder: (context, state) {
          final SubscriptionPackage package =
              state.extra as SubscriptionPackage;
          return PaymentCheckoutScreen(package: package);
        },
      ),
      GoRoute(
        path: AppRoutes.paymentStatus,
        name: AppRoutes.paymentStatusName,
        builder: (context, state) {
          final PaymentStatusArgs args =
              state.extra as PaymentStatusArgs;
          return PaymentStatusScreen(
            transaction: args.transaction,
            package: args.package,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.paymentHistory,
        name: AppRoutes.paymentHistoryName,
        builder: (context, state) => const PaymentHistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminCms,
        name: AppRoutes.adminCmsName,
        builder: (context, state) => const AdminCmsScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminQuestions,
        name: AppRoutes.adminQuestionsName,
        builder: (context, state) => const AdminQuestionScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminContent,
        name: AppRoutes.adminContentName,
        builder: (context, state) => const AdminContentScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminPackages,
        name: AppRoutes.adminPackagesName,
        builder: (context, state) => const AdminPackageScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminSubjectAccess,
        name: AppRoutes.adminSubjectAccessName,
        builder: (context, state) => const AdminSubjectAccessScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminPayments,
        name: AppRoutes.adminPaymentsName,
        builder: (context, state) => const AdminPaymentScreen(),
      ),
    ],
    errorBuilder: (context, state) => const NotFoundScreen(),
  );
});
