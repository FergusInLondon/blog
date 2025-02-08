+++
title = "First thoughts on Meshtastic"
date = "2025-02-08T00:10:29Z"
description = "Why the Arduino forums are toxic."
+++

Recently I've been playing around with Meshtastic. For the uninitiated, Meshtastic is a "_An open source, off-grid, decentralized, mesh network built to run on affordable, low-power devices_". Or, simply put, it's a mesh network that allows unlicensed users to operate cheap hardware and send peer-to-peer messages via radio.

I first heard about Meshtastic about a year ago, and immediately purchased some hardware to "give it a go" - sadly though, life got in the way and it was soon forgotten... until this week, when I dusted off the two Heltec V3 devices that I purchased and did some experimenting.

### 1. The technology is pretty cool.

Before talking about Meshtastic, we need to talk about LoRa: a radio technology that aims to achieve **Lo**ng **Ra**nge communications using the unlicensed ISM bands. It's primarily aimed at sensors and small devices which are likely to be remotely operated and powered via battery, and as a result it's power consumption is pretty impressive.

LoRa itself describes the _physical layer_ of the network communications. It outlines the mechanics behind data _transmission_ - i.e. how data should be modulated and how errors should be detected. Due to the availability of LoRa hardware it's become quite common to see hobbyist projects building upon it too, with transciever modules being available for less than £10.

Meshtastic defines quite a simple protocol on top of LoRa that defines a set of message types[^1] for transmission between devices; these message types are the building blocks that allow mesh networks to form, with functionality such as chat channels and private messaging. Meshtastic also provides inbuilt support for encryption, in the form of AES256-CTR with a configurable key[^2].

### 2. The technology is both cool _and simple_.

One thing that is striking when reading the documentation for Meshtastic is that it works on some pretty simple principles. Consider the [Mesh Algorithm](https://meshtastic.org/docs/overview/mesh-algo/) - in one document you can understand how messages are _represented_ between nodes, and how messages _travel_ between nodes.

Simplicity often incurs a performance cost though, and that's true of Meshtastic. At it's core, it relies upon messages being flooded across the mesh - with each node rebroadcasting every message that it sees. There's some traffic management in the form of (a) a limit to the number of retransmissions (or "hops") that can occur, and (b) a pause before retransmission occurs.

Whilst this mechanism is pretty easy to understand, it does lead to some pretty big drawbacks: for example - if I'm in a location with a large number of nodes, then my range may actually be limited by the number of "hops" being nearby retransmissions.

### 3. Long distance chat is difficult.

Whilst it's certainly a characteristic of radio, but perhaps one compounded by the simplicity of the algorithm, there is one major frustration I've faced so far: I'm constantly missing half the conversation.

There's (what appears to be) quite an active net approximately ~30km away, with one node using a Yagi antenna (i.e. with a directional radiation pattern). As a result transmissions from this node are completely inconsistent with it's local peers, and they're blasting out random messages that make no sense.[^3]

It's difficult to feel particularly annoyed at that particular node though: they're likely doing a great job in amplifying smaller nodes in their mesh and contributing to the overall health of the network... _but still_.

### 4. It's ripe for experimentation

An active community, readily available hardware, easily digestible technology, and some minor frustrations like the one above? They're all great ingredients for experimentation! 

- If you're in to electronics then the meshtastic firmware provides easy support for integrating projects via [GPIO](https://meshtastic.org/docs/configuration/module/remote-hardware/).
- Enjoy writing code? The codebase is [surprisingly nice](https://github.com/meshtastic/firmware/blob/master/src/mesh/MeshModule.cpp) (and has a [complete test suite too!](https://github.com/meshtastic/meshTestic/tree/dcac7e5673005f4d8a2b1f0f6e06877b689d7519)), and there's even [a range of APIs](https://meshtastic.org/docs/development/device/).
- For those who prefer networking then there's different node [roles](https://meshtastic.org/docs/configuration/radio/device/) such as `REPEATER` and `ROUTER`, which when combined with a [decent antenna](https://meshtastic.org/docs/hardware/antennas/) could allow you to configure a PtP link between different mesh nets.

Personally I've learnt more about propagation and antenna placement over the last week than I did when I was studying for my amatuer radio license. Similarly, I've thought more about network design and topologies than I have when designing secure PtP links at work!

### 5. The community is active, and adoption seems high.

Any new technology that aims to facilitate communication is immediately trapped in a catch-22 predicament: (a) to incentivise adoption there must be other users, but (b) for other users to exist they must be willing to adopt the new technology. What's the incentive for an early adopter to purchase and configure a radio device that allows them to transmit messages to no one else?

Although there's a vibrant community of users on [/r/meshtastic](https://www.reddit.com/r/meshtastic/) - it's still difficult to gauge local adoption... _unless you have a map_, and fortunately there are "mesh maps" available online! The two largest ones appear to be [meshmap.net](https://meshmap.net/) and [this one by Liam Cottle](https://meshtastic.liamcottle.net/). These maps are built using the telemetry data sent from the nodes themselves.[^4]

I was pleasantly surprised to see quite a few nodes within range when I initially booted my device up... and although I wouldn't describe the default channel as "lively", there are certainly messages exchanged on a daily basis.



---

[^1]: These messages are available on Github in protobuf format - [meshtastic/protobufs](https://github.com/meshtastic/protobufs).

[^2]: This presents an interesting dilemma for those holding an amatuer radio license: in some (most?) regions a condition of your license is not to transmit encrypted communications. Meshtastic actually provides a "licensed" mode which essentially isolates the user from communicating with unlicensed nodes, and prevents the retransmission of encrypted messages... neither of which are great for either the user _or_ the network. 

[^3]: This may well be exasperated by the hop limits impacting the retransmission of messages originating from that mesh.

[^4]: Location telemetry is optional, and there are different levels of granularity that you can set - meaning you can randomise your location to within a specific distance of your "true" location.


