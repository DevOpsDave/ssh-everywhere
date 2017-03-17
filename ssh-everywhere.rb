#!/usr/bin/ruby

require 'optparse'
require 'json'

def cmd_line()
  options = {}
  optparse = OptionParser.new do |opts|

    opts.banner = "Usage: #{opts.program_name}"

    opts.on("-s","--session [STRING]","session name") do |s|
      options[:session] = s
    end

    opts.on("-l","--host_list [STRING]","path to host list.") do |s|
      host_list = File.open(s).readlines.map { |line| line.strip }
      options[:host_list] = host_list
    end

    options[:user] = `echo $USER`.chomp
    opts.on('-u', '--user [USER]', 'The user to login as. Default=<current user>') do |s|
      options[:user] = s
    end

    options[:max_panes] = 20
    opts.on("-m","--max_panes [INT]", OptionParser::DecimalInteger, "Max number of panes per session.") do |s|
      options[:max_panes] = s
    end

    opts.on('-r',"--aws_region [REGION]", "The region to use when looking up hosts.") do |s|
      options[:aws_region] = s
    end

    options[:aws_tag] = []
    opts.on('-t', "--aws_tag [TAG]", "The name of the aws tag to use for looking up hosts.") do |s|
      options[:aws_tag].push(s)
    end

    opts.on('-d', '--debug', 'Will print debug info.') do |s|
      options[:debug] = s
    end

    opts.on('--list-hosts', "Outputs list of hosts and then exits.") do |s|
      options[:list_hosts] = s
    end

    opts.on('--get-tags', 'Output the tags.') do |s|
      options[:get_tags] = s
    end
  end

  optparse.parse!

  # Set the session name if it is not set.
  if options[:session] == nil
    options[:session] = "tmux_session_#{$$}"
  end

  return options
end

class AwsHosts

  attr_reader :instances

  def initialize(debug=nil)
    @instances = []
    @debug = debug
  end

  def get_hosts_by_tag_value(tag_array, region=nil)
    query_str = %/--query "Reservations[].Instances[].{ n1: Tags[?Key == 'Name'].Value, t1: Tags } | [*].{ name: n1[0], tags: t1 }"/
    filters = tag_array.collect { |x| "Name=tag-value,Values=#{x}" }.join(' ')
    command = ["aws ec2 describe-instances"]
    unless region.nil?
      command.push("--region #{region}")
    end
    command.push("--filter #{filters}")
    command.push("#{query_str}")

    if @debug
      puts "AWS command used => #{command.join('')}\n\n"
    end

    output = %x(#{command.join(' ')})
    @instances = JSON.parse(output)
  end

  def list_hosts()
    @instances.map { |host| host['name'] }
  end

  def print_host_list()
    puts self.list_hosts().join("\n")
  end

  def print_instances()
    puts JSON.pretty_generate(@instances)
  end

end

def starttmux(host_ary, opts)
  max_pane = opts[:max_panes]
  cmd = 'tmux'
  user = opts[:user]
  session = opts[:session]

  ittr_hosts = host_ary.each_slice(max_pane).to_a
  ittr_hosts.each do |mem_ary|
    system("#{cmd} new-session -d -s #{session}")
    main_pane = %x(#{cmd} list-panes | awk {'print $1'} | sed s/://)
    #print "main_pane is #{main_pane}"
    mem_ary.each do |host|
      puts "Adding #{host}"
      run="#{cmd} split-window -v -t #{session} \"ssh -l #{user} #{host}\""
      system(run)
      run='tmux select-layout tiled'
      system(run)
    end
    system("#{cmd} set-window-option synchronize-panes on")
    system("#{cmd} kill-pane -t #{main_pane}")
    system("#{cmd} attach -t #{session}")
  end
end

def main(options)

  if options[:debug]
    puts "Options => #{options}\n\n"
  end

  ah_obj = AwsHosts.new(options[:debug])

  host_ary = []
  if options[:host_list]
    host_ary = options[:host_list]
  elsif not options[:aws_tag].empty?
    ah_obj.get_hosts_by_tag_value(options[:aws_tag], options[:aws_region])
    host_ary = ah_obj.list_hosts
  end

  if host_ary.empty?
    print "No hosts."
    exit(1)
  end

  if options[:debug]
    puts "host_ary => #{host_ary}\n\n"
  end

  if options[:list_hosts]
    if not options[:aws_tag].empty?
      puts "List hosts from aws_tag." unless options[:debug].nil?
      print ah_obj.print_host_list
    elsif options[:host_list]
      puts "List hosts from host list." unless options[:debug].nil?
      puts host_ary
    end
    exit(0)
  elsif options[:get_tags]
    puts "List the host data." unless options[:debug].nil?
    print ah_obj.print_instances
    exit(0)
  end

  starttmux(host_ary, options)
end

if __FILE__ == $0

  options = cmd_line()
  main(options)
end
