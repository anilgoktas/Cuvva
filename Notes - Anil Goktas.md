### Initial notes about the project

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
