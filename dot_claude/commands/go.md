---
description: Go on with the next item in the plan
---

Do one of the following based on the project state.

1. If `scrum.yaml` and `plan.md` both exists, ask user for migration preference:
    * continue with `scrum.yaml` process
    * migrate to `plan.md` process starting from next unmarked test
2. If `scrum.yaml` exists, repeatably do following until no more PBIs can be refined:
    * product backlog refinement
    * sprint planning
    * sprint execution with `tdd` skill
    * sprint review
    * sprint retrospective
    * `scrum.yaml` compaction
3. If `plan.md` exists, do
    * find the next unmarked test, implement the test, then implement only enough code to make that test pass.
4. If neither file exists, do
    * create a new `plan.md` with a list of tests to implement for the feature
    * start with the first test in the plan 

Make sure to update the status of tasks in documents as you work on
