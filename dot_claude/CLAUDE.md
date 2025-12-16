# CORE PRINCIPLES

Follow Kent Beck's Test-Driven Development (TDD) methodology as the preferred approach for all development work.

When I say "go":

1. If `scrum.yaml` exists
    * ask scrum master subagent for what to do next
2. If `plan.md` exists
    * find the next unmarked test, implement the test, then implement only enough code to make that test pass.
3. If neither file exists
    * create a new `plan.md` with a list of tests to implement for the feature
    * start with the first test in the plan 

Make sure to update the status of tasks in documents as you work on them.
