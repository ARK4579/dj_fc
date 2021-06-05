Auto-Generate corresponding Dj Widgets for Flutter Widgets given Flutter SDK location.

## Usage

To update djNameMap:

```ps1
flutter pub run .\scripts\dj_names_map_writer.dart
```

And then to generate all Dj Widgets:

```ps1
flutter pub run .\scripts\widget_converter.dart
```

Finally, generate part files in `dj_fj` repo:

```pas1
cd ../dj_fj
flutter pub run build_runner build
dart format .
```

## bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/ARK4579/dj_fc/issues
