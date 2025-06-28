# Smart TODO

A cross-platform mobile app built with Flutter that acts as a smart TODO manager. It learns from user behavior, suggests optimal daily routines using LLMs, and syncs tasks with Google Calendar for seamless time-blocking and journaling.

## Features

### Smart TODO Tasks
- Tasks with title, description, start/end time, duration
- Priority levels and completion status
- Categories for organization

### AI-Powered Suggestions
- Analyzes past tasks and calendar data
- Suggests daily plans and prioritization
- Smart time-blocks with estimated durations

### Calendar Integration
- Syncs tasks to Google Calendar
- Updates calendar entries when tasks are updated

### Personal Journal
- Automatically logs completed tasks with timestamps
- Sentiment analysis for how the day went
- Weekly progress summaries

### Cross-Platform App
- Works on Android, iOS
- Web support (optional)
- Local storage with Hive

### Daily Timeline View
- Visual representation of the day's planned tasks
- Color-coded for completed/incomplete/AI-suggested tasks

## Tech Stack

- **UI Framework**: Flutter
- **State Management**: Riverpod
- **LLM Integration**: OpenRouter API (Mistral 7B)
- **Auth**: Google Sign-In
- **Calendar Sync**: Google Calendar API
- **Storage**: Hive (local storage)
- **Notifications**: Local Push

## Getting Started

### Prerequisites
- Flutter SDK (3.2.0 or higher)
- Dart SDK (3.2.0 or higher)
- Android Studio / Xcode for mobile deployment

### Images
  ![image](https://github.com/user-attachments/assets/f56be234-b3db-4b03-8945-172a765d7859)
![image](https://github.com/user-attachments/assets/7e2ec075-0fd0-473f-b4dd-234787a09ad0)
![image](https://github.com/user-attachments/assets/e48bafdf-8491-484a-8227-de3319c6e10a)
![image](https://github.com/user-attachments/assets/075dd043-ec5e-45b5-8de7-a41517f21cfb)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/smart_todo.git
cd smart_todo
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## Project Structure

- `lib/models/` - Data models for tasks, journals, and user preferences
- `lib/providers/` - Riverpod providers for state management
- `lib/screens/` - UI screens for the application
- `lib/services/` - Services for storage, calendar, and AI integration
- `lib/widgets/` - Reusable UI components
- `lib/config/` - App configuration and theme
- `lib/utils/` - Utility functions and helpers

## Configuration

To use Google Calendar integration and AI features, you need to:

1. Create a Google Cloud project and enable the Google Calendar API
2. Configure OAuth 2.0 credentials
3. Get an API key for OpenRouter or OpenAI
4. Update the API keys in the appropriate service files

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Flutter team for the amazing framework
- OpenRouter for LLM access
- Google Calendar API
