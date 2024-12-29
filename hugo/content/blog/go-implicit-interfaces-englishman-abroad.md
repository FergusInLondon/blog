+++
title = "Go: Implicit Interfaces and being an Englishman Abroad"
date = 2018-10-30T09:19:29-04:00
+++

One of the biggest things I struggled with when I began writing Go was how exactly interfaces were meant to work. Although the concept was already very familiar, I couldn't get my head around all the buzz over "*implicit interfaces*". Gee, the compiler basically writes `implements MyIFace` for me... not exactly earth-shattering!

By the time I finished contracting a couple of years later though, I'd be spending most of my time helping revitalise hastily written Go codebases. Many of the problems I came across were solvable via some basic steps: fixing slice usage, using concurrency primitives from the `sync` package, creatively using closures for state capture, and... erh... **using interfaces properly**.

But why?

### 1. An interface is just another Pointer... kinda
Forget everything you thought you knew about interfaces (unless you already know Go, in which case find better ways to spend your time!) and start from the beginning: an interface is - at heart - a humble pointer.

There's a good discussion on the internals [available here](https://github.com/teh-cmc/go-internals/blob/master/chapter2_interfaces/README.md#overview-of-the-datastructures), but the simplest mental model is that an interface is little more than a label with an accompanying pointer to the concrete struct.

**This is why you're very unlikely to come across a pointer to an interface, and if you do - it tends to be a mistake and an artifact of someone wrangling with the compiler!**

### 2. Define interfaces at the point of consumption
Go has a very simple phrase: "*accept interfaces and return structs*" - and this is where the idea of implicit interfaces begin to get fun!

This idiom encourages the practice of *defining small/specific interfaces where they're consumed*, something facilitated by the fact they're implicit. In turn this produces a cleaner architecture without boilerplate or unnecessary layers of abstraction: you return a concrete implementation, and your consumer is free to consume via whatever interface they decide captures their requirements.

This has several benefits, many of which first appear to be quite subjective - but all lead to clean, legibile, and simplistic code.

1. Decoupling from a package by using an interface that's defined in that package is a bit of an anti-pattern: is it even really decoupling[^1]?
2. Declaring smaller interfaces leads to a smaller burden if you do decide to change the underlying implementation later.
3. When writing a consumable package it's often not clear what functionality will actually be required externally, nor whether all consumers will require the same subset of functions.
4. Testing is a breeze when you can incrementally build interfaces over code that you don't necessarily want to modify.

In my own experience there's also another - often overlooked - advantage to declaring interfaces in this way: *it dramatically reduces the cognitive load when trying to maintain context over multiple moving parts*.

All these advantages have led to Go being the only language I've ever really been comfortable embracing TDD in without any overhead[^2].

### 3. Composition: interfaces everywhere! 

One of the cliche "Go for OOPers" comparisons is that composition in Go (i.e. struct embedding) is analogous to inheritance or traits. This rapidly falls apart when we consider interfaces.

It's perfectly acceptable - or encouraged even - to compose interfaces based upon other interfaces; a quick look at the standard library's io package reveals various permutations of Reader, Writer, and Closer interfaces - such as.. erhh... the aptly named `ReadWriteCloser`.

```go
type ReadWriteCloser interface {
    Reader
    Writer
    Closer
}
```

Even more flexibility appears when we embed interfaces inside structs though. Suggesting this can often elicit a groan, accompanied by an exasperated "*we're keeping it simple*": but this is simple.

Leveraging the ability to embed an interface in a struct allows you to reduce wrapper/adapter methods, enhance the granularity of your tests, maintain control over what methods you export, and saves you keystrokes too. Easy!

Despite these advantages though, this is something I rarely - if ever - saw in the wild whilst contracting. Why? Because it would appear to be uncommon other than in Go, and therefore it's rarely part of the thought process for developers new to the language: and that actually leads quite nicely to...

## Don't be an "Englishman abroad"
Go is a practical language: it lends itself to producing testable code with a simple structure; and it achieves this by ditching the mentality of reproducing the index page of a book on Design Patterns! Ye many "new" Go codebases are full of the same abstractions and obfuscations as their legacy counterparts, and are often *less readable than their equivalents as that's not how the language is meant to work*.

I like to think of this as the "Englishman abroad" problem; when an Englishman arrives in a new country they'll often find the nearest English style pub - usually serving English drinks and showing English football - and then they'll finish the evening by hunting down the kind of kebab or chips that they'll find along their local high street at home. And why? "Because that's how I've always had a night out!"

Developers can be similarly stubborn; except the drinks are design patterns, and the food is code structure. When in new surroundings though, the local ways of doing things are often the quickest and most effective.

[^1]: This is why some languages seem to encourage the idea of standardised interfaces being bundled in packages external to both the implementation and the consumer. (i.e. [PHP's PSR-7 for HTTP messages](https://www.php-fig.org/psr/psr-7/))

[^2]: Whilst there are mocking packages for Go - usually taking advantage of `go generate` as opposed to reflection - these are often fiddly and brittle. When interfaces are declared in the idiomatic style outlined in this post, these packages are rarely - if ever - necessary.
