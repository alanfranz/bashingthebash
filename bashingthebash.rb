#!/usr/bin/env ruby

ALWAYS_PRINT_STDOUT=false
ALWAYS_ECHO_CMDLINE=false
EXCEPTION_ON_NONZERO_STATUS=false
LOGFILE=nil
LOGFILE_MAX_LINES=1000

require 'open3'
require 'io/wait'

module BashLike
  def `(cmdline)
    puts p(cmdline, true)
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

  def log(message)
    if $global_log.nil? and !LOGFILE.nil?
      # remove the exceeding lines
      if File.exists?(LOGFILE)
        f = File.open(LOGFILE, "r")
        lines = f.readlines()
        retain_from = [lines.size, LOGFILE_MAX_LINES].min
        retain_lines = lines[-retain_from..-1]
        f.close()
      else
        retain_lines=[]
      end
      $global_log = File.open(LOGFILE, "a")
      $global_log.write(retain_lines.join(''))
    end

    final_message = "[#{Time.now.to_s}] #{message}"
    $global_log.puts(final_message) unless $global_log.nil?
    $stdout.puts(final_message)
  end

end

include BashLike
# BASHINGTHEBASH END - write your things down there

