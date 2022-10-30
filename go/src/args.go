package main

import "flag"

type Args struct {
	DebugCpu bool
	DebugApu bool
	DebugGpu bool
	DebugRam bool
	Headless bool
	Silent   bool
	Turbo    bool
	Profile  int
	Rom      string
}

func boolFlagWithShort(long string, short string, default_value bool, help string) *bool {
	var result bool

	flag.BoolVar(&result, long, default_value, help)
	flag.BoolVar(&result, short, default_value, help)

	return &result
}

func NewArgs() *Args {
	var debug_cpu = boolFlagWithShort("debug-cpu", "c", false, "Debug CPU")
	var debug_gpu = boolFlagWithShort("debug-gpu", "g", false, "Debug GPU")
	var debug_apu = boolFlagWithShort("debug-apu", "a", false, "Debug APU")
	var debug_ram = boolFlagWithShort("debug-ram", "r", false, "Debug RAM")
	var headless = boolFlagWithShort("headless", "H", false, "No video")
	var silent = boolFlagWithShort("silent", "S", false, "No audio")
	var turbo = boolFlagWithShort("turbo", "t", false, "No sleep()")

	var profile int
	flag.IntVar(&profile, "profile", 0, "Exit after N frames")
	flag.IntVar(&profile, "p", 0, "Exit after N frames")

	flag.Parse()
	var rom = flag.Arg(0)

	return &Args{
		DebugCpu: *debug_cpu,
		DebugGpu: *debug_gpu,
		DebugApu: *debug_apu,
		DebugRam: *debug_ram,
		Headless: *headless,
		Silent:   *silent,
		Turbo:    *turbo,
		Profile:  profile,
		Rom:      rom,
	}
}
