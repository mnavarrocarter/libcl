Zig LibCL
=========

Contains utilities to work with different things related to Chile.

## RUT

This library provides support for working with Chilean RUTs.

You can parse Ruts in various string forms very easily:

```zig
const std = @import("std");
const cl = @import("libcl");

testing "it_creates_rut" {
    try std.testing.expectEqual(16_894_365, (try cl.id.rut.Standard.parse("16.894.365-2")).num);
    try std.testing.expectEqual(9_433_316, (try cl.id.rut.Standard.parse("9433316-4")).num);
    try std.testing.expectEqual(9_433_316, (try cl.id.rut.Standard.parse("94333164")).num);
}
```

Creating a new RUT from the raw number and formatting it is simple enough too:

```zig
const std = @import("std");
const cl = @import("libcl");

testing "it_creates_rut" {
    const rut = try cl.rut.Standard.new(16_894_365);
    
    // "h" stands for human format
    try std.testing.expectFmt("16.894.365-2", "{h}", .{rut});
    // "s" stands for simple format
    try std.testing.expectFmt("16894365-2", "{s}", .{rut});
    // "n" stands for numeric format
    try std.testing.expectFmt("16894365", "{n}", .{rut});
    // A blank format specifier prints the human format
    try std.testing.expectFmt("16894365", "{}", .{rut});
}
```

A Standard Rut is a comptime generated type that only supports 8 or 7 digits,
which is the range in which all RUTs live. This means that creating a 
Rut that is too big or too small can fail:

```zig
const std = @import("std");
const cl = @import("libcl");

testing "it_fails_to_create_rut" {
    // This fails because number has 9 digits
    try std.testing.expectError(error.DigitLengthOutOfBounds, cl.id.rut.Standard.new(916_894_365));
    
    // This fails because number has 6 digits
    try std.testing.expectError(error.DigitLengthOutOfBounds, cl.id.rut.Standard.new(894_365));
}
```

If you need to support more or less digits for some strange reason, you can
create your own type.

```zig
const std = @import("std");
const cl = @import("libcl");

testing "it_creates_non_standard" {
    // This type now accepts Ruts between 9 and 6 digits
    const NonStandard = cl.id.rut.Constrained(9, 6);
    
    // It works with 9 digits now
    try std.testing.expectFmt("116.894.365-9", "{h}", .{try NonStandard.new(116_894_365)});
    // It works with 6 now too
    try std.testing.expectFmt("894.365-6", "{h}", .{try NonStandard.new(894_365)});
    // It keeps working for anything in between
    try std.testing.expectFmt("16.894.365-2", "{h}", .{try NonStandard.new(16_894_365)});
}
```