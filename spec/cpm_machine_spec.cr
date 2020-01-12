require "./spec_helper"

cpu = CPMMachine.new

describe CPMMachine do
  puts "=== 8080PRE ==="

  cpu.load_file "#{__DIR__}/../vendor/cpu_diagnostics/8080PRE.COM"
  cpu.run

  # cpu.reset
  #
  # puts "=== 8080EX1 ==="
  #
  # cpu.load_file "#{__DIR__}/../vendor/cpu_diagnostics/8080EX1.COM"
  # cpu.run
end

