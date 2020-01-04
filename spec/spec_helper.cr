require "spec"
require "../src/i8080"

include I8080

def remove_trailing_nops(file)
  data = File.read(file)
    .chomp.bytes
    .reverse.skip_while(&.zero?)
    .reverse

  File.write(file, Bytes.new(data.to_unsafe, data.size))
end
