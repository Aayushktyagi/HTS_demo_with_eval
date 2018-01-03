#!/usr/bin/perl

$| = 1;

if ( @ARGV < 1 ) {
   print "usage: Training.pl Config.pm\n";
   exit(0);
}

# load configuration variables
require( $ARGV[0] );

# model structure
foreach $set (@SET) {
   $vSize{$set}{'total'}   = 0;
   $nstream{$set}{'total'} = 0;
   $nPdfStreams{$set}      = 0;
   foreach $type ( @{ $ref{$set} } ) {
      $vSize{$set}{$type} = $nwin{$type} * $ordr{$type};
      $vSize{$set}{'total'} += $vSize{$set}{$type};
      $nstream{$set}{$type} = $stre{$type} - $strb{$type} + 1;
      $nstream{$set}{'total'} += $nstream{$set}{$type};
      $nPdfStreams{$set}++;
   }
}

# File locations =========================
# data directory
$datdir = "$prjdir/data";

# data location file
$scp{'trn'} = "$datdir/scp/train.cmp.scp";
$scp{'gen'} = "$datdir/scp/gen.lab.scp";

# model list files
$lst{'mon'} = "$datdir/lists/mono.list";
$lst{'ful'} = "$datdir/lists/full.list";
$lst{'all'} = "$datdir/lists/full_all.list";

# master label files
$mlf{'mon'} = "$datdir/labels/mono.mlf";
$mlf{'ful'} = "$datdir/labels/full.mlf";

# configuration variable files
$cfg{'trn'} = "$prjdir/configs/ver${ver}/trn.cnf";
$cfg{'nvf'} = "$prjdir/configs/ver${ver}/nvf.cnf";
$cfg{'syn'} = "$prjdir/configs/ver${ver}/syn.cnf";
$cfg{'apg'} = "$prjdir/configs/ver${ver}/apg.cnf";
$cfg{'stc'} = "$prjdir/configs/ver${ver}/stc.cnf";
foreach $type (@cmp) {
   $cfg{$type} = "$prjdir/configs/ver${ver}/${type}.cnf";
}
foreach $type (@dur) {
   $cfg{$type} = "$prjdir/configs/ver${ver}/${type}.cnf";
}

# name of proto type definition file
$prtfile{'cmp'} = "$prjdir/proto/ver${ver}/state-${nState}_stream-$nstream{'cmp'}{'total'}";
foreach $type (@cmp) {
   $prtfile{'cmp'} .= "_${type}-$vSize{'cmp'}{$type}";
}
$prtfile{'cmp'} .= ".prt";

# model files
foreach $set (@SET) {
   $model{$set}   = "$prjdir/models/ver${ver}/${set}";
   $hinit{$set}   = "$model{$set}/HInit";
   $hrest{$set}   = "$model{$set}/HRest";
   $vfloors{$set} = "$model{$set}/vFloors";
   $avermmf{$set} = "$model{$set}/average.mmf";
   $initmmf{$set} = "$model{$set}/init.mmf";
   $monommf{$set} = "$model{$set}/monophone.mmf";
   $fullmmf{$set} = "$model{$set}/fullcontext.mmf";
   $clusmmf{$set} = "$model{$set}/clustered.mmf";
   $untymmf{$set} = "$model{$set}/untied.mmf";
   $reclmmf{$set} = "$model{$set}/re_clustered.mmf";
   $rclammf{$set} = "$model{$set}/re_clustered_all.mmf";
   $tiedlst{$set} = "$model{$set}/tiedlist";
   $stcmmf{$set}  = "$model{$set}/stc.mmf";
   $stcammf{$set} = "$model{$set}/stc_all.mmf";
   $stcbase{$set} = "$model{$set}/stc.base";
}

# statistics files
foreach $set (@SET) {
   $stats{$set} = "$prjdir/stats/ver${ver}/${set}.stats";
}

# model edit files
foreach $set (@SET) {
   $hed{$set} = "$prjdir/edfiles/ver${ver}/${set}";
   $lvf{$set} = "$hed{$set}/lvf.hed";
   $m2f{$set} = "$hed{$set}/m2f.hed";
   $mku{$set} = "$hed{$set}/mku.hed";
   $unt{$set} = "$hed{$set}/unt.hed";
   $upm{$set} = "$hed{$set}/upm.hed";
   foreach $type ( @{ $ref{$set} } ) {
      $cnv{$type} = "$hed{$set}/cnv_$type.hed";
      $cxc{$type} = "$hed{$set}/cxc_$type.hed";
   }
}

# questions about contexts
foreach $set (@SET) {
   foreach $type ( @{ $ref{$set} } ) {
      $qs{$type}     = "$datdir/questions/questions_${qname}.hed";
      $qs_utt{$type} = "$datdir/questions/questions_utt_${qname}.hed";
   }
}

# decision tree files
foreach $set (@SET) {
   $trd{$set} = "${prjdir}/trees/ver${ver}/${set}";
   foreach $type ( @{ $ref{$set} } ) {
      $mdl{$type} = "-m -a $mdlf{$type}" if ( $thr{$type} eq '000' );
      $tre{$type} = "$trd{$set}/${type}.inf";
   }
}

# converted model & tree files for hts_engine
$voice = "$prjdir/voices/ver${ver}";
foreach $set (@SET) {
   foreach $type ( @{ $ref{$set} } ) {
      $trv{$type} = "$voice/tree-${type}.inf";
      $pdf{$type} = "$voice/${type}.pdf";
   }
}
$type       = 'lpf';
$trv{$type} = "$voice/tree-${type}.inf";
$pdf{$type} = "$voice/${type}.pdf";

# window files for parameter generation
$windir = "${datdir}/win";
foreach $type (@cmp) {
   for ( $d = 1 ; $d <= $nwin{$type} ; $d++ ) {
      $win{$type}[ $d - 1 ] = "${type}.win${d}";
   }
}
$type                 = 'lpf';
$d                    = 1;
$win{$type}[ $d - 1 ] = "${type}.win${d}";

# global variance files and directories for parameter generation
$gvdir           = "$prjdir/gv/ver${ver}";
$gvfaldir{'phn'} = "$gvdir/fal/phone";
$gvfaldir{'stt'} = "$gvdir/fal/state";
$gvdatdir        = "$gvdir/dat";
$gvlabdir        = "$gvdir/lab";
$gvmodels        = "$gvdir/models";
$scp{'gv'}       = "$gvdir/gv.scp";
$mlf{'gv'}       = "$gvdir/gv.mlf";
$lst{'gv'}       = "$gvdir/gv.list";
$stats{'gv'}     = "$gvdir/stats/gv.stats";
$prtfile{'gv'}   = "$gvdir/proto/state-1_stream-${nPdfStreams{'cmp'}}";
foreach $type (@cmp) {
   $prtfile{'gv'} .= "_${type}-$ordr{$type}";
}
$prtfile{'gv'} .= ".prt";
$vfloors{'gv'} = "$gvmodels/vFloors";
$avermmf{'gv'} = "$gvmodels/average.mmf";
$fullmmf{'gv'} = "$gvmodels/fullcontext.mmf";
$clusmmf{'gv'} = "$gvmodels/clustered.mmf";
$clsammf{'gv'} = "$gvmodels/clustered_all.mmf";
$tiedlst{'gv'} = "$gvmodels/tiedlist";
$mku{'gv'}     = "$gvdir/edfiles/mku.hed";

foreach $type (@cmp) {
   $gvcnv{$type} = "$gvdir/edfiles/cnv_$type.hed";
   $gvcxc{$type} = "$gvdir/edfiles/cxc_$type.hed";
   $gvmdl{$type} = "-m -a $gvmdlf{$type}" if ( $gvthr{$type} eq '000' );
   $gvtre{$type} = "$gvdir/trees/${type}.inf";
   $gvpdf{$type} = "$voice/gv-${type}.pdf";
   $gvtrv{$type} = "$voice/tree-gv-${type}.inf";
}

# files and directories for modulation spectrum-based postfilter
$mspfdir     = "$prjdir/mspf/ver${ver}";
$mspffaldir  = "$mspfdir/fal";
$scp{'mspf'} = "$mspfdir/fal.scp";
foreach $type ('mgc') {
   foreach $mspftype ( "nat", "gen/1mix/$pgtype" ) {
      $mspfdatdir{$mspftype}   = "$mspfdir/dat/$mspftype";
      $mspfstatsdir{$mspftype} = "$mspfdir/stats/$mspftype";
      for ( $d = 0 ; $d < $ordr{$type} ; $d++ ) {
         $mspfmean{$type}{$mspftype}[$d] = "$mspfstatsdir{$mspftype}/${type}_dim$d.mean";
         $mspfstdd{$type}{$mspftype}[$d] = "$mspfstatsdir{$mspftype}/${type}_dim$d.stdd";
      }
   }
}

# files and directories for neural networks
$dnndir           = "$prjdir/dnn/ver${ver}";
$dnnffidir{'ful'} = "$dnndir/ffi/full";
$dnnffidir{'gen'} = "$dnndir/ffi/gen";
$dnnmodels        = "$dnndir/models";
$scp{'fio'}       = "$dnndir/train.ffi-ffo.scp";
$scp{'ffi'}       = "$dnndir/gen.ffi.scp";
$cfg{'tdn'}       = "$prjdir/configs/ver${ver}/trn_dnn.cnf";
$cfg{'sdn'}       = "$prjdir/configs/ver${ver}/syn_dnn.cnf";
foreach $type ( @cmp, 'ffo' ) {
   $var{$type} = "$datdir/stats/$type.var";
}
$qconf = "$datdir/configs/$qname.conf";

# HTS Commands & Options ========================
$HCompV{'cmp'} = "$HCOMPV    -A    -C $cfg{'trn'} -D -T 1 -S $scp{'trn'} -m ";
$HCompV{'gv'}  = "$HCOMPV    -A    -C $cfg{'trn'} -D -T 1 -S $scp{'gv'}  -m ";
$HList         = "$HLIST     -A    -C $cfg{'trn'} -D -T 1 -S $scp{'trn'} -h -z ";
$HInit         = "$HINIT     -A    -C $cfg{'trn'} -D -T 1 -S $scp{'trn'}                -m 1 -u tmvw    -w $wf ";
$HRest         = "$HREST     -A    -C $cfg{'trn'} -D -T 1 -S $scp{'trn'}                -m 1 -u tmvw    -w $wf ";
$HERest{'mon'} = "$HEREST    -A    -C $cfg{'trn'} -D -T 1 -S $scp{'trn'} -I $mlf{'mon'} -m 1 -u tmvwdmv -w $wf -t $beam ";
$HERest{'ful'} = "$HEREST    -A -B -C $cfg{'trn'} -D -T 1 -S $scp{'trn'} -I $mlf{'ful'} -m 1 -u tmvwdmv -w $wf -t $beam ";
$HERest{'gv'}  = "$HEREST    -A    -C $cfg{'trn'} -D -T 1 -S $scp{'gv'}  -I $mlf{'gv'}  -m 1 ";
$HHEd{'trn'}   = "$HHED      -A -B -C $cfg{'trn'} -D -T 1 -p -i ";
$HSMMAlign     = "$HSMMALIGN -A    -C $cfg{'trn'} -D -T 1 -S $scp{'trn'} -I $mlf{'ful'}                 -w 1.0 -t $beam ";
$HMGenS        = "$HMGENS    -A -B -C $cfg{'syn'} -D -T 1                                                      -t $beam ";

# =============================================================
# ===================== Main Program ==========================
# =============================================================

# preparing environments
if ($MKENV) {
   print_time("preparing environments");

   # make directories
   foreach $dir ( 'models', 'stats', 'edfiles', 'trees', 'gv', 'mspf', 'dnn', 'voices', 'gen', 'proto', 'configs' ) {
      mkdir "$prjdir/$dir",           0755;
      mkdir "$prjdir/$dir/ver${ver}", 0755;
   }
   foreach $set (@SET) {
      mkdir "$model{$set}", 0755;
      mkdir "$hinit{$set}", 0755;
      mkdir "$hrest{$set}", 0755;
      mkdir "$hed{$set}",   0755;
      mkdir "$trd{$set}",   0755;
   }

   # make config files
   #make_config();

   # make model prototype definition file
   #make_proto();
}

# HCompV (computing variance floors)
#if ($HCMPV) {
#   print_time("computing variance floors");

   # make average model and compute variance floors
#   shell("$HCompV{'cmp'} -M $model{'cmp'} -o $avermmf{'cmp'} $prtfile{'cmp'}");
#   shell("head -n 1 $prtfile{'cmp'} > $initmmf{'cmp'}");
#   shell("cat $vfloors{'cmp'} >> $initmmf{'cmp'}");

#   make_duration_vfloor( $initdurmean, $initdurvari );
#}

# HInit & HRest (initialization & reestimation)
#if ($IN_RE) {
#   print_time("initialization & reestimation");
#
#   if ($daem) {
#      open( LIST, $lst{'mon'} ) || die "Cannot open $!";
#      while ( $phone = <LIST> ) {
#
#         # trimming leading and following whitespace characters
#         $phone =~ s/^\s+//;
#         $phone =~ s/\s+$//;
#
#         # skip a blank line
#         if ( $phone eq '' ) {
#            next;
#         }
#
#         print "=============== $phone ================\n";
#         print "use average model instead of $phone\n";
#         foreach $set (@SET) {
#            open( SRC, "$avermmf{$set}" )       || die "Cannot open $!";
#            open( TGT, ">$hrest{$set}/$phone" ) || die "Cannot open $!";
#            while ( $str = <SRC> ) {
#               if ( index( $str, "~h" ) == 0 ) {
#                  print TGT "~h \"$phone\"\n";
#               }
#               else {
#                  print TGT "$str";
#               }
#            }
#            close(TGT);
#            close(SRC);
#         }
#      }
#      close(LIST);
#   }
#   else {
#      open( LIST, $lst{'mon'} ) || die "Cannot open $!";
#      while ( $phone = <LIST> ) {
#
#         # trimming leading and following whitespace characters
#         $phone =~ s/^\s+//;
#         $phone =~ s/\s+$//;
#
#         # skip a blank line
#         if ( $phone eq '' ) {
#            next;
#         }
#         $lab = $mlf{'mon'};
#
#         if ( grep( $_ eq $phone, keys %mdcp ) <= 0 ) {
#            print "=============== $phone ================\n";
#            shell("$HInit -H $initmmf{'cmp'} -M $hinit{'cmp'} -I $lab -l $phone -o $phone $prtfile{'cmp'}");
#            shell("$HRest -H $initmmf{'cmp'} -M $hrest{'cmp'} -I $lab -l $phone -g $hrest{'dur'}/$phone $hinit{'cmp'}/$phone");
#         }
#      }
#      close(LIST);
#
#      open( LIST, $lst{'mon'} ) || die "Cannot open $!";
#      while ( $phone = <LIST> ) {
#
#         # trimming leading and following whitespace characters
#         $phone =~ s/^\s+//;
#         $phone =~ s/\s+$//;
#
#         # skip a blank line
#         if ( $phone eq '' ) {
#            next;
#         }
#
#         if ( grep( $_ eq $phone, keys %mdcp ) > 0 ) {
#            print "=============== $phone ================\n";
#            print "use $mdcp{$phone} instead of $phone\n";
#            foreach $set (@SET) {
#               open( SRC, "$hrest{$set}/$mdcp{$phone}" ) || die "Cannot open $!";
#               open( TGT, ">$hrest{$set}/$phone" )       || die "Cannot open $!";
#               while (<SRC>) {
#                  s/~h \"$mdcp{$phone}\"/~h \"$phone\"/;
#                  print TGT;
#               }
#               close(TGT);
#               close(SRC);
#            }
#         }
#      }
#      close(LIST);
#   }
#}
#
## HHEd (making a monophone mmf)
#if ($MMMMF) {
#   print_time("making a monophone mmf");
#
#   foreach $set (@SET) {
#      open( EDFILE, ">$lvf{$set}" ) || die "Cannot open $!";
#
#      # load variance floor macro
#      print EDFILE "// load variance flooring macro\n";
#      print EDFILE "FV \"$vfloors{$set}\"\n";
#
#      # tie stream weight macro
#      foreach $type ( @{ $ref{$set} } ) {
#         if ( $strw{$type} != 1.0 ) {
#            print EDFILE "// tie stream weights\n";
#            printf EDFILE "TI SW_all {*.state[%d-%d].weights}\n", 2, $nState + 1;
#            last;
#         }
#      }
#
#      close(EDFILE);
#
#      shell("$HHEd{'trn'} -d $hrest{$set} -w $monommf{$set} $lvf{$set} $lst{'mon'}");
#      shell("gzip -c $monommf{$set} > $monommf{$set}.nonembedded.gz");
#   }
#}
#
## HERest (embedded reestimation (monophone))
#if ($ERST0) {
#   print_time("embedded reestimation (monophone)");
#
#   if ($daem) {
#      for ( $i = 1 ; $i <= $daem_nIte ; $i++ ) {
#         for ( $j = 1 ; $j <= $nIte ; $j++ ) {
#
#            # embedded reestimation
#            $k = $j + ( $i - 1 ) * $nIte;
#            print("\n\nIteration $k of Embedded Re-estimation\n");
#            $k = ( $i / $daem_nIte )**$daem_alpha;
#            shell("$HERest{'mon'} -k $k -H $monommf{'cmp'} -N $monommf{'dur'} -M $model{'cmp'} -R $model{'dur'} $lst{'mon'} $lst{'mon'}");
#         }
#      }
#   }
#   else {
#      for ( $i = 1 ; $i <= $nIte ; $i++ ) {
#
#         # embedded reestimation
#         print("\n\nIteration $i of Embedded Re-estimation\n");
#         shell("$HERest{'mon'} -H $monommf{'cmp'} -N $monommf{'dur'} -M $model{'cmp'} -R $model{'dur'} $lst{'mon'} $lst{'mon'}");
#      }
#   }
#
#   # compress reestimated model
#   foreach $set (@SET) {
#      shell("gzip -c $monommf{$set} > ${monommf{$set}}.embedded.gz");
#   }
#}
#
## HHEd (copying monophone mmf to fullcontext one)
#if ($MN2FL) {
#   print_time("copying monophone mmf to fullcontext one");
#
#   foreach $set (@SET) {
#      open( EDFILE, ">$m2f{$set}" ) || die "Cannot open $!";
#      open( LIST,   "$lst{'mon'}" ) || die "Cannot open $!";
#
#      print EDFILE "// copy monophone models to fullcontext ones\n";
#      print EDFILE "CL \"$lst{'ful'}\"\n\n";    # CLone monophone to fullcontext
#
#      print EDFILE "// tie state transition probability\n";
#      while ( $phone = <LIST> ) {
#
#         # trimming leading and following whitespace characters
#         $phone =~ s/^\s+//;
#         $phone =~ s/\s+$//;
#
#         # skip a blank line
#         if ( $phone eq '' ) {
#            next;
#         }
#         print EDFILE "TI T_${phone} {*-${phone}+*.transP}\n";    # TIe transition prob
#      }
#      close(LIST);
#      close(EDFILE);
#
#      shell("$HHEd{'trn'} -H $monommf{$set} -w $fullmmf{$set} $m2f{$set} $lst{'mon'}");
#      shell("gzip -c $fullmmf{$set} > $fullmmf{$set}.nonembedded.gz");
#   }
#}
#
## HERest (embedded reestimation (fullcontext))
#if ($ERST1) {
#   print_time("embedded reestimation (fullcontext)");
#
#   $opt = "-C $cfg{'nvf'} -s $stats{'cmp'} -w 0.0";
#
#   # embedded reestimation
#   print("\n\nEmbedded Re-estimation\n");
#   shell("$HERest{'ful'} -H $fullmmf{'cmp'} -N $fullmmf{'dur'} -M $model{'cmp'} -R $model{'dur'} $opt $lst{'ful'} $lst{'ful'}");
#
#   # compress reestimated model
#   foreach $set (@SET) {
#      shell("gzip -c $fullmmf{$set} > ${fullmmf{$set}}.embedded.gz");
#   }
#}
#
## HHEd (tree-based context clustering)
#if ($CXCL1) {
#   print_time("tree-based context clustering");
#
#   # convert cmp stats to duration ones
#   convstats();
#
#   # tree-based clustering
#   foreach $set (@SET) {
#      shell("cp $fullmmf{$set} $clusmmf{$set}");
#
#      $footer = "";
#      foreach $type ( @{ $ref{$set} } ) {
#         if ( $strw{$type} > 0.0 ) {
#            make_edfile_state($type);
#            shell("$HHEd{'trn'} -C $cfg{$type} -H $clusmmf{$set} $mdl{$type} -w $clusmmf{$set} $cxc{$type} $lst{'ful'}");
#            $footer .= "_$type";
#            shell("gzip -c $clusmmf{$set} > $clusmmf{$set}$footer.gz");
#         }
#      }
#   }
#}
#
## HERest (embedded reestimation (clustered))
#if ($ERST2) {
#   print_time("embedded reestimation (clustered)");
#
#   for ( $i = 1 ; $i <= $nIte ; $i++ ) {
#      print("\n\nIteration $i of Embedded Re-estimation\n");
#      shell("$HERest{'ful'} -H $clusmmf{'cmp'} -N $clusmmf{'dur'} -M $model{'cmp'} -R $model{'dur'} $lst{'ful'} $lst{'ful'}");
#   }
#
#   # compress reestimated mmfs
#   foreach $set (@SET) {
#      shell("gzip -c $clusmmf{$set} > $clusmmf{$set}.embedded.gz");
#   }
#}
#
## HHEd (untying the parameter sharing structure)
#if ($UNTIE) {
#   print_time("untying the parameter sharing structure");
#
#   foreach $set (@SET) {
#      make_edfile_untie($set);
#      shell("$HHEd{'trn'} -H $clusmmf{$set} -w $untymmf{$set} $unt{$set} $lst{'ful'}");
#   }
#}
#
## fix variables
#foreach $set (@SET) {
#   $stats{$set} .= ".untied";
#   foreach $type ( @{ $ref{$set} } ) {
#      $tre{$type} .= ".untied";
#      $cxc{$type} .= ".untied";
#   }
#}
#
## HERest (embedded reestimation (untied))
#if ($ERST3) {
#   print_time("embedded reestimation (untied)");
#
#   $opt = "-C $cfg{'nvf'} -s $stats{'cmp'} -w 0.0";
#
#   print("\n\nEmbedded Re-estimation for untied mmfs\n");
#   shell("$HERest{'ful'} -H $untymmf{'cmp'} -N $untymmf{'dur'} -M $model{'cmp'} -R $model{'dur'} $opt $lst{'ful'} $lst{'ful'}");
#}
#
# HHEd (tree-based context clustering)
#if ($CXCL2) {
#   print_time("tree-based context clustering");
#
#   # convert cmp stats to duration ones
#   convstats();
#
#   # tree-based clustering
#   foreach $set (@SET) {
#      shell("cp $untymmf{$set} $reclmmf{$set}");
#
#      $footer = "";
#      foreach $type ( @{ $ref{$set} } ) {
#         make_edfile_state($type);
#         shell("$HHEd{'trn'} -C $cfg{$type} -H $reclmmf{$set} $mdl{$type} -w $reclmmf{$set} $cxc{$type} $lst{'ful'}");
#
#         $footer .= "_$type";
#         shell("gzip -c $reclmmf{$set} > $reclmmf{$set}$footer.gz");
#      }
#      shell("gzip -c $reclmmf{$set} > $reclmmf{$set}.nonembedded.gz");
#   }
#}
#
## HERest (embedded reestimation (re-clustered))
#if ($ERST4) {
#   print_time("embedded reestimation (re-clustered)");
#
#   for ( $i = 1 ; $i <= $nIte ; $i++ ) {
#      print("\n\nIteration $i of Embedded Re-estimation\n");
#      shell("$HERest{'ful'} -H $reclmmf{'cmp'} -N $reclmmf{'dur'} -M $model{'cmp'} -R $model{'dur'} $lst{'ful'} $lst{'ful'}");
#   }
#
#   # compress reestimated mmfs
#   foreach $set (@SET) {
#      shell("gzip -c $reclmmf{$set} > $reclmmf{$set}.embedded.gz");
#   }
#}
#
## HSMMAlign (forced alignment for no-silent GV)
#if ($FALGN) {
#   print_time("forced alignment for no-silent GV");
#
#   if ( ( $useGV && $nosilgv && @slnt > 0 ) || $useMSPF || $useDNN ) {
#
#      # make directory
#      mkdir "$gvdir/fal",       0755;
#      mkdir "$gvfaldir{'phn'}", 0755;
#      mkdir "$gvfaldir{'stt'}", 0755;
#
#      # forced alignment
#      shell("$HSMMAlign -f -H $reclmmf{'cmp'} -N $reclmmf{'dur'} -m $gvfaldir{'stt'} $lst{'ful'} $lst{'ful'}");
#
#      # convert state alignment to phoneme alignment
#      convert_state2phone();
#   }
#}
#
## making global variance
#if ($MCDGV) {
#   print_time("making global variance");
#
#   if ($useGV) {
#
#      # make directories
#      mkdir "$gvdatdir",      0755;
#      mkdir "$gvlabdir",      0755;
#      mkdir "$gvmodels",      0755;
#      mkdir "$gvdir/proto",   0755;
#      mkdir "$gvdir/stats",   0755;
#      mkdir "$gvdir/trees",   0755;
#      mkdir "$gvdir/edfiles", 0755;
#
#      # make proto
#      make_proto_gv();
#
#      # make training data, labels, scp, list, and mlf
#      make_data_gv();
#
#      # make average model
#      shell("$HCompV{'gv'} -o $avermmf{'gv'} -M $gvmodels $prtfile{'gv'}");
#
#      if ($cdgv) {
#
#         # make full context depdent model
#         copy_aver2full_gv();
#         shell("$HERest{'gv'} -C $cfg{'nvf'} -s $stats{'gv'} -w 0.0 -H $fullmmf{'gv'} -M $gvmodels $lst{'gv'}");
#
#         # context-clustering
#         my $s = 1;
#         shell("cp $fullmmf{'gv'} $clusmmf{'gv'}");
#         foreach $type (@cmp) {
#            make_edfile_state_gv( $type, $s );
#            shell("$HHEd{'trn'} -H $clusmmf{'gv'} $gvmdl{$type} -w $clusmmf{'gv'} $gvcxc{$type} $lst{'gv'}");
#            $s++;
#         }
#
#         # re-estimation
#         shell("$HERest{'gv'} -H $clusmmf{'gv'} -M $gvmodels $lst{'gv'}");
#      }
#      else {
#         copy_aver2clus_gv();
#      }
#   }
#}
#
## HHEd (making unseen models (GV))
#if ($MKUNG) {
#   print_time("making unseen models (GV)");
#
#   if ($useGV) {
#      if ($cdgv) {
#         make_edfile_mkunseen_gv();
#         shell("$HHEd{'trn'} -H $clusmmf{'gv'} -w $clsammf{'gv'} $mku{'gv'} $lst{'gv'}");
#      }
#      else {
#         copy_clus2clsa_gv();
#      }
#   }
#}
#
## HMGenS & SPTK (training modulation spectrum-based postfilter)
#if ($TMSPF) {
#   print_time("training modulation spectrum-based postfilter");
#
#   if ($useMSPF) {
#
#      $mix     = '1mix';
#      $gentype = "gen/$mix/$pgtype";
#
#      # make directories
#      mkdir "$mspffaldir",               0755;
#      mkdir "$mspfdir/gen",              0755;
#      mkdir "$mspfdir/gen/$mix",         0755;
#      mkdir "$mspfdir/gen/$mix/$pgtype", 0755;
#      foreach $dir ( 'dat', 'stats' ) {
#         mkdir "$mspfdir/$dir",                  0755;
#         mkdir "$mspfdir/$dir/nat",              0755;
#         mkdir "$mspfdir/$dir/gen",              0755;
#         mkdir "$mspfdir/$dir/gen/$mix",         0755;
#         mkdir "$mspfdir/$dir/gen/$mix/$pgtype", 0755;
#      }
#
#      # make scp and fullcontext forced-aligned label files
#      make_full_fal();
#
#      # synthesize speech parameters using model alignment
#      shell("$HMGenS -C $cfg{'apg'} -S $scp{'mspf'} -c $pgtype -H $reclmmf{'cmp'} -N $reclmmf{'dur'} -M $mspfdir/$gentype $lst{'ful'} $lst{'ful'}");
#
#      # estimate statistics for modulation spectrum
#      make_mspf($gentype);
#   }
#}

# HHEd (making unseen models (1mix))
if ($MKUN1) {
   print_time("making unseen models (1mix)");

   foreach $set (@SET) {
      #make_edfile_mkunseen($set);
      #shell("$HHEd{'trn'} -H $reclmmf{$set} -w $rclammf{$set}.1mix $mku{$set} $lst{'ful'}");
      
      make_edfile_mkunseen($set);
      shell("$HHEd{'trn'} -H $clusmmf{'gv'} -w $clsammf{'gv'} $mku{'gv'} $lst{'gv'}");
      #shell("$HHEd{'trn'} -H $clusmmf{$set} -w $untymmf{$set} $unt{$set} $lst{'ful'}");
   }
}

# HMGenS (generating speech parameter sequences (1mix))
if ($PGEN1) {
   print_time("generating speech parameter sequences (1mix)");

   $mix = '1mix';
   $dir = "${prjdir}/gen/ver${ver}/$mix/$pgtype";
   mkdir "${prjdir}/gen/ver${ver}/$mix", 0755;
   mkdir $dir, 0755;

   # generate parameter
   #shell("$HMGenS -S $scp{'gen'} -c $pgtype -H $fullmmf{'cmp'}.$mix -N $fullmmf{'dur'}.$mix -M $dir $tiedlst{'cmp'} $tiedlst{'dur'}");
   shell("$HMGenS -S $scp{'gen'} -c $pgtype -H $clusmmf{'cmp'} -N $clusmmf{'dur'} -M $dir $tiedlst{'cmp'} $tiedlst{'dur'}");
   #shell("$HMGenS -S $scp{'gen'} -c $pgtype -H $untymmf{'cmp'} -N $untymmf{'dur'} -M $dir $tiedlst{'cmp'} $tiedlst{'dur'}");
}

# SPTK (synthesizing waveforms (1mix))
if ($WGEN1) {
   print_time("synthesizing waveforms (1mix)");

   $mix = '1mix';
   $dir = "${prjdir}/gen/ver${ver}/$mix/$pgtype";

   gen_wave("$dir");
}


# sub routine for speech synthesis from log f0 and Mel-cepstral coefficients
sub gen_wave($) {
   my ($gendir) = @_;
   my ( $line, @FILE, $lgopt, $file, $base, $T, $mgc, $lf0, $bap );

   $line = `ls $gendir/*.mgc`;
   @FILE = split( '\n', $line );
   if ($lg) {
      $lgopt = "-L";
   }
   else {
      $lgopt = "";
   }
   print "Processing directory $gendir:\n";
   foreach $file (@FILE) {
      $base = `basename $file .mgc`;
      chomp($base);

      if ( $gm == 0 ) {

         # apply postfiltering
         if ($useMSPF) {
            postfiltering_mspf( $base, $gendir, 'mgc' );
            $mgc = "$gendir/$base.p_mgc";
         }
         elsif ( !$useGV && $pf_mcp != 1.0 ) {
            postfiltering_mcp( $base, $gendir );
            $mgc = "$gendir/$base.p_mgc";
         }
         else {
            $mgc = $file;
         }
      }
      else {

         # apply postfiltering
         if ($useMSPF) {
            postfiltering_mspf( $base, $gendir, 'mgc' );
            $mgc = "$gendir/$base.p_mgc";
         }
         elsif ( !$useGV && $pf_lsp != 1.0 ) {
            postfiltering_lsp( $base, $gendir );
            $mgc = "$gendir/$base.p_mgc";
         }
         else {
            $mgc = $file;
         }

         # MGC-LSPs -> MGC coefficients
         $line = "$LSPCHECK -m " . ( $ordr{'mgc'} - 1 ) . " -s " . ( $sr / 1000 ) . " $lgopt -c -r 0.1 -g -G 1.0E-10 $mgc | ";
         $line .= "$LSP2LPC -m " . ( $ordr{'mgc'} - 1 ) . " -s " . ( $sr / 1000 ) . " $lgopt | ";
         $line .= "$MGC2MGC -m " . ( $ordr{'mgc'} - 1 ) . " -a $fw -c $gm -n -u -M " . ( $ordr{'mgc'} - 1 ) . " -A $fw -C $gm " . " > $gendir/$base.c_mgc";
         shell($line);

         $mgc = "$gendir/$base.c_mgc";
      }

      $lf0 = "$gendir/$base.lf0";
      $bap = "$gendir/$base.bap";

      if ( !$usestraight && -s $file && -s $lf0 ) {
         print " Synthesizing a speech waveform from $base.mgc and $base.lf0...";

         # convert log F0 to pitch
         $line = "$SOPR -magic -1.0E+10 -EXP -INV -m $sr -MAGIC 0.0 $lf0 > $gendir/${base}.pit";
         shell($line);

         # synthesize waveform
         $lfil = `$PERL $datdir/scripts/makefilter.pl $sr 0`;
         $hfil = `$PERL $datdir/scripts/makefilter.pl $sr 1`;

         $line = "$SOPR -m 0 $gendir/$base.pit | $EXCITE -n -p $fs | $DFS -b $hfil > $gendir/$base.unv";
         shell($line);

         $line = "$EXCITE -n -p $fs $gendir/$base.pit | ";
         $line .= "$DFS -b $lfil | $VOPR -a $gendir/$base.unv | ";
         $line .= "$MGLSADF -P 5 -m " . ( $ordr{'mgc'} - 1 ) . " -p $fs -a $fw -c $gm $mgc | ";
         $line .= "$X2X +fs -o > $gendir/$base.raw";
         shell($line);
         $line = "$RAW2WAV -s " . ( $sr / 1000 ) . " -d $gendir $gendir/$base.raw";
         shell($line);

         $line = "rm -f $gendir/$base.unv";
         shell($line);

         print "done\n";
      }
      elsif ( $usestraight && -s $file && -s $lf0 && -s $bap ) {
         print " Synthesizing a speech waveform from $base.mgc, $base.lf0, and $base.bap... ";

         # convert log F0 to F0
         $line = "$SOPR -magic -1.0E+10 -EXP -MAGIC 0.0 $lf0 > $gendir/${base}.f0 ";
         shell($line);
         $T = get_file_size("$gendir/${base}.f0 ") / 4;

         # convert Mel-cepstral coefficients to spectrum
         if ( $gm == 0 ) {
            shell( "$MGC2SP -a $fw -g $gm -m " . ( $ordr{'mgc'} - 1 ) . " -l $ft -o 2 $mgc > $gendir/$base.sp" );
         }
         else {
            shell( "$MGC2SP -a $fw -c $gm -m " . ( $ordr{'mgc'} - 1 ) . " -l $ft -o 2 $mgc > $gendir/$base.sp" );
         }

         # convert band-aperiodicity to aperiodicity
         shell( "$MGC2SP -a $fw -g 0 -m " . ( $ordr{'bap'} - 1 ) . " -l $ft -o 0 $bap > $gendir/$base.ap" );

         # synthesize waveform
         open( SYN, ">$gendir/${base}.m" ) || die "Cannot open $!";
         printf SYN "path(path,'%s');\n",                 ${STRAIGHT};
         printf SYN "prm.spectralUpdateInterval = %f;\n", 1000.0 * $fs / $sr;
         printf SYN "prm.levelNormalizationIndicator = 0;\n\n";
         printf SYN "fprintf(1,'\\nSynthesizing %s\\n');\n", "$gendir/$base.wav";
         printf SYN "fid1 = fopen('%s','r','%s');\n",        "$gendir/$base.sp", "ieee-le";
         printf SYN "fid2 = fopen('%s','r','%s');\n",        "$gendir/$base.ap", "ieee-le";
         printf SYN "fid3 = fopen('%s','r','%s');\n",        "$gendir/$base.f0", "ieee-le";
         printf SYN "sp = fread(fid1,[%d, %d],'float');\n", ( $ft / 2 + 1 ), $T;
         printf SYN "ap = fread(fid2,[%d, %d],'float');\n", ( $ft / 2 + 1 ), $T;
         printf SYN "f0 = fread(fid3,[%d, %d],'float');\n", 1, $T;
         printf SYN "fclose(fid1);\n";
         printf SYN "fclose(fid2);\n";
         printf SYN "fclose(fid3);\n";
         printf SYN "sp = sp/32768.0;\n";
         printf SYN "[sy] = exstraightsynth(f0,sp,ap,%d,prm);\n", $sr;
         printf SYN "wavwrite(sy,%d,'%s');\n\n", $sr, "$gendir/$base.wav";
         printf SYN "quit;\n";
         close(SYN);
         shell("$MATLAB < $gendir/${base}.m");

         $line = "rm -f $gendir/$base.m";
         shell($line);

         print "done\n";
      }
   }
}
sub print_time ($) {
   my ($message) = @_;
   my ($ruler);

   $message .= `date`;

   $ruler = '';
   for ( $i = 0 ; $i <= length($message) + 10 ; $i++ ) {
      $ruler .= '=';
   }

   print "\n$ruler\n";
   print "Start @_ at " . `date`;
   print "$ruler\n\n";
}
sub shell($) {
   my ($command) = @_;
   my ($exit);

   $exit = system($command);

   if ( $exit / 256 != 0 ) {
      die "Error in $command\n";
   }
}
sub make_edfile_mkunseen($) {
   my ($set) = @_;
   my ($type);

   open( EDFILE, ">$mku{$set}" ) || die "Cannot open $!";
   print EDFILE "\nTR 2\n\n";
   foreach $type ( @{ $ref{$set} } ) {
      print EDFILE "// load trees for $type\n";
      print EDFILE "LT \"$tre{$type}\"\n\n";
   }

   print EDFILE "// make unseen model\n";
   print EDFILE "AU \"$lst{'all'}\"\n\n";
   print EDFILE "// make model compact\n";
   print EDFILE "CO \"$tiedlst{$set}\"\n\n";

   close(EDFILE);
}
sub postfiltering_mspf($$$) {
   my ( $base, $gendir, $type ) = @_;
   my ( $gentype, $T, $line, $d, @seq );

   $gentype = $gendir;
   $gentype =~ s/$prjdir\/gen\/ver$ver\/+/gen\//g;
   $T = get_file_size("$gendir/$base.$type") / $ordr{$type} / 4;

   # subtract utterance-level mean
   $line = get_cmd_utmean( "$gendir/$base.$type", $type );
   shell("$line > $gendir/$base.$type.mean");
   $line = get_cmd_vopr( "$gendir/$base.$type", "-s", "$gendir/$base.$type.mean", $type );
   shell("$line > $gendir/$base.$type.subtracted");

   for ( $d = 0 ; $d < $ordr{$type} ; $d++ ) {

      # calculate modulation spectrum/phase
      $line = get_cmd_seq2ms( "$gendir/$base.$type.subtracted", $type, $d );
      shell("$line > $gendir/$base.$type.mspec_dim$d");
      $line = get_cmd_seq2mp( "$gendir/$base.$type.subtracted", $type, $d );
      shell("$line > $gendir/$base.$type.mphase_dim$d");

      # convert
      $line = "cat $gendir/$base.$type.mspec_dim$d | ";
      $line .= "$VOPR -l " . ( $mspfFFTLen / 2 + 1 ) . " -s $mspfmean{$type}{$gentype}[$d] | ";
      $line .= "$VOPR -l " . ( $mspfFFTLen / 2 + 1 ) . " -d $mspfstdd{$type}{$gentype}[$d] | ";
      $line .= "$VOPR -l " . ( $mspfFFTLen / 2 + 1 ) . " -m $mspfstdd{$type}{'nat'}[$d] | ";
      $line .= "$VOPR -l " . ( $mspfFFTLen / 2 + 1 ) . " -a $mspfmean{$type}{'nat'}[$d] | ";

      # apply weight
      $line .= "$VOPR -l " . ( $mspfFFTLen / 2 + 1 ) . " -s $gendir/$base.$type.mspec_dim$d | ";
      $line .= "$SOPR -m $mspfe{$type} | ";
      $line .= "$VOPR -l " . ( $mspfFFTLen / 2 + 1 ) . " -a $gendir/$base.$type.mspec_dim$d > $gendir/$base.p_$type.mspec_dim$d";
      shell($line);

      # calculate filtered sequence
      push( @seq, msmp2seq( "$gendir/$base.p_$type.mspec_dim$d", "$gendir/$base.$type.mphase_dim$d", $T ) );
   }
   open( SEQ, ">$gendir/$base.tmp" ) || die "Cannot open $!";
   print SEQ join( "\n", @seq );
   close(SEQ);
   shell("$X2X +af $gendir/$base.tmp | $TRANSPOSE -m $ordr{$type} -n $T > $gendir/$base.p_$type.subtracted");

   # add utterance-level mean
   $line = get_cmd_vopr( "$gendir/$base.p_$type.subtracted", "-a", "$gendir/$base.$type.mean", $type );
   shell("$line > $gendir/$base.p_$type");

   # remove temporal files
   shell("rm -f $gendir/$base.$type.mspec_dim* $gendir/$base.$type.mphase_dim* $gendir/$base.p_$type.mspec_dim*");
   shell("rm -f $gendir/$base.$type.subtracted $gendir/$base.p_$type.subtracted $gendir/$base.$type.mean $gendir/$base.$type.tmp");
}
sub postfiltering_lsp($$) {
   my ( $base, $gendir ) = @_;
   my ( $file, $lgopt, $line, $i, @lsp, $d_1, $d_2, $plsp, $data );

   $file = "$gendir/${base}.mgc";
   if ($lg) {
      $lgopt = "-L";
   }
   else {
      $lgopt = "";
   }

   $line = "$LSPCHECK -m " . ( $ordr{'mgc'} - 1 ) . " -s " . ( $sr / 1000 ) . " $lgopt -c -r 0.1 -g -G 1.0E-10 $file | ";
   $line .= "$LSP2LPC -m " . ( $ordr{'mgc'} - 1 ) . " -s " .                     ( $sr / 1000 ) . " $lgopt | ";
   $line .= "$MGC2MGC -m " . ( $ordr{'mgc'} - 1 ) . " -a $fw -c $gm -n -u -M " . ( $fl - 1 ) . " -A 0.0 -G 1.0 | ";
   $line .= "$SOPR -P | $VSUM -t $fl | $SOPR -LN -m 0.5 > $gendir/${base}.ene1";
   shell($line);

   # postfiltering
   open( LSP,  "$X2X +fa < $gendir/${base}.mgc |" );
   open( GAIN, ">$gendir/${base}.gain" );
   open( PLSP, ">$gendir/${base}.lsp" );
   while (1) {
      @lsp = ();
      for ( $i = 0 ; $i < $ordr{'mgc'} && ( $line = <LSP> ) ; $i++ ) {
         push( @lsp, $line );
      }
      if ( $ordr{'mgc'} != @lsp ) { last; }

      $data = pack( "f", $lsp[0] );
      print GAIN $data;
      for ( $i = 1 ; $i < $ordr{'mgc'} ; $i++ ) {
         if ( $i > 1 && $i < $ordr{'mgc'} - 1 ) {
            $d_1 = $pf_lsp * ( $lsp[ $i + 1 ] - $lsp[$i] );
            $d_2 = $pf_lsp * ( $lsp[$i] - $lsp[ $i - 1 ] );
            $plsp = $lsp[ $i - 1 ] + $d_2 + ( $d_2 * $d_2 * ( ( $lsp[ $i + 1 ] - $lsp[ $i - 1 ] ) - ( $d_1 + $d_2 ) ) ) / ( ( $d_2 * $d_2 ) + ( $d_1 * $d_1 ) );
         }
         else {
            $plsp = $lsp[$i];
         }
         $data = pack( "f", $plsp );
         print PLSP $data;
      }
   }
   close(PLSP);
   close(GAIN);
   close(LSP);

   $line = "$MERGE -s 1 -l 1 -L " . ( $ordr{'mgc'} - 1 ) . " -N " . ( $ordr{'mgc'} - 2 ) . " $gendir/${base}.lsp < $gendir/${base}.gain | ";
   $line .= "$LSPCHECK -m " . ( $ordr{'mgc'} - 1 ) . " -s " .                     ( $sr / 1000 ) . " $lgopt -c -r 0.1 -g -G 1.0E-10 | ";
   $line .= "$LSP2LPC -m " .  ( $ordr{'mgc'} - 1 ) . " -s " .                     ( $sr / 1000 ) . " $lgopt | ";
   $line .= "$MGC2MGC -m " .  ( $ordr{'mgc'} - 1 ) . " -a $fw -c $gm -n -u -M " . ( $fl - 1 ) . " -A 0.0 -G 1.0 | ";
   $line .= "$SOPR -P | $VSUM -t $fl | $SOPR -LN -m 0.5 > $gendir/${base}.ene2 ";
   shell($line);

   $line = "$VOPR -l 1 -d $gendir/${base}.ene2 $gendir/${base}.ene2 | $SOPR -LN -m 0.5 | ";
   $line .= "$VOPR -a $gendir/${base}.gain | ";
   $line .= "$MERGE -s 1 -l 1 -L " . ( $ordr{'mgc'} - 1 ) . " -N " . ( $ordr{'mgc'} - 2 ) . " $gendir/${base}.lsp > $gendir/${base}.p_mgc";
   shell($line);

   $line = "rm -f $gendir/${base}.ene1 $gendir/${base}.ene2 $gendir/${base}.gain $gendir/${base}.lsp";
   shell($line);
}
sub make_proto_gv {
   my ( $s, $type, $k );

   open( PROTO, "> $prtfile{'gv'}" ) || die "Cannot open $!";
   $s = 0;
   foreach $type (@cmp) {
      $s += $ordr{$type};
   }
   print PROTO "~o <VecSize> $s <USER> <DIAGC>\n";
   print PROTO "<MSDInfo> $nPdfStreams{'cmp'} ";
   foreach $type (@cmp) {
      print PROTO "0 ";
   }
   print PROTO "\n";
   print PROTO "<StreamInfo> $nPdfStreams{'cmp'} ";
   foreach $type (@cmp) {
      print PROTO "$ordr{$type} ";
   }
   print PROTO "\n";
   print PROTO "<BeginHMM>\n";
   print PROTO "  <NumStates> 3\n";
   print PROTO "  <State> 2\n";
   $s = 1;
   foreach $type (@cmp) {
      print PROTO "  <Stream> $s\n";
      print PROTO "    <Mean> $ordr{$type}\n";
      for ( $k = 1 ; $k <= $ordr{$type} ; $k++ ) {
         print PROTO "      " if ( $k % 10 == 1 );
         print PROTO "0.0 ";
         print PROTO "\n" if ( $k % 10 == 0 );
      }
      print PROTO "\n" if ( $k % 10 != 1 );
      print PROTO "    <Variance> $ordr{$type}\n";
      for ( $k = 1 ; $k <= $ordr{$type} ; $k++ ) {
         print PROTO "      " if ( $k % 10 == 1 );
         print PROTO "1.0 ";
         print PROTO "\n" if ( $k % 10 == 0 );
      }
      print PROTO "\n" if ( $k % 10 != 1 );
      $s++;
   }
   print PROTO "  <TransP> 3\n";
   print PROTO "    0.000e+0 1.000e+0 0.000e+0 \n";
   print PROTO "    0.000e+0 0.000e+0 1.000e+0 \n";
   print PROTO "    0.000e+0 0.000e+0 0.000e+0 \n";
   print PROTO "<EndHMM>\n";
   close(PROTO);
}
sub make_data_gv {
   my ( $type, $cmp, $base, $str, @arr, $start, $end, $find, $i, $j );

   shell("rm -f $scp{'gv'}");
   shell("touch $scp{'gv'}");
   open( SCP, $scp{'trn'} ) || die "Cannot open $!";
   if ($cdgv) {
      open( LST, "> $gvdir/tmp.list" );
   }
   while (<SCP>) {
      $cmp = $_;
      chomp($cmp);
      $base = `basename $cmp .cmp`;
      chomp($base);
      print " Making data, labels, and scp from $base.lab for GV...";
      shell("rm -f $gvdatdir/tmp.cmp");
      shell("touch $gvdatdir/tmp.cmp");
      $i = 0;

      foreach $type (@cmp) {
         if ( $nosilgv && @slnt > 0 ) {
            shell("rm -f $gvdatdir/tmp.$type");
            shell("touch $gvdatdir/tmp.$type");
            open( F, "$gvfaldir{'phn'}/$base.lab" ) || die "Cannot open $!";
            while ( $str = <F> ) {
               chomp($str);
               @arr = split( / /, $str );
               $find = 0;
               for ( $j = 0 ; $j < @slnt ; $j++ ) {
                  if ( $arr[2] eq "$slnt[$j]" ) { $find = 1; last; }
               }
               if ( $find == 0 ) {
                  $start = int( $arr[0] * ( 1.0e-7 / ( $fs / $sr ) ) );
                  $end   = int( $arr[1] * ( 1.0e-7 / ( $fs / $sr ) ) );
                  shell("$BCUT -s $start -e $end -l $ordr{$type} < $datdir/$type/$base.$type >> $gvdatdir/tmp.$type");
               }
            }
            close(F);
         }
         else {
            shell("cp $datdir/$type/$base.$type $gvdatdir/tmp.$type");
         }
         if ( $msdi{$type} == 0 ) {
            shell("cat      $gvdatdir/tmp.$type                              | $VSTAT -d -l $ordr{$type} -o 2 >> $gvdatdir/tmp.cmp");
         }
         else {
            shell("$X2X +fa $gvdatdir/tmp.$type | grep -v '1e+10' | $X2X +af | $VSTAT -d -l $ordr{$type} -o 2 >> $gvdatdir/tmp.cmp");
         }
         system("rm -f $gvdatdir/tmp.$type");
         $i += 4 * $ordr{$type};
      }
      shell("$PERL $datdir/scripts/addhtkheader.pl $sr $fs $i 9 $gvdatdir/tmp.cmp > $gvdatdir/$base.cmp");
      $i = `$NAN $gvdatdir/$base.cmp`;
      chomp($i);
      if ( length($i) > 0 ) {
         shell("rm -f $gvdatdir/$base.cmp");
      }
      else {
         shell("echo $gvdatdir/$base.cmp >> $scp{'gv'}");
         if ($cdgv) {
            open( LAB, "$datdir/labels/full/$base.lab" ) || die "Cannot open $!";
            $str = <LAB>;
            close(LAB);
            chomp($str);
            while ( index( $str, " " ) >= 0 || index( $str, "\t" ) >= 0 ) { substr( $str, 0, 1 ) = ""; }
            open( LAB, "> $gvlabdir/$base.lab" ) || die "Cannot open $!";
            print LAB "$str\n";
            close(LAB);
            print LST "$str\n";
         }
      }
      system("rm -f $gvdatdir/tmp.cmp");
      print "done\n";
   }
   if ($cdgv) {
      close(LST);
      system("sort -u $gvdir/tmp.list > $lst{'gv'}");
      system("rm -f $gvdir/tmp.list");
   }
   else {
      system("echo gv > $lst{'gv'}");
   }
   close(SCP);

   # make mlf
   open( MLF, "> $mlf{'gv'}" ) || die "Cannot open $!";
   print MLF "#!MLF!#\n";
   print MLF "\"*/*.lab\" -> \"$gvlabdir\"\n";
   close(MLF);
}
sub copy_aver2full_gv {
   my ( $find, $head, $tail, $str );

   $find = 0;
   $head = "";
   $tail = "";
   open( MMF, "$avermmf{'gv'}" ) || die "Cannot open $!";
   while ( $str = <MMF> ) {
      if ( index( $str, "~h" ) >= 0 ) {
         $find = 1;
      }
      elsif ( $find == 0 ) {
         $head .= $str;
      }
      else {
         $tail .= $str;
      }
   }
   close(MMF);
   $head .= `cat $vfloors{'gv'}`;
   open( LST, "$lst{'gv'}" )       || die "Cannot open $!";
   open( MMF, "> $fullmmf{'gv'}" ) || die "Cannot open $!";
   print MMF "$head";
   while ( $str = <LST> ) {
      chomp($str);
      print MMF "~h \"$str\"\n";
      print MMF "$tail";
   }
   close(MMF);
   close(LST);
}
sub make_edfile_state_gv($$) {
   my ( $type, $s ) = @_;
   my (@lines);

   open( QSFILE, "$qs_utt{$type}" ) || die "Cannot open $!";
   @lines = <QSFILE>;
   close(QSFILE);

   open( EDFILE, ">$gvcxc{$type}" ) || die "Cannot open $!";
   if ($cdgv) {
      print EDFILE "// load stats file\n";
      print EDFILE "RO $gvgam{$type} \"$stats{'gv'}\"\n";
      print EDFILE "TR 0\n\n";
      print EDFILE "// questions for decision tree-based context clustering\n";
      print EDFILE @lines;
      print EDFILE "TR 3\n\n";
      print EDFILE "// construct decision trees\n";
      print EDFILE "TB $gvthr{$type} gv_${type}_ {*.state[2].stream[$s]}\n";
      print EDFILE "\nTR 1\n\n";
      print EDFILE "// output constructed trees\n";
      print EDFILE "ST \"$gvtre{$type}\"\n";
   }
   else {
      open( TREE, ">$gvtre{$type}" ) || die "Cannot open $!";
      print TREE " {*}[2].stream[$s]\n   \"gv_${type}_1\"\n";
      close(TREE);
      print EDFILE "// construct tying structure\n";
      print EDFILE "TI gv_${type}_1 {*.state[2].stream[$s]}\n";
   }
   close(EDFILE);
}
sub copy_aver2clus_gv {
   my ( $find, $head, $mid, $tail, $str, $tmp, $s, @pdfs );

   # initaialize
   $find = 0;
   $head = "";
   $mid  = "";
   $tail = "";
   $s    = 0;
   @pdfs = ();
   foreach $type (@cmp) {
      push( @pdfs, "" );
   }

   # load
   open( MMF, "$avermmf{'gv'}" ) || die "Cannot open $!";
   while ( $str = <MMF> ) {
      if ( index( $str, "~h" ) >= 0 ) {
         $head .= `cat $vfloors{'gv'}`;
         last;
      }
      else {
         $head .= $str;
      }
   }
   while ( $str = <MMF> ) {
      if ( index( $str, "<STREAM>" ) >= 0 ) {
         last;
      }
      else {
         $mid .= $str;
      }
   }
   while ( $str = <MMF> ) {
      if ( index( $str, "<TRANSP>" ) >= 0 ) {
         $tail .= $str;
         last;
      }
      elsif ( index( $str, "<STREAM>" ) >= 0 ) {
         $s++;
      }
      else {
         $pdfs[$s] .= $str;
      }
   }
   while ( $str = <MMF> ) {
      $tail .= $str;
   }
   close(MMF);

   # save
   open( MMF, "> $clusmmf{'gv'}" ) || die "Cannot open $!";
   print MMF "$head";
   $s = 1;
   foreach $type (@cmp) {
      print MMF "~p \"gv_${type}_1\"\n";
      print MMF "<STREAM> $s\n";
      print MMF "$pdfs[$s-1]";
      $s++;
   }
   print MMF "~h \"gv\"\n";
   print MMF "$mid";
   $s = 1;
   foreach $type (@cmp) {
      print MMF "<STREAM> $s\n";
      print MMF "~p \"gv_${type}_1\"\n";
      $s++;
   }
   print MMF "$tail";
   close(MMF);
   close(LST);
}
sub copy_clus2clsa_gv {
   shell("cp $clusmmf{'gv'} $clsammf{'gv'}");
   shell("cp $lst{'gv'} $tiedlst{'gv'}");
}
sub make_edfile_mkunseen_gv {
   my ($type);

   open( EDFILE, ">$mku{'gv'}" ) || die "Cannot open $!";
   print EDFILE "\nTR 2\n\n";
   foreach $type (@cmp) {
      print EDFILE "// load trees for $type\n";
      print EDFILE "LT \"$gvtre{$type}\"\n\n";
   }

   print EDFILE "// make unseen model\n";
   print EDFILE "AU \"$lst{'all'}\"\n\n";
   print EDFILE "// make model compact\n";
   print EDFILE "CO \"$tiedlst{'gv'}\"\n\n";

   close(EDFILE);
}
sub make_full_fal() {
   my ( $line, $base, $istr, $lstr, @iarr, @larr );

   open( ISCP, "$scp{'trn'}" )   || die "Cannot open $!";
   open( OSCP, ">$scp{'mspf'}" ) || die "Cannot open $!";

   while (<ISCP>) {
      $line = $_;
      chomp($line);
      $base = `basename $line .cmp`;
      chomp($base);

      open( LAB,  "$datdir/labels/full/$base.lab" ) || die "Cannot open $!";
      open( IFAL, "$gvfaldir{'phn'}/$base.lab" )    || die "Cannot open $!";
      open( OFAL, ">$mspffaldir/$base.lab" )        || die "Cannot open $!";

      while ( ( $istr = <IFAL> ) && ( $lstr = <LAB> ) ) {
         chomp($istr);
         chomp($lstr);
         @iarr = split( / /, $istr );
         @larr = split( / /, $lstr );
         print OFAL "$iarr[0] $iarr[1] $larr[$#larr]\n";
      }

      close(LAB);
      close(IFAL);
      close(OFAL);
      print OSCP "$mspffaldir/$base.lab\n";
   }

   close(ISCP);
   close(OSCP);
}
# sub routine for calculating statistics of modulation spectrum
sub make_mspf($) {
   my ($gentype) = @_;
   my ( $cmp, $base, $type, $mspftype, $orgdir, $line, $d );
   my ( $str, @arr, $start, $end, $find, $j );

   # reset modulation spectrum files
   foreach $type ('mgc') {
      foreach $mspftype ( 'nat', $gentype ) {
         for ( $d = 0 ; $d < $ordr{$type} ; $d++ ) {
            shell("rm -f $mspfstatsdir{$mspftype}/${type}_dim$d.data");
            shell("touch $mspfstatsdir{$mspftype}/${type}_dim$d.data");
         }
      }
   }

   # calculate modulation spectrum from natural/generated sequences
   open( SCP, "$scp{'trn'}" ) || die "Cannot open $!";
   while (<SCP>) {
      $cmp = $_;
      chomp($cmp);
      $base = `basename $cmp .cmp`;
      chomp($base);
      print " Making data from $base.lab for modulation spectrum...";

      foreach $type ('mgc') {
         foreach $mspftype ( 'nat', $gentype ) {

            # determine original feature directory
            if   ( $mspftype eq 'nat' ) { $orgdir = "$datdir/$type"; }
            else                        { $orgdir = "$mspfdir/$mspftype"; }

            # subtract utterance-level mean
            $line = get_cmd_utmean( "$orgdir/$base.$type", $type );
            shell("$line > $mspfdatdir{$mspftype}/$base.$type.mean");
            $line = get_cmd_vopr( "$orgdir/$base.$type", "-s", "$mspfdatdir{$mspftype}/$base.$type.mean", $type );
            shell("$line > $mspfdatdir{$mspftype}/$base.$type.subtracted");

            # extract non-silence frames
            if ( @slnt > 0 ) {
               shell("rm -f $mspfdatdir{$mspftype}/$base.$type.subtracted.no-sil");
               shell("touch $mspfdatdir{$mspftype}/$base.$type.subtracted.no-sil");
               open( F, "$gvfaldir{'phn'}/$base.lab" ) || die "Cannot open $!";
               while ( $str = <F> ) {
                  chomp($str);
                  @arr = split( / /, $str );
                  $find = 0;
                  for ( $j = 0 ; $j < @slnt ; $j++ ) {
                     if ( $arr[2] eq "$slnt[$j]" ) { $find = 1; last; }
                  }
                  if ( $find == 0 ) {
                     $start = int( $arr[0] * ( 1.0e-7 / ( $fs / $sr ) ) );
                     $end   = int( $arr[1] * ( 1.0e-7 / ( $fs / $sr ) ) );
                     shell("$BCUT -s $start -e $end -l $ordr{$type} < $mspfdatdir{$mspftype}/$base.$type.subtracted >> $mspfdatdir{$mspftype}/$base.$type.subtracted.no-sil");
                  }
               }
               close(F);
            }
            else {
               shell("cp $mspfdatdir{$mspftype}/$base.$type.subtracted $mspfdatdir{$mspftype}/$base.$type.subtracted.no-sil");
            }

            # calculate modulation spectrum of each dimension
            for ( $d = 0 ; $d < $ordr{$type} ; $d++ ) {
               $line = get_cmd_seq2ms( "$mspfdatdir{$mspftype}/$base.$type.subtracted.no-sil", $type, $d );
               shell("$line >> $mspfstatsdir{$mspftype}/${type}_dim$d.data");
            }

            # remove temporal files
            shell("rm -f $mspfdatdir{$mspftype}/$base.$type.mean");
            shell("rm -f $mspfdatdir{$mspftype}/$base.$type.subtracted.no-sil");
         }
      }
      print "done\n";
   }
   close(SCP);

   # estimate modulation spectrum statistics
   foreach $type ('mgc') {
      foreach $mspftype ( 'nat', $gentype ) {
         for ( $d = 0 ; $d < $ordr{$type} ; $d++ ) {
            shell( "$VSTAT -o 1 -l " . ( $mspfFFTLen / 2 + 1 ) . " -d $mspfstatsdir{$mspftype}/${type}_dim$d.data > $mspfmean{$type}{$mspftype}[$d]" );
            shell( "$VSTAT -o 2 -l " . ( $mspfFFTLen / 2 + 1 ) . " -d $mspfstatsdir{$mspftype}/${type}_dim$d.data | $SOPR -SQRT > $mspfstdd{$type}{$mspftype}[$d]" );

            # remove temporal files
            shell("rm -f $mspfstatsdir{$mspftype}/${type}_dim$d.data");
         }
      }
   }
}

# sub routine to convert statistics file for cmp into one for dur
sub convstats {
   open( IN,  "$stats{'cmp'}" )  || die "Cannot open $!";
   open( OUT, ">$stats{'dur'}" ) || die "Cannot open $!";
   while (<IN>) {
      @LINE = split(' ');
      printf OUT ( "%4d %14s %4d %4d\n", $LINE[0], $LINE[1], $LINE[2], $LINE[2] );
   }
   close(IN);
   close(OUT);
}

# sub routine for generating .hed files for decision-tree clustering
sub make_edfile_state($) {
   my ($type) = @_;
   my ( @lines, $i, @nstate );

   $nstate{'cmp'} = $nState;
   $nstate{'dur'} = 1;

   open( QSFILE, "$qs{$type}" ) || die "Cannot open $!";
   @lines = <QSFILE>;
   close(QSFILE);

   open( EDFILE, ">$cxc{$type}" ) || die "Cannot open $!";
   print EDFILE "// load stats file\n";
   print EDFILE "RO $gam{$type} \"$stats{$t2s{$type}}\"\n\n";
   print EDFILE "TR 0\n\n";
   print EDFILE "// questions for decision tree-based context clustering\n";
   print EDFILE @lines;
   print EDFILE "TR 3\n\n";
   print EDFILE "// construct decision trees\n";

   for ( $i = 2 ; $i <= $nstate{ $t2s{$type} } + 1 ; $i++ ) {
      print EDFILE "TB $thr{$type} ${type}_s${i}_ {*.state[${i}].stream[$strb{$type}-$stre{$type}]}\n";
   }
   print EDFILE "\nTR 1\n\n";
   print EDFILE "// output constructed trees\n";
   print EDFILE "ST \"$tre{$type}\"\n";
   close(EDFILE);
}

# sub routine for untying structures
sub make_edfile_untie($) {
   my ($set) = @_;
   my ( $type, $i, @nstate );

   $nstate{'cmp'} = $nState;
   $nstate{'dur'} = 1;

   open( EDFILE, ">$unt{$set}" ) || die "Cannot open $!";

   print EDFILE "// untie parameter sharing structure\n";
   foreach $type ( @{ $ref{$set} } ) {
      for ( $i = 2 ; $i <= $nstate{$set} + 1 ; $i++ ) {
         if ( $#{ $ref{$set} } eq 0 ) {
            print EDFILE "UT {*.state[$i]}\n";
         }
         else {
            if ( $strw{$type} > 0.0 ) {
               print EDFILE "UT {*.state[$i].stream[$strb{$type}-$stre{$type}]}\n";
            }
         }
      }
   }

   close(EDFILE);
}
sub convert_state2phone {
   my ( $line, @FILE, $file, $base, $s, $e, $phone, $ct, @ary );

   @FILE = glob "$gvfaldir{'stt'}/*.lab";
   foreach $file (@FILE) {
      $base = `basename $file`;
      chomp($base);

      open( STATE, "$file" ) || die "Cannot open $!";
      open( PHONE, ">$gvfaldir{'phn'}/$base" ) || die "Cannot open $!";

      $ct = 1;
      while ( $line = <STATE> ) {
         $line =~ s/^\s*(.*?)\s*$/$1/;
         if ( $ct == 1 ) {
            @ary   = split /\s+/, $line;
            $s     = $ary[0];
            $phone = ( $ary[2] =~ /^.+?-(.+?)\+/ ) ? $1 : "";
         }
         elsif ( $ct == $nState ) {
            @ary = split /\s+/, $line;
            $e   = $ary[1];
            $ct  = 0;
            print PHONE "$s $e $phone\n";
         }
         $ct++;
      }

      close(PHONE);
      close(STATE);
   }
}

