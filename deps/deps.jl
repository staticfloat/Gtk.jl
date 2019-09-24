using Libdl

const glib = dlpath(dlopen("libglib-2.0"))
const gobject = dlpath(dlopen("libgobject-2.0"))
const gtk = dlpath(dlopen("libgtk-quartz-2.0"))
const gdk = dlpath(dlopen("libgdk-quartz-2.0"))
const gdk_pixbuf = dlpath(dlopen("libgdk_pixbuf-2.0"))
const gio = dlpath(dlopen("libgio-2.0"))
