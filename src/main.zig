const std = @import("std");
const dbus = @cImport({
    @cInclude("dbus/dbus.h");
});

const DBusError = extern struct {
    name: [*c]const u8,
    message: [*c]const u8,
    dummy: isize,
    padding: *opaque {},
};

pub fn main() !void {
    var buf: DBusError = undefined;
    const err: *dbus.DBusError = @ptrCast(&buf);
    var args: dbus.DBusMessageIter = undefined;
    var serial: u32 = 0;

    dbus.dbus_error_init(err);

    const conn = dbus.dbus_bus_get(dbus.DBUS_BUS_SESSION, err);
    if (dbus.dbus_error_is_set(err) != 0) {
        std.debug.print("{s}\n", .{std.mem.span(buf.message)});
        dbus.dbus_error_free(err);
    }

    const message: ?*dbus.DBusMessage = dbus.dbus_message_new_signal("/test/signal/Object", "test.signal.Type", "Test");

    if (message) |_| {} else {
        std.debug.print("Error could not create message {?}\n", .{message});
        return;
    }

    var sigvalue: [*:0]const u8 = "This is a message";
    const items: ?*anyopaque = @ptrCast(&sigvalue);

    dbus.dbus_message_iter_init_append(message, &args);
    if (dbus.dbus_message_iter_append_basic(&args, dbus.DBUS_TYPE_STRING, items) == 0) {
        std.debug.print("Error cannot append data to message\n", .{});
        return;
    }
    if (dbus.dbus_connection_send(conn, message, &serial) == 0) {
        std.debug.print("Error sending message to dbus\n", .{});
        return;
    }

    dbus.dbus_connection_flush(conn);
    dbus.dbus_message_unref(message);
}
