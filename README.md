HTS demo with evaluation scripts for any text to speech synthesis using HTS demo pipeline
#how to use 
HTS-demo->data->labels->texttospeech_lab->make_full_labels_master->examples
#In example edit example.txt to any input text need to be synthesised.
#cd ..
#perl text2lab.pl
text2lab file will create .data file for text file and further creates full labels.It calls remove_timestamp.py file to remove
timestamp of phonemes in .lab file which was generated.Change the directory(input and output) for both text2lab and remove_timestamp 
with your directory structure.
#make labels (remove_timestamp.py file add newly generated file to data->label->gen.)
#tts_kush_final.pl(to generated speech signals using 1mix hmm model.)
