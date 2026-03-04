---
phase: 3
slug: ingredient-selection
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-04
---

# Phase 3 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (built-in) + mocktail 1.0.4 |
| **Config file** | none — standard `flutter test` discovery |
| **Quick run command** | `flutter test test/features/ingredients/` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/features/ingredients/`
- **After every plan wave:** Run `flutter test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 03-01-01 | 01 | 1 | INGR-01 | unit | `flutter test test/features/ingredients/data/ingredient_repository_test.dart` | ✅ | ⬜ pending |
| 03-01-02 | 01 | 1 | INGR-01 | unit | `flutter test test/features/ingredients/data/ingredient_repository_test.dart` | ❌ W0 | ⬜ pending |
| 03-01-03 | 01 | 1 | INGR-02 | unit | `flutter test test/features/ingredients/data/ingredient_repository_test.dart` | ✅ | ⬜ pending |
| 03-01-04 | 01 | 1 | INGR-03 | unit | `flutter test test/features/ingredients/data/ingredient_repository_test.dart` | ✅ | ⬜ pending |
| 03-01-05 | 01 | 1 | INGR-04 | unit | `flutter test test/features/ingredients/data/ingredient_repository_test.dart` | ✅ | ⬜ pending |
| 03-02-01 | 02 | 2 | INGR-05 | unit | `flutter test test/features/ingredients/presentation/providers/selected_today_provider_test.dart` | ✅ | ⬜ pending |
| 03-02-02 | 02 | 2 | INGR-05 | unit | `flutter test test/features/ingredients/presentation/providers/selected_today_provider_test.dart` | ✅ | ⬜ pending |
| 03-02-03 | 02 | 2 | INGR-05 | unit | `flutter test test/features/ingredients/data/ingredient_repository_test.dart` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/features/ingredients/data/ingredient_repository_test.dart` — add test for local-first search (local list matched before OFf API call) — covers INGR-01 fast path
- [ ] `test/features/ingredients/data/ingredient_repository_test.dart` — add test for alphabetical sort within category

*Existing infrastructure covers framework needs — `flutter_test` and `mocktail` already in `pubspec.yaml`.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Shimmer placeholders display during load | INGR-01, INGR-02 | Visual rendering verification | Launch app → navigate to ingredients → observe shimmer during network load |
| Haptic feedback on favorite toggle | INGR-03 | Requires physical device | Tap heart icon → feel light haptic pulse |
| Autocomplete results within 500ms | INGR-01 | Performance timing on real device | Type 3+ chars → results appear within 500ms |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
