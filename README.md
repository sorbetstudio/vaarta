# Vaarta

<div align="center">

![Vaarta Logo](assets/logo.png)

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev)
[![License](https://img.shields.io/github/license/sorbetstudio/vaarta?style=for-the-badge)](LICENSE)
[![Stars](https://img.shields.io/github/stars/sorbetstudio/vaarta?style=for-the-badge)](https://github.com/sorbetstudio/vaarta/stargazers)

A beautiful, open-source AI interface built with Flutter, focusing on utility and deep integration.

[Home Page (not up yet haha)](https://vaarta.sorbet.studio) | [Documentation](docs/README.md) | [Contributing](CONTRIBUTING.md)

</div>

## 📖 About

Vaarta (વાર્તા) means "Story" or "Conversation" in Gujarati. This project aims to create an intuitive and powerful interface for AI interactions.

## 🌟 Features

- 🤖 Advanced AI Integration
- 🎨 Beautiful, Modern UI
- 🔒 Privacy-Focused
- ⚡ High Performance
- 📱 Cross-Platform, by Default

## Finished

- [x] Add copy and regenerate buttons
- [x] Add chunk based text streaming
- [x] Add a settings screen
  - [x] Adding a custom system prompt
  - [x] Custom params (temp, max tokens, etc)
- [x] Implement sqflite
- [x] Implement an LLM Helper to avoid stale AI pub.dev packages

## Todo

- [ ] Issue: Creates a new screen on clicking new message (potentially bloating memory)
- [ ] Feature: Auto-Rename Chats in Chat History
- [ ] SQUIRCLES! <- figma_squircle: ^0.6.3
- [ ] Implement better theming
  - [ ] Get app_theme.dart to integrate correctly
  - [ ] Research and Improve the color scheme
  - [ ] Improve the performance of theme switching toggle
  - [ ] Create a custom mode based on a yaml file that users can edit and backup for theming.
- [ ] Migrate to riverpod completely for state-management
- [ ] Improve the implementation of settings screen
- [ ] Fix the regenerate and copy button design and logic
- [ ] Improve the input widget
  - [ ] Decide on the design
  - [ ] Add the Modality button
- [ ] Modalities:
  - [ ] Add support for image input
  - [ ] Add support for text file attachments text files
  - [ ] Add native audio input for supported models
  - [ ] Add native video input for supported models
- [ ] Realtime Audio (for Gemini and OpenAI)
- [ ] Tool Calling Implementation
- [ ] Provider Support
  - [ ] Gemini
  - [x] OpenRouter
  - [ ] Claude
  - [ ] OpenAI
  - [ ] Ollama
  - [ ] LM Studio
  - [ ] Deepseek
  - [ ] Pollinations

## 🚀 Building Locally / Development

### Prerequisites

- Flutter (latest version)
- Dart SDK
- Android Studio / VS Code
- Git

### Installation

1. Clone the repository

```bash
git clone https://github.com/sorbetstudio/vaarta.git
```

2. Navigate to the project directory

```bash
cd vaarta
```

3. Install dependencies

```bash
flutter pub get
```

4. Run the app

```bash
dart run build_runner build
flutter run
```

## 🤝 Contributing

Contributions are welcome! Please read our [Contributing Guidelines](CONTRIBUTING.md) before submitting a Pull Request.

## 📄 License

This project is licensed under the GPLv3 License - see the [LICENSE](LICENSE) file for details.

## Reach out:

Telegram Group: (under works)

Email: [hi@sorbet.studio](hi@sorbet.studio)

Project Link: [https://github.com/sorbetstudio/vaarta](https://github.com/sorbetstudio/vaarta)
