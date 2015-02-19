#!/usr/bin/env ruby

ALWAYS_PRINT_STDOUT=false
ALWAYS_ECHO_CMDLINE=false
EXCEPTION_ON_NONZERO_STATUS=false

require 'open3'
require 'io/wait'

module BashLike
  def `(cmdline)
    p(cmdline, true)
  end

  def p(cmdline, print_each_line=ALWAYS_PRINT_STDOUT)
    $stdout.puts "+ #{cmdline}" if ALWAYS_ECHO_CMDLINE
    Open3.popen3(cmdline)  { |stdin, stdout, stderr, wait_thr|
    all_out = ''
    all_err = ''
    while wait_thr.alive?
      if !(stderr.ready? || stdout.ready?)
        sleep(0.1)
        next
      end
      current_out = stdout.read(stdout.nread)
      current_err = stderr.read(stderr.nread)
      all_out = all_out + current_out
      all_err = all_err + current_err
      $stdout.puts current_out if (print_each_line && !current_out.empty?)
      $stderr.puts current_err if !current_err.empty?
    end
    status = wait_thr.value
    # do it once more to catch everything that was buffered
    current_out = stdout.read()
    current_err = stderr.read()
    all_out = all_out + current_out
    all_err = all_err + current_err
    $stdout.puts current_out if (print_each_line && !current_out.empty?)
    $stderr.puts current_err if !current_err.empty?
    $out = all_out
    $err = all_err
    $exit = status.exitstatus
    raise StandardError.new("ERROR: #{cmdline.split()[0]} -> exit status #{status.exitstatus}") if (status.exitstatus != 0 && EXCEPTION_ON_NONZERO_STATUS)
    all_out
    }
  end
end

include BashLike
# BASHINGTHEBASH END - write your things down there
