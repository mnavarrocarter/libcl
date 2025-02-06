const std = @import("std");
const cl = @import("libcl");

pub fn main() !void {
    const rut = cl.id.rut.Standard.new(25_917_936);

    std.debug.print("Rut: {any}\n", .{rut});
}
