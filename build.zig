const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zig_gpio = b.dependency("zig_gpio", .{
        .target = target,
        .optimize = optimize
    });

    const zig_spidev = b.createModule(.{
       .root_source_file = b.path("src/root.zig"),
       .target = target,
       .optimize = optimize,
    });
    zig_spidev.addImport("gpio", zig_gpio.module("gpio"));

    try b.modules.put(b.dupe("zig_spidev"), zig_spidev);
    try b.modules.put(b.dupe("gpio"), zig_gpio.module("gpio"));
}
