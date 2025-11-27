const std = @import("std");
const math = std.math;
const assert = std.debug.assert;
const max_64 = math.maxInt(u64);
const max_128 = math.maxInt(u128);

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

inline fn compute_m_u32(d: u32) u64 {
    return (max_64 / @as(u64, d)) + 1;
}

inline fn compute_m_u64(d: u64) u128 {
    return (max_128 / @as(u128, d)) + 1;
}

// ==================== u32 ====================

pub const PrecomputedDivU32 = packed struct {
    m: u64,

    pub inline fn init(d: u32) PrecomputedDivU32 {
        assert(d > 1);
        return PrecomputedDivU32{ .m = compute_m_u32(d) };
    }

    ///  a / d
    pub inline fn div(self: PrecomputedDivU32, a: u32) u32 {
        return @intCast(mul128_u32(self.m, a));
    }

    ///  a % d
    pub inline fn mod(self: PrecomputedDivU32, a: u32, d: u32) u32 {
        const lowbits: u64 = self.m *% @as(u64, a);
        return @intCast(mul128_u32(lowbits, d));
    }

    pub inline fn isMultiple(self: PrecomputedDivU32, a: u32) bool {
        return (@as(u64, a) *% self.m) <= (self.m - 1);
    }
};

// ==================== u64 ====================

pub const PrecomputedDivU64 = packed struct {
    m: u128,

    pub inline fn init(d: u64) PrecomputedDivU64 {
        assert(d > 1);
        return PrecomputedDivU64{ .m = compute_m_u64(d) };
    }

    ///  a / d
    pub inline fn div(self: PrecomputedDivU64, a: u64) u64 {
        return mul128_u64(self.m, a);
    }

    ///  a % d
    pub inline fn mod(self: PrecomputedDivU64, a: u64, d: u64) u64 {
        const lowbits: u128 = self.m *% @as(u128, a);
        return mul128_u64(lowbits, d);
    }

    pub inline fn isMultiple(self: PrecomputedDivU64, a: u64) bool {
        return (@as(u128, a) *% self.m) <= (self.m - 1);
    }
};

test "fastdiv u32 example" {
    const d: u32 = 3;
    const pre = PrecomputedDivU32.init(d);

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
        const p = PrecomputedDivU32.init(j);

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
        const p = PrecomputedDivU64.init(j);

        var i: u64 = 0;
        while (i < n) : (i += 1) {
            try std.testing.expectEqual(i % j, p.mod(i, j));
            try std.testing.expectEqual(i / j, p.div(i));
            try std.testing.expectEqual(i % j == 0, p.isMultiple(i));
        }
    }
}
