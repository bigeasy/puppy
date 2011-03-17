#!/usr/bin/env ruby
require 'net/imap'

# Destination server connection info.
SOURCE_HOST = 'imap.gmail.com'
SOURCE_PORT = 993
SOURCE_SSL  = true

SOURCE_USER = 'client@prettyrobots.com'
SOURCE_PASS = IO.read("./client_password")[0...32]

source = Net::IMAP.new(SOURCE_HOST, SOURCE_PORT, SOURCE_SSL)
source.login(SOURCE_USER, SOURCE_PASS)

code = nil
source.select("INBOX")
source.search(["ALL"]).each do |message_id|
  envelope = source.fetch(message_id, "ENVELOPE")[0].attr["ENVELOPE"]
  if envelope.subject == "Activate Your Account at Puppy"
    msg = source.fetch(message_id,'RFC822')[0].attr['RFC822']
    match = /\$ puppy account:activate ([\d\w]+)/.match(msg)
    code = match[1]
    source.store(message_id, "+FLAGS", [:Deleted])
  end
end

source.expunge()

if code
  puts code
else
  exit 1
end
