# NextSlice

> 다음 한 조각을 베어 무는 노트.
> One thin slice at a time.

A daily learning ritual built on Kim Chang-jun's (김창준) agile-coach principles:
intent → execution → reflection → recall, in the smallest possible loop.

---

## Why NextSlice

Most productivity apps are about doing more. NextSlice is about **learning more
from less**. Each day produces one "slice":

```
morning  →  one-line intent  (max 80 chars — split forced)
day      →  observations     (optional, mid-day notes)
evening  →  4F retrospective  (Fact / Feeling / Finding / Future)
            └─ Finding is the only field that survives past tonight
sunday   →  weekly retro     (this week's findings + 1 active-recall card)
```

## Design pillars

| Pillar (Kim Chang-jun) | How NextSlice embodies it |
|---|---|
| 자라기 > 잘하기 | Goals are framed as "what will you learn", not "what will you do" |
| 의도적 수련 | One target per day. 80-char ceiling forces small slices. |
| 짧은 피드백 루프 | Daily reflection. Yesterday must close before tomorrow opens (at Hard stage). |
| 암묵지 명시화 | 4F retrospective forces tacit insight into a written Finding. |
| 작은 성공의 누적 | Gradient enforcement: Soft → Medium → Hard, by day count. |
| 능동적 회상 | Weekly retro surfaces one past Finding at a milestone day, asks "does this still apply?" |

## Trust gauge — gradient enforcement

The app gets stricter over time, not stricter immediately:

| Day  | Stage  | Behavior |
|------|--------|----------|
| 1–7  | Soft   | Reminders only. Skipping is fine. |
| 8–21 | Medium | Yesterday's reflection prompts first on morning open, but you can override. |
| 22+  | Hard   | No new intent until yesterday is closed. |

Manual override is always available in Settings — autonomy is part of the philosophy.

## Three screens, that's it

1. **Today** — branches automatically into Morning / Active / Evening / Completed.
2. **Notebook** — accumulated Findings. Searchable, tag-filterable. No proactive recall.
3. **Week** — Sunday retrospective. The only place past Findings come back.

Plus a Lock Screen + Home widget so your intent is always one glance away.

## Tech stack

- SwiftUI (iOS 17+)
- SwiftData (@Model, @Query)
- WidgetKit (Lock Screen + Home Small)
- App Group shared SwiftData store between app & widget

## Project layout

```
NextSlice/
├── NextSliceApp.swift         App entry, container setup
├── ContentView.swift          TabView root
├── Models/                    @Model SwiftData types
│   ├── DailyEntry.swift
│   ├── Finding.swift
│   ├── WeeklyPattern.swift
│   └── UserStage.swift
├── Services/                  Pure logic, no UI
│   ├── EnforcementService.swift       gauge → can-start-today?
│   ├── ReflectionRecallService.swift  picks one Finding for weekly recall
│   └── Date+Helpers.swift             week boundaries
├── Views/
│   ├── Today/                 Morning / Active / Evening / Completed
│   ├── Notebook/              Findings list + detail
│   ├── Week/                  Weekly retro with TrustGauge + recall
│   ├── Shared/                TrustGaugeView, SettingsView
│   └── DesignSystem/Theme.swift
└── NextSliceWidget/           Widget extension target
    ├── NextSliceWidget.swift  WidgetBundle entry
    ├── TodayProvider.swift    TimelineProvider, shared SwiftData read
    └── TodayWidgetView.swift  All families
```

See `SETUP.md` for Xcode project setup steps.

## v0.1 MVP scope

- [x] Today flow (morning intent / 4F retro)
- [x] Notebook (Findings list + detail)
- [x] Weekly retrospective with active recall
- [x] Trust gauge with manual override
- [x] iOS Widget (Lock + Home Small)
- [ ] Export weekly card as image (TODO in WeekView.exportCard)
- [ ] Notifications for evening reflection / weekly retro
- [ ] Onboarding flow (1-screen intro)

## Out of scope (deliberately)

- CBL / Academy integration — keep the tool universal
- Multi-device sync (CloudKit) — could add later if needed
- Social / sharing features — first version is solitary on purpose
- Streaks — they create learned helplessness on miss
