# ----------------------------------------------------------------- #
#           The HMM-Based Speech Synthesis System (HTS)             #
#           developed by HTS Working Group                          #
#           http://hts.sp.nitech.ac.jp/                             #
# ----------------------------------------------------------------- #
#                                                                   #
#  Copyright (c) 2001-2016  Nagoya Institute of Technology          #
#                           Department of Computer Science          #
#                                                                   #
#                2001-2008  Tokyo Institute of Technology           #
#                           Interdisciplinary Graduate School of    #
#                           Science and Engineering                 #
#                                                                   #
# All rights reserved.                                              #
#                                                                   #
# Redistribution and use in source and binary forms, with or        #
# without modification, are permitted provided that the following   #
# conditions are met:                                               #
#                                                                   #
# - Redistributions of source code must retain the above copyright  #
#   notice, this list of conditions and the following disclaimer.   #
# - Redistributions in binary form must reproduce the above         #
#   copyright notice, this list of conditions and the following     #
#   disclaimer in the documentation and/or other materials provided #
#   with the distribution.                                          #
# - Neither the name of the HTS working group nor the names of its  #
#   contributors may be used to endorse or promote products derived #
#   from this software without specific prior written permission.   #
#                                                                   #
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND            #
# CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,       #
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF          #
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE          #
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS #
# BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,          #
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED   #
# TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,     #
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON #
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,   #
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY    #
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE           #
# POSSIBILITY OF SUCH DAMAGE.                                       #
# ----------------------------------------------------------------- #

# setting
SPEAKER = aayush
DATASET = test
QNAME   = en_US.talk

# awk and perl
AWK  = mawk
PERL = /usr/bin/perl

# SPTK commands
X2X     = /usr/local/bin/x2x
MGCEP   = /usr/local/bin/mcep
LPC2LSP = /usr/local/bin/lpc2lsp
MERGE   = /usr/local/bin/merge
VSTAT   = /usr/local/bin/vstat
SOPR    = /usr/local/bin/sopr
NAN     = /usr/local/bin/nan
MINMAX  = /usr/local/bin/minmax
PITCH   = /usr/local/bin/pitch
FRAME   = /usr/local/bin/frame
WINDOW  = /usr/local/bin/window
RAW2WAV = /usr/local/bin/raw2wav
BCUT    = /usr/local/bin/bcut

# MATLAB and STRAIGHT
USESTRAIGHT = 0
MATLAB      = : -nodisplay -nosplash -nojvm
STRAIGHT    =

# DNN
USEDNN = 0

# Festival commands
USEUTT    = 1
TEXT2UTT  = /home/aayush/Downloads/FestivalTts/festival/examples/text2utt
DUMPFEATS = /home/aayush/Downloads/FestivalTts/festival/examples/dumpfeats

# speech analysis conditions
SAMPFREQ   = 48000   # Sampling frequency (48kHz)
FRAMELEN   = 1200   # Frame length in point (1200 = 48000 * 0.025)
FRAMESHIFT = 240 # Frame shift in point (240 = 48000 * 0.005)
WINDOWTYPE = 1 # Window type -> 0: Blackman 1: Hamming 2: Hanning
NORMALIZE  = 1  # Normalization -> 0: none  1: by power  2: by magnitude
FFTLEN     = 2048     # FFT length in point
FREQWARP   = 0.55   # frequency warping factor
GAMMA      = 0      # pole/zero weight for mel-generalized cepstral (MGC) analysis
MGCORDER   = 34   # order of MGC analysis
BAPORDER   = 24   # order of BAP analysis
LNGAIN     = 1     # use logarithmic gain rather than linear gain
LOWERF0    = 110    # lower limit for f0 extraction (Hz)
UPPERF0    = 280    # upper limit for f0 extraction (Hz)

# windows for calculating delta features
MGCWIN  = win/mgc.win
LF0WIN  = win/lf0.win
BAPWIN  = win/bap.win
NMGCWIN = 3
NLF0WIN = 3
NBAPWIN = 3

all: analysis labels



labels: lab mlf list scp question


lab:
	# Extracting monophone and fullcontext labels
	mkdir -p labels/mono
	mkdir -p labels/full
	if [ $(USEUTT) -eq 1 ]; then \
		for utt in utts/$(DATASET)_$(SPEAKER)_*.utt; do \
			base=`basename $${utt} .utt`; \
			if [ -s $${utt} ]; then \
				echo "Extracting labels from $${utt}"; \
				$(DUMPFEATS) -eval scripts/extra_feats.scm -relation Segment -feats scripts/label.feats -output tmp.feats $${utt}; \
			fi; \
			if [ -s tmp.feats ]; then \
				$(AWK) -f scripts/label-full.awk tmp.feats > labels/full/$${base}.lab; \
				$(AWK) -f scripts/label-mono.awk tmp.feats > labels/mono/$${base}.lab; \
				rm -f tmp.feats; \
			fi; \
		done; \
	else \
		for txt in txt/$(DATASET)_$(SPEAKER)_*.txt; do \
			base=`basename $${txt} .txt`; \
			if [ -s $${txt} ]; then \
				echo "Extracting labels from $${txt}"; \
				$(PERL) scripts/normtext.pl $${txt} > tmp.txt; \
				$(TEXT2UTT) tmp.txt > tmp.utt; \
				$(DUMPFEATS) -eval scripts/extra_feats.scm -relation Segment -feats scripts/label.feats -output tmp.feats tmp.utt; \
				rm -f tmp.txt tmp.utt; \
			fi; \
			if [ -s tmp.feats ]; then \
				$(AWK) -f scripts/label-full.awk tmp.feats > labels/full/$${base}.lab; \
				$(AWK) -f scripts/label-mono.awk tmp.feats > labels/mono/$${base}.lab; \
				rm -f tmp.feats; \
			fi; \
		done; \
	fi

mlf:
	# Generating monophone and fullcontext Master Label Files (MLF)
	echo "#!MLF!#" > labels/mono.mlf
	echo "\"*/$(DATASET)_$(SPEAKER)_*.lab\" -> \"/home/aayush/Downloads/HTS-demo_CMU-ARCTIC-SLT/data/labels/texttospeech_lab/Example/labels/mono\"" >> labels/mono.mlf

	echo "#!MLF!#" > labels/full.mlf
	echo "\"*/$(DATASET)_$(SPEAKER)_*.lab\" -> \"/home/aayush/Downloads/HTS-demo_CMU-ARCTIC-SLT/data/labels/texttospeech_lab/Example/labels/full\"" >> labels/full.mlf

list:
	# Generating a fullcontext model list file
	mkdir -p lists

	rm -f tmp
	for lab in labels/full/$(DATASET)_$(SPEAKER)_*.lab; do \
		if [ -s $${lab} -a -s labels/mono/`basename $${lab}` -a -s cmp/`basename $${lab} .lab`.cmp ]; then \
			sed -e "s/.* //g" $${lab} >> tmp; \
		fi \
	done
	sort -u tmp > lists/full.list
	rm -f tmp

	# Generating a fullcontext model list file which includes unseen models
	rm -f tmp
	cat lists/full.list > tmp
	for lab in labels/gen/*.lab; do \
		sed -e "s/.* //g" $${lab} >> tmp; \
	done
	sort -u tmp > lists/full_all.list
	rm -f tmp

	# Generating a monophone list file
	rm -f tmp
	for lab in labels/mono/$(DATASET)_$(SPEAKER)_*.lab; do \
		if [ -s $${lab} -a -s labels/full/`basename $${lab}` -a -s cmp/`basename $${lab} .lab`.cmp ]; then \
			sed -e "s/.* //g" $${lab} >> tmp; \
		fi \
	done
	sort -u tmp > lists/mono.list
	rm -f tmp

scp:
	# Generating a trainig data script
	mkdir -p scp

	rm -f scp/train.cmp.scp
	for cmp in /home/aayush/Downloads/HTS-demo_CMU-ARCTIC-SLT/data/cmp/$(DATASET)_$(SPEAKER)_*.cmp; do \
		if [ -s $${cmp} -a -s labels/mono/`basename $${cmp} .cmp`.lab -a -s labels/full/`basename $${cmp} .cmp`.lab ]; then \
			echo $${cmp} >> scp/train.cmp.scp; \
		fi \
	done

	# Generating a generation label script
	rm -f scp/gen.lab.scp
	for lab in /home/aayush/Downloads/HTS-demo_CMU-ARCTIC-SLT/data/labels/gen/*.lab; do \
		echo $${lab} >> scp/gen.lab.scp; \
	done

question:
	# Generating a question file
	mkdir -p questions
	$(PERL) scripts/makequestion.pl configs/$(QNAME).conf > questions/questions_$(QNAME).hed
	grep Utterance questions/questions_$(QNAME).hed > questions/questions_utt_$(QNAME).hed

clean: clean-mgc clean-lf0 clean-bap clean-cmp clean-ffo clean-stats clean-lab clean-mlf clean-list clean-scp clean-question

clean-mgc:
	rm -rf mgc

clean-lf0:
	rm -rf lf0

clean-bap:
	rm -rf bap

clean-cmp:
	rm -rf cmp

clean-ffo:
	rm -rf ffo

clean-stats:
	rm -rf stats

clean-lab:
	rm -rf labels/mono
	rm -rf labels/full

clean-mlf:
	rm -f labels/*.mlf

clean-list:
	rm -rf lists

clean-scp:
	rm -rf scp

clean-question:
	rm -rf questions

distclean: clean
	rm -f Makefile

.PHONY: all  labels lab mlf list scp question clean distclean
