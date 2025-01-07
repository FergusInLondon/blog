---
title: "Developing for Linux on the Desktop: dbus"
date: 2017-11-04T19:30:00+00:00
categories:
  - development
tags:
  - linux
  - dbus
---

I've previously written about how I feel Linux is a great OS for developers: it's insanely configurable, it's easy to customise, there are distributions to suit whichever level of stability you require, and the community around it is thriving. But what about developing _for_ Linux, as opposed to _on_ Linux?

Although language choice isn't much of an issue, there's clearly a lot more than the language that goes in to developing a working application. After all, one of the most important factors when choosing a language is it's ecosystem - the libraries and frameworks around it. With that in mind, let's look at Linux as an ecosystem for desktop development, and the tools and services available for budding developers!

One of the first things that new users to Linux will notice is "*it's all a bit fragmented*"; with several mainstream desktop environments, and a multitude of services competing for the similar responsibilities - how's a developer meant to integrate with the underlying system?

## Enter DBus - The Linux "*Desktop Bus*"

Originating from RedHat in the early 2000s, DBus provides an interprocess communications bus - allowing various desktop applications to work in conjunction with eachother. When you get a desktop notification? That's via DBus. Adjusting your network settings via your desktop environment's control panel? DBus.

Architecturally DBus is simple: different applications and services "register" with the bus, and expose interactions that are then callable to other bus users.

![Processes_with_D-Bus.svg-1](/content/images/2017/11/Processes_with_D-Bus.svg-1.png)

Unfortunately - as simple as that sounds - there's actually a little more complexity at work when using DBus - and you need to be familiar with the standard terminology. The good news is that the terminology is most likely very familiar, and if you're used to Object Oriented Programming then this wont be very difficult to grasp.

1. An application must have a unique identifier, or a **Name**.
2. An application can export one or more **Objects**.
3. An **Object** will adhere to one or more **Interfaces**.
4. **Interfaces** describe **Methods**, **Properties** and **Signals**.
5. **Methods** can be called on an **Object** via an **Interface**.
6. **Properties** can be read and/or written via an **Interface**.
7. **Signals** can be emitted via an **Interface**, and sent to applications which are registered to listen.

Here's a diagram explaining this visually:

![bus-hierarchy-conceptual-1](/content/images/2017/11/bus-hierarchy-conceptual-1.png)

Still not helping? Let's work through 3 examples - one whereby we use dbus to query information from another service, one whereby we use dbus to act upon updates from another service, and a final example where we actively open up our own functionality to other services.

These examples use Python and Golang, the choices aren't meant to signify anything. DBus has [bindings for most languages](https://www.freedesktop.org/wiki/Software/DBusBindings/), I'm just trying to make an active effort to write examples in my blog posts in different languages at the moment! Python seems to be a good choice as it's syntax is the closest to psuedocode in my mind, so the easiest to parse mentally and illustrate a point with.

### An example: The Chat Application

Let's pretend that you're developing a chat application, and being the caring developer that you are, you don't want to bother users with notifications when they're busy watching a video in full screen mode; after all, that's just annoying! You're also rather nostalgic and pine for the days of MSN Messenger where you could share information about what you were watching or listening too.

Using DBus you could take advantage of something known as the [Media Player Remote Interfacing Specification](https://specifications.freedesktop.org/mpris-spec/latest/index.html) - or MPRIS - which opens up a very comprehensive way of interfacing with Media Players.

Here's an example of this functionality, written in Python using [pydbus](https://github.com/LEW21/pydbus):

```python
from pydbus import SessionBus

class MediaPlayer:
    """Recieves state from a MediaPlayer using dbus."""

    player_properties = False

    def __init__(self, player_name):
        # Get an instance of the dbus session bus, and retrieve
        #  a proxy object for accessing the MediaPlayer
        bus = SessionBus()
        player = bus.get(
            'org.mpris.MediaPlayer2.%s' % player_name,
            '/org/mpris/MediaPlayer2'
        )

        # Apply the interface 'org.freedesktop.DBus.Properties to
        #  the player proxy, allowing us to call .Get() and .GetAll()
        self.player_properties = player['org.freedesktop.DBus.Properties']

    """
        Retrieve the properties from the Player interface, return a
         song string.
    """
    def song_string(self):
        props = self.player_properties.GetAll('org.mpris.MediaPlayer2.Player')
        return "%s - %s (%s)" % (
            props["Metadata"]["xesam:artist"][0],
            props["Metadata"]["xesam:title"],
            props["Metadata"]["xesam:album"]
        )

    """
        Retrieve properties from the MediaPlayer2 interface, return
         whether a screen is maximised or not.
    """
    def is_fullscreen(self):
        props = self.player_properties.GetAll('org.mpris.MediaPlayer2')
        return bool(props["Fullscreen"])


player = MediaPlayer('vlc')
print("Status: %s" % ("Do Not Disturb" if player.is_fullscreen() else "Available"))
print("Playing: %s" % (player.song_string()))
```

This code is all thats required to (a) connect to the DBus Session Bus (i.e a specific bus for the current active user), and (b) query a media player for it's state. It's simple, but it's functional and capable of retrieving all manner of information - including but not limited to volume, album art, playlists, track information and more.

Ideally we would maintain a list of compatible media players (i.e Spotify, VLC, Rhythmbox..) and iterate through it, reducing the coupling between our application and the underlying player; however for our example this is good enough!

That said, there's still a bit of a problem...


#### Retrieving real time updates via Signals
Upon releasing your new chat application, your users are filled with joy at the nostalgia of having - often embarassing - musical insights displayed to their friends! There's a pretty big problem though: the users are complaining that the song information never changes, and that it makes them appear to have an obsession with one particular song.

Although you could poll for changes regularly - and on a short enough interval it would *work* - it still wouldn't be very efficient. Fortunately, MPRIS provides *Signals* that allow clients to recieve updates when properties are changed. If we look at [MediaPlayer2.Player's properties](https://specifications.freedesktop.org/mpris-spec/latest/Player_Interface.html#properties), we can see that it implements an Interface named `org.freedesktop.DBus.Properties`.

The [`DBus.Properties`](https://dbus.freedesktop.org/doc/dbus-specification.html#standard-interfaces-properties) Interface is - like other `DBus.*` Interfaces - *very common*, and it also provides a Signal named `PropertiesChanged (STRING interface_name,DICT<STRING,VARIANT> changed_properties,ARRAY<STRING> invalidated_properties);`. This is the Signal we'll listen for below:

```python
from gi.repository import GLib
from pydbus import SessionBus

class MediaPlayer:
    """Recieves state from a MediaPlayer using dbus."""

    is_playing_fullscreen = False

    song_string = ""

    player_properties = False

    def __init__(self, player_name):
        # Get an instance of the dbus session bus, setting the GLib main
        #  loop, and retrieve a proxy object for accessing the media player.
        bus = SessionBus()
        player = bus.get(
            'org.mpris.MediaPlayer2.%s' % player_name,
            '/org/mpris/MediaPlayer2'
        )

        # Apply the interface 'org.freedesktop.DBus.Properties to
        #  the player proxy, allowing us to call .Get() and .GetAll()
        self.player_properties = player['org.freedesktop.DBus.Properties']

        # Retrieve our MediaPlayer properties, and our MediaPlayer.Player
        #  ones too. See Example (1) - this is essentially the same.
        self.parse_mediaplayer_properties()
        self.parse_player_properties()

        # Set the signal listener, and listen for the "PropertiesChanged"
        #  signal.
        self.player_properties.onPropertiesChanged = self.on_dbus_update

        # Run GLib Loop, allowing us to wait for the above signal, and run
        #  a demonstration function (print_state()) every 2 seconds.
        GLib.timeout_add(2000, self.print_state) # Example.
        GLib.MainLoop().run()


    """
        Generates a song string - "artist - song title (album name)" from
         information taken via the 'MediaPlayer2.Player' Interface.
    """
    def parse_player_properties(self):
        props = self.player_properties.GetAll('org.mpris.MediaPlayer2.Player')
        self.song_string = "%s - %s (%s)" % (
            props["Metadata"]["xesam:artist"][0],
            props["Metadata"]["xesam:title"],
            props["Metadata"]["xesam:album"]
        )


    """
        Simple method that queries the 'MediaPlayer2' Interface, and retrieves
         all available properties, before casting "Fullscreen" to a native py
         boolean.
    """
    def parse_mediaplayer_properties(self):
        props = self.player_properties.GetAll('org.mpris.MediaPlayer2')
        self.is_playing_fullscreen = bool(props["Fullscreen"])


    """
        This is called automatically upon a DBus "PropertiesChanged" signal
         being triggered from the '.DBus.Properties' interface. This method
         has a signature that matches the parameters of the Signal it listens
         for.

        Note: We should parse the properties out of 'changed_properties' - but
         we're lazy when writing examples.
    """
    def on_dbus_update(self, interface_name, changed_properties, invalidated_properties):
        # Look up the correct method for the interface with the new properties
        action = {
            "org.mpris.MediaPlayer2.Player" : self.parse_player_properties,
            "org.mpris.MediaPlayer2" : self.parse_mediaplayer_properties
        }.get(interface_name, False)

        # If we have a valid action, then call it.
        if action: action()

    """
        For example purposes: it would be a bit rubbish if our example wasn't
         capable of demonstrating it was working!
    """
    def print_state(self): # Example.
        print("Status: %s" % ("Do Not Disturb" if self.is_playing_fullscreen else "Available"))
        print("Playing: %s" % self.song_string)
        return True # Required to keep GLib.timeout_add() running.

player = MediaPlayer('vlc')
```

Don't be alarmed at the presence of `GLib` in this example; we need GLib to provide an event loop for our application. Without this event loop we wouldn't be able to wait for, and respond to, input from the Signals we've attached too. Similarly, you can ignore the line prepended with `# Example.` and the `print_state()` method: these are here purely in case you want to run the example yourself and see the output in your terminal.

The Python library - pydbus - is clever enough to know that when we assign a callable object to a property beginning with `on`, that we're actually setting a signal handler. This means that this line... 

    self.player_properties.onPropertiesChanged = self.on_dbus_update

...is actually where all of our magic happens.

If you think back to the signature of the `PropertiesChanged()` Signal, you'll remember that the first parameter contains the interface that the Signal originates from. This is how we determine which properties we need to retrieve again:

    def on_dbus_update(self, interface_name, changed_properties, invalidated_properties):
        action = {
            "org.mpris.MediaPlayer2.Player" : self.parse_player_properties,
            "org.mpris.MediaPlayer2" : self.parse_mediaplayer_properties
        }.get(interface_name, False)

In a real world scenario, this would be quite a poor solution - as Signal provides a `key:value` object containing the new properties. For the sake of simplicity though, our example manually requests the properties again. 



Up until now though, we've only looked at being a *client* on DBus - i.e interacting with objects exposed by other applications and services - what if we wanted to export our own object?

## An example of listening: Email Dispatch
Everyone likes to be aware of what's happening on the systems that they maintain; visibility provides a layer of awareness on things like system stability and security. Everyone also has an email account and loves getting new emails... *right?*

With these two facts in mind, you've decided to build a simple little service that runs in the background of a Linux machine. This services exposes a method (via DBus) that allows applications to dispatch an email notification to a pre-configured email address; that is to say that given a message title and a message body, your service will provide a simple mechanism for dispatching an email to the sysadmin.

Here we're using Golang to export a small object that allows a client to call a method named `DispatchEmail(string title, string message)`:

```go

package main

import (
	"fmt"

	"github.com/godbus/dbus"
	"github.com/godbus/dbus/introspect"
)

/* XML String to be used with DBus' Introspection Interface. */
const introspectString = `<node>
	<interface name="london.fergus.email.dispatch">
		<method name="DispatchEmail">
			<arg name="title" direction="in" type="s"/>
			<arg name="message" direction="in" type="s"/>
		</method>
	</interface>` + introspect.IntrospectDataString + `</node> `

/* Our Object to be Exported, complete with method: DispatchEmail() */
type emailDispatch struct {
	EmailAddress string
}

func (ed *emailDispatch) DispatchEmail(title, message string) *dbus.Error {
    /* This is where we would send our email, we're really just echoing
       it back to the user for our demonstration. */
	fmt.Printf("Email Dispatched to %s:\n\nTitle: %s\n%s\n\n", ed.EmailAddress, title, message)
	return nil
}

func main() {
    // Get a connection to our SessionBus
	dbusConn, err := dbus.SessionBus()
	if err != nil {
		panic(err)
	}

	// Request our unique name, panic if it's not available or upon any
	//  other error
	reply, err := dbusConn.RequestName("london.fergus.email.dispatch",
		dbus.NameFlagDoNotQueue)
	if err != nil {
		panic(err)
	}

	if reply != dbus.RequestNameReplyPrimaryOwner {
		panic("DBus Object Name Unavailable!")
	}

	// Create an instance of our emailDispatch object.
	dispatcher := &emailDispatch{EmailAddress: "sysadmin@example.com"}

    // Export our EmailDispatch object, and our Introspection Interface
	dbusConn.Export(dispatcher, "/london/fergus/email/dispatch", "london.fergus.email.dispatch")
	dbusConn.Export(introspect.Introspectable(introspectString), "/london/fergus/email/dispatch",
		"org.freedesktop.DBus.Introspectable")

    // Await Connections
	select {}

	fmt.Println("Exported EmailDispatch object to DBus, awaiting connections...")
}
```

In this example we can see how [godbus](https://github.com/godbus/dbus) - the dbus bindings for Golang - makes it very simple to export an object for client applications to interact with.

It's worth noting that I also enable the [org.freedesktop.DBus.Introspectable](https://dbus.freedesktop.org/doc/dbus-specification.html#standard-interfaces-introspectable) interface - allowing clients to query what methods, properties and signals the exported object possesses. This isn't essential, but it's a good practice if you expect other developers to use your service.

## Conclusion

If you're looking at developing desktop applications for the Linux environment, then understanding DBus can not only make your life a lot easier - but it can also open up a lot of new opportunities for interfacing with everything from media players, networking interfaces, system services and hardware peripherals.

Hopefully you now know not only what DBus is, but you can understand its terminology and the scenarios in which it can be useful. I'd definitely recommend a read of [DBus Overview](https://pythonhosted.org/txdbus/dbus_overview.html), and if you're looking at implementing a service which provides a D-Bus interface - then the [DBus API Design Guidelines](https://dbus.freedesktop.org/doc/dbus-api-design.html).

