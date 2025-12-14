# Adhan Dart 1.2.0 - API Reference

## Correct API Usage for Prayer Times

Based on the official documentation at https://pub.dev/packages/adhan_dart

### 1. PrayerTimes Constructor

**Correct Signature:**

```dart
PrayerTimes prayerTimes = PrayerTimes(
  coordinates: coordinates,
  date: date,
  calculationParameters: params,
  precision: true,  // optional, defaults to false (minute precision)
);
```

**Parameters:**

- `coordinates:` - Coordinates object (required)
- `date:` - DateTime object (required)
- `calculationParameters:` - CalculationParameters object (required)
- `precision:` - bool (optional) - true for second precision, false for minute precision

### 2. CalculationMethod for Singapore

**INCORRECT (What's currently in the code):**

```dart
❌ final calculationParams = CalculationMethod.singapore.getParameters();
```

**CORRECT (Two valid options):**

```dart
// Option 1: Using static method (from documentation examples)
✅ CalculationParameters params = CalculationMethod.Singapore();

// Option 2: Using CalculationMethodParameters class
✅ CalculationParameters params = CalculationMethodParameters.singapore();
```

**Note:** The example from pub.dev uses `CalculationMethod.MuslimWorldLeague()` with capital letters,
so for Singapore it should be `CalculationMethod.Singapore()`.

### 3. Full Working Example

````dart
import 'package:adhan_dart/adhan_dart.dart';

// Define coordinates (Bandar Lampung, Indonesia)
Coordinates coordinates = const Coordinates(-5.4292, 105.2625);

// Get current date
DateTime date = DateTime.now();

// Get calculation parameters for Singapore method (good for Indonesia)
// Two valid options:
CalculationParameters params = CalculationMethod.Singapore();
// OR:
// CalculationParameters params = CalculationMethodParameters.singapore();

// Optional: Customize parameters
// params.madhab = Madhab.hanafi;  // For different Asr calculation
// params.adjustments[Prayer.fajr] = 2;  // Add 2 minutes adjustment

// Create PrayerTimes object
PrayerTimes prayerTimes = PrayerTimes(
  coordinates: coordinates,
  date: date,
  calculationParameters: params,
  precision: true,  // For second-level precision
);

// Access prayer times
DateTime fajrTime = prayerTimes.fajr;
DateTime sunriseTime = prayerTimes.sunrise;
DateTime dhuhrTime = prayerTimes.dhuhr;
DateTime asrTime = prayerTimes.asr;
DateTime maghribTime = prayerTimes.maghrib;
### 4. Available Calculation Methods

Methods can be accessed via `CalculationMethod` (with capital letters) or `CalculationMethodParameters`:

```dart
// Muslim World League
CalculationMethod.MuslimWorldLeague()
// OR: CalculationMethodParameters.muslimWorldLeague()

// Egyptian General Authority
CalculationMethod.Egyptian()
// OR: CalculationMethodParameters.egyptian()

// University of Islamic Sciences, Karachi
CalculationMethod.Karachi()
// OR: CalculationMethodParameters.karachi()

// Umm al-Qura University, Makkah
CalculationMethod.UmmAlQura()
// OR: CalculationMethodParameters.ummAlQura()

// Dubai
CalculationMethod.Dubai()
// OR: CalculationMethodParameters.dubai()

// Qatar
CalculationMethod.Qatar()
// OR: CalculationMethodParameters.qatar()

// Kuwait
CalculationMethod.Kuwait()
// OR: CalculationMethodParameters.kuwait()

// Moonsighting Committee (North America, UK)
CalculationMethod.MoonsightingCommittee()
// OR: CalculationMethodParameters.moonsightingCommittee()

// Singapore, Malaysia, Indonesia ⭐ (Best for this project)
CalculationMethod.Singapore()
// OR: CalculationMethodParameters.singapore()

// Turkey
CalculationMethod.Turkey()
// OR: CalculationMethodParameters.turkiye()

// Tehran
CalculationMethod.Tehran()
// OR: CalculationMethodParameters.tehran()

// North America (ISNA)
CalculationMethod.NorthAmerica()
// OR: CalculationMethodParameters.northAmerica()

// Custom method
CalculationMethod.Other()
// OR: CalculationMethodParameters.other()
````

// Custom method
CalculationMethodParameters.other()

````

### 5. Convenience Methods

```dart
// Get current prayer (returns Prayer enum or null)
var current = prayerTimes.currentPrayer(date: DateTime.now());

// Get next prayer (returns Prayer enum)
var next = prayerTimes.nextPrayer();

// Get time for specific prayer
var nextPrayerTime = prayerTimes.timeForPrayer(next);
````

### 6. Madhab Options

```dart
// Earlier Asr time (default)
params.madhab = Madhab.shafi;

// Later Asr time
params.madhab = Madhab.hanafi;
```

### 7. Adjustments

````dart
// Add custom time adjustments (in minutes)
params.adjustments[Prayer.fajr] = 2;    // Add 2 minutes to Fajr
## Summary of Required Changes

In `prayer_times_service.dart`, change:

**FROM:**
```dart
final calculationParams = CalculationMethod.singapore.getParameters();
````

**TO (Option 1 - Matches official example style):**

```dart
final calculationParams = CalculationMethod.Singapore();
```

**OR (Option 2 - Alternative API):**

```dart
final calculationParams = CalculationMethodParameters.singapore();
```

That's the main fix needed! The PrayerTimes constructor usage is already correct with named parameters.

## Official Example Reference

From https://pub.dev/packages/adhan_dart/example:

```dart
import 'package:adhan_dart/adhan_dart.dart';

main() {
  DateTime date = DateTime.now();
  Coordinates coordinates = Coordinates(35.78056, -78.6389);

  // Note the capital letters in method name
  CalculationParameters params = CalculationMethod.MuslimWorldLeague();
  params.madhab = Madhab.Hanafi;

  PrayerTimes prayerTimes = PrayerTimes(
    coordinates: coordinates,
    date: date,
    calculationParameters: params,
    precision: true
  );

  // Access prayer times
  DateTime fajrTime = prayerTimes.fajr;
  DateTime dhuhrTime = prayerTimes.dhuhr;
  DateTime asrTime = prayerTimes.asr;
  DateTime maghribTime = prayerTimes.maghrib;
  DateTime ishaTime = prayerTimes.isha;

  // Convenience methods
  String current = prayerTimes.currentPrayer(date: DateTime.now());
  String next = prayerTimes.nextPrayer();
  DateTime? nextPrayerTime = prayerTimes.timeForPrayer(next);
}
```

In `prayer_times_service.dart`, change:

**FROM:**

```dart
final calculationParams = CalculationMethod.singapore.getParameters();
```

**TO:**

```dart
final calculationParams = CalculationMethodParameters.singapore();
```

That's the main fix needed! The PrayerTimes constructor usage is already correct with named parameters.
