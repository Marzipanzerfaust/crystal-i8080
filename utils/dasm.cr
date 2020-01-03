require "../src/i8080"

include I8080

file_path = ARGV.first

dasm = Disassembler.new
dasm.load_file(file_path)
dasm.run
