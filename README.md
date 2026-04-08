# Tactics Board

A web-first tactical board application for football coaches and analysts. Design formations, annotate plays with a full drawing toolkit, and share boards via URL — all in real time.

---

## Features

### Pitch & Formations
- Interactive drag-and-drop player positioning on a football pitch
- 16 built-in formations: `4-4-2`, `4-3-3`, `4-2-3-1`, `3-5-2`, `5-3-2`, `5-4-1`, and more
- Horizontal and vertical pitch orientations
- Classic and modern field styles
- Adjustable field scale
- Snap-to-grid with configurable magnetization
- Show/hide player names

### Drawing Toolkit
- **Tools:** freehand, line, arrow, rectangle, ellipse, text
- **Objects:** spot markers, cones, poles, mannequins, mini goals
- **Line styles:** solid, dashed, dotted
- **Arrow heads:** none, start, end, both
- Color picker, opacity, stroke width controls
- Layer ordering (bring forward / send back)
- Undo / redo
- Draggable toolbar — dock to bottom or left side

### Squad Management
- Add players from club squads (La Liga, Bundesliga, Ligue 1, Serie A, and more)
- Add fully custom players with name, number, and position
- Bench system — move players on/off the pitch
- Clear field in one click

### Boards & Collaboration
- Personal dashboard to manage multiple boards
- Board titles — editable inline
- Real-time persistence to Supabase
- Shareable URLs — `/board/:id` loads the board directly, even for unauthenticated users (redirected to login first)

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart 3.9+) |
| Backend | Supabase (PostgreSQL + Auth) |
| State management | Flutter BLoC + Hydrated BLoC |
| Routing | Go Router |
| Icons | Lucide Icons |
| Typography | Raleway |

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) `^3.9.2`
- A [Supabase](https://supabase.com) project with the schema applied
- Chrome (for web development)

### 1. Clone the repo

```bash
git clone https://github.com/your-username/tactics_board.git
cd tactics_board
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Configure environment

Copy the VS Code launch config example and fill in your Supabase credentials:

```bash
cp .vscode/launch.json.example .vscode/launch.json
```

Open `.vscode/launch.json` and replace the placeholder values:

```json
"--dart-define=SUPABASE_URL=https://your-project.supabase.co",
"--dart-define=SUPABASE_ANON_KEY=your-anon-key-here"
```

> Get these from your Supabase project: **Settings → API → Project URL** and **anon public key**.

### 4. Run

```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key-here
```

Or use the **tactics_board (dev)** launch configuration in VS Code.

---

## Project Structure

```
lib/
├── bloc/               # BLoC state management (tactics board, drawing)
├── config/             # Supabase config (values injected via --dart-define)
├── data/               # Static data — formations, clubs, competitions
├── models/             # Domain models (BoardModel, TacticPlayer, DrawingElement…)
├── services/           # Supabase services (BoardService, AuthService…)
├── utils/              # Web utilities
├── widgets/            # UI components
│   ├── drawing_layer.dart          # Full drawing engine
│   ├── field_controls_toolbar.dart # Field settings toolbar
│   ├── football_pitch_painter.dart # Pitch renderer
│   ├── squad_sidebar.dart          # Squad panel
│   └── add_player_dialog.dart      # Custom player dialog
├── dashboard_page.dart
├── tactics_board_page.dart
├── router.dart
└── main.dart
```

---

## Environment Variables

| Variable | Description |
|---|---|
| `SUPABASE_URL` | Your Supabase project URL |
| `SUPABASE_ANON_KEY` | Supabase anon (public) key — safe for client use |

> Never use the `service_role` key in client-side code — it bypasses Row Level Security.

---

## License

MIT
