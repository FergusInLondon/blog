---
title: "When \"Design Patterns\" become \"Anti-patterns\""
date: 2017-04-07T12:18:00Z
categories:
  - development
tags:
  - design
  - learning
---

As a software engineer, learning about design patterns was a kind of "*Eureka*" moment. It was the moment where I finally began to look at architectural issues, and how to structure a piece of software.

I began to think of software as more of a mechanical system, one where different entities and objects could be thought of as cogs, each interacting with eachother to perform a larger task - i.e "*Object Composition*".

With this in mind, I can appreciate how some developers begin to see design patterns as a bit of a "crutch" - rigid structures that have to be adhered too. Alas, this is *oh so wrong*.

### The "*Cargo Cult*" of "Design Pattern Evangelism"

Technology can be a fickle industry, whereby today's "*tried and tested*" is often tomorrow's "*tired and rested*". An industry where techniques and technologies are often picked upon the basis of social media consensus, as opposted to actual technical merit.

This leads to a peculiar herd mentality, one where there's often more weight placed upon developer preference than the actual needs of solving a given domain problem or requirement.

For instance; consider the humble [Singleton](https://en.wikipedia.org/wiki/Singleton_pattern) pattern - a simple concept that can be pivotal in certain scenarios. Alas, due to the negative connotations associated with it - it's often dismissed, if it even gets suggested to begin with! Yet for many use cases it just *makes sense*.

Similarly, I've seen scenarios where the adoption of [CQRS](https://en.wikipedia.org/wiki/Command%E2%80%93query_separation) has arguably been an *acceptable* solution, but it's actually resulted in entirely unmaintanable abominations - all due to attempts at ahering to the strictest definition of it. Yet it needn't have been that way, and with a few simple modifications - whilst keeping the *principles* of the pattern in mind - the quality of the end result would've been far superior, and the complexity (and thus maintanability) would've been reduced heavily.

It doesn't have to be this way, and it really shouldn't be.

### Design Patterns are about language

The primary advantage that comes with the usage of Design Patterns is the resulting common language that can be used to describe architectural decisions. This actively facilitates the communication of abstract - and often complex - ideas. Consider the following two examples, each discussing a simple desktop application complete with UI, and decide which is more concise:

> **Example One (using design pattern terminology)**
> 
> "*The architecture relies upon an Observer pattern implementation, whereby the Subject maintains the state of the application, emiting updates upon changes, whilst the UI components act as Observers - rendering based upon those changes.*"
> 
>
> **Example Two (without design pattern terminology)**
> 
> "*The architecture relies upon a central object which contains (a) the state, and (b) a registry of other objects which need to be updated upon state changes. Upon a state change, the central object will iterate through it's registry, interacting with each other object. These other objects - which are often UI components - expose a method that the central object can call, allowing the central object to push state changes.*"
>

Both of these descriptions provide enough detail for a developer to either (a) sit down and begin working on a feature, or (b) understand an existing feature and begin a maintenance task. The difference between the two descriptions is the language used, and the conciseness used to express the core idea.

Note how neither description prescribes enough detail for a developer to get bogged down in minor implementation details; it doesn't dictate any minutia, and still allows developer freedom. That's the real beauty of basing a solution on an existing design pattern.

## Going further

This post has not been an argument against design patterns, quite the contrary in fact! When communicating with others, the vernacular that design patterns provide is incredibly useful, and so is the ability to identify scenarios where suitable patterns already exist.

For an aspiring developer, or one who has only recently embarked on their journey, there are few books I could recommend as much as both [Head First: Design Patterns](https://www.amazon.co.uk/Design-Patterns-Available-Freeman-Paperback/dp/B017QQL9DW/ref=sr_1_3?s=books&ie=UTF8&qid=1523143613&sr=1-3&keywords=head+first+design+patterns), followed by the obvious ["Gang of Four"](https://www.amazon.co.uk/Design-Patterns-Object-Oriented-Addison-Wesley-Professional-ebook/dp/B000SEIBB8) book. Combined with [Clean Code](https://www.amazon.co.uk/Clean-Code-Handbook-Software-Craftsmanship/dp/0132350882/ref=sr_1_7?s=books&ie=UTF8&qid=1523143613&sr=1-7&keywords=head+first+design+patterns), and [Beautiful Code](https://www.amazon.co.uk/Beautiful-Code-Leading-Programmers-Practice/dp/0596510047/ref=sr_1_1?s=books&ie=UTF8&qid=1523143779&sr=1-1&keywords=beautiful+code), these are the technical books that I feel gave me the firmest foundation for my career.

Alas, once you've learnt some cool new techniques, it's very easy to overuse them - applying them where it's either inappropriate, or just plain incorrect!

Ultimately, this post aims to be more of a warning: if you find yourself fighting against the constraints of a given pattern, or ruminating on specific definitions, then you're likely chasing an incorrect approach. Design Patterns are architectural ideas, and like most ideas, they exist not to dictate; they exist to be challenged, adapted, and improved.
