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

    var sigvalue: [*c]u8 = undefined;
    dbus.dbus_error_init(err);
    const conn = dbus.dbus_bus_get(dbus.DBUS_BUS_SESSION, err);
    if (dbus.dbus_error_is_set(err) != 0) {
        std.debug.print("{s}\n", .{std.mem.span(buf.message)});
        dbus.dbus_error_free(err);
    }

    dbus.dbus_bus_add_match(conn, "type='signal',interface='test.signal.Type'", err);
    dbus.dbus_connection_flush(conn);
    if (dbus.dbus_error_is_set(err) != 0) {
        std.debug.print("Match error {s}\n", .{buf.message});
        return;
    }

    const sigval_ptr: *anyopaque = @ptrCast(&sigvalue);
    while (true) {
        _ = dbus.dbus_connection_read_write(conn, 100);
        const msg = dbus.dbus_connection_pop_message(conn);
        if (msg) |data| {
            if (dbus.dbus_message_is_signal(data, "test.signal.Type", "Test") == 1) {
                if (dbus.dbus_message_iter_init(msg, &args) == 0) {
                    std.debug.print("Message has no arguments!\n", .{});
                } else {
                    dbus.dbus_message_iter_get_basic(&args, sigval_ptr);
                    std.debug.print("Message from dbus: {s}\n", .{sigvalue});
                }
            } else {
                std.debug.print("This is a different message\n", .{});
            }
        }
    }
}
