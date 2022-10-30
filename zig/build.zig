const std = @import("std");
const Sdk = @import("lib/sdl/Sdk.zig");

pub fn build(b: *std.build.Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});
    const sdk = Sdk.init(b);

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("rosettaboy", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    sdk.link(exe, .dynamic);
    exe.addPackage(sdk.getWrapperPackage("sdl2"));
    exe.install();
    exe.addPackagePath("clap", "lib/clap/clap.zig");

    // TODO: flto, fno-lto
    // exe.want_lto = true; // not supported when targetting macOS!

    {
        const process = std.process;
        var alloc = std.heap.GeneralPurposeAllocator(.{}){};
        // defer alloc.deinit();

        const gpa = alloc.allocator();

        // TODO: accept `-l` in LDFLAGS
        // TODO: map `-iframework` to the below in cflags

        if (process.getEnvVarOwned(gpa, "NIX_CFLAGS_COMPILE")) |cflags| {
            defer gpa.free(cflags);

            var it = std.mem.tokenize(u8, cflags, " ");
            while (true) {
                const word = it.next() orelse break;
                if (std.mem.eql(u8, word, "-iframework")) {
                    const framework_path = it.next() orelse {
                        break;
                    };
                    std.debug.print("{s}\n", .{framework_path});
                    exe.addFrameworkPath(framework_path);
                }
            }
        } else |_| {

        }

    }

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_tests = b.addTest("src/main.zig");
    exe_tests.setTarget(target);
    exe_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);

}
