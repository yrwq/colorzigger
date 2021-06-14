usingnamespace @cImport({
    @cInclude("X11/cursorfont.h");
    @cInclude("X11/Xutil.h");
    @cInclude("unistd.h");
    @cInclude("stdio.h");
});

const std = @import("std");
const hca = std.heap.c_allocator;
const io = std.io;

//
// Types
//

pub const CpiError = error{DisplayNotFound};

//
// Variables
//

var dpy: *Display = undefined;
var root: Window = undefined;
var buf: std.ArrayList(u8) = undefined;

// 
// Functions
//

pub fn debug(msg: []const u8) void {
    std.io.getStdOut().writer().writeAll(msg) catch {};
}

pub fn main() !void {
    // buffer, where we output the color codes
    buf = std.ArrayList(u8).init(hca);
    defer buf.deinit();

    // Try to open X Display, otherwise exit the program gracefully
    dpy = XOpenDisplay(null) orelse {
        debug("Failed to open X Display\n");
        return CpiError.DisplayNotFound;
    };
    
    // Grab the mouse on the root window
    root = XDefaultRootWindow(dpy);
    var cursor: Cursor = XCreateFontCursor(dpy, 130);
    _ = XGrabPointer(dpy, root, 0, ButtonPressMask, GrabModeAsync, GrabModeAsync, root, cursor, CurrentTime);

    // Get window attrs
    var gwa: XWindowAttributes = undefined;
    _ = XGetWindowAttributes(dpy, root, &gwa);
    _ = XGrabKeyboard(dpy, root, 0, GrabModeAsync, GrabModeAsync, CurrentTime);

    while (true) {
        var e: XEvent = undefined;
        _ = XNextEvent(dpy, &e);
        var image: *XImage = XGetImage(
            dpy,
            root,
            @as(c_int, 0),
            @as(c_int, 0),
            @bitCast(c_uint, gwa.width),
            @bitCast(c_uint, gwa.height),
            (@bitCast(c_ulong, ~@as(c_long, 0))),
            @as(c_int, 2)
        );

        if ((e.type == @as(c_int, 4))
            and (e.xbutton.button == @bitCast(c_uint, @as(c_int, 1)))
            ) {
            var pixel: c_ulong = (((image).*.f.get_pixel).?((image), (e.xbutton.x_root), (e.xbutton.y_root)));

            _ = printf("#%06X\n", pixel);
        }

        if ((e.type == @as(c_int, 4))
            and (e.xbutton.button == @bitCast(c_uint, @as(c_int, 3)))
            ) {
            break;
        }

        _ = (((image).*.f.destroy_image).?((image)));
    }

    _ = XUngrabPointer(dpy, @bitCast(Time, @as(c_long, 0)));
    _ = XUngrabKeyboard(dpy, @bitCast(Time, @as(c_long, 0)));
    _ = XFreeCursor(dpy, cursor);
    _ = XDestroyWindow(dpy, root);
    _ = XCloseDisplay(dpy);
}
