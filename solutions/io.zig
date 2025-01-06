const std = @import("std");

pub const stdout = std.io.getStdOut().writer();
pub const stderr = std.io.getStdErr().writer();

pub const ErrorSet = error{
    AccessDenied,
    InputOutput,
    FileTooBig,
    SystemResources,
    NoSpaceLeft,
    DeviceBusy,
    Unexpected,
    WouldBlock,
    OperationAborted,
    BrokenPipe,
    ConnectionResetByPeer,
    DiskQuota,
    InvalidArgument,
    NotOpenForWriting,
    LockViolation,
};
