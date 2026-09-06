import 'package:shared_preferences/shared_preferences.dart';

import 'onboarding_models.dart';

abstract interface class OnboardingStore {
  Future<bool> isCompleted();

  Future<OnboardingAnswers?> loadAnswers();

  Future<void> complete(OnboardingAnswers answers);
}

class SharedPreferencesOnboardingStore implements OnboardingStore {
  SharedPreferencesOnboardingStore([SharedPreferencesAsync? preferences])
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _completedKey = 'onboarding.completed';
  static const _sourceKey = 'onboarding.source';
  static const _paceKey = 'onboarding.pace';
  static const _dailyGoalKey = 'onboarding.dailyGoal';

  final SharedPreferencesAsync _preferences;

  @override
  Future<bool> isCompleted() async =>
      await _preferences.getBool(_completedKey) ?? false;

  @override
  Future<OnboardingAnswers?> loadAnswers() async {
    final source = await _preferences.getString(_sourceKey);
    final pace = await _preferences.getString(_paceKey);
    final dailyGoal = await _preferences.getInt(_dailyGoalKey);
    if (source == null || pace == null || dailyGoal == null) return null;
    return OnboardingAnswers(source: source, pace: pace, dailyGoal: dailyGoal);
  }

  @override
  Future<void> complete(OnboardingAnswers answers) async {
    await _preferences.setString(_sourceKey, answers.source);
    await _preferences.setString(_paceKey, answers.pace);
    await _preferences.setInt(_dailyGoalKey, answers.dailyGoal);
    await _preferences.setBool(_completedKey, true);
  }
}

class MemoryOnboardingStore implements OnboardingStore {
  MemoryOnboardingStore({this.completed = false, this.answers});

  bool completed;
  OnboardingAnswers? answers;

  @override
  Future<bool> isCompleted() async => completed;

  @override
  Future<OnboardingAnswers?> loadAnswers() async => answers;

  @override
  Future<void> complete(OnboardingAnswers value) async {
    answers = value;
    completed = true;
  }
}
