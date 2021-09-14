## Cuvva Technical Interview

- This repository includes my solution for [Cuvva](https://www.cuvva.com) technical interview.
- Original repository can be found [here](https://github.com/cuvva/hiring-mobile-test)

### App Feedback

- As a heads up on iOS 15b6, the launch screen has this glitch where it gets smaller to the left side and then goes full screen.
- When the app is completely closed, opening the app using the "Contact support" shortcut dismisses the Intercom support screen.
- Onboarding
    - Nice animation on button highlighting
    - VoiceOver reads the Support button as Ic support
    - Continue web quote screen Close button accessibility label is CloseBarButtonItem
- Signup
    - Deep-link using emailed magic link and consent UX is really nice.
- Profile
    - FPS drops during the list header becomes the navigation bar title
    - The new App Store Review Guidelines (5.1.1) states that "If your app supports account creation, you must also offer account deletion within the app". Since your app does not have the deletion on the App store version, another heads up
- IPA Notes
    - Since the minimum iOS version for the app is 13, how about using Color assets instead of defining them in theme.json probably by using a script error-codes.json strings.json generated common messages for all platforms?
    - Lots of nibs, Storyboard ✅
    - BSON, Binary JSON, MongoDB? Do you plan to use Realm as well?

### Initial notes about the review project

- We could use `warning("// TODO: Configure") in order to notify the candidate for missing points on the code through Xcode warnings

- `Policy` and `Vehicle` storing each other using strong references which would cause a retain cycle.

### Personal notes

- Most of the classes marked as `final` in order to improve compilation time.

- Currently we're not verifying backend endpoint for edge cases such as:
    - Policy end date must be later than the start date.
    - Created policy must have `start_date`, `end_date`, `vehicle` fields.
    - Extended policy must have `original_policy_id`, `start_date`, `end_date` fields.

- `LivePolicyEventProcessor` uses memory storage. 
    - Storage could be expanded to CoreData/SQLite/Realm/GRDB. 
    - However due to `PolicyEventProcessor.retrieve(:)` function returns the value synchronously, threading off of main thread wouldn't be an option for current implementation.
    - `autoreleasepool` used inside the `for` loops in order not to bloat memory with temporary variables.

- `LivePolicyEventProcessor.store(:)` **assumes** some rules while configuring `PolicyHistory` array, such as:
    - A vehicle can have multiple policies.
    - A policy should be created with `policy_created` event.
    - The policy can be extended with `policy_extended` event.
    - An extended policy (A) can be extended again, second extension (B) points to first extension (A) in `original_policy_id` field.
    - Any policy can be cancelled with `policy_cancelled`. Therefore `policy_id` field can point to any created or extended policy.

- I believe snapshot testing would be nice before starting the UI testing in order to capture smaller views' formats.
