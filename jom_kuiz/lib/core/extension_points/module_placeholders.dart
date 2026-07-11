/// Future modules that the Parent Dashboard reserves visual/data slots for.
///
/// Each value maps to a placeholder card on the dashboard today. When a
/// module ships, replace its corresponding placeholder card with the real
/// widget -- no dashboard layout refactor should be required.
///
/// Do NOT add business logic for these modules yet; this enum exists only
/// so placeholder UI and future feature wiring share one source of truth
/// instead of hardcoded strings scattered across screens.
enum PlaceholderModule {
  children('Total Children', 'Manage the children linked to this account'),
  subscription('Subscription Status', 'View or upgrade your current plan'),
  wallet('Reward Wallet', 'Track points and rewards earned'),
  referral('Referral', 'Invite friends and earn rewards'),
  latestActivity('Latest Activity', 'Recent quiz and learning activity'),
  analytics('Analytics', 'Learning progress insights'),
  subjects('Subjects', 'Browse available subjects'),
  quiz('Quiz', 'Assign or review quizzes'),
  leaderboard('Leaderboard', 'Compare progress across children'),
  payment('Payment', 'Manage billing and payment methods'),
  admin('Admin', 'Administrative tools');

  const PlaceholderModule(this.title, this.description);

  final String title;
  final String description;
}
