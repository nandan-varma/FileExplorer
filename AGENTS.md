## Language and Coding Style

- **Prefer simpler implementations over complex ones:** Choose straightforward solutions that are easy to understand and maintain.
- **Prefer `struct` for data models** unless reference semantics, inheritance, or shared mutable state are required.
- **Embrace protocol-oriented design:** Define behaviors in protocols and compose types, avoiding deep class hierarchies.
- **Handle optionals safely:** Avoid force unwraps (`!`). Use `if let`, `guard let`, and `??`.
- **Use `guard` for early exits** to keep logic flat and readable.
- **Keep functions small and focused** on a single responsibility. Extract private helpers as needed.
- **Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/):**  
    - Use clear naming and argument labels  
    - Avoid abbreviations  
    - Prefer clarity over brevity

## Project Structure and Architecture

- **Organize by feature** (e.g., Home, Auth, Settings) rather than by type (Views, ViewModels, etc.), especially for larger apps.
- **Choose and apply a clear architecture** (MVC, MVVM, VIPER, TCA, etc.) consistently across modules.
- **Separate layers:**
    - **UI:** SwiftUI / UIKit
    - **Business logic:** Use cases, interactors, view models
    - **Data layer:** Networking, persistence, services
- **Use protocols for abstractions** at boundaries (e.g., `UserService`, `AuthRepository`) to enable mocking and swapping implementations.

## Memory Management and Safety

- **Avoid retain cycles in closures:** Use `[weak self]` (or `[unowned self]` when strictly safe).
- **Manage long-lived closures carefully:** Invalidate timers and remove observers as needed.
- **Minimize global state:** Prefer dependency injection (constructor or property) over singletons.
- **If singletons are necessary:** Keep them thin, focused, and well-encapsulated.

## Optionals, Errors, and Concurrency

- **Model absence with optionals;** avoid sentinel values like empty strings or magic numbers.
- **Use `Result` or `async/await` with `throws`** for asynchronous work, not callback pyramids.
- **Define domain-specific error types** (enums conforming to `Error`) for clarity and better user messages.
- **Use structured concurrency:** Prefer `Task`, `MainActor` for UI code, and avoid unnecessary background queues.

## Testing and Tooling

- **no testing at this time**

## Xcode and Dependency Management

- **Use Swift Package Manager** for third-party libraries when possible; avoid unnecessary dependencies.
- **Prefer using Swift packages over implementing or wrapping native APIs** when suitable, to leverage community support and reduce maintenance.
- **Keep dependencies updated and pinned** to specific versions to prevent breakages.
- **Use build configurations and schemes** (Debug, Release, Staging) with separate bundle IDs and environment settings.
- **Keep targets modular:** Separate app, feature modules, and shared core utilities/frameworks to reduce compile times and coupling.
- **To build the application, use the provided script:**  
  ```sh
  ./build.sh
  ```

## Clean Code and Maintainability

- **Name types and methods after their intent** (e.g., `loadUserProfile()`, not `doStuff()`); avoid generic “Manager/Helper” types.
- **Group code with `// MARK:`** and use extensions to separate responsibilities (e.g., data source methods, layout, navigation).
- **Refactor regularly in small steps;** avoid large, sweeping changes in a single PR.
- **Document public APIs with `///` comments** and keep internal documentation up to date.
- **Keep files reasonably small;** split large view controllers or views into smaller components and child controllers.

