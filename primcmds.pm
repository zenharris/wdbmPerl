#!/usr/bin/perl
#
# @File primcmds.pm
# @Author harris
# @Created 12/09/2015 7:44:46 PM
#

package primcmds;

use warnings;
use strict;
use DBI;


sub new {
	my ($class) = @_;
	my $self = bless {
		ident => "sewer database Commands package",
		prompt => "\n[I]ns [E]dt [F]nd [G]et [S]QL [N]ext [P]rev [L]ist [D]el [R]en [Q]uit\n?: ",
	},$class;
	return($self);
}



sub get_first {
        my ($self,$wdbm) = @_;
        return($wdbm->fetch_list(qq(
		SELECT $wdbm->{fieldlist} from $wdbm->{table_name} order by joic_no;
	)));
}


sub get_SQL {
	my ($self,$SQLexpression,$wdbm) = @_;
	return($wdbm->fetch_list(qq(
		SELECT $wdbm->{fieldlist} from $wdbm->{table_name} where $SQLexpression;
	)));
}


sub get_find {
	my ($self,$searchstr,$wdbm) = @_;
	my $statement;
       $statement = qq(
		SELECT $wdbm->{fieldlist} from $wdbm->{table_name} where similarity('$searchstr',name)>0.1 or similarity('$searchstr',address)>0.1;
	);
       return($wdbm->fetch_list($statement));
}


sub get_last {
	my ($self,$wdbm) = @_;
        return($wdbm->fetch_list(qq(
		SELECT $wdbm->{fieldlist} from $wdbm->{table_name} order by joic_no desc;
	)));
}

sub get_eq {
	my ($self,$key,$wdbm) = @_;
	return($wdbm->fetch_list(qq(
		SELECT $wdbm->{fieldlist} from $wdbm->{table_name} where joic_no >= $key;
	)));
}

sub get_direct {
	my ($self,$key,$wdbm) = @_;
	return($wdbm->fetch_list(qq(
		SELECT $wdbm->{fieldlist} from $wdbm->{table_name} where joic_no = $key;
	)));
}



sub executor {
	my ($self,$wdbm,$inchr) = @_;
	my ($searchterm);

	if ($inchr =~ /^[fF]/) {
		$wdbm->head("SearchTerm  : ");
		$wdbm->{user_commands}->get_find(wdbm::linedt($searchterm,8),$wdbm);
		$wdbm->list_view($wdbm);
	} elsif ($inchr =~ /^[gG]/) {
		$wdbm->head("Unit/Lot No  : ");
		$wdbm->{user_commands}->get_direct(wdbm::linedt($searchterm,8),$wdbm);
		$wdbm->list_view($wdbm);
	} elsif ($inchr =~ /^[lL]/) {
		$wdbm->warn("List View");
		$wdbm->list_view ($wdbm);
	} elsif ($inchr =~ /^[sS]/) {
		$wdbm->head("WHERE ");
		$wdbm->{user_commands}->get_SQL(wdbm::linedt($searchterm,60),$wdbm);
		$wdbm->list_view($wdbm);
	} elsif ($inchr =~ /^[iI]/) {
	    $wdbm->warn("Insert Record");
	    $wdbm->unpack_db_record("");
	    $wdbm->form_display();
	    $wdbm->prompt();
	    if(!edit_db_record("enter")) {
	#	error_handler(&get_eq($svlog_name));
	    }
	} elsif ($inchr =~ /^[eE]/) {
		$wdbm->warn("Edit Record");
    		$wdbm->form_display();
		edit_db_record("edit");
	} elsif ($inchr =~ /^[rR]/) {
	    $wdbm->warn("Rename Record");
#	    rename_db_record($dbmhandle);
	} elsif ($inchr =~ /^[nN]/) {
		$wdbm->warn("Get Next");
		$wdbm->fetch_list_next;
	} elsif ($inchr =~ /^[pP]/) {
		$wdbm->warn("Get Previous");
		$wdbm->fetch_list_previous;
	} elsif ($inchr =~ /^[dD]/) {
#		delete_record($dbmhandle);
	}
}

1;
