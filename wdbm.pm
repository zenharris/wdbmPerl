#!/usr/bin/perl
#
# @File wdbm.pm
# @Author harris
# @Created 12/09/2015 7:24:07 PM
#

package wdbm;
require "flush.pl";
use warnings;
use strict;
use DBI;

use POSIX;
use Term::Cap;

# use Exporter;
# our @ISA = 'Exporter';
# our @EXPORT = qw($terminal);

no warnings 'uninitialized';


our ($form_length,$terminal,$raw_mode,$save_stty,$msg_window,$current_window,$curscr,$curses,$edited);
our $blank = "                                                                            ";



# Get the terminal speed through the POSIX module and use that
# to initialize Term::Cap.
sub termcap_init {
	my($self) = @_; 
    #$| = 1;
    #$delay = (shift() || 0) * 0.005;
	my $termios = POSIX::Termios->new();
	$termios->getattr;
	my $ospeed = $termios->getospeed;
	$terminal = Term::Cap->Tgetent ({ TERM => undef, OSPEED => $ospeed });
	$terminal->Trequire(qw/cl cm cd ce ku kd/);

	#$current_window = $stdscr;
	
	return ($terminal);
}

# Move the cursor to a particular location.
sub gotoxy {
	my ($x,$y) = @_;
	$terminal->Tgoto('cm', $x, $y, *STDOUT);
} 

# clear_screen
# clear_end clears to the end of the screen.
sub clear_screen { $terminal->Tputs('cl', 1, *STDOUT) } 
sub clear_end    { $terminal->Tputs('cd', 1, *STDOUT) } 
sub clear_eol    { $terminal->Tputs('ce', 1, *STDOUT) } 

sub raw_on {
    if(!$raw_mode){
        system "stty intr ^c";
        $save_stty = `stty -g`;
        system "stty -cooked opost -echo isig intr ^c";
        $raw_mode = 1;
    }
}

sub raw_off {
    if($raw_mode) {
        system "stty $save_stty";
        $raw_mode = 0;
    }
}


sub signal_set {
    $SIG{'INT'}= 'IGNORE';
    $SIG{'QUIT'}= 'IGNORE';
    $SIG{'HUP'}= 'IGNORE';
}

sub signal_reset {
    $SIG{'INT'}= 'DEFAULT';
    $SIG{'QUIT'}= 'DEFAULT';
    $SIG{'HUP'}= 'DEFAULT';
    $SIG{'ALRM'}= 'DEFAULT';
}


sub screen_handling_on {
	raw_on();
	termcap_init();
	signal_set();
}

sub screen_handling_off {
	raw_off();
	signal_reset();
	alarm(0);
}

sub flash {
	my ($self,$error_deets) = @_;
	my $iter;
	for($iter=0;$iter<10;$iter++) {
		printflush (*STDOUT,"\rZxZxZxZxZ $error_deets ZxZxZxZxZxZ");
		select(undef, undef, undef, 0.18);
		printflush (*STDOUT,"\rxZxZxZxZx $error_deets xZxZxZxZxZx");
		select(undef, undef, undef, 0.18);
	}
}

sub error_handler {
	my ($self,$errordeets) = @_;
    my ($err,$errcode,$ascerr,$xdelay) = split(':}',$errordeets);
    if($err eq "error") {
	if($curses) {
	    waddstr($msg_window,"\r");
	    wclrtoeol($msg_window);
	    waddstr($msg_window,"ERROR $ascerr <enter>");
	    wrefresh($msg_window);
	    wgetch($msg_window);
	    waddstr($msg_window,"\r");
	    wclrtoeol($msg_window);
	    wrefresh($msg_window);
	} else {
	    printflush(*STDOUT,"\r");
		clear_eol();
		$/ = "\r\n";
		chomp($ascerr);
#		$ascerr =~ s/\s+$//;
		$ascerr =~ s/^\s+|\s+$//g;
#		printflush(*STDOUT,"\r$ascerr <enter>");
		print("$ascerr <enter>");
		getc(STDIN);
		printflush(*STDOUT,"\r");
		clear_eol();
		printflush(*STDOUT,"?: ");
	}
	return(1);
    } elsif ($err eq "warn") {
	if($curses) {
	    waddstr($msg_window,"\r");
	    wclrtoeol($msg_window);
	    waddstr($msg_window,"$ascerr");
	    wrefresh($msg_window);
	} else {
		gotoxy(0,$form_length-1);
		clear_eol();
		$/ = "\r\n";
		chomp($ascerr);
#		$ascerr =~ s/\s+$//;
		$ascerr =~ s/^\s+|\s+$//g;
		printflush(*STDOUT,"\r$ascerr");
	   # print("$ascerr");
	}
#	if($xdelay != 0){
#	    sleep($xdelay);
#	}
	return(1);
    }
    return(0);
}




sub warn {
	my ($self,$parm1,$parm2) = @_;
	return($self->error_handler("warn:}foo:}$parm1:}"));
}

sub error {
	my ($self,$parm1) = @_;
	return($self->error_handler("error:}foo:}$parm1:}"));
}

sub prompt {
	my ($self) = @_;
    if($curses) {
	waddstr($current_window,$self->{user_commands}->{prompt});
	wrefresh($current_window);
    } else {
	gotoxy(0,$form_length-1);
	print($self->{user_commands}->{prompt});
    }
}



sub head {
	my ($self,$header) = @_;
    if($curses) {
	waddstr($current_window,"\r");
	wclrtoeol($current_window);
	waddstr($current_window,$header);
	wrefresh($current_window);
    } else {
	printflush(*STDOUT,"\r");
	clear_eol();
	printflush(*STDOUT,$header);
    }
}


sub cls {
	if ($curses) {
		werase($current_window);
		wrefresh($current_window);
	} else {
		clear_screen();
	}
}


sub inkey {
    if($curses) {
       return(wgetch($current_window));
    } else {
        return(getc(STDIN));
    }
}



sub getyn {
    my($answer);
    wdbm->warn($_[0]);
    if($curses) {
	do {
	    while(($answer=wgetch($current_window)) =~ /^[^yYnN]/) {};
	} until ($answer ne "");
	if ($answer =~ /^[yY]/) {
	    wdbm->warn("Yes");
	} else {
	    wdbm->warn("No");
	}
	wrefresh($current_window);
    } else {
	while(($answer=getc(STDIN)) =~ /^[^yYnN]/) {};
	if ($answer =~ /^[yY]/) {
	    wdbm->warn("Yes");
	} else {
	    wdbm->warn("No");
	}
    }
    $answer =~ /^[yY]/;
}	



sub attrib {
	my($test,@attribs) = @_;
	for(@attribs) {
		return(1) if ($_ eq $test);
	}
	return(0);
}


sub linedt {
    my($default,$lnth_limit,@type) = @_;
    my($inchr,$iter,$once);
    my $linbuff = "";
    my $select_iter = 0;
	my @select_options = @type;

	if(attrib("sel",@select_options)) {
		while (shift(@select_options) ne "sel"){};
	}

    if($curses) {
	waddstr($current_window,substr($blank,0,$lnth_limit));
	for($iter=0;$iter<$lnth_limit;$iter++) {
	    waddstr($current_window,"\b");
	}	    
	waddstr($current_window,$default);
	for($iter=0;$iter<length($default);$iter++) {
	    waddstr($current_window,"\b");
	}	    
	wrefresh($current_window);
    } else {
	print(substr($blank,0,$lnth_limit));
	for($iter=0;$iter<$lnth_limit;$iter++) {
	    print("\b");
	}	    
	print($default);
	for($iter=0;$iter<length($default);$iter++) {
	    print("\b");
	}	    
    }

    while(($inchr=inkey()) =~ /^[^\r\n]/) { 
	if($inchr eq "\cl") {
#	    wrefresh($curscr);
	    next;
	}
###	if($inchr =~ /^[^A-Za-z0-9\@\.()\/\b' '\*\?\-_\177\010]/) {next;}
	if(length($inchr) == 0) {next;}
	if($inchr =~ /^[\b\177\010]/) {
	    if (length($linbuff) > 0){
		chop($linbuff);
		if($curses) {
		    waddstr($current_window,"\b \b");
		    wrefresh($current_window);
		} else {
		    print "\b \b";
		}
	    }
	} elsif (length($linbuff) < $lnth_limit){
	    if(!$once) {
		if($curses) {
		    waddstr($current_window,substr($blank,0,$lnth_limit));
		    for($iter=0;$iter<$lnth_limit;$iter++) {
			waddstr($current_window,"\b");
		    }	    
		} else {
		    print(substr($blank,0,$lnth_limit));
		    for($iter=0;$iter<$lnth_limit;$iter++) {
			print("\b");
		    }	    
		}
		$once = 1;
	    }

	    if(attrib("sel",@type)) {
		if($inchr eq ' '){
			$linbuff = $select_options[$select_iter++];
			$select_iter = 0 if ($select_iter > scalar(@select_options));
			print(substr($blank,0,$lnth_limit));
			for($iter=0;$iter<$lnth_limit;$iter++) {
			    print("\b");
			}	    
			print ($linbuff);
			for($iter=0;$iter<length($linbuff);$iter++) {
			    print("\b");
			}	    
		}
		next;

	}

	    if(attrib("cap",@type)) {
		if(length($linbuff) == 0 || (substr($linbuff,-1,1) eq " ")){
		    $inchr =~ tr/[a-z]/[A-Z]/;
		} else {
		    $inchr =~ tr/[A-Z]/[a-z]/;
		}
	    }
	    if (attrib("low",@type)) {
		$inchr =~ tr/[A-Z]/[a-z]/;
	    }
	    if (attrib("up",@type)) {
		$inchr =~ tr/[a-z]/[A-Z]/;
	    }
	    if (attrib("num",@type) || &attrib("int",@type)) {
		next if ($inchr =~ /^[^0-9]/);
	    }
	    if (attrib("flags",@type)) {
		next if ($inchr =~ /^[^01]/);
	    }
	    if (attrib("deci",@type)) {
		next if ($inchr =~ /^[^0-9.]/);
	    } 
	    if (attrib("date",@type)) {
		next if ($inchr =~ /^[^0-9\/\s]/);
		if(length($linbuff) =~ /[47]/) { $inchr = '-';}
	    } 
	    if (attrib("alphacap",@type)) {
		next if ($inchr =~ /^[^A-Za-z' ']/);
		if(length($linbuff) == 0 || (substr($linbuff,-1,1) eq " ")){
		    $inchr =~ tr/[a-z]/[A-Z]/;
		} else {
		    $inchr =~ tr/[A-Z]/[a-z]/;
		}
	    }
	    $linbuff .= $inchr;
	    if(attrib("pas",@type)){
		if($curses) {
		    waddstr($current_window,"*");
		    wrefresh($current_window);
		} else {
		    print "*";
		}
	    } else {
		if($curses) {
		    waddstr($current_window,$inchr);
		    wrefresh($current_window);
		} else {
		    print $inchr;
		}
	    }
	}
    }
    if(length($linbuff) == 0) {
	return($default);
    } else {
	$_[0] = $linbuff;
	return($linbuff);
    }
}




sub new {
	my($class,$table_name,$dict_dir,$command_package) = @_;
	my $password = "";
	my $self = {
		path_to_dictionary => "$dict_dir",
		table_name =>  "$table_name",
		database_handle => "",
		statement_handle => "",
		form_templ => [],
		field_array => [],
		list_fields => [],
		list_format => "",
		fieldlist => "",
		current_SQLexpression => "",
		current_record => [ () ],
		current_record_edit_flags => [ () ],
		current_arrayref => "",
		iter_arrayref => "",
		fields => {},
		server_details => {},
		terminal => "",
		user_commands => $command_package,
	};
	bless $self,$class;
	$self->read_data_dictionary();	
	cls();
	$self->head ("PassWord : ");
	$self->open_server(linedt($password,16));	
	$curses=0;
	return ($self);
}


sub open_server {
	my ($self,$password) = @_;
	my $dsn = "dbi:$self->{server_details}{driver}:dbname=$self->{server_details}{database};host=$self->{server_details}{server_address};port=$self->{server_details}{server_port}";
	my $dbh=DBI->connect ($dsn,$self->{server_details}{userid},$password) 
				|| error("error opening database: $DBI::errstr");
	wdbm->warn("Opened database successfully");
	$self->{database_handle} = $dbh;
	return($dbh);
}

sub close_server {


}


sub sysdb {
	my ($self,$stmt) = @_;
	my $sth = $self->{database_handle}->prepare( $stmt );
	my $rv = $sth->execute();
	$self->error("$DBI::errstr") if($rv < 0);
	return($sth);
}

sub SQLexecute {
	my ($self,$wdbm,$SQLexpression) = @_;
	my ($rv,$statement_handle);
	$statement_handle = $wdbm->{database_handle}->prepare($SQLexpression);
	$statement_handle->execute();
	return($statement_handle);
	

#	if( $rv < 0 ){
#		$wdbm->error($DBI::errstr);
#	}else{
#		$wdbm->error("Total number of result rows $rv");
#	}
#	return ($rv);
}

sub pack_db_record {
	my ($self) = @_;
	my $iter;
	my $fields = "";
	my $values = "";
	my $junk;
	my $field_type;
	for ($iter=0;$iter < scalar(@{$self->{current_record}});$iter++) {
		if($self->{current_record_edit_flags}[$iter]) {
			($junk,$junk,$field_type) = split(/:/,$self->{fields}{$self->{field_array}[$iter]});
			if ($field_type eq "str" || $field_type eq "date" || $field_type eq "text") {
				$values = $values."'$self->{current_record}[$iter]'".",";			
			} else {
				$values = $values.$self->{current_record}[$iter].",";
			}
			$fields = $fields.$self->{field_array}[$iter].",";			
		}
	}
	chop($values);
	chop($fields);
	return(($fields,$values));
#	return(("SET ($fields) = ($values)");
}

sub unpack_db_record {
	my($self,@record) = @_;
	@{$self->{current_record}} = ();
	@{$self->{current_record_edit_flags}} = ();
	@{$self->{current_record}} = @record;
	return(@record);
}

sub unpack_db_record_wdb {
    my($self,$rec_buff) = @_;
    my($tester) = split(/:/,$rec_buff);
    if($tester eq "error") {
        return($rec_buff);
    }
    @{$self->{current_record}} = ();
    @{$self->{current_record_edit_flags}} = ();
    if($rec_buff =~ /\n/) {
        chop($rec_buff);
    }
    @{$self->{current_record}} = split(/:/,$rec_buff);
    return($rec_buff);
}

sub getfields {
	my($self,@fieldnames) = @_;
	my($fldnum,$fldname,@fldattr,$fieldname);
	my @retarray = ();
	foreach $fieldname (@fieldnames) {
		($fldnum,$fldname,@fldattr) = split(/:/,$self->{fields}{$fieldname});
   		push (@retarray,$self->{current_record}[$fldnum]);
	}
	return(@retarray);
}

sub putfield {
	my ($self,$fieldname,$fieldcontent) = @_;
    my ($offset,$fldname) = split(/:/,$self->{fields}{$fieldname});
    if($fldname eq $fieldname) {
        $self->{current_record}[$offset] = $fieldcontent;
        $self->{current_record_edit_flags}[$offset] = 1;
    }else {
        error("Putfield  No Field Named $fieldname");
    }
}

sub getfield {
	my($self,$fieldname) = @_;
	my($fldnum,$fldname) = split(/:/,$self->{fields}{$fieldname});
    if($fldname eq $fieldname) {
	return($self->{current_record}[$fldnum]);
    } else {
	error("Getfield  No Field Named $fieldname");
    }
    return("");
}

sub getfieldnum {
	my ($self,$fieldkey) = @_;
	my ($offset,$fldname) = split(/:/,$self->{fields}{$fieldkey});
    if($fldname eq $fieldkey) {
	return($offset);
    } else {
	error("Getfieldnum  No Field Named $fieldkey");
    }
}

sub read_data_dictionary {
	my ($self) = @_;
	my ($iter,$key,$value);

	$self->{form_templ} = ();
	$self->{field_array} = ();
	$self->{list_fields} = ();
	$self->{list_format} = "";
	$self->{fieldlist} = "";
	$self->{current_record} = ();
	$self->{current_record_edit_flags} = ();
	$self->{fields} = ();
	$self->{server_details} = ();

	if(open(DICT,"$self->{path_to_dictionary}/$self->{table_name}.dict")) {
	while(<DICT>) {
			last if($_ =~ /%FIELD_DEF%/);
			chop($_);
			push(@{$self->{form_templ}},$_);
		}
		$self->{fieldlist} ="";    ##  Field List Hack
		$iter = 0;
		while(<DICT>) {
			last if($_ =~ /%END%/);
			chop($_);
			($key) = split(/:/,$_);
			$self->{fields}{$key} = "$iter:$_";
			push (@{$self->{field_array}},$key);
			$self->{fieldlist} = $self->{fieldlist}."$key,";    ##  Field List Hack
			$iter++;
		}
		$form_length = $iter;
		chop($self->{fieldlist});
		my $first = 1;
		while (<DICT>) {
		last if($_ =~ /%LIST_DEF%/);
				chop($_);
			if ($first) {
				$self->{list_format} = $_;
				$first = 0;
			} else {
				($key) = split(/:/,$_);
				push (@{$self->{list_fields}},$key);
			}
		}
		while (<DICT>) {
			last if($_ =~ /%SERVER_DETAILS%/);
			chop($_);
			($key,$value) = split(/:/,$_);
			$self->{server_details}{$key} = $value;
		}
		close(DICT);
		if($iter) {
		    return(1);
		}
	}
	return(0);
}

sub getyes {
	my($self,$prompt) = @_;
    $self->error_handler("warn:}foo:}$prompt:}");
    my $answer;
    while(($answer=getc(STDIN)) =~ /^[^yYnN]/) {};
    $answer =~ /^[yY]/;
}

sub subst {
	my($self,$parm) = @_;
	$parm =~ /\d+/;

	my ($junk,$fldattr);
	my $fieldname =	$self->{field_array}[$&];
	($junk,$junk,$fldattr) = split(/:/,$self->{fields}{$fieldname});
	if($fldattr eq "boolean") {
		if ($self->{current_record}[$&]) {
			return("true");
		} else {
			return("false");
		}
	}else { 
		return($self->{current_record}[$&]);
	}
}


sub list_view {
	my ($self,$wdbm) = @_;
	my $row;
	print "\n";
	foreach $row ( @{$wdbm->{current_arrayref}} ) {
		$wdbm->unpack_db_record(@{$row});
		printf("$wdbm->{list_format}\n",$wdbm->getfields(@{$wdbm->{list_fields}}));
	}
	$wdbm->unpack_db_record(@{${$wdbm->{current_arrayref}}[$wdbm->{iter_arrayref}]});
	$wdbm->error ("End of List");
}



sub edit_form_field {
	my ($self,$fieldname) = @_;
    my ($default,$buffer,$iter,$row,$col,$lnth,$fnum,$junk,@fldattr);
    $default = $self->getfield($fieldname);
    $fnum = $self->getfieldnum($fieldname);
    for($iter=0;$iter < scalar(@{$self->{form_templ}});$iter++){
	$buffer = $self->{form_templ}[$iter];
	if($buffer =~/\@$fnum<+/) {
	    $col = length($`);
	    $row = $iter;
	    $lnth = length($&);
	    last;
	}
    }
    if($curses) {
	wmove($current_window,$row,$col);
    } else {
	gotoxy($col,$row);
    }
    $buffer = $default;

 ($junk,$junk,@fldattr) = split(/:/,$self->{fields}{$fieldname});

    linedt($buffer,$lnth,@fldattr);
    if ($buffer ne $default) {
	$edited = 1;
	$self->putfield($fieldname,$buffer);
    }
}

sub form_edit {
	my($self,$edtype) = @_;
	my $ret;
	my $field_name;
	$edited = 0;

	foreach $field_name ( @{$self->{field_array}} ) {
		$self->edit_form_field($field_name);
	}

	$self->warn("All Fields Edited, Please Wait");
	$self->form_display();
	if ($edited) {
		if ($ret = getyn("Save Record ?")) {
			if ($edtype eq "edit") {
				$self->{user_commands}->update_record($self,$self->pack_db_record());
			} else {
				$self->{user_commands}->insert_record($self,$self->pack_db_record());
			}

			$self->refresh_list($self);

			$self->warn("Record Written",1);
		} else {
			$self->warn("Exit Without Save",1);
		}
		return($ret);
	}
	return(0);
}


sub form_display {
	my($self,@params) = @_;
	my ($iter,$buffer,$fld2,$count,$tempstr);
    my $blank = "                                                                                 ";
    if($curses) {
        werase($current_window);
    } else {
        $self->clear_screen();
    }
	
    for ($iter=0;$iter < scalar(@{$self->{form_templ}}) ;$iter++) {
        $buffer = $self->{form_templ}[$iter];
        while($buffer =~ /[%@]\d+<+/) {
            if($buffer =~ /%\d+<+/) {
                my $tmpstr = $&;
                $fld2 = substr($params[$count++],0,length($tmpstr));
                $fld2 = $fld2.substr($blank,0,length($tmpstr)-length($fld2));
                $buffer =~ s/%\d+<+/$fld2/;
            } elsif ($buffer =~ /@\d+<+/) {
                my $tmpstr = $&;
                $fld2 = substr($self->subst($tmpstr),0,length($tmpstr));
                $fld2 = $fld2.substr($blank,0,length($tmpstr)-length($fld2));
                $buffer =~ s/@\d+<+/$fld2/;
            }
        }
        if($curses) {
            waddstr($current_window,"$buffer\n\r");
        } else {
            print("$buffer\n");
        }
    }
    if($curses) {
        wrefresh($current_window);
    }
}



sub form_view {
	my ($self,$wdbm) = @_;
	my ($nowrt,$inchr);

	$wdbm->{user_commands}->get_first($wdbm);
	$wdbm->form_display();
	$wdbm->prompt();
	while(($inchr=$wdbm->inkey()) =~ /^[^Qq]/) {
		if($inchr eq "\cl") {
			if($curses) {
				wrefresh($curscr);
			}
			next;
		}
		$wdbm->{user_commands}->executor($wdbm,$inchr);
		if(!$nowrt) {
			$wdbm->form_display();
			$wdbm->prompt();
		} else {
			$nowrt = 0;
		}
	}
}

sub refresh_list {
	my ($wdbm) = @_;
	$wdbm->{statement_handle} = $wdbm->sysdb($wdbm->{current_SQLexpression});
	$wdbm->unpack_db_record(@{${$wdbm->{current_arrayref} = $wdbm->{statement_handle}->fetchall_arrayref}[$wdbm->{iter_arrayref}]}); 
}

sub fetch_list {
	my ($wdbm,$SQLexpression) = @_;
	$wdbm->{statement_handle} = $wdbm->sysdb($SQLexpression);
	$wdbm->unpack_db_record(@{${$wdbm->{current_arrayref} = $wdbm->{statement_handle}->fetchall_arrayref}[$wdbm->{iter_arrayref}=0]});
	$wdbm->{current_SQLexpression} = $SQLexpression;
}

sub fetch_list_next {
	my ($wdbm) = @_;
	$wdbm->unpack_db_record(@{(${$wdbm->{current_arrayref}}[++$wdbm->{iter_arrayref}])}) if ($wdbm->{iter_arrayref} < (scalar(@{$wdbm->{current_arrayref}})-1));
}

sub fetch_list_previous {
	my ($wdbm) = @_;
	$wdbm->unpack_db_record(@{(${$wdbm->{current_arrayref}}[--$wdbm->{iter_arrayref}])}) if ($wdbm->{iter_arrayref} > 0);
}



1;
