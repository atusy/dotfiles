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
3. If `plan.md` exists, do following
    * ensure plan follows Follow Kent Beck's Test-Driven Development (`tdd` skill) and Tidy First (`tidying` skill) methodologies
    * find the next unmarked test, use `tdd` skill to implement it, update `plan.md`
4. If neither file exists, do following
    * create a new `plan.md` with a list of tests to implement for the feature
    * start with the first test in the plan 

Make sure to update the status of tasks in documents as you work on
