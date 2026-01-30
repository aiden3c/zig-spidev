const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zig_gpio = b.dependency("zig_gpio", .{
        .target = target,
        .optimize = optimize
    });

    const zig_spi = b.createModule(.{
       .root_source_file = b.path("src/root.zig"),
       .target = target,
       .optimize = optimize,
    });

    zig_spi.addImport("gpio", zig_gpio.module("gpio"));

}
