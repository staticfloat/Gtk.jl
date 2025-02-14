##Julia interface to `Gtk+ 2` and `Gtk+ 3` GUI library
Gui building, using the Gtk library: [http://www.gtk.org/](http://www.gtk.org/)
<br>
Complete Gtk documentation is available at [https://developer.gnome.org/gtk/stable](https://developer.gnome.org/gtk/stable)

## Installation

Prior to using this library, you must install a semi-recent version of `libgtk` on your computer. While this interface currently defaults to using `Gtk+-3`, it can be configured by editing `Gtk/deps/ext.jl` and changing the integer valued `gtk_version` variable to `2`.

### Windows

The necessary libraries will be downloaded and installed automatically when you run `Pkg.add("Gtk")`.


In case you run into some problem with the automatic installation, you can install manually 
using `WinRPM.jl`:

     Pkg.add("WinRPM")
     using WinRPM
     WinRPM.install(["gtk2","gtk3",
          "hicolor-icon-theme",
          "tango-icon-theme",
          "glib2-tools",
          "glib2-devel",
          "gnome-icon-theme",
          "gnome-icon-theme-extras",
          "gnome-icon-theme-symbolic",
          "gtk3-devel",
          "gtk2-devel",
          "gtk3-tools",
          "gtk2-tools",
          "pango-tools",
          "gdk-pixbuf-query-loaders",
          "gtk2-lang"
          "gtk3-lang"])
     RPMbindir = Pkg.dir("WinRPM","deps","usr","$(Sys.ARCH)-w64-mingw32","sys-root","mingw","bin")
     ENV["PATH"]=ENV["PATH"]*";"*RPMbindir

You may need to repeat the last two steps every time you restart julia, or put these two lines in your `$HOME/.juliarc.jl` file

### OS X

I use MacPorts:

1. `port install gtk2 +quartz gtk3 +quartz` (this may require that you first remove Cairo and Pango via `sudo port deactivate active` for example, I like to put this in my `/opt/local/etc/macports/variants.conf` file as `+quartz` before installing anything, to minimize conflicts and maximize usage of the native Quartz)
2. `push!(DL_LOAD_PATH,"/opt/local/lib")` You will need to repeat this step every time you restart julia, or put this line in your `~/.juliarc.jl` file.

If you want to use Homebrew, the built-in formula is deficient (it does not support the Quartz backend). See [Homebrew#27](https://github.com/JuliaLang/Homebrew.jl/issues/27) for possible eventual workarounds.

### Linux

Try any of the following lines until something is successful:

     aptitude install libgtk2.0-0 libgtk-3-0
     apt-get install libgtk2.0-0 libgtk-3-0
     yum install gtk2 gtk3
     pkg install gtk2 gtk3

On some distributions you can also install a `devhelp` package to have a local copy of the Gtk documentation.

## Precompilation

Startup time for packages that use Gtk can be dramatically reduced by precompiling Gtk.
For this to work, you need to be building Julia from source, and you need to be using
at least Julia version 0.3.

In your Julia `base/` directory, create (or append to) a file called `userimg.jl` the line

    require("Gtk")

Then build Julia as you normally would; the Gtk module will be available when julia starts.

In some cases, it might be necessary to add the path to the folder containing the Gtk shared libraries, for example:

    push!(DL_LOAD_PATH, "/usr/lib/x86_64-linux_gnu")
    require("Gtk")
    pop!(DL_LOAD_PATH)

The `"/usr/lib/x86_64-linux_gnu"` needs to be replaced with the location of the GTK libraries on your system.
However, when the library is in a standard location -- such as `/usr/lib`, `/usr/local/lib`, or `/usr/lib/x86_64-linux_gnu` (on some systems) -- this step can be skipped.

## Overview

This Gtk wrapper attempts to expose all of the power of the Gtk library in a simple, uniform interface. The structure and names employed should be easily familiar to anyone browsing the Gtk documentation or example code, or anyone who has prior experience with Gtk.

It is always safe to alter the properties of a Gtk object defined in Gtk.jl outside of calling the functions provided therein, such as through another program language, or direct ccall's.

There is also a more detailed description in [tutorial style](doc/usage.md), as well as a [property/hierarchy browser](doc/properties.md) and [function reference](doc/function_reference.md).
People interested in extending the functionality of this package may be interested in the [developer documentation](doc/developer.md).

### Referring to Gtk.Objects

Gtk object can be referenced by their Gtk names (which almost always have a name like `GtkWindow`), or their "short name" (which is generally just the Gtk name without the "Gtk", for example, `Window`). You can call `using Gtk` to import the regular names, or `using Gtk.ShortNames` to import the shorter names. You can also call `import Gtk`, and then access either the regular or short names (e.g. `Gtk.Window` or `Gtk.GtkWindow`).

The concrete types are the Gtk object name with a suffix of `Leaf` appended (to remind the user that this is a "leaf" in the Julia type-tree). For example, to refer to the concrete `GtkWindow` type, the user would write `Gtk.GtkWindowLeaf`.

### Constructing a Gtk.@Object

Gtk object constructors (by convention), are the name of the Gtk object (interface) name, with a suffix of `Leaf` appended. For example, to construct a new window, the user would invoke `Gtk.WindowLeaf()`.

Alternatively, the user can use the macro form of the widget name to construct a new `GObject`, as shown in the example below.

All object constructors accept keyword arguments to set object properties. These arguments are forwarded to the corresponding `setproperty!` method (see below).

    w = @GtkWindow(title="Hello World")

### Objects are containers for their [child_elements...]

All objects in Gtk are intended to behave uniformly. This means that all objects will try to act as container objects for whatever they 'contain'. Indexing into an object (by number), or iterating the object will return a list of its contents or child objects. This also means that constructors are called with information on the elements that they contain. For example, when you create a button, you can specify either the embedded text or another widget!

    Gtk.@Button("This is a button")
    Gtk.@Button(Gtk.@Label("Click me"))

On the flip side, you can assign child widgets to indices, or `push!` them onto the list of child widgets, for any object which derives from a `GtkContainer`. Of special note is the anti-object `GtkNullContainer` or simply `Null`. This is not actually a `GObject`. However, it can be used to prevent the creation of a default container, and it has the special behavior that it will remove any object added to it from its existing parent (although standard operations like `splice!` and `delete!` also exist, and are typically preferable for readability).

The optimal pattern for creating objects generally depends upon the usage. However, you may find the following pattern useful for creating layout hierarchies:

    w=Gtk.@Window() |>
        (f=Gtk.@Box(:h) |>
            (b=Gtk.@Button("1")) |>
            (c=Gtk.@Button("2")) |>
            (f2=Gtk.@Box(:v) |>
                Gtk.@Label("3") |>
                Gtk.@Label("4"))) |>
        showall

### Objects have getproperty(obj, :prop, types) and setproperty!(obj, :prop, value)

     > warning: this API uses 0-based indexing

The properties of any object can be accessed by via the `getproperty` and `setproperty!` methods. Displaying a `GtkObject` at the REPL-prompt will show you all of the properties that can be set on the object. Or you can view the [Gtk documentation](https://developer.gnome.org/gtk3/stable/GtkWidget.html) online. Indexing is typically done using a symbol, but you can also use a string. In property names, you can replace `-` with `_` as shown below.

When retrieving a property, you must specify the output type. Specifying the input type when setting a property is strictly optional.

Some Examples:

    w = @GtkWindow("Title")
    show(STDOUT, w) # without the STDOUT parameter, show(w) would
                    # make the window visible on the screen, instead
                    # of printing the information in the REPL
    getproperty(w,:title,String)
    setproperty!(w,:title,"New title")
    setproperty!(w,:urgency_hint,Bool,true)

### Objects can signal events

There are two entry points to the API for handling signals: Simple and robust OR fast and precise.

You can remove signal handlers by their id using `signal_handler_disconnect` or temporarily block them by id using `signal_handler_block` and `signal_handler_unblock`

#### Easy Event Handlers

Upon entry to the signal handler, Julia will unpack the arguments it received into native types:

    id = signal_connect(widget, :event) do obj, args...
        println("That tickles: $args")
        nothing
    end

See section on [Extending Gtk's Functionality with new GValue<->Julia auto-conversions](#new-gvalue-julia-auto-conversions) at the end of this document for details on the auto-unpacking implementation.

#### Fast Event Handlers

If you want pre-optimized event handlers, you will need to specify the interface types when creating the signal handlers. (There are a few `on_signal_` convenience functions which do this, often in conjunction with setting other flags needed for the signal handler to function). You will often find it necessary to refer to the Gtk documentation for the signals API for Gtk callbacks:

- Gtk+ 2
  -  [Gtk2 Object Closures](https://developer.gnome.org/gtk2/stable/GObject.html#GObject-destroy)
  -  [Gtk2 Widget Closures](https://developer.gnome.org/gtk2/stable/GtkWidget.html#GtkWidget-accel-closures-changed)
- Gtk+ 3
  -  [Gtk3 Widget Closures](https://developer.gnome.org/gtk3/stable/GtkWidget.html#GtkWidget-accel-closures-changed)

Note that the ArgType argument only specifies the type for the middle arguments. The type of the first and last arguments are determined automatically.

Example:

    function on_signal_event(ptr, args, widget)
        println("That tickles")
        nothing
    end
    id = signal_connect(widget, :event, Void, (ArgType,))
    ## OR
    id = signal_connect(widget, :event, Void, (ArgType,)) do ptr, args, obj
        println("That tickles")
        nothing
    end

### Events can be emitted

In addition to listening for events, you can trigger your own:

    #syntax: signal_emit(w::GObject, sig::Union(String,Symbol), RT::Type, args...)
    signal_emit(widget, :event, Void, 42)

Note: the return type and argument types do not need to match the spec. However, the length of the args list MUST exactly match the length of the ArgType's list.

### Objects have get and set accessor methods

    > warning: this API has not been completely finalized
    > warning: this API uses 0-based indexing
    > note: this API will likely be exposed in a later version as ``Window[:title] = "My Title"``, ``Window[:title,String]``

``Gtk._`` (not exported), ``Gtk.G_`` (exported by `Gtk.ShortNames`), and ``Gtk.GAccessor`` (exported by Gtk) all refer to the same module: a collection of auto-generated method stubs for calling get/set methods on the `GObject`'s. The difference between a get and set method is based upon the number of arguments.

Example usage:

    bytestring(Gtk._.title(WindowLeaf("my title")))
    G_.title(WindowLeaf("my title"), "my new title")
    GAccessor.size(WindowLeaf("what size?"))

Note that because these are auto-generated, you will often need to do your own gc-management at the interface. For example, the string returned by title must not be freed or modified. Since the code auto-generator cannot know this, it simply returns the raw pointer.


### Constants

Interaction with Gtk sometimes requires constants, which are bundled into the `Gtk.GConstants` module.
`GConstants` in turn contains modules corresponding to each Gtk `enum` type.
For example, constants corresponding to the [GdkEventMask](https://developer.gnome.org/gdk3/stable/gdk3-Events.html#GdkEventMask)
are in `Gtk.GConstants.GdkEventMask`. Each constant can be referred to by its full Gtk name or by a shortened name,
for example `GDK_KEY_PRESS_MASK` can also be used as `KEY_PRESS`. The rule for generating the shortened name is that
any prefix common to the entire `enum` is stripped off, as well as any trailing `_MASK` if that ending is common to
all elements in the enum.

## Gtk Object Tree

    +- Any
    .  +- AbstractArray = AbstractArray{GValue,1}
    .  .  +- MatrixStrided = MatrixStrided{T}
    .  .  +- Ranges = Ranges{T}
    .  .  .  +- GtkTextRange
    .  +- GError
    .  +- GObject
    .  .  +- GObjectLeaf{Name}
    .  .  +- GdkPixbuf
    .  .  +- GtkStatusIcon
    .  .  +- GtkTextBuffer
    .  .  +- GtkTextMark
    .  .  +- GtkTextTag
    .  .  +- GtkWidget
    .  .  .  +- GtkCanvas
    .  .  .  +- GtkComboBoxText
    .  .  .  +- GtkContainer
    .  .  .  .  +- GtkBin
    .  .  .  .  .  +- GtkAlignment
    .  .  .  .  .  +- GtkAspectFrame
    .  .  .  .  .  +- GtkButton
    .  .  .  .  .  +- GtkCheckButton
    .  .  .  .  .  +- GtkExpander
    .  .  .  .  .  +- GtkFrame
    .  .  .  .  .  +- GtkLinkButton
    .  .  .  .  .  +- GtkRadioButton
    .  .  .  .  .  +- GtkToggleButton
    .  .  .  .  .  +- GtkVolumeButton
    .  .  .  .  .  +- GtkWindow
    .  .  .  .  .  .  +- GtkDialog
    .  .  .  .  .  .  .  +- GtkFileChooserDialog
    .  .  .  .  +- GtkBox
    .  .  .  .  .  +- GtkButtonBox
    .  .  .  .  .  +- GtkStatusbar
    .  .  .  .  +- GtkGrid
    .  .  .  .  +- GtkLayout
    .  .  .  .  +- GtkNotebook
    .  .  .  .  +- GtkNullContainer
    .  .  .  .  +- GtkOverlay
    .  .  .  .  +- GtkPaned
    .  .  .  .  +- GtkRadioButtonGroup
    .  .  .  .  +- GtkTable
    .  .  .  +- GtkEntry
    .  .  .  +- GtkImage
    .  .  .  +- GtkLabel
    .  .  .  +- GtkProgressBar
    .  .  .  +- GtkScale
    .  .  .  +- GtkSpinButton
    .  .  .  +- GtkSpinner
    .  .  .  +- GtkSwitch
    .  .  .  +- GtkTextView
    .  +- GParamSpec
    .  +- GSList{T}
    .  +- GValue
    .  +- GdkEvent
    .  .  +- GdkEventAny
    .  .  +- GdkEventButton
    .  .  +- GdkEventCrossing
    .  .  +- GdkEventKey
    .  .  +- GdkEventMotion
    .  .  +- GdkEventScroll
    .  +- GdkPoint
    .  +- GdkRectangle
    .  +- GtkTextIter
    .  +- MouseHandler
    .  +- RGB
    .  +- RGBA

