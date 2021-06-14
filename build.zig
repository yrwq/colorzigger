const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();
    const exe = b.addExecutable("czi", "main.zig");

    exe.setBuildMode(mode);
    exe.setTarget(target);
    exe.linkSystemLibrary("X11");
    exe.linkSystemLibrary("c");
    exe.linkLibC();
    exe.install();
}
