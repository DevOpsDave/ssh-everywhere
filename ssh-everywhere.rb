#!/usr/bin/ruby

require 'optparse'


def cmd_line()
  options = {}
  optparse = OptionParser.new do |opts|

    opts.banner = "Usage: #{opts.program_name}"

    opts.on("-s","--session [STRING]","session name") do |s|
      options[:session] = s
    end

    opts.on("-l","--host_list [STRING]","path to host list.") do |s|
      options[:host_list] = s
    end

    options[:user] = `echo $USER`.chomp
    opts.on('-u', '--user [USER]', 'The user to login as. Default=<current user>') do |s|
      options[:user] = s
    end

    options[:max_panes] = 20
    opts.on("-m","--max_panes [INT]", OptionParser::DecimalInteger, "Max number of panes per session.") do |s|
      options[:max_panes] = s
    end

    options[:aws_region] = 'us-east-1'
    opts.on('-r',"--aws_region [REGION]", "The region to use when looking up hosts.") do |s|
      options[:aws_region] = s
    end

    opts.on('-g', "--aws_group [SEC GROUP]", "The name of the sec grp to use when looking up hosts.") do |s|
      options[:aws_group] = s
    end

    options[:aws_tag] = []
    opts.on('-t', "--aws_tag [TAG]", "The name of the aws tag to use for looking up hosts.") do |s|
      options[:aws_tag].push(s)
    end

    opts.on('-d', '--dry-run', 'Will print debug info and quit before doing anything.') do |s|
      options[:dry_run] = s
    end

  end

  optparse.parse!

  # Set the session name if it is not set.
  if options[:session] == nil
    options[:session] = "tmux_session_#{$$}"
  end

  return options
end

def get_hosts(opts)
  host_array = []
  if opts[:host_list]
    host_array = IO.readlines(opts[:host_list]).map(&:chomp)
  elsif not opts[:aws_tag].empty?
    filters = ""
    opts[:aws_tag].each { |value| filters += "Name=tag-value,Values=#{value} "}
    command = %Q/aws ec2 describe-instances --region #{opts[:aws_region]} --filter #{filters} --query "Reservations[*].Instances[*].[Tags[?Key=='Name']]" --output text | sort | awk {' print $2 '}/
    if opts[:dry_run]
      print "AWS CLI Command => #{command}\n"
    end
    command_output = %x(#{command})
    host_array = command_output.split()
  elsif opts[:aws_group]
    command_output = `aws ec2 describe-instances --region #{opts[:aws_region]} --filter "Name=group-name,Values=#{opts[:aws_group]}" --query "Reservations[*].Instances[*].[Tags[?Key=='Name']]" --output text | sort | awk {' print $2 '}`
    host_array = command_output.split()
  end

  host_array
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
  host_ary = get_hosts(options)

  if host_ary.empty?
    print "No hosts."
    exit(1)
  end

  if options[:dry_run]
    puts host_ary.join("\n")
    exit(0)
  end

  starttmux(host_ary, options)
end



if __FILE__ == $0

  options = cmd_line()
  main(options)
end
