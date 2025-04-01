# Vanishing Tic Tac Toe

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-039BE5?style=for-the-badge&logo=Firebase&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)

A multiplayer Tic Tac Toe game with a twist - pieces vanish after a certain number of turns, adding a strategic element to the classic game.

## ✨ Features

- **Vanishing Effect**: Pieces disappear after a set number of turns, creating dynamic gameplay
- **Multiple Game Modes**: Play locally, against AI, or online with other players
- **Hell Mode**: A challenging variant where each cell becomes its own Tic Tac Toe board
- **Friend System**: Add friends and challenge them to matches
- **Match History**: Track your game results and statistics
- **Mission System**: Complete missions to earn rewards
- **User Profiles**: Customize your profile and track your progress

## 🎮 Game Modes

- **Two Players**: Local multiplayer on the same device
- **vs Computer**: Play against AI with adjustable difficulty levels
- **Online Matchmaking**: Compete against random players online
- **Hell Mode**: A recursive Tic Tac Toe variant for advanced players
- **Friendly Match**: Challenge your friends to a game

## 🏗️ Architecture

The project follows a feature-first architecture with clear separation of concerns:

- **Core**: Utilities, configurations, and shared functionality
- **Features**: Self-contained modules (auth, game, friends, etc.)
- **Shared**: Models, providers, and widgets used across features

## 🚀 Recent Updates

- Fixed end game dialog issues in computer games
- Improved match history handling to prevent duplications
- Enhanced computer player behavior in Hell Mode
- Added center cell restriction for more strategic gameplay
- Refactored connection monitoring logic
- Improved rank update handling

## 🛠️ Technologies

- **Flutter**: Cross-platform UI framework
- **Firebase**: Backend services (Auth, Firestore, Realtime Database)
- **Provider**: State management
- **Dart**: Programming language

## 📱 Screenshots

<!-- Add screenshots here -->

## 🔧 Installation

1. Clone the repository
2. Set up Firebase project and add configuration files
3. Run `flutter pub get` to install dependencies
4. Run `flutter run` to start the app

## 🧪 Development

This project is built with Flutter and Firebase, providing a cross-platform mobile gaming experience with online capabilities.

```
flutter pub get
flutter run
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request
