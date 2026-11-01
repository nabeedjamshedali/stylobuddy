/// The two wardrobe profiles a user can choose on `/gender` (F24, design D1).
///
/// Shared so the onboarding feature (which sets it) and the profile
/// repository (which persists it) agree on the values without either
/// feature importing the other. `firestore.rules`' `users/{uid}` value check
/// is the only other place this list lives (F24 §13 Q1).
abstract final class Genders {
  static const male = 'male';
  static const female = 'female';
  static const values = <String>{male, female};
}
