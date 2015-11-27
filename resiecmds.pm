#!/usr/bin/perl
#
# @File resiecmds.pm
# @Author harris
# @Created 12/09/2015 7:46:10 PM
#

package resiecmds;

use warnings;
use strict;
use DBI;
use wdbm;

no warnings 'uninitialized';

our $searchterm = "";

sub new {
	my ($class) = @_;
	my $self = bless {
		ident => "Resies Database commands package",
		prompt => "[I]ns [E]dt [F]nd [G]et [S]QL [X]ecute [N]ext [P]rev [L]ist [D]el [R]en [Q]uit\n?: ",
	},$class;
	return($self);
}

sub get_first {
        my ($self,$wdbm) = @_;
        return($wdbm->fetch_list(qq(
		SELECT $wdbm->{fieldlist} from $wdbm->{table_name} order by lot_number;
	)));
}

#--------------------------------------------------------------------------------------------------------------------------

sub get_SQL {
	my ($self,$SQLexpression,$wdbm) = @_;
	return($wdbm->fetch_list(qq(
		SELECT $wdbm->{fieldlist} from $wdbm->{table_name} where $SQLexpression;
	)));
}

sub get_find {
	my ($self,$searchstr,$wdbm) = @_;
        my $SQLexpression = qq(
SELECT $wdbm->{fieldlist} from $wdbm->{table_name} where similarity('$searchstr',name)>0.1 or similarity('$searchstr',address1)>0.1 or similarity('$searchstr',address2)>0.1 or similarity('$searchstr',address3)>0.3 or similarity('$searchstr',comment)>0.1 order by lot_number;
	);
	return($wdbm->fetch_list($SQLexpression));
}

sub get_last {
	my ($self,$wdbm) = @_;
        return($wdbm->fetch_list(qq(
		SELECT $wdbm->{fieldlist} from $wdbm->{table_name} order by lot_number desc;
	)));
}

sub get_eq {
	my ($self,$key,$wdbm) = @_;
	return($wdbm->fetch_list(qq(
		SELECT $wdbm->{fieldlist} from $wdbm->{table_name} where unit_number >= $key order by lot_number;
	)));
}

sub get_direct {
	my ($self,$key,$wdbm) = @_;
	return($wdbm->fetch_list(qq(
		SELECT $wdbm->{fieldlist} from $wdbm->{table_name} where unit_number = $key or lot_number = $key;
	)));
}

sub insert_record {
	my ($self,$wdbm,@SQLupdate_fields_values) = @_;
	my ($statement,$rv);
	$statement = qq(
INSERT INTO $wdbm->{table_name} ($SQLupdate_fields_values[0]) VALUES ($SQLupdate_fields_values[1]);
        );
	$wdbm->error($statement);
	$wdbm->SQLexecute($wdbm,$statement);
}

sub update_record {
	my ($self,$wdbm,@SQLupdate_fields_values) = @_;
	my ($statement,$rv);
	my @original_record =  @{$wdbm->{current_arrayref}[$wdbm->{iter_arrayref}]};
	$statement = qq(
UPDATE $wdbm->{table_name} SET ($SQLupdate_fields_values[0]) = ($SQLupdate_fields_values[1]) where lot_number = $original_record[$wdbm->getfieldnum("lot_number")];
        );
	$wdbm->error($statement);
	$wdbm->SQLexecute($wdbm,$statement);
}

sub executor {
	my ($self,$wdbm,$inchr) = @_;
#	my $searchterm = "";
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
	} elsif ($inchr =~ /^[xX]/) {
		$wdbm->head("SQL : ");
		my $statement_handle = $wdbm->SQLexecute($wdbm,wdbm::linedt($searchterm,60));
		print "\r";
		my @row;
		while (@row = $statement_handle->fetchrow_array){
			print (join(' ',@row));
			print "\n";
		}
		$wdbm->error("execution terminates"); 
#		$wdbm->list_view($wdbm);
	} elsif ($inchr =~ /^[iI]/) {
		$wdbm->warn("Insert Record");
		$wdbm->unpack_db_record("");
		$wdbm->form_display();
		$wdbm->prompt();
		if(!$wdbm->form_edit("enter")) {
			# error_handler(&get_eq($svlog_name));
		}
	} elsif ($inchr =~ /^[eE]/) {
		$wdbm->warn("Edit Record");
    		$wdbm->form_display();
		$wdbm->form_edit("edit");
	} elsif ($inchr =~ /^[nN]/) {
		$wdbm->warn("Get Next");
		$wdbm->fetch_list_next;
	} elsif ($inchr =~ /^[pP]/) {
		$wdbm->warn("Get Previous");
		$wdbm->fetch_list_previous;
	}
}

1;
