//! By convention, root.zig is the root source file when making a library.
const gpio = @import("gpio");
pub const std = @import("std");

const posix = std.posix;

pub const spi_ioc_transfer = extern struct {
    tx_buf: u64,
    rx_buf: u64,
    len: u32,
    speed_hz: u32,
    delay_usecs: u16,
    bits_per_word: u8,
    cs_change: u8,
    pad: u32,
};

pub const SPI = struct {
    serial_path: [] u8 = "/dev/spidev0.0",
    baud: u32 = 2_000_000,

    serial_fd: posix.fd_t = undefined,


    // Ioctl request numbers from <linux/spi/spidev.h>
    const SPI_IOC_MAGIC: u8 = 'k';

    fn _IOW(nr: u8, size: usize) u32 {
        return ((1 << 30) | (@as(u32, size) << 16) | (@as(u32, SPI_IOC_MAGIC) << 8) | nr);
    }

    const SPI_IOC_WR_MODE: u32 = _IOW(1, @sizeOf(u8));
    const SPI_IOC_WR_MAX_SPEED_HZ: u32 = _IOW(4, @sizeOf(u32));

    fn SPI_IOC_MESSAGE(n: u32) u32 {
        // _IOW(SPI_IOC_MAGIC, 0, struct spi_ioc_transfer[n])
        return ((1 << 30) | ((@sizeOf(spi_ioc_transfer) * n) << 16) | (@as(u32, SPI_IOC_MAGIC) << 8));
    }

    pub fn init(Self: *SPI) !void {
        Self.serial_fd = try posix.open(Self.serial_path, .{ .ACCMODE = .RDWR }, 0);
        defer std.debug.assert(Self.serial_fd >= 0);

        var mode: u8 = 0;
        if (posix.system.ioctl(Self.serial_fd, SPI_IOC_WR_MODE, @intFromPtr(&mode)) < 0)
            return error.IoctlFailed;

        var speed: u32 = Self.baud;
        if (posix.system.ioctl(Self.serial_fd, SPI_IOC_WR_MAX_SPEED_HZ, @intFromPtr(&speed)) < 0)
            return error.IoctlFailed;
    }

    pub fn spiWriteByte(Self: *SPI, data: u8) !void {
        var buf: [1]u8 = .{data};
        var tr = spi_ioc_transfer{
            .tx_buf = @intFromPtr(&buf[0]),
            .rx_buf = 0,
            .len = 1,
            .speed_hz = Self.baud,
            .delay_usecs = 0,
            .bits_per_word = 8,
            .cs_change = 0,
            .pad = 0,
        };
        if (posix.system.ioctl(Self.serial_fd, @intCast(SPI_IOC_MESSAGE(1)), @intFromPtr(&tr)) < 0)
            return error.IoctlFailed;
    }

    pub fn spiWriteBytes(Self: *SPI, data: []const u8) !void {
        var tr = spi_ioc_transfer{
            .tx_buf = @intFromPtr(data.ptr),
            .rx_buf = 0,
            .len = @as(u32, @intCast(data.len)),
            .speed_hz = Self.baud,
            .delay_usecs = 0,
            .bits_per_word = 8,
            .cs_change = 0,
            .pad = 0,
        };
        if (posix.system.ioctl(Self.serial_fd, @intCast(SPI_IOC_MESSAGE(1)), @intFromPtr(&tr)) < 0)
            return error.IoctlFailed;
    }
};
