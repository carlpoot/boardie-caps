import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How many properties can be compared at once (per the task: "2-3
/// properties").
const maxCompareSelection = 3;

/// Property ids the student has picked to compare, from either Browse
/// (Home tab) or the Saved Properties list -- shared across both entry
/// points so a selection carries over if the student switches screens
/// mid-pick.
final compareSelectionProvider = StateProvider<Set<String>>((ref) => {});
