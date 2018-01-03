#Directory structure

#!/usr/bin/perl

$text2utt="/home/aayush16081/speechsynthesis/pipeline/FestivalTts/Festival/festvox/src/promptselect/text2utts";

$dumpfeats="/home/aayush16081/speechsynthesis/pipeline/FestivalTts/Festival/festival/examples/dumpfeats";

$src="/home/aayush16081/speechsynthesis/pipeline/FestivalTts/HTS-demo_CMU-ARCTIC-SLT/data/labels/make_full_labels/src/";

$example="/home/aayush16081/speechsynthesis/pipeline/FestivalTts/HTS-demo_CMU-ARCTIC-SLT/data/labels/make_full_labels/example";

$full_all_list="/home/aayush16081/speechsynthesis/pipeline/FestivalTts/HTS-demo_CMU-ARCTIC-SLT/data/lists";

#data dir 
$data="/home/aayush16081/speechsynthesis/pipeline/FestivalTts/HTS-demo_CMU-ARCTIC-SLT/data";



shell("python $src/text2prompt.py $example/example.txt $example/example.data ");
shell("$text2utt -all -level Text -odir $example/utts -otype utts -itype data '$example/example.data'");
shell("$src/generate_labels.sh $example/labels $example/utts $dumpfeats $src");
shell("python $src/remove_timestamp.py");

#adding new file to full_all.list
shell("cat $full_all_list/full_all.list $data/labels/gen/alice_new.lab|sort -u>temp");
shell("mv temp $full_all_list/full_all.list");

#make labels 
shell("$data/make labels");


sub shell($) {
   my ($command) = @_;
   my ($exit);

   $exit = system($command);

   if ( $exit / 256 != 0 ) {
      die "Error in $command\n";
   }
}

