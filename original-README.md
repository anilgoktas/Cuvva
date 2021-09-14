# Hello fellow iOS developer.

We’re really happy you’re interested in joining our iOS team at Cuvva.

The point of this task is to demonstrate your thinking process, deductive reasoning, problem solving and how well you can interpret and implement a brief. We’re looking for a clean, well factored Swift codebase. Your submission should demonstrate your ability to produce functionally correct, maintainable, testable code. And of course, we want to see your well-versed understanding of the Swift language and the iOS SDK.

What we are not going to look at is any “boilerplate code”. We don’t care how you get the data from the API for instance, feel free to do a blocking synchronous hack if you want to!

If you have any questions, feel free to reach out to the team – we’re here to help you succeed.

## Getting started

We have supplied a skeleton of a simple app that displays insurance policy data for a customers cars.
Each car could have an active policy (one where the current app time is between the start and end dates of the policy) and an array of previous or cancelled policies.
The final models for the UI and the UI itself are complete and should not be changed.
We have supplied mock examples to create these models which you can use as a guide for your "live" implementation

### Your task is : 
 - to retrieve the event stream from the endpoint specified in the API Client
 - decode these event payloads into JSONEvents (of your specification)
 - process these JSONEvents into the final models (Vehicle and Policy)
 - processing logic should be in the LivePolicyEventProcessor
 - we have littered the code base with "TODO"s - all these todo's should be resolved to consider the test as complete
 - create some unit tests that test what you think are the most important aspects (we will run a different valid event stream through your code and would expect the outcome to be correct)
 - UI tests are not required

### Important information about interpreting events
 - the insurance cover for a car (referred to here as a "policy") can actually be multiple concurrent policy type events joined together
 eg
 ```
 "type": "policy_created"
 "policy_id": "dev_pol_0000001",
 "start_date": "2020-03-19T13:00:00.000Z",
 "end_date": "2020-03-20T14:00:00.000Z",
 ```
 then 
 ```
 "type": "policy_extension",
 "original_policy_id": "dev_pol_0000001",
 "policy_id": "dev_pol_0000002",
 "start_date": "2020-03-19T14:00:01.000Z",
 "end_date": "2020-03-20T15:00:00.000Z",
```
This tells us that dev_pol_0000001 has been extended by an hour and is therefore a 2 hour policy (internally made up of 2 x 1 hour policies) 

  - cancellation : start date stays same - duration is zero
  - extension : start date stays same, duration is extended to the new end time

### Notes:
 - No need to touch the UI folder.  If your implementation is correct then the UI will just work :D 
 - Consider the processing of the event stream - we're looking for efficiency & speed of processing (imagine the event stream could contain thousands of events)
 - There is potentially bad design decision in the policy and vehicle models - can you spot it? (you do not need to fix it!)

### Completion
Share your private Github repo with the user @cuvvatest.

Remember to mention your Github username in communication with us or include your name in the repository description so that we know whose code we’re looking at.

After we have considered your submission you may be asked to discuss your solution either face to face or over a video / screen sharing call.

Good luck and we look forward to speaking with you very soon.
