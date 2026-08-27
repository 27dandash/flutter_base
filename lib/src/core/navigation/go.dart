// Re-exports the animation option classes from every transition family so a
// single import gives callers ergonomic access to `FadeAnimationOptions`,
// `SlideAnimationOption`, etc. The `Go` class itself lives in
// `navigator.dart`.
export 'transition/implementation/cupertino/options/cupertino_animation_option.dart';
export 'transition/implementation/fade/option/fade_animation_option.dart';
export 'transition/implementation/rotation/option/rotation_animation_option.dart';
export 'transition/implementation/scale/options/scale_animation_option.dart';
export 'transition/implementation/size/option/size_animation_option.dart';
export 'transition/implementation/slide/option/slide_animation_option.dart';
