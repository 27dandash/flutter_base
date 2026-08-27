# Navigation

A small, transition-aware routing layer over Flutter's `Navigator`. You almost
never touch the internals — you call the `Go` facade.

## TL;DR — what you actually use

```dart
// Push a widget with a transition
Go.to(const ProfileScreen(), transition: TransitionType.fade);

// Push a named route
Go.toNamed(NamedRoutes.profile.routeName, arguments: id);

// Replace / clear the stack
Go.off(const HomeScreen());
Go.offAll(const LoginScreen());

// Pop (optionally with a result)
Go.back(result: true);

// Global context (e.g. for dialogs from non-widget code)
final ctx = Go.contextOrNull;        // null-safe; null before first frame
```

`Go.context` asserts it is read only after the Navigator is mounted. In code
that can run during bootstrap, use `Go.contextOrNull` and null-check.

## File map (which file to touch)

| You want to… | Open |
| --- | --- |
| Add a navigation call site | nothing — just call `Go.*` |
| Add a named route | `named_routes.dart` + `route_generator.dart` |
| Change the default app transition | `main.dart` → `PageRouterBuilder().initAppRouter(...)` |
| Add a brand-new transition family | `transition/implementation/<name>/` (option + animator + animation) and register it in `transition/imports_transition_builder.dart` |
| Tune an existing transition's curve/duration | the matching `transition/implementation/<name>/option/*_animation_option.dart` |

## Structure

```
navigation/
├── go.dart                       Re-exports the transition *Option classes
├── navigator.dart                The `Go` facade (push/pop/replace + context)
├── named_routes.dart             Route name enum
├── route_generator.dart          onGenerateRoute switch
├── constants/                    Shared defaults (durations, default options)
├── helper/interfaces/            Abstract contracts: Animator, AnimationOption, curve/tween behaviours
├── page_router/                  Builds a PageRoute from a (widget, transition) pair
│   ├── factory/                  PageRouterCreator
│   └── implementation/           Concrete page-router builder
└── transition/                   The 7 transition families
    ├── factory/                  TransitionCreator
    └── implementation/
        ├── fade/   ├── slide/   ├── scale/
        ├── size/   ├── shake/   ├── rotation/   └── cupertino/
            ├── option/           Per-family tunables (duration, curve, …)
            └── animator/         The actual Tween/AnimatedBuilder wiring
```

> The system is intentionally extensible (Strategy + Factory). For most apps you
> only ever call `Go.to(...)`; the deeper folders exist so a new transition can
> be added without touching the call sites.
