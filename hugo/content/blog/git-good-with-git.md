---
title: "You should probably learn how Git works."
date: 2018-07-17T13:12:00Z
categories:
  - development
tags:
  - git
  - learning
---

Imagine a carpenter who couldn't use a chisel, or a plumber who didn't understand piping. A pretty ludicrous thought, right? After all, those are key parts of the job. In a rather familiar story though, Software Development breaks the norms.. Strap yourselves in, this could be a long one.

One of *the most vital* tools in a Developer's toolkit is source control, and in much (most?) of the industry this means **Git**. Created by Linus Torvalds out of urgency as the Linux kernel was relying upon a proprietary solution, Git has become an industry standard - with the likes of Github, Bitbucket, and Gitlab all providing solutions for teams and individuals alike.

As a technology it's *easy* to deploy - as a home user I've even deployed a personal server to a Raspberry Pi! It's also incredibly easy to dive in to too: learn how to `git init`, `git add`, `git push`, `git merge`, and `git checkout`.. and you're pretty much done. Sure, over time you may even use the likes of `git tag` or `git cherry-pick`, or even fight with the odd *git conflict*.. but you can google that, right?

What if I was to say that out of the 10 chapters of the [Git Book (Pro Git)](https://git-scm.com/book/en/v2), all of these examples were simply Chapter 2 - "*Git Basics*" - and that you've likely never even scratched the surface of how to actually use Git?

When people are initially introduced to Git, they're often a bit apprehensive: after all, they're trusting the entirety of their work with this unknown piece of software. If Git fails, then they can lose painstaking hours of work: that's pretty terrifying.

Slowly they learn the basics, the commands I've listed above, and they feel confident.. and then they understand the daily tasks relating to *their workflow*, and continue blissfully on their way. Most will usually pick a nice GUI client too, further distancing themselves from the lower level details.

Before you know it, they're commiting merge conflicts (Yup, I've seen it done by "Senior" developers.), breaking builds and team environments by incorrectly merging things (Yup, I've seen it.), and having regular existential crises over whether or not their work still exists...! (Yup, been there.)

Clearly there's a bit more than the basics to know.

## Beyond the basics.

It's easy to get complacent, and simply "*know enough to get by*": after all, why should you care about the things you don't need to use? Unfortunately though, there's a good chance you're missing some very useful functionality, not to mention - when things go wrong.. you'll wish you understood a bit more of the stuff "you don't need to use".

Whilst I'm not suggesting reading the entire Git Book (just kidding - I totally am.), having a firm grasp of how a commit actually works - and what the HEAD and Index are - will go *a long way* to understanding other commands such as [`git reset`](https://git-scm.com/book/en/v2/Git-Tools-Reset-Demystified) and [`git stash`](https://git-scm.com/book/en/v2/Git-Tools-Stashing-and-Cleaning). It's safe to say that these are two commands you *will* need to use later on.

In particular, there are two times when having a solid understanding of Git is advantageous; (1) when things go bad, and (2) when you need to get things done.

### Help! Where's my work gone?!

This is arguably the most common way for people to uncover some of Git's advance features, notably the [`reflog`](https://www.atlassian.com/git/tutorials/rewriting-history/git-reflog). Being the safe and trustworthy solution that Git is, it tries *very hard* not to lose your precious work, and thus maintains an internal list of all actions and their relevant changes.

Viewing this list of changes is as simplistic as running `git reflog`; and will - 99 times out of 100 - allow you to find anything that you think you've "lost". Sure, you can delete reflog entries... but if you've got enough storage space, why on earth would you?!

Once you've found the entry in the reflog, it's as simple as copying the commit hash and either doing a `git cherry-pick [hash]`, or a `git checkout [hash]`, and voila - you have your "lost" work.

The exceptions to this are (a) `git reset --hard [hash]`, and (b) `git checkout [hash] [filepath]`, which are both destructive to the working directory... but we knew that from our basic understanding of the differences between the *HEAD*, *Index*, and "*Working Directory*".. right? 

### Getting stuff done; The Git Way.

You'll be glad to know that it's not only in times of peril that knowledge of Git can prove advantageous though; when used effectively, Git is capable of radically improving your workflow.

#### Git Bisect

I have a personal favourite here, and it's: [`git bisect`](https://git-scm.com/docs/git-bisect), which can be an incredible timesaver when troubleshooting a large repository.

Upon encountering a bug, you can use `git bisect` to specify a known good commit, and Git will cycle through various intermediate commits allowing you to tag them as either good or bad. It chooses these commits using a binary search algorithm, providing the most effective mechanism to find the exact commit where an issue was introduced.

A workflow for utilising `git bisect` when troubleshooting a bug could look something like this:

```
$ git bisect            # begin a git bisect
$ git bisect bad        # mark the latest revision as buggy
$ git bisect good v1.3  # specify a known good revision
 ...
$ git bisect [good|bad] # test with the bisect selected commit, tag as good or bad
 ...
$ git bisect reset      # upon finding the problematic commit, reset
$ git show [commit]     # view the diff for the commit 
```

Using this method you can view exactly what introduced the bug, place a few breakpoints in with your favourite IDE, and debug away.. safe in the knowledge that you know exactly where - *and when* - the bug was introduced.

Obviously this relies upon a clean git history, and mammoth commits spanning hundreds of lines are.. well, not very helpful. This is why smaller commits are generally better than rebasing on *larger* projects, and Git's biggest secret - [`git rerere`](https://git-scm.com/book/en/v2/Git-Tools-Rerere) - can be an awesome tool for avoiding conflicts whilst also avoiding merge commits. 

#### Git Hooks

You'll be glad to know that Git's functionality provides help for more than just bugfixing though; and utilising [Git Hooks](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks) can be one of the biggest tools for both policy enforcement (i.e checking commit messages, or running code quality tools) and general automation. (i.e calling a CDN API to clear cache upon push, or triggering a CI task)

Located in the `.git/hooks` directory, they can be written in any scripting language that's available on the host machine - i.e bash, python, ruby, or even javascript. As such it's possible to perform nearly any task, and reject/accept a commit based upon any criteria. Common uses include running tests or generating code quality metrics.

An often overlooked feature - in part because SaaS solutions like Github or Bitbucket don't provide it - is the ability to have server side hooks; hooks that run after a developer attempts to push code to a remote server. Whilst a developer may disable hooks on their own machine, they are powerless when the hook is located on the remote one!

I maintain 4 sites which are powered by Dokku - a self-hosted PaaS solution that's powered by Git - and one of my favourite uses of hooks is to trigger a cache clearance with Cloudflare upon a new deployment. This automated script took under 10 minutes to write, yet automates what was quite a convulated task - involving two factor authentication, password managers and more. Another example is utilising the [Jenkins API](https://wiki.jenkins.io/display/JENKINS/Remote+access+API) and triggering a CI build, potentially itself triggering tests, deployments or docker builds.

### Git submodules

Ever stumbled across a repository that has an external library simply copied in; losing it's git history, *and* losing the ability to keep track of upstream changes? This is where [`git submodule`](https://git-scm.com/book/en/v2/Git-Tools-Submodules) can come to the rescue.

Using a submodule you can keep a repository within a repository; which sounds quite simple, but unfortunately submodules can be surprisingly difficult to get your head around at first; and can often confuse developers who haven't had prior exposure to them. That's why they should, in reality, be avoided where possible.

When you *need* to utilise a submodule though, they can be prove to be invaluable - providing the ability to treat the encapsulated repository as simply another file, allowing you to pin specific revisions and/or branches.

If you're using Github - or your encapsulated repository is hosted on Github - and the repository originates from a third party, then submodules can be especially powerful when combined with forks. By forking the third party repository, you can make changes (and provide them upstream via a Pull Request), [synchronise with the original repository](https://help.github.com/articles/syncing-a-fork/), and specify which revisions you'd like in your parent repository.

## So you want to learn more?

Honestly, I can't fault [Pro Git](https://www.amazon.co.uk/Pro-Git-Scott-Chacon/dp/1484200772) - it's £35 to purchase, but is [available freely](https://git-scm.com/book/en/v2) in electronic form from the official Git website: that's how good it is.

I don't think *every developer* needs to know everything contained in the book, but for Senior roles an understanding of everything mentioned *in this post* - in addition to the likes of `git revert`, `git grep`, branch management and workflows - is essential. Whilst for Tech Lead positions and above, I'd recommend the book in it's entirety - including the "*Git Internals*" chapter.

I've worked for multinationals and had to sit on emergency conference calls - lead by an apparent Tech Lead based in another country - because they've hit a Git stumbling block and have blocked a deployment. Similarly, I've worked in controlled environments where development work has ground to a halt for hours, due to an erroneous merge that has found it's way to a production branch. Both of these issues cost a lot of money, and both should've been resolved within seconds using one command.

Knowing how to use your tools - and how your tools actually work - is crucial to the effective running of any team, and it's rare to find a tool that a development team is more reliant on than it's source control software.
