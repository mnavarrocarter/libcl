//! A RUT is a number that uniquely identifies an individual or a company
//! in Chile. They are used pretty much anywhere you or a company need to
//! do anything legal.
const std = @import("std");

pub const RutError = error{
    // Rut numeric part is too big or too small to fit the specified digits
    DigitLengthOutOfBounds,
};

// Represents an standard RUT.
//
// The standard is to have a maximum of 8 digits and a minimum of 7 in their
// numeric part.
pub const Standard = Constrained(8, 7);

// Creates Rut type which digit length is constrained to max and min
pub fn Constrained(comptime max: u8, comptime min: u8) type {
    if (min > max) {
        @compileError("Max digits must be greater than min digits");
    }

    if (max > 10) {
        @compileError("Ruts can only have a maximum length of 10, since its be max digits that can fit in a u32");
    }

    const max_separators = if (max > 3) (max - 1) / 3 else 0;

    return struct {
        pub const Self = @This();

        // The number of this Rut
        num: u32,

        // Creates a new Rut directly from the number
        pub fn new(num: u32) RutError!Self {
            const d = countDigits(num);
            if (d > max or d < min) {
                return error.DigitLengthOutOfBounds;
            }

            return .{ .num = num };
        }

        pub fn parse(_: []const u8) !Self {
            @panic("Not Implemented");
        }

        pub fn format(
            self: Self,
            comptime fmt: []const u8,
            _: std.fmt.FormatOptions,
            writer: anytype,
        ) !void {
            // Number format can be done using normal print
            if (std.mem.eql(u8, fmt, "n")) {
                try writer.print("{d}", .{self.num});
                return;
            }

            // Simple format can also be done using normal print
            if (std.mem.eql(u8, fmt, "s")) {
                try writer.print("{d}-{c}", .{ self.num, computeVerifier(self.num) });
                return;
            }

            // Human format is a bit more complex
            // Create buffer of digit length + separators + dash + verifier digit
            var buffer: [max + max_separators + 2]u8 = undefined;
            var i = buffer.len;

            buffer[i - 1] = computeVerifier(self.num);
            buffer[i - 2] = '-';
            i -= 2;

            // Process number
            var n = self.num;
            var count: usize = 0;
            while (n > 0 or count == 0) {
                if (count > 0 and count % 3 == 0) {
                    buffer[i - 1] = '.';
                    i -= 1;
                }
                buffer[i - 1] = @intCast('0' + n % 10); // Don't understand this line
                n /= 10;
                i -= 1;
                count += 1;
            }

            try writer.writeAll(buffer[i..]);
        }
    };
}

// Computes the verifier digit for a given RUT number
pub fn computeVerifier(num: u32) u8 {
    var n = num;
    var x: usize = 2;
    var s: usize = 0;

    while (n > 0) {
        if (x > 7) {
            x = 2;
        }

        s += (n % 10) * x;
        x += 1;
        n /= 10;
    }

    return switch (11 - (s % 11)) {
        1 => '1',
        2 => '2',
        3 => '3',
        4 => '4',
        5 => '5',
        6 => '6',
        7 => '7',
        8 => '8',
        9 => '9',
        10 => 'K',
        11 => '0',
        else => unreachable,
    };
}

fn countDigits(num: u32) u8 {
    var n = num;
    var count: u8 = 0;
    while (n > 0) {
        count += 1;
        n /= 10;
    }

    return count;
}

test "computeVerifier" {
    try std.testing.expectEqual('2', computeVerifier(16_894_365));
    try std.testing.expectEqual('2', computeVerifier(24_736_732));
    try std.testing.expectEqual('4', computeVerifier(9_433_316));
}

test "Standard_new" {
    try std.testing.expectEqual(16_894_365, (try Standard.new(16_894_365)).num);

    try std.testing.expectError(error.DigitLengthOutOfBounds, Standard.new(916_894_365));
    try std.testing.expectError(error.DigitLengthOutOfBounds, Standard.new(894_365));
}

test "NonStandard" {
    const NonStandard = Constrained(9, 6);

    try std.testing.expectFmt("116.894.365-9", "{h}", .{try NonStandard.new(116_894_365)});
    try std.testing.expectFmt("894.365-6", "{h}", .{try NonStandard.new(894_365)});
    try std.testing.expectFmt("16.894.365-2", "{h}", .{try NonStandard.new(16_894_365)});
}

test "Standard_format" {
    try std.testing.expectFmt("16.894.365-2", "{h}", .{try Standard.new(16_894_365)});
    try std.testing.expectFmt("16894365-2", "{s}", .{try Standard.new(16_894_365)});
    try std.testing.expectFmt("16894365", "{n}", .{try Standard.new(16_894_365)});

    try std.testing.expectFmt("9.433.316-4", "{h}", .{try Standard.new(9_433_316)});
    try std.testing.expectFmt("9433316-4", "{s}", .{try Standard.new(9_433_316)});
    try std.testing.expectFmt("9433316", "{n}", .{try Standard.new(9_433_316)});
}
