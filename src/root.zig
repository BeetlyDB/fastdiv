const std = @import("std");
const math = std.math;
const assert = std.debug.assert;
const max_64 = math.maxInt(u64);
const max_128 = math.maxInt(u128);

pub fn FastDiv(comptime T: type) type {
    const W = @typeInfo(T).int.bits;

    const MType = switch (W) {
        32 => u64,
        64 => u128,
        else => @compileError("FastDiv supports only u32 and u64"),
    };

    return struct {
        m: MType,

        pub inline fn init(d: T) @This() {
            assert(d > 1);
            const max = switch (W) {
                32 => max_64,
                64 => max_128,
                else => unreachable,
            };
            const mval = (max / @as(MType, d)) + 1;
            return .{
                .m = mval,
            };
        }

        pub inline fn div(self: @This(), a: T) T {
            return switch (W) {
                32 => @intCast(mul128_u32(self.m, a)),
                64 => mul128_u64(self.m, a),
                else => unreachable,
            };
        }

        pub inline fn mod(self: @This(), a: T, d: T) T {
            const lowbits = self.m *% @as(MType, a);
            return switch (W) {
                32 => @intCast(mul128_u32(lowbits, d)),
                64 => mul128_u64(lowbits, d),
                else => unreachable,
            };
        }

        pub inline fn isMultiple(self: @This(), a: T) bool {
            return (@as(MType, a) *% self.m) <= (self.m - 1);
        }
    };
}

/// Multiplying a 64-bit number by a 32-bit number, obtaining the upper 64 bits of the result (128 bits in total)
inline fn mul128_u32(lowbits: u64, d: u32) u64 {
    const prod: u128 = @as(u128, lowbits) * @as(u128, d);
    return @truncate(prod >> 64);
}

/// Multiplying a 128-bit number by a 64-bit number to obtain the upper 64 bits of the result (192 bits in total)
inline fn mul128_u64(lowbits: u128, d: u64) u64 {
    //  lowbits (64 bits) * d
    var bottom: u128 = (lowbits & 0xFFFFFFFFFFFFFFFF) * @as(u128, d);
    bottom >>= 64;
    const top: u128 = (lowbits >> 64) * @as(u128, d);
    const sum: u128 = bottom + top;
    return @truncate(sum >> 64);
}

test "fastdiv u32 example" {
    const d: u32 = 3;
    const pre = FastDiv(u32).init(d);

    const n1: u32 = 4;
    const n2: u32 = 9;

    try std.testing.expectEqual(n1 / d, pre.div(n1));
    try std.testing.expectEqual(n2 / d, pre.div(n2));

    try std.testing.expectEqual(n1 % d, pre.mod(n1, d));
    try std.testing.expectEqual(n2 % d, pre.mod(n2, d));

    try std.testing.expectEqual(n1 % d == 0, pre.isMultiple(n1));
    try std.testing.expectEqual(n2 % d == 0, pre.isMultiple(n2));
}

test "exhaustive u32" {
    const n: u32 = 1000;
    var j: u32 = 2;
    while (j < n) : (j += 1) {
        const p = FastDiv(u32).init(j);

        var i: u32 = 0;
        while (i < n) : (i += 1) {
            try std.testing.expectEqual(i % j, p.mod(i, j));
            try std.testing.expectEqual(i / j, p.div(i));
            try std.testing.expectEqual(i % j == 0, p.isMultiple(i));
        }
    }
}

test "exhaustive u64" {
    const n: u64 = 1000;
    var j: u64 = 2;
    while (j < n) : (j += 1) {
        const p = FastDiv(u64).init(j);

        var i: u64 = 0;
        while (i < n) : (i += 1) {
            try std.testing.expectEqual(i % j, p.mod(i, j));
            try std.testing.expectEqual(i / j, p.div(i));
            try std.testing.expectEqual(i % j == 0, p.isMultiple(i));
        }
    }
}
