# crystal-i8080

**WIP: mostly functional**

This is a simple intrepretive emulator for the [Intel 8080](https://en.wikipedia.org/wiki/Intel_8080) written in [Crystal](https://crystal-lang.org/). It is intended to be used as a core for projects that require an embedded i8080 CPU. I wrote it because 1) I wanted to learn more about Crystal and 2) I wanted to learn about writing emulators.

In addition to the CPU itself, there is a very simple CP/M machine (`I8080::CPMMachine`) that emulates simple CP/M I/O calls. It isn't a fully functional emulator, but it should be enough to test simple CP/M programs, such as diagnostic tests.

I have tested this using my own spec derived from examples in the 8080 Programmer's Manual; this is located at `spec/cpu_spec.cr`. I have also used Ian Bartholomew's 8080/8085 Exerciser, the files of which are courtesy of [begoon/8080ex1](https://github.com/begoon/8080ex1); these are located in `vendor/cpu_diagnostics`.

If you have Crystal installed, you can check the test results yourself by running `crystal spec` from the root directory; just be warned that the 8080/8085 Exerciser spec can take several minutes to complete.

## Installation

1. Add the dependency to your `shard.yml`:

```
dependencies:
  i8080:
    github: jlcrochet/crystal-i8080
```

2. Run `shards install`

## Usage

```crystal
require "i8080"
```

Load a ROM and execute it:

```crystal
cpu = I8080::CPU.new
cpu.load_file("path/to/rom")
cpu.run
```

Disassemble a ROM, printing the instructions to STDOUT:

```crystal
dasm = I8080::Disassembler.new
dasm.load_file("path/to/rom")
dasm.run
# Output:
# 0000: 3E 56     MVI    A,$56
# 0002: CE BE     ACI    $BE
# 0004: CE 42     ACI    $42
# ...
```

Alternatively, you can create a CPU in debug mode, which will use an embedded disassembler to print instructions to STDOUT as they're executed:

```crystal
cpu = I8080::CPU.new(debug: true)
cpu.load_file("path/to/rom")
cpu.step     # => 0000: 31 5C 02  LXI     SP,$025C
cpu.step     # => 0003: 01 FF 03  LXI     B,$03FF
cpu.step     # => 0006: C5        PUSH    B
```

There is also a very barebones CP/M implementation:

```crystal
cpm_machine = I8080::CPMMachine.new
cpm_machine.load_file("path/to/cpm/program")
```

For more details, check the [documentation](https://jlcrochet.github.io/crystal-i8080).
