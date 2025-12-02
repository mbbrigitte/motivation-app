# Challenge Replay System Implementation

## Summary of Changes

### 1. **New Files Created**
- `lib/screens/challenges_list.dart` - The main challenges list screen
- Storage service additions (add to your existing `storage_service.dart`)

### 2. **Modified Files**
- `instrument_challenge.dart` - Now supports replay mode
- `practice_finished.dart` - Add the button to navigate to challenges

---

## Key Features Implemented

### ✅ Replay Mode
- `InstrumentChallenge` now accepts `isReplay` parameter
- When `isReplay = true`: No tokens awarded, shows "Excellent! Well done!"
- When `isReplay = false`: Awards tokens, shows token count

### ✅ Challenge Tracking
- Challenges are automatically unlocked when first accessed
- Unlocked status is stored persistently using SharedPreferences
- `StorageService` tracks which challenges are unlocked

### ✅ Challenges List Screen
- Shows all challenges with lock/unlock status
- Locked challenges appear semi-transparent (50% opacity)
- Clicking locked challenges shows a message
- Clicking unlocked challenges launches them in replay mode

### ✅ Tokens Instead of Points
- Changed from awarding both points and tokens to **only tokens**
- First puzzle completion: 1 token
- Label challenge completion: 1 additional token
- Maximum 2 tokens per complete playthrough

---

## How It Works

### First Time Playing (from practice session):
```dart
InstrumentChallenge(isReplay: false)
```
1. Challenge is automatically unlocked
2. Child completes puzzle → receives 1 token
3. Optional label challenge → receives 1 more token
4. Navigates to PracticeFinished screen

### Replaying (from challenges list):
```dart
InstrumentChallenge(isReplay: true)
```
1. Child completes puzzle → NO tokens, shows "Excellent! Well done!"
2. Optional label challenge → NO tokens, same encouragement message
3. Returns to challenges list

---

## Installation Steps

### 1. Add the new files:
- Create `lib/screens/challenges_list.dart` with the provided code

### 2. Update `storage_service.dart`:
Add the four new methods:
- `unlockChallenge(String challengeId)`
- `getUnlockedChallenges()`
- `isChallengeUnlocked(String challengeId)`
- `resetChallenges()` (for testing)

### 3. The `instrument_challenge.dart` is already updated in the artifact

### 4. Add button to `practice_finished.dart`:
```dart
import 'challenges_list.dart';

// Add the button from the practice_finished_button artifact
```

---

## Testing Checklist

- [ ] Complete a practice session → challenge unlocks automatically
- [ ] Navigate to "Ear Training & More Challenges" from final screen
- [ ] See the challenge as unlocked (green border, fully opaque)
- [ ] Replay the challenge
- [ ] Verify NO tokens awarded in replay mode
- [ ] Verify message says "Excellent! Well done!" instead of token count
- [ ] Click locked challenges → shows locked message
- [ ] After completing replay, returns to challenges list

---

## Future Expansion

To add more challenges:

1. Add to `allChallenges` list in `challenges_list.dart`:
```dart
ChallengeItem(
  id: 'new_challenge_id',
  title: 'New Challenge Name',
  description: 'Description here',
  icon: Icons.your_icon,
),
```

2. Add case in `_onChallengePressed()`:
```dart
case 'new_challenge_id':
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => YourNewChallenge(isReplay: true),
    ),
  );
  break;
```

3. In your new challenge widget:
```dart
class YourNewChallenge extends StatefulWidget {
  final bool isReplay;
  const YourNewChallenge({super.key, this.isReplay = false});
}
```

4. Unlock it when first accessed:
```dart
if (!widget.isReplay) {
  StorageService.unlockChallenge('new_challenge_id');
}
```

---

## Notes

- The system automatically tracks which challenges have been completed at least once
- Children can replay challenges as many times as they want
- Only the first completion awards tokens
- The unlock state persists across app restarts
- Use `StorageService.resetChallenges()` for testing/debugging