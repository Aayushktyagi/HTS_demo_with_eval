#evalutation script for testing purpose
#check uttrance file directory for gen
#Acoustic path model
#config.pm file]
#HMGenS for parameter generation
#gen_waveE
$| = 1;
if ( @ARGV < 1 ) {
   print "usage: eval_sptk_dnn.pl Config.pm\n";
   exit(0);
}

# load configuration variables
require( $ARGV[0] );
print "checkpoint1\n";



# model structure
foreach $set (@SET) {
   $vSize{$set}{'total'}   = 0;
   foreach $type ( @{ $ref{$set} } ) {
      $vSize{$set}{$type} = $nwin{$type} * $ordr{$type};
      $vSize{$set}{'total'} += $vSize{$set}{$type};
   }
}



#pre-req:
$datdir = "$prjdir/data";
$scp{'gen'} = "$datdir/scp/gen.lab.scp";
foreach $set (@SET) {
   $model{$set} = "$prjdir/models/ver${ver}/${set}";
   $rclammf{$set} = "$model{$set}/re_clustered_all.mmf";
   $tiedlst{$set} = "$model{$set}/tiedlist";

}
# configuration variable files
$cfg{'trn'} = "$prjdir/configs/ver${ver}/trn.cnf";
$cfg{'nvf'} = "$prjdir/configs/ver${ver}/nvf.cnf";
$cfg{'syn'} = "$prjdir/configs/ver${ver}/syn.cnf";
$cfg{'apg'} = "$prjdir/configs/ver${ver}/apg.cnf";
$cfg{'stc'} = "$prjdir/configs/ver${ver}/stc.cnf";


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

foreach $type (@cmp) {
   $cfg{$type} = "$prjdir/configs/ver${ver}/${type}.cnf";
}
foreach $type (@dur) {
   $cfg{$type} = "$prjdir/configs/ver${ver}/${type}.cnf";
}
$HMGenS        = "$HMGENS    -A -B -C $cfg{'syn'} -D -T 1 -t $beam ";

$useDNN = 1;

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



# TensorFlow & SPTK (generating speech parameter sequences (dnn))
if ($PGEND) {
   print_time("generating speech parameter sequences (dnn)");

   if ($useDNN) {
      $mix = 'dnn';
      $dir = "${prjdir}/gen/ver${ver}/$mix/$pgtype";
      mkdir "${prjdir}/gen/ver${ver}/$mix", 0755;
      mkdir $dir, 0755;

      # predict duration from HMMs
      shell("$HMGenS -S $scp{'gen'} -c $pgtype -H $rclammf{'cmp'}.1mix -N $rclammf{'dur'}.1mix -M $dir $tiedlst{'cmp'} $tiedlst{'dur'}");
      shell("rm -f $dir/*.{mgc,lf0,bap}");

      mkdir "$dnnffidir{'gen'}", 0755;
      convert_dur2lab($dir);
      make_gen_data_dnn($dir);

      # generate parameter
      make_dnn_config();
      shell("$PYTHON $datdir/scripts/DNNSynthesis.py -C $cfg{'sdn'} -S $scp{'ffi'} -H $dnnmodels -M $dir");

      # generate smooth parameter sequence
      gen_param("$dir");
   }
}


# SPTK (synthesizing waveforms (dnn))
if ($WGEND) {
   print_time("synthesizing waveforms (dnn)");

   if ($useDNN) {
      $mix = 'dnn';
      $dir = "${prjdir}/gen/ver${ver}/$mix/$pgtype";

      gen_wave("$dir");
   }
}


# sub routine for generating parameter sequences using MLPG and neural network outputs
sub gen_param($) {
   my ($gendir) = @_;
   my ( $line, @FILE, $file, $base, $T, $s, $e, $t );

   $line = `ls $gendir/*.ffo`;
   @FILE = split( '\n', $line );
   print "Processing directory $gendir:\n";
   foreach $file (@FILE) {
      $base = `basename $file .ffo`;
      chomp($base);

      print " Generating parameter sequences from $base.ffo...";

      $vuvsize = 1;
      $ffosize = $vuvsize + $vSize{'cmp'}{'total'};
      $T       = get_file_size("$gendir/${base}.ffo ") / $ffosize / 4;

      # generate a mgc sequence
      $s = 0;
      $e = $s + $vSize{'cmp'}{'mgc'} - 1;
      print "before bcp 1 in gen_param";
      shell("$BCP +f -s $s -e $e -l $ffosize $file > $gendir/$base.mgc.mean");
      shell("rm -f $gendir/$base.mgc.var");
      for ( $t = 0 ; $t < $T ; $t++ ) {
         shell("cat $var{'mgc'} >> $gendir/$base.mgc.var");
      }
      $mgc_win_delta = `cut -d " " -f 2- $windir/$win{'mgc'}[1]`;
      $mgc_win_accel = `cut -d " " -f 2- $windir/$win{'mgc'}[2]`;
      chomp $mgc_win_delta;
      chomp $mgc_win_accel;
      $line = "$MERGE -l $vSize{'cmp'}{'mgc'} -L $vSize{'cmp'}{'mgc'} $gendir/$base.mgc.mean < $gendir/$base.mgc.var | ";
      $line .= "$MLPG -l $ordr{'mgc'} -d $mgc_win_delta -d $mgc_win_accel > $gendir/$base.mgc";
      shell($line);
      shell("rm -f $gendir/$base.mgc.mean $gendir/$base.mgc.var");

      # generate a vuv sequence
      $s = $e + 1;
      $e = $s + $vuvsize - 1;
      print "before bcp 2 in gen_param";
      shell("$BCP +f -s $s -e $e -l $ffosize $file | $SOPR -s 0.5 -UNIT > $gendir/$base.vuv");

      # generate a lf0 sequence
      $s = $e + 1;
      $e = $s + $vSize{'cmp'}{'lf0'} - 1;
      print "before bcp 3 in gen_param";
      shell("$BCP +f -s $s -e $e -l $ffosize $file > $gendir/$base.lf0.mean");
      shell("rm -f $gendir/$base.lf0.var");
      for ( $t = 0 ; $t < $T ; $t++ ) {
         shell("cat $var{'lf0'} >> $gendir/$base.lf0.var");
      }
      $lf0_win_delta = `cut -d " " -f 2- $windir/$win{'lf0'}[1]`;
      $lf0_win_accel = `cut -d " " -f 2- $windir/$win{'lf0'}[2]`;
      chomp $lf0_win_delta;
      chomp $lf0_win_accel;
      $line = "$MERGE -l $vSize{'cmp'}{'lf0'} -L $vSize{'cmp'}{'lf0'} $gendir/$base.lf0.mean < $gendir/$base.lf0.var | ";
      $line .= "$MLPG -l $ordr{'lf0'} -d $lf0_win_delta -d $lf0_win_accel | ";
      $line .= "$VOPR -l 1 -m $gendir/$base.vuv | ";
      $line .= "$SOPR -magic 0 -MAGIC -1.0E+10 > $gendir/$base.lf0";
      shell($line);
      shell("rm -f $gendir/$base.lf0.mean $gendir/$base.lf0.var $gendir/$base.vuv");

      # generate a bap sequence
      if ($usestraight) {
         $s = $e + 1;
         $e = $s + $vSize{'cmp'}{'bap'} - 1;
         shell("$BCP +f -s $s -e $e -l $ffosize $file > $gendir/$base.bap.mean");
         shell("rm -f $gendir/$base.bap.var");
         for ( $t = 0 ; $t < $T ; $t++ ) {
            shell("cat $var{'bap'} >> $gendir/$base.bap.var");
         }
         $bap_win_delta = `cut -d " " -f 2- $windir/$win{'bap'}[1]`;
         $bap_win_accel = `cut -d " " -f 2- $windir/$win{'bap'}[2]`;
         chomp $bap_win_delta;
         chomp $bap_win_accel;
         $line = "$MERGE -l $vSize{'cmp'}{'bap'} -L $vSize{'cmp'}{'bap'} $gendir/$base.bap.mean < $gendir/$base.bap.var | ";
         $line .= "$MLPG -l $ordr{'bap'} -d $bap_win_delta -d $bap_win_accel > $gendir/$base.bap";
         shell($line);
         shell("rm -f $gendir/$base.bap.mean $gendir/$base.bap.var");
      }

      print "done\n";
   }
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

sub make_dnn_config {
   my ( $nin, $nhid, $nout );
   my @activations = qw(Linear Sigmoid Tanh ReLU);
   my @optimizers  = qw(SGD Momentum AdaGrad AdaDelta Adam RMSprop);

   $nin = `grep -c -v -e '^\$' -e '^ *#' $qconf`;
   chomp $nin;
   $nhid = join ", ", ( split /\s+/, $nHiddenUnits );
   $nout = $vSize{'cmp'}{'total'} + 1;

   open( CONF, ">$cfg{'tdn'}" ) || die "Cannot open $!";
   print CONF "[Architecture]\n";
   print CONF "num_input_units: $nin\n";
   print CONF "num_hidden_units: [$nhid]\n";
   #print CONF "num_output_units: $nout\n";
   print CONF "num_output_units: 109\n";
   print CONF "hidden_activation: $activations[$activation]\n";
   print CONF "output_activation: $activations[0]\n";
   print CONF "\n[Strategy]\n";
   print CONF "optimizer: $optimizers[$optimizer]\n";
   print CONF "learning_rate: $learnRate\n";
   print CONF "keep_prob: $keepProb\n";
   print CONF "use_queue: $useQueue\n";
   print CONF "queue_size: $queueSize\n";
   print CONF "batch_size: $batchSize\n";
   print CONF "num_epochs: $nEpoch\n";
   print CONF "num_threads: $nThread\n";
   print CONF "num_threads_for_queue: 2\n";
   print CONF "random_seed: $randomSeed\n";
   print CONF "\n[Output]\n";
   print CONF "num_models_to_keep: $nKeep\n";
   print CONF "log_interval: $logInterval\n";
   print CONF "save_interval: $saveInterval\n";
   close(CONF);

   open( CONF, ">$cfg{'sdn'}" ) || die "Cannot open $!";
   print CONF "[Architecture]\n";
   print CONF "num_input_units: $nin\n";
   print CONF "num_hidden_units: [$nhid]\n";
   #print CONF "num_output_units: $nout\n";
   print CONF "num_output_units: 109\n";
   print CONF "hidden_activation: $activations[$activation]\n";
   print CONF "output_activation: $activations[0]\n";
   print CONF "\n[Others]\n";
   print CONF "num_threads: $nThread\n";
   print CONF "restore_ckpt: $restoreCkpt\n";
   close(CONF);
}


sub make_train_data_dnn {
   my ( $line, $base, $lab, $ffi, $ffo );

   # make frame-by-frame input features
   foreach $lab ( glob "$gvfaldir{'stt'}/*.lab" ) {
      $base = `basename $lab .lab`;
      chomp($base);
      print " Making data from $lab for neural network training...";
      $line = "$PERL $datdir/scripts/makefeature.pl $qconf " . int( 10E+6 * $fs / $sr ) . " $lab | ";
      $line .= "$X2X +af > $dnnffidir{'ful'}/$base.ffi";
      shell($line);
      print "done\n";
   }

   # make scp
   open( SCP, ">$scp{'fio'}" ) || die "Cannot open $!";
   foreach $ffi ( glob "$dnnffidir{'ful'}/*.ffi" ) {
      $base = `basename $ffi .ffi`;
      chomp($base);
      $ffo = "$datdir/ffo/$base.ffo";
      if ( -s $ffi && -s $ffo ) {
         print SCP "$ffi $ffo\n";
      }
   }
   close(SCP);
}

sub convert_dur2lab($) {
   my ($gendir) = @_;
   my ( $line, @FILE, $file, $base, $s, $e, $model, $ct, $t, $p, @ary );

   $p    = int( 10E+6 * $fs / $sr );
   @FILE = glob "$gendir/*.dur";
   foreach $file (@FILE) {
      $base = `basename $file .dur`;
      chomp($base);

      open( DUR, "$file" ) || die "Cannot open $!";
      open( LAB, ">$gendir/$base.lab" ) || die "Cannot open $!";

      $t  = 0;
      $ct = 1;
      while ( $line = <DUR> ) {
         if ( $ct <= $nState ) {
            $line =~ s/^\s*(.*?)\s*$/$1/;
            ( $model, $dur, @ary ) = split /\s+/, $line;
            $model =~ s/\.state\[\d+\]://;
            $dur =~ s/duration=//;
            $s = $t * $p;
            $e = ( $t + $dur ) * $p;
            $t += $dur;
            print LAB "$s $e $model\[" . ( $ct + 1 ) . "\]";
            print LAB " $model" if ( $ct == 1 );
            print LAB "\n";
            $ct++;
         }
         else {
            $ct = 1;
         }
      }

      close(LAB);
      close(DUR);
   }
}

sub make_gen_data_dnn($) {
   my ($gendir) = @_;
   my ( $line, $base, $lab );

   # make frame-by-frame input features
   foreach $lab ( glob "$gendir/*.lab" ) {
      $base = `basename $lab .lab`;
      chomp($base);
      print " Making data from $lab for neural network running...";
      $line = "$PERL $datdir/scripts/makefeature.pl $qconf " . int( 10E+6 * $fs / $sr ) . " $lab 2> /dev/null | ";
      $line .= "$X2X +af > $dnnffidir{'gen'}/$base.ffi";
      shell($line);
      print "done\n";
   }

   # make scp
   open( SCP, ">$scp{'ffi'}" ) || die "Cannot open $!";
   print SCP "$_\n" for glob "$dnnffidir{'gen'}/*.ffi";
   close(SCP);
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

# sub routine for getting file size
sub get_file_size($) {
   my ($file) = @_;
   my ($file_size);

   $file_size = `$WC -c < $file`;
   chomp($file_size);

   return $file_size;
}

