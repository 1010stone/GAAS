#!/usr/bin/perl -w

package GAAS::Utilities;

use strict;
use warnings;
use Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(exists_keys exists_undef_value get_proper_codon_table printSurrounded sizedPrint activate_warning_limit);
sub import {
  GAAS::Utilities->export_to_level(1, @_); # to be able to load the EXPORT functions when direct call; (normal case)
  GAAS::Utilities->export_to_level(2, @_); # to be able to load the EXPORT functions when called from one level up;
}

=head1 SYNOPSIS

 package containing utility tools

=head1 DESCRIPTION



=head1 AUTHOR

    Jacques Dainat - jacques.dainat@nbis.se

=cut

#check if reference exists in hash. Deep infinite : hash{a} or hash{a}{b} or hash{a}{b}{c}, etc.
# usage example: exists_keys($hash_omniscient,('level3','cds',$level2_ID)
sub exists_keys {
    my ($hash, @keys) = @_;

    for my $key (@keys) {
    	if (ref $hash ne 'HASH' or ! exists $hash->{$key}) {
    		return '';
    	}
		  $hash = $hash->{$key};
    }
    return 1;
}


# @Purpose: check if a value is undef in hash recursively (potentialy due to autovivification)
# @input: 1 =>  hash reference
# @output 1 => bolean
sub exists_undef_value {
    my ($hash) = @_;

    if (ref $hash ne 'HASH'){ print "It is not a hash you provided\n";return ''; }
    my $result = undef;

    foreach my $key (keys %{$hash}) {
      if (ref $hash->{$key} eq 'HASH'){
        if ( exists_undef_value($hash->{$key})){return 1;};
      }
      else{
		    if(! defined $hash->{$key}){
          return 1;
        }
      }
    }
    return '';
}

# @Purpose: check if the table codon is available in bioperl
# @input: 1 =>  integer
# @output 1 => integer
sub get_proper_codon_table {
  my ($codon_table_id_original) = @_;
  my $codonTable = Bio::Tools::CodonTable->new( -id => $codon_table_id_original);
  my $codon_table_id_bioperl = $codonTable->id;

  if ($codon_table_id_original == 0 and  $codon_table_id_original != $codon_table_id_bioperl){
    $codonTable->warn("Your version of bioperl do not handle codon table 0\n".
    "see https://github.com/bioperl/bioperl-live/pull/315\n".
    "It uses codon table $codon_table_id_bioperl instead.");
    return $codon_table_id_bioperl;
  }

  return $codon_table_id_original;
}

# @Purpose: allows to add a frame to a string to print
# @input: 4 =>  String (What has to be printed), int (size of the canevas),
#               char (character to use to make the frame), String (extra to print at the end after the frame)
# @output 1 => String
sub printSurrounded{
  my ($term, $size, $char, $extra) = @_;

   my $frame=$char x ($size+4);
  $frame.="\n";

  my $result = $frame;

  my @lines = split(/\n/,$term);

  	foreach my $line (@lines){

			while ( defined($line) ){
				$result .="$char ";

	  		my $sizeTerm=length($line);
		  	if ($sizeTerm > $size ){
			    my $lineout = substr($line, 0,($size),"");
					$lineout .= " $char\n";
					#print "l1 $lineout";
					$result .= $lineout;
		 	 	}
		 		else{
			    my $nbBlancBefore=int(($size-$sizeTerm) / 2);
			    my $nbBlancAfter = ($size-$sizeTerm) - $nbBlancBefore;
			    my $lineout =  " " x $nbBlancBefore;
			    $lineout .= $line;
			    $lineout .= " " x $nbBlancAfter;
					$lineout .= " $char\n";
					$result .= $lineout;
					$line  = undef;
					#print "l2 $lineout";
		  	}
			}
	}
	$result .= "$frame";
	if($extra){$result .= "$extra";}
	print $result;
}

# @Purpose: Print a String in a specified String size. Add space before and after String to
# center it in a decided String Size. If String is longer that Int, we shrink it.
# @input: 3 => String (to be print), Int (size to print the string), option to print left (L) or right (R) default is center
# @output 1 => String
sub sizedPrint{
  my ($term,$size, $side) = @_;
  my $result;
  my $sizeTerm = (defined($term)) ? length($term) : 0; #defnined to deal with string/int 0
  if ($sizeTerm > $size ){
    $result=substr($term, 0,$size);
    return $result;
  }
  else{
    my $nbBlanc=$size-$sizeTerm;

    my $float = $nbBlanc/2;
    my $nbBlanc_before = sprintf "%.0f", $float;
    my $nbBlanc_after = $nbBlanc - $nbBlanc_before;

		#print left instead of center
		if($side and lc($side) eq "l"){
			$nbBlanc_before = 1;
			$nbBlanc_after = $nbBlanc - 1;
		}
		#print right instead of center
		elsif($side and lc($side) eq "r"){
			$nbBlanc_before = $nbBlanc - 1;
			$nbBlanc_after = 1;
		}

    $result="";
    for (my $i = 0; $i < $nbBlanc_before; $i++){
      $result.=" ";
    }
    $result.=$term;
    for (my $i = 0; $i < $nbBlanc_after; $i++){
      $result.=" ";
    }
    return $result;
  }
}

# the warning message will be filtered to be printed only $nb_warnings times
# To use it in a script do: my %warnings; activate_warning_limit(\%warnings, $nb_warnings);
# @input: 2 => empty hash, Int
# @output 0 => None
sub activate_warning_limit{
	my ($warnings_hash,$nb_warnings) = @_;

	if (! $nb_warnings){ $nb_warnings = 10;} # Handle to not print to much warning

		$SIG{__WARN__} = sub {
		my $message = shift;

		$warnings_hash->{$message}++;

		if ($warnings_hash->{$message} <= $nb_warnings){
			print "WARNING: ".$message;
		}
		if($warnings_hash->{$message} == $nb_warnings){
			print "************** Too much WARNING of this type we skip the next **************\n";
		}
	};
}

1;
