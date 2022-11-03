import std/os

import argparse

type
    Args* = object
        rom*: string
        frames*, profile*: int
        headless*, silent*: bool
        turbo*, debug_cpu*, debug_apu*, debug_gpu*, debug_ram*: bool

proc parseArgs*(args: seq[string]): Args =
    var p = newParser("rosettaboy-nim"):
        flag("-H", "--headless")
        flag("-S", "--silent")
        flag("-c", "--debug-cpu")
        flag("-g", "--debug-gpu")
        flag("-r", "--debug-ram")
        flag("-a", "--debug-apu")
        flag("-t", "--turbo")
        option("-f", "--frames", default = some("0"), help = "Exit after N frames")
        option("-p", "--profile", default = some("0"), help = "Exit after N seconds")
        arg("rom")

    try:
        var opts = p.parse(args)
        return Args(
            rom: opts.rom,
            headless: opts.headless,
            silent: opts.silent,
            debug_cpu: opts.debug_cpu,
            debug_gpu: opts.debug_gpu,
            debug_apu: opts.debug_apu,
            debug_ram: opts.debug_ram,
            frames: parseInt(opts.frames),
            profile: parseInt(opts.profile),
            turbo: opts.turbo,
        )
    except ShortCircuit as e:
        if e.flag == "argparse_help":
            echo p.help
            quit(0)
