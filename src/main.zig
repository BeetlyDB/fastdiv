const std = @import("std");
const fastdiv = @import("fastdiv");
//NOTE: use fastdiv only for runtime divisions

pub fn main() !void {
    try benchu32();
    try benchu64();
}

fn benchu32() !void {
    const trials = 1_000_000_000;
    const divisor: u32 = @intCast(std.crypto.random.int(u32));
    const pre = fastdiv.PrecomputedDivU32.init(divisor);

    var a: u32 = 123456789;

    // ————————— default —————————
    var timer1 = try std.time.Timer.start();
    var sum1: u64 = 0;
    for (0..trials) |_| {
        sum1 +%= a / divisor;
        a = @addWithOverflow(a, 1)[0];
    }
    const elapsed_native = timer1.read();

    // ————————— fastdiv —————————
    a = 123456789;
    var timer2 = try std.time.Timer.start();
    var sum2: u64 = 0;
    for (0..trials) |_| {
        sum2 +%= pre.div(a);
        a = @addWithOverflow(a, 1)[0];
    }
    const elapsed_fast = timer2.read();

    try std.testing.expect(sum1 == sum2);

    const faster_by = @as(f64, @floatFromInt(elapsed_native)) / @as(f64, @floatFromInt(elapsed_fast));

    std.debug.print("\nu32 division benchmark ({d} iterations)\n", .{trials});
    std.debug.print("  default /  : {d: >8} ns  ({d} cyc/op approx)\n", .{
        elapsed_native / trials,
        elapsed_native / trials * 3,
    });
    std.debug.print("  fastdiv    : {d: >8} ns  ({d} cyc/op approx)\n", .{
        elapsed_fast / trials,
        elapsed_fast / trials * 3,
    });
    std.debug.print("  → fastdiv faster in {d:.2} \n\n", .{faster_by});
}

fn benchu64() !void {
    const trials = 500_000_000;
    const divisor: u32 = @intCast(std.crypto.random.int(u32));

    const pre = fastdiv.PrecomputedDivU64.init(divisor);

    var a: u64 = 9876543210123;

    var timer1 = try std.time.Timer.start();
    var sum1: u64 = 0;
    for (0..trials) |_| {
        sum1 +%= a / divisor;
        a +%= 1;
    }
    const elapsed_native = timer1.read();

    a = 9876543210123;
    var timer2 = try std.time.Timer.start();
    var sum2: u64 = 0;
    for (0..trials) |_| {
        sum2 +%= pre.div(a);
        a +%= 1;
    }
    const elapsed_fast = timer2.read();

    try std.testing.expect(sum1 == sum2);

    const faster_by = @as(f64, @floatFromInt(elapsed_native)) / @as(f64, @floatFromInt(elapsed_fast));

    std.debug.print("u64 division benchmark ({d} iterations)\n", .{trials});
    std.debug.print("  default /  : {d: >8} ns\n", .{elapsed_native / trials});
    std.debug.print("  fastdiv    : {d: >8} ns\n", .{elapsed_fast / trials});
    std.debug.print("  → fastdiv faster in {d:.2} \n", .{faster_by});
}
