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

    options[:tmux_bin] = '/usr/bin/tmux'
    opts.on('-t','--tmux-bin [path to bin]','Path to tmux binary.  Defualt=/usr/bin/tmux') do |s|
      options[:tmux_bin] = s
    end

    options[:aws_regioin] = 'us-east-1'
    opts.on('-r','--region [aws region]',"AWS region to use.  Default=#{options[:aws_region]}") do |s|
      options[:aws_region] = s
    end

    opts.on('-g','--security-group [security group]',"AWS security group to build session list from.") do |s|
      options[:security_group] = s
    end

  end

  optparse.parse!

  # Set the session name if it is not set.
  if options[:session] == nil
    options[:session] = options[:host_list].split('/').last.gsub(/\..*$/,'')
    print options[:session]
  end

  return options
end

def get_hosts(opts)
  host_list = ""
  if opts[:security_group]
    host_list = %{aws ec2 describe-instances --filter "Name=group-name,Values=%{opts[:security_group]}" --query 'Reservations[*].Instances[*].[Tags[?Key==`Name`]]' --output text | awk '{print $2}'}
  else
	  host_list = IO.readlines(opts[:host_list]).map(&:chomp)
  end
  host_list
end

def starttmux(opts)
	max_pane = opts[:max_panes]
	host_ary = opts[:hosts]
	cmd = opts[:tmux_bin]
  user = opts[:user]
	session = opts[:session]

	ittr_hosts = host_ary.each_slice(max_pane).to_a
	ittr_hosts.each do |mem_ary|
		system("#{cmd} new-session -d -s #{session}")
		mem_ary.each do |host|
			puts "Adding #{host}"
			run="#{cmd} split-window -v -t #{session} \"ssh -l #{user} #{host}\""
			system(run)
			run='tmux select-layout tiled'
			system(run)
		end
		system("#{cmd} set-window-option synchronize-panes on")
		system("#{cmd} kill-pane -t 0")
		system("#{cmd} attach -t #{session}")
	end
end

def main(options)

	options[:hosts] = get_hosts(options)
        starttmux(options)

end



if __FILE__ == $0

	options = cmd_line()
	main(options)
end
