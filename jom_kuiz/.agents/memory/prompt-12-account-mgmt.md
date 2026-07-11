---
name: Prompt 12 Account Management 2.0
description: Architecture decisions and completion status for parent/child account management upgrade
---

## Status: ALL FILES COMPLETE as of July 2026

### New files created (all layers)
- `lib/domain/entities/education_level.dart` — EducationLevel enum, ChildAccountStatus, EducationLevelHelper
- `lib/core/error/account_management_error_codes.dart` — ACCT-001..010
- `lib/data/models/account_management_requests.dart` — Create/Update/SetStatus/ResetPassword requests
- `lib/data/models/account_management_models.dart` — ChildManagementModel + ChildCardData
- `lib/domain/repositories/account_management_repository.dart` — abstract interface
- `lib/data/datasources/account_management_remote_data_source.dart` — Supabase PostgREST + loginChild
- `lib/data/repositories/account_management_repository_impl.dart`
- `lib/data/services/account_management_service.dart` — validation + generateUsername
- `lib/data/services/child_auth_service.dart` — child login → saves tokens → returns childId
- `lib/presentation/providers/account_management_providers.dart` — DI chain + childAuthServiceProvider
- `lib/presentation/controllers/children_list_controller.dart` — bulk children+perf fetch
- `lib/presentation/controllers/child_management_controller.dart` — autoDispose.family keyed by childId
- `lib/presentation/screens/auth/child_login_screen.dart` — student_id + username + password form
- `lib/presentation/screens/parent/children_list_screen.dart` — ChildCardData list with perf stats
- `lib/presentation/screens/parent/add_child_screen.dart` — create child form
- `lib/presentation/screens/parent/edit_child_screen.dart` — edit child (no school/grade)
- `lib/presentation/screens/parent/child_management_screen.dart` — status toggle, perf links, password reset
- `lib/presentation/providers/quiz_filter_providers.dart` — childEducationLevelProvider, childYearGradeProvider

### Modified files
- `lib/domain/entities/child_profile.dart` — added studentId, educationLevel, yearGrade, accountStatus; removed school, grade
- `lib/data/models/child_profile_model.dart` — mapped new fields; removed school/grade
- `lib/data/models/child_requests.dart` — UpdateChildProfileRequest now only bio/gender/dateOfBirth/name
- `lib/domain/repositories/child_repository.dart` — removed school/grade params
- `lib/data/services/child_service.dart` — removed school/grade
- `lib/data/repositories/child_repository_impl.dart` — removed school/grade
- `lib/presentation/controllers/child_profile_controller.dart` — removed school/grade
- `lib/presentation/providers/child_providers.dart` — added userRoleProvider; removed edu level providers (moved to quiz_filter_providers.dart)
- `lib/presentation/controllers/auth_controller.dart` — added loginAsChild; sets userRoleProvider='parent' on parent login
- `lib/presentation/controllers/session_controller.dart` — clears userRoleProvider + currentChildIdProvider on logout
- `lib/core/routing/route_guard.dart` — role-based redirect (child→/child/dashboard, parent→/dashboard)
- `lib/core/routing/app_routes.dart` — added childLogin, childrenList, addChild, editChild, childManagement
- `lib/core/routing/app_router.dart` — wired all new screens
- `lib/core/validators/validators.dart` — added studentId() validator (exactly 8 digits)
- `lib/core/error/child_error_codes.dart` — added CHILD-008 disabledAccount, CHILD-009 invalidCredentials
- `lib/presentation/screens/auth/login_screen.dart` — added "Login as Student" button → /child-login
- `lib/presentation/screens/dashboard/dashboard_screen.dart` — _ChildrenCard navigates to /parent/children
- `lib/presentation/screens/child/child_profile_screen.dart` — shows studentId, educationLevel, yearGrade, accountStatus
- `lib/presentation/screens/child/edit_child_profile_screen.dart` — simplified to self-edit only (no school/grade)
- `lib/presentation/screens/child/child_dashboard_screen.dart` — _ClassInfoCard uses educationLevel/yearGrade

### Key architectural decisions

**Why child auth is separate from AuthService:**
Added `ChildAuthService` (uses `AccountManagementRemoteDataSource.loginChild`) rather than extending the existing auth layer, to avoid touching AuthRepository/AuthRepositoryImpl. The `loginChild` endpoint (`POST /auth/child/login`) is Supabase-custom and differs enough from parent JWT auth that keeping it separate is cleaner.

**Why userRoleProvider lives in child_providers.dart:**
It's a lightweight StateProvider with no deps. Placing it in auth_providers would create a circular dep (auth_controller → auth_providers → child_providers is fine; the reverse is not). Placing it in child_providers.dart avoids this.

**Why quiz_filter_providers.dart is separate from child_providers.dart:**
`childEducationLevelProvider` and `childYearGradeProvider` watch `childProfileControllerProvider` (from `child_profile_controller.dart`), which imports `child_providers.dart`. Putting them in child_providers.dart would create a circular import.

**School/grade removal is complete:**
Both `ChildProfile` entity and `ChildProfileModel` no longer have `school`/`grade` fields. The `UpdateChildProfileRequest` only covers self-edit fields (name, bio, gender, dateOfBirth). Education level management is fully parent-side via `AccountManagementService`.
