#!/usr/bin/env ruby

require 'optparse'

options = {}
OptionParser.new do |opt|
  opt.on('--opname OPNAME') { |o| options[:opname] = o }
  opt.on('--homebase_ip HOMEBASE_IP') { |o| options[:homebase_ip] = o }
end.parse!

# https://stackoverflow.com/questions/1541294/how-do-you-specify-a-required-switch-not-argument-with-ruby-optionparser/1542658#1542658
begin
  mandatory = [:homebase_ip, :opname]
  missing = mandatory.select{ |param| options[param].nil? }
  raise OptionParser::MissingArgument, missing.join(', ') unless missing.empty?
rescue OptionParser::ParseError => e
  puts e
  puts options
  exit
end

homebase_ip = options[:homebase_ip]
opname = options[:opname]

stanza =
<<SSH
Host homebase-#{opname}
     Hostname #{homebase_ip}
     User <SSH_USER>
     IdentityFile ~/.ssh/id_rsa
     #Uncomment AddressFamily if you have WSL errors to force ipv4
     #AddressFamily inet
     LocalForward 50050 127.0.0.1:50050
     LocalForward 5000 192.168.2.14:5000
     LocalForward 9001 127.0.0.1:9001
     ##Change 59xx to your VNC Port and uncomment this forward. Your UID is found in sshKeys users.json
     #Your port number is (5900 + (UID - 6000) + 1)
     #LocalForward 5901 127.0.0.1:59xx

Host proxy01-#{opname}
     Proxycommand ssh homebase-#{opname} nc -q0 %h.infra.redteam %p
     User <SSH_USER>

Host proxy02-#{opname}
     Proxycommand ssh homebase-#{opname} nc -q0 %h.infra.redteam %p
     User <SSH_USER>

Host elk-#{opname}
     Proxycommand ssh homebase-#{opname} nc -q0 %h.infra.redteam %p
     User <SSH_USER>
     LocalForward 5601 192.168.1.13:5601

Host natlas-#{opname}
     Proxycommand ssh homebase-#{opname} nc -q0 %h.infra.redteam %p
     User <SSH_USER>
SSH

stanzafile = "homebase-#{opname}"
File.open(stanzafile, 'w') do |file|
  file.write(stanza)
end

STDOUT.puts <<INSTRUCTIONS
Copy the generated file (#{stanzafile}) into you ssh config like this:
cat #{stanzafile} >> ~/.ssh/config
INSTRUCTIONS
