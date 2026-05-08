# No Nonsense Sports

iOS live-scores app in SwiftUI.

## Architecture

MVVM + Service layer:

```
No Nonsense Sports/
├── App/              # Entry point + dependency container
├── Models/           # Domain models
├── Networking/       # API client
├── Services/         # ESPN service + mocks
├── ViewModels/       # @Observable view models
├── Views/            # SwiftUI views
└── Assets.xcassets/
```

**Notes:**

- `ScoresService` protocol lets you swap ESPN for another API by implementing the protocol
- `AppEnvironment` has `live()` and `preview()` for real vs mock data
- Uses Swift 6 concurrency (MainActor isolation)
- `@Observable` instead of `ObservableObject`
- DTO types for ESPN JSON → domain models

## Data source

ESPN's public scoreboard API (no key):

```
https://site.api.espn.com/apis/site/v2/sports/{sport}/{league}/scoreboard
```

## Tests

Unit tests use Swift Testing. Run with `⌘U` in Xcode.
