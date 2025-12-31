# Refactoring Patterns Catalog

Behavior-preserving transformations organized by category. Based on Martin Fowler's catalog.

## Composing Methods

Patterns for organizing code within methods.

| Pattern | When to Use | Mechanics |
|---------|-------------|-----------|
| **Extract Method** | Code block does one identifiable thing | Move code to new method, replace with call |
| **Inline Method** | Method body is as clear as its name | Replace calls with body, remove method |
| **Extract Variable** | Complex expression repeated or unclear | Assign to descriptive variable |
| **Inline Variable** | Variable adds no clarity | Replace variable with expression |
| **Replace Temp with Query** | Temp holds easily computed value | Extract computation to method |
| **Split Variable** | Variable assigned multiple times for different purposes | Create separate variable for each purpose |

## Moving Features

Patterns for distributing responsibilities between classes.

| Pattern | When to Use | Mechanics |
|---------|-------------|-----------|
| **Move Method** | Method uses more of another class | Move to class it envies, delegate if needed |
| **Move Field** | Field used more by another class | Move field, update all references |
| **Extract Class** | Class has too many responsibilities | Create new class, move relevant fields/methods |
| **Inline Class** | Class does too little | Move all features to another class |
| **Hide Delegate** | Client reaches through object to another | Create delegating methods on server |
| **Remove Middle Man** | Class has too many simple delegations | Let client call delegate directly |

## Organizing Data

Patterns for handling data and primitives.

| Pattern | When to Use | Mechanics |
|---------|-------------|-----------|
| **Replace Magic Number with Constant** | Literal has special meaning | Create named constant |
| **Replace Data Value with Object** | Data item needs behavior (primitive obsession) | Create class for the data |
| **Encapsulate Field** | Public field needs controlled access | Make private, add getter/setter |
| **Encapsulate Collection** | Exposing collection directly | Return copy/unmodifiable, add/remove methods |
| **Replace Type Code with Class** | Type code doesn't affect behavior | Create class for each type |
| **Replace Type Code with Subclasses** | Type code affects behavior | Create subclass for each type |
| **Replace Type Code with State/Strategy** | Type code changes at runtime | Use State or Strategy pattern |

## Simplifying Conditionals

Patterns for making conditional logic clearer.

| Pattern | When to Use | Mechanics |
|---------|-------------|-----------|
| **Decompose Conditional** | Complex condition obscures intent | Extract condition and branches to methods |
| **Consolidate Conditional Expression** | Multiple conditions yield same result | Combine with logical operators, extract |
| **Consolidate Duplicate Conditional Fragments** | Same code in all branches | Move outside conditional |
| **Remove Control Flag** | Variable controlling loop exit | Use break/return instead |
| **Replace Nested Conditional with Guard Clauses** | Deep nesting obscures normal path | Use early returns for special cases |
| **Replace Conditional with Polymorphism** | Conditional based on type | Create subclasses, override method |
| **Introduce Null Object** | Null checks scattered throughout code | Create class representing null case |
| **Introduce Assertion** | Code assumes something about state | Make assumption explicit |

## Simplifying Method Calls

Patterns for cleaner interfaces.

| Pattern | When to Use | Mechanics |
|---------|-------------|-----------|
| **Rename Method** | Name doesn't reveal intent | Choose better name, update all callers |
| **Add Parameter** | Method needs more info from caller | Add parameter, update all callers |
| **Remove Parameter** | Parameter no longer used | Remove from signature and callers |
| **Separate Query from Modifier** | Method returns value AND changes state | Split into two methods |
| **Parameterize Method** | Multiple methods do similar things | Create one method with parameter |
| **Replace Parameter with Explicit Methods** | Method behavior depends on parameter | Create method for each case |
| **Preserve Whole Object** | Passing several values from same object | Pass the object itself |
| **Replace Parameter with Method Call** | Parameter value can be obtained by callee | Have callee compute the value |
| **Introduce Parameter Object** | Parameters travel together frequently | Create class to hold them |
| **Remove Setting Method** | Field should be set at creation only | Initialize in constructor, remove setter |

## Dealing with Generalization

Patterns for organizing inheritance hierarchies.

| Pattern | When to Use | Mechanics |
|---------|-------------|-----------|
| **Pull Up Field** | Subclasses have same field | Move to superclass |
| **Pull Up Method** | Subclasses have identical methods | Move to superclass |
| **Pull Up Constructor Body** | Subclass constructors mostly identical | Create superclass constructor |
| **Push Down Field** | Field only used by some subclasses | Move to those subclasses |
| **Push Down Method** | Method only relevant to some subclasses | Move to those subclasses |
| **Extract Subclass** | Class has features used only sometimes | Create subclass for the features |
| **Extract Superclass** | Classes have common features | Create superclass to hold them |
| **Extract Interface** | Clients use subset of class's interface | Create interface for that subset |
| **Collapse Hierarchy** | Subclass not different enough | Merge into superclass |
| **Replace Inheritance with Delegation** | Subclass uses only part of interface | Hold reference instead, delegate |
| **Replace Delegation with Inheritance** | Many simple delegations to one class | Inherit from delegate |

## Big Refactorings

Long-term structural improvements (use incrementally).

| Pattern | When to Use |
|---------|-------------|
| **Tease Apart Inheritance** | Hierarchy doing two jobs at once |
| **Convert Procedural Design to Objects** | Code using long procedures with shared data |
| **Separate Domain from Presentation** | UI logic mixed with business logic |
| **Extract Hierarchy** | Class doing too much with many conditionals |

## Pattern Selection by Smell

Quick reference for common code smells:

| Smell | Patterns to Consider |
|-------|---------------------|
| **Duplicated Code** | Extract Method, Pull Up Method, Extract Class |
| **Long Method** | Extract Method, Replace Temp with Query, Decompose Conditional |
| **Large Class** | Extract Class, Extract Subclass, Extract Interface |
| **Long Parameter List** | Introduce Parameter Object, Preserve Whole Object |
| **Divergent Change** | Extract Class (one class changed for different reasons) |
| **Shotgun Surgery** | Move Method, Move Field, Inline Class (one change touches many classes) |
| **Feature Envy** | Move Method, Extract Method |
| **Data Clumps** | Extract Class, Introduce Parameter Object |
| **Primitive Obsession** | Replace Data Value with Object, Replace Type Code |
| **Switch Statements** | Replace Conditional with Polymorphism, Replace Type Code |
| **Parallel Inheritance Hierarchies** | Move Method, Move Field |
| **Lazy Class** | Inline Class, Collapse Hierarchy |
| **Speculative Generality** | Collapse Hierarchy, Inline Class, Remove Parameter |
| **Temporary Field** | Extract Class, Introduce Null Object |
| **Message Chains** | Hide Delegate, Extract Method |
| **Middle Man** | Remove Middle Man, Inline Method |
| **Inappropriate Intimacy** | Move Method, Move Field, Extract Class |
| **Alternative Classes with Different Interfaces** | Rename Method, Extract Superclass |
| **Incomplete Library Class** | Introduce Foreign Method, Introduce Local Extension |
| **Data Class** | Move Method, Encapsulate Field, Encapsulate Collection |
| **Refused Bequest** | Push Down Method, Replace Inheritance with Delegation |
| **Comments** | Extract Method, Rename (the code should speak for itself) |
