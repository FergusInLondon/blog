+++
title = "My testing workflow: mixing TDD and BDD for a unique blend"
date = "2021-06-24T20:52:00-00:00"
+++

A few years ago it felt like automated testing was similar to teenagers discussing sex: whilst there was lots of talk and claims of prowess, in reality very few actually *did it*. In a similar vein, most *are* doing it now: but does that mean they're doing it well?

Well, with the mucky teenage bravado out of the way, lets get down to the gritty: *how do I like my... erhh.. tests?* In this post I'm going to describe how I combine elements of both TDD and BDD to produce a workflow that suits me, and seems to produce good testable solutions without getting in the way of design or obsessing over questionable metrics.

### Unit Tests

The "*bread and butter*" test: small methods that verify specific areas of functionality. Usually structured in such a way as to verify that when `method x is called with parameter y it will return value z`. For example, the following test ensures that specific forms of invalid input trigger specific exceptions:

```
@pytest.mark.parametrize("module, strategy, exception", [
    ('Ehe', 'definitely.not.a.real.module', StrategyNotFound),
    ('InvalidStrategy', 'test.fixtures.invalid_strategy', InvalidStrategyProvided),
])
def test_no_strategy_module_available(module, strategy, exception):
    correct_exception = False
    try:
        load_strategy(module, strategy)
    except exception:
        correct_exception = True
    
    assert correct_exception
```

It's composed of (a) data in, (b) expected data out, and (c) an assertion that the real data out matches that expectation. This specific test makes use of pytest's `parametrize` functionality - some simple syntactic sugar to execute the test on multiple inputs without the need for boilerplate such as table definitions or loops. Other useful features that you'll regularly see in use are `mocks` and `fixtures`.

Unit tests should be small and limited in scope, and the best strategy to achieve this is to ensure that they only test *one layer at a time*; this means that any dependencies are *mocked* and injected in to the component under test.

<p><img style="max-width:100%" src="/code/tdd-layers.png" alt="Layered unit tests"></p>

The usage of mocks can be quite controversial, and some people tend to think that writing tests without mocks is something that is due some kudos or bragging rights - or that it's even the sign of a good design. Whilst this may be true on occasion, it's not a particularly healthy goal to strive towards as the reality is that different components rely upon others, and well designed software usually follows a layered architecture.

Trying to be too clever with your unit tests is a recipe for a brittle test suite where simple changes cause cascading failures. In the past I've certainly looked at "clever tests" and wondered whether they need a test case themselves!

But if unit tests are great at forming the foundation of a good test strategy, and are invaluable for verifying the functionality of specific components, how can we verify that all of these components work together?


### BDD Style Tests (i.e Feature specs written with Gherkin)

By borrowing a tool from Behaviour Driven Development - notable the [Gherkin language](https://cucumber.io/docs/gherkin/) - we can begin to test entire features, and do so *from an external point of view, whilst also generating a useful form of documentation*.

Consider writing tests to verify the functionality of an API; there's often quite a lot of boilerplate to manage things such as making a request, transforming the payload, and performing obtuse assertions upon nested objects. This can make them long, difficult to read, and introduce complexity. Now contrast what I've just described with this:


```
  Scenario: Prevent execution of the scikit model when parameters are cached
    Given the API is ready and responding to requests
     When an valid payload is supplied
      and the cache contains a matching prediction
      and the prediction endpoint is called
     Then the sklearn model is not called
      and the status code is 200
      and the payload contains a matching prediction with the cache
```

Note how it's easy to read and - even if written by a developer - relatively easy to understand regardless of technical abilities. Whilst you could write an equivalent "*traditional*" test, it would likely lack the clarity that's provided by the Gherkin syntax. Although there has to be an underlying implementation behind the individual "*steps*" of this test, these implementations are often very small and easily digestible too.

In addition to this clarity, theres some less obvious advantages to:

- **Test Composition** - the ability to re-use "steps" across different "scenarios" often reduces the work required to implement additional tests: the steps required are often already defined.
- **Abstraction** - the scenario definitions are not tied to the underlying implementation of the system under test, meaning they remain true even if the implementation details change. In larger - or legacy - projects, retrofitting tests written in Gherkin is often more useful than trying to implement granular unit tests that tie in to the current implementation.
- **Production Usage and Integration Testing** - by toggling the implementation behind these steps - i.e. via an environment variable - it becomes possible to target different environments, allowing you to verify functionality on production post-deployment. 

Whilst BDD style tests are very useful when testing components from an external - i.e. client facing - view, there are also times where it makes sense to test individual components in this style too.  For a recent project I found myself building a component that utilised a design similar to the [Actor Model](https://en.wikipedia.org/wiki/Actor_model) - specifically an isolated component that ran in it's own thread, used a queue structure as a messagebox, and maintained it's own internal state.

Testing this proved to be similar to testing an API: the implementation details weren't of great interest, *I wanted to test this component as a "black box"*. I wanted verification of the overall functionality and how various message types were handled, and feature specs were an ideal solution. The result contained definitions like this:

```
  Scenario: Skip order requests rejected by the calculator
    Given a running an actor awaiting messages
      and a request to buy BTC is dispatched
      and the calculator will reject the request
     When all the request is submitted and processed
     Then the API should not recieve any orders
```

## When to write a test?

Personally I've never been a fan of *Test Driven Development* - I've utilised it on codebases I've been responsible for, and also codebases where it's been enforced by others. Both times the benefit of high test coverage has come at a cost - and that cost is often brittle test suites and the evolution of dubious design decisions. As a result, I don't tend to give too much credence to test driven development as a workflow.

My own preference (perhaps controversially!) is to use unit tests sparingly - *and specifically cover functionality that possesses edge cases or relatively complex logic*. Ideal candidates include:

- data transformation functions,
- functions that perform complex calculations,
- and objects responsible for handling business logic.

This isn't to say that there are no test cases that I write before any code; I've got in to the nice habit of writing - you guessed it - Gherkin feature specs. This ensures that whilst the functionality is prescribed up front, the implementation *is not*.

### Exceptions to the rule.

There are two times where it often *is* beneficial to begin with writing unit tests:

- **Handling legacy code** - in addition to writing BDD style tests to capture external functionality, small unit tests can help verify your understanding of particular components, and also help monitor for small side-effects.
- **Regression prevention** - capturing incorrect behaviour with a failing test before carrying out a fix is a good strategy to (a) confirm the validity of your fix, and (b) ensure future regressions do not occur (i.e. they become a regression test).

