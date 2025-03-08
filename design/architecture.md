# Project Architecture Plan

This document outlines the proposed architecture for the Vaarta application, incorporating the initial critique, recommendations for extensibility, and the addition of advanced features like tool calling, image generation, and voice mode.

## Initial Critique and Recommendations

The initial project structure was organized into `screens`, `services`, and `theme` directories, which is a good starting point for a Flutter project. The use of `Provider` for state management and the abstraction of database and LLM interactions were also positive aspects.

Recommendations for improvement included:

1.  Creating a `lib/models` directory for data models.
2.  Relocating UI-related classes (e.g., `ThinkingAnimation`, `ThinkingBubble`) to either `lib/screens/` (if specific to a screen) or `lib/widgets/` (if reusable).
3.  Moving the `SlideRightRoute` class to `lib/utils/`.
4.  Creating a `lib/widgets` or `lib/components` directory for reusable UI components.
5. Adding more comments.

## Extensibility and Advanced Features

To accommodate future growth and the addition of features like tool calls, image generation, FIM completion, OS integration, and voice mode, the architecture has been further refined.  The key principle is to maintain a modular design with clear separation of concerns.

The following features were considered:

*   **Tool Calls:**  Allowing the AI to interact with external tools (web search, calculations, etc.).
*   **Image Generation:**  Integrating image generation capabilities.
*   **Artifacts:**  Managing files/data generated during interactions.
*   **Fill-in-the-Middle (FIM) Completion:**  A specialized text completion mode.
*   **OS Integration:**  Interacting with the operating system.
*   **Voice-Only Mode:**  Supporting voice input and output.

## Proposed Directory Structure

```
lib/
├── models/
│   └── chat_message.dart
├── widgets/
│   ├── thinking_animation.dart
│   ├── thinking_bubble.dart
│   ├── streaming_message.dart
│   ├── skeuomorphic_toggle.dart
│   ├── skeuomorphic_dropdown.dart
│   └── skeuomorphic_textfield.dart
├── utils/
│   └── slide_right_route.dart
├── services/
│   ├── database_helper.dart
│   └── llms/
│       ├── llm_client.dart
│       └── fim_completions.dart
├── screens/
│   ├── chat_list_screen.dart
│   ├── chat_screen.dart
│   └── settings_screen.dart
├── theme/
│   └── app_theme.dart
├── providers/
│   ├── app_state.dart
│   └── chat_provider.dart  (Future)
├── config/
│    └── open_router_config.dart
├── core/
│    ├── llm_message.dart
│    ├── llm_config.dart
│    └── llm_response.dart
├── tools/
│   ├── os_integration.dart
│   ├── image_generation.dart
│   └── web_search.dart  (Example)
├── audio/
│   ├── speech_to_text.dart
│   └── text_to_speech.dart
├── artifacts/
│    └── artifact_manager.dart
└── main.dart
```

## Mermaid Diagram

Below is the Mermaid code representing the proposed directory structure.  **You will need to generate a PNG image from this code and save it as `design/architecture.png`.** You can use an online Mermaid editor (like the one at [https://mermaid.live/](https://mermaid.live/)) or a VS Code extension (like "Markdown Preview Mermaid Support") to generate the image.

```mermaid
graph TD;
    subgraph lib
        subgraph models
            A[chat_message.dart]
        end
        subgraph widgets
            B[thinking_animation.dart]
            C[thinking_bubble.dart]
            D[streaming_message.dart]
            E[skeuomorphic_toggle.dart]
            F[skeuomorphic_dropdown.dart]
            G[skeuomorphic_textfield.dart]
        end
        subgraph utils
            H[slide_right_route.dart]
        end
        subgraph services
            I[database_helper.dart]
            subgraph llms
                J[llm_client.dart]
                JA[fim_completions.dart]
            end
        end
        subgraph screens
            K[chat_list_screen.dart]
            L[chat_screen.dart]
            M[settings_screen.dart]
        end
        subgraph theme
            N[app_theme.dart]
        end
        subgraph providers
            O[app_state.dart]
            P[chat_provider.dart]
        end
         subgraph config
            Q[open_router_config.dart]
        end
        subgraph core
            R[llm_message.dart]
            S[llm_config.dart]
            T[llm_response.dart]
        end
        subgraph tools
            TA[os_integration.dart]
            TB[image_generation.dart]
            TC[web_search.dart]
        end
        subgraph audio
            U[speech_to_text.dart]
            V[text_to_speech.dart]
        end
        subgraph artifacts
            W[artifact_manager.dart]
        end

        U[main.dart]
    end
```

## Directory/File Explanations:

*   **`lib/models/`**: Data model classes (e.g., `ChatMessage`).
*   **`lib/widgets/`**: Reusable UI components.
*   **`lib/utils/`**: Utility functions and classes.
*   **`lib/services/`**: Interactions with external services (database, LLMs).
    *   **`lib/services/llms/`**:  LLM-related logic.
        *   `llm_client.dart`: Handles communication with LLMs.
        *   `fim_completions.dart`:  Logic for Fill-In-the-Middle completions.
*   **`lib/screens/`**: UI for different app screens.
*   **`lib/theme/`**: Theme definitions.
*   **`lib/providers/`**: State management logic (using `Provider`).
*   **`lib/config/`**: Configuration classes.
* **`lib/core/`**: Core abstractions.
*   **`lib/tools/`**: Integrations with external tools.
    *   `os_integration.dart`: OS interaction.
    *   `image_generation.dart`: Image generation.
    *   `web_search.dart`: Example tool (web search).
*   **`lib/audio/`**: Voice-related functionalities.
    *   `speech_to_text.dart`: Speech-to-text conversion.
    *   `text_to_speech.dart`: Text-to-speech conversion.
* **`lib/artifacts/`**:
    *   `artifact_manager.dart`: Handles the storage, retrieval, and management of generated files or data.
*   **`lib/main.dart`**: Application entry point.