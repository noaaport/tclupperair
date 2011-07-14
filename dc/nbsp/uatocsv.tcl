#!/usr/local/bin/tclsh8.6
#
# $Id: uatocsv.tcl,v b66a07506bf5 2011/07/14 19:16:31 jfnieves $
#
# Usage: uatocsv [-h] [-l <levels_sep>] [-n <na_str>] [-s <outputsep>] [<file>]
#
# The input data should be in the format such as
#
# dems,211200,42410,2112|surface,1000,26.4,-85.6,3,270|1000,54,26.4,-85.6,3,270
# dems,211200,42410,2112 surface,1000,26.4,-85.6,3,270 1000,54,26.4,-85.6,3,270
#
# as returned by the fm35dc decoder, where the <levels_sep> (" " or "|")
# separates the different levels. So, an example usage is
#
#      fm35dc -c 78526_20110714.upperair | uatocsv
#
# The data portion of such records (which starts after the first <separator>)
#
# surface,<p_mb>,<temp_c>,<dewp_c>,<wspeed_kt>,<wdir>
# tropopause,<p_mb>,<temp_c>,<dewp_c>,<wspeed_kt>,<wdir>
# windmax,<p_mb>,<wspeed_kt>,<wdir>                         
# 1000,<height_m>,<temp_c>,<dewp_c>,<wspeed_kt>,<wdir>
#
# is then converted to a set of records of the form
#
# <level_name>,<height>,<p_mb>,<temp_c>,<dewp_c>,<wspeed_kt>,<wdir>
#
# that is,
#
# surface,0,<p_mb>,<temp_c>,<dewp_c>,<wspeed_kt>,<wdir>        (surface)
# <level>,<height_m>,1000,<temp_c>,<dewp_c>,<wspeed_kt>,<wdir> (1000, 950, ...)
# tropopause,NA,<p_mb>,<temp_c>,<dewp_c>,<wspeed_kt>,<wdir>    (tropopause)
# windmax,NA,<p_mb>,NA,NA,<wspeed_kt>,<wdir>                   (windmax)
#
# and each such converted record is output preceeded by the two elements
#
# <obstation>,<obtime>
#
# So, for each input record, the complete output is a set of records
# of the form
#
# <obstation>,<obtime>,\
#	<level_name>,<height>,<p_mb>,<temp_c>,<dewp_c>,<wspeed_kt>,<wdir>
#
# If the [-h] option is given, the first line of the output is a header
# with the column names.

#
# Functions
#

proc process_file {} {

    global g;

    if {$g(header) == 1} {
	puts -nonewline "# ";
	puts [join [list station time \
			level height_m p_mb temp_c dewp_c wspeed_kt wdir] \
		  $g(data_separator)];
    }

    while {[gets $g(F) data] >= 0} {
	if {[regexp {^\s+$} $data]} {
	    continue;
	}
	if {$g(levels_separator) ne ""} {
	    set data [split $data $g(levels_separator)];
	} else {
	    set data [split $data];
	}

	# info = <wmostation>,<wmotime>,<obstation>,<obtime>
	set info [split [lindex $data 0] $g(data_separator)];
	set obstation [lindex $info 2];
	set obtime [lindex $info 3];
	
	set level_records [lrange $data 1 end];

	foreach record $level_records {
	    set record_values [split $record $g(data_separator)];
	    set level_name [lindex $record_values 0];

	    if {$level_name eq "surface"} {
		# surface,<p_mb>,<temp_c>,<dewp_c>,<wspd_kt>,<wdir>
		# surface,0,<p_mb>,<temp_c>,<dewp_c>,<wspd_kt>,<wdir>
		set output [linsert $record_values 1 "0"];
	    } elseif {$level_name eq "tropopause"} {
		# tropopause,<p_mb>,<temp_c>,<dewp_c>,<wspd_kt>,<wdir>
		# tropopause,NA,<p_mb>,<temp_c>,<dewp_c>,<wspd_kt>,<wdir>
		set output [linsert $record_values 1 $g(na_str)];
	    } elseif {$level_name eq "windmax"} {
		# windmax,<p_mb>,<wspeed_kt>,<wdir>
		# windmax,NA,<p_mb>,NA,NA,<wspd_kt>,<wdir>
		set output [linsert $record_values 2 $g(na_str) $g(na_str)];
		set output [linsert $output 1 $g(na_str)];
	    } else {
		# <level>,<height_m>,<temp_c>,<dewp_c>,<wspd_kt>,<wdir>
		# <level>,<height_m>,<level>,<temp_c>,<dewp_c>,<wspd_kt>,<wdir>
		set output [linsert $record_values 2 $level_name];
	    }
	    set output [linsert $output 0 $obstation $obtime];
	    puts [join $output $g(data_separator)];
	}
    }
}

#
# main
#
package require cmdline;
package require fileutil;

set usage {uatocsv [-h] [-l <levels_sep>] [-n <na_str>] [-s <output_sep>]
    [<file>]};
set optlist {h {l.arg ""} {n.arg ""} {s.arg ""}}; 

set g(data_separator) ",";      # not configurable as defined in fm35.tcl
set g(levels_separator) "";	# -l
set g(na_str) "";		# -n
set g(output_separator) ",";	# -s

# Variables
set g(F) stdin;
set g(fpath) "";
set g(header) 0;

array set option [::cmdline::getoptions argv $optlist $usage];
set argc [llength $argv];

set g(header) $option(h);

if {$option(l) ne ""} {
    set g(levels_sep) $option(l);
}

if {$option(n) ne ""} {
    set g(na_str) $option(n);
}

if {$option(s) ne ""} {
    set g(separator) $option(s);
}

if {$argc != 0} {
    set g(fpath) [lindex $argv 0];
    set status [catch {set g(F) [open $g(fpath) "r"]} errmsg];
    if {$status != 0} {
	puts $errmsg;
	exit 1;
    }
}

fconfigure $g(F) -encoding binary -translation binary;
fconfigure stdout -encoding binary -translation binary;

set status [catch {process_file} errmsg];

if {$g(fpath) ne ""} {
    close $g(F);
}

if {$status != 0} {
    puts $errmsg;
    exit 1;
}
