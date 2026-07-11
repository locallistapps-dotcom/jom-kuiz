---
name: Teacher module layout
description: What was built in Prompt 05A (dashboard only) and what remains for future Teacher prompts.
---

Prompt 05A built the Teacher Dashboard exclusively:
- `TeacherDashboard` aggregate entity (profile + school + classes + schedule + activities)
- `TeacherRepository` with ONE method: `getDashboard`
- `TeacherService` with dashboard validation only
- `TeacherDashboardController` — AsyncNotifier, reacts to `currentTeacherIdProvider`
- `/teacher/dashboard` route, protected by RouteGuard automatically
- 3 test files: service (6 tests), controller (5 tests), widget (6 tests)

Quick-action chips (My Classes, Attendance, Homework, Quiz, Announcements) show "coming soon" snackbar — they do NOT navigate anywhere.

**Future prompts add to TeacherRepository and TeacherService:**
- My Classes list / detail
- Attendance marking
- Homework assignment / review
- Quiz creation / review
- Announcements

**`currentTeacherIdProvider` (StateProvider<String>):** same pattern as `currentChildIdProvider`. Set before navigating to teacher screens. In future, sourced from JWT sub claim.

**Why:** Dashboard-only scope keeps the module surface small and avoids building unused infrastructure for unimplemented features.
