#!/bin/bash
# ENTRYPOINT SCRIPT ===================
# rzv.sh
# =====================================
set -eu
#
# Base: rzv-base
# Amazon Linux 2 with Docker
# AMI : ami-0fdf24f2ce3c33243
# login: ec2-user@<ipv4>
# base: 9 Gb

PIPE_VERSION="$RZVVERSION"
CONTAINER_VERSION="rzv:$RZVVERSION"
AMI_VERSION='ami-0fdf24f2ce3c33243'

# sudo docker run  -v `pwd`:`pwd` -w `pwd` \
# --entrypoint "/bin/bash" serratusbio/rzh:dev \
# /home/serratus/rzv.sh -i data/murray.fa -o murray
 

function usage {
  echo ""
  echo "Usage: sudo docker run  -v `pwd`:`pwd` -w `pwd` \
                 --entrypoint "/bin/bash" serratusbio/rzv:latest \
                 /home/serratus/rzv.sh -i <input.fa> -o <output_prefix> [OPTIONS]"
  echo " OR"
  echo "rzv='sudo docker run  -v `pwd`:`pwd` -w `pwd` --entrypoint "/bin/bash" serratusbio/rzv:latest /home/serratus/rzv.sh'"
  echo ""
  echo "\$rzv -i <input.fa> -o <output_prefix> [OPTIONS]"
  echo ""
  echo "    -h    Show this help/usage message"
  echo ""
  echo "    [Required]"
  echo "    -i    input fasta file [nt]*"
  echo "          *(must be in current working dir)"
  echo "    -o    prefix for output files"
  echo ""
  echo "    [Optional]"
  echo "    -d    output directory [<value from -o>]"
  echo ""
  echo "e.g:"
  echo " sudo docker run  -v `pwd`:`pwd` -w `pwd` --entrypoint "/bin/bash" serratusbio/rzv:latest /home/serratus/rzv.sh -i data/murray.fa -o murray"
  echo ""
  exit 1
}

# SCRIPT ==================================================

echo '================================================='
echo "================= rzv -- $PIPE_VERSION =================="
echo '================================================='
echo 'ababaian (artem@rRNA.ca)'
echo 'issues: https://github.com/ababaian/palmid/issues'
echo ''

# PARSE INPUT =============================================
# Variable inputs
INPUT=""
OUTNAME=""
OUTDIR=""

# Hardcoded inputs
DB='/home/serratus/data/DVR4.cm'
HMM='/home/serratus/data/dAg.hmm'
HOME='/home/serratus'

# Parse inputs

while getopts i:o:d:h! FLAG; do
  case $FLAG in
    i)
      INPUT=$OPTARG
      ;;
    o)
      OUTNAME=$OPTARG
      ;;
    d)
      OUTDIR=$(readlink -f $OPTARG)
      ;;
    h)  #show help ----------
      usage
      ;;
    \?) #unrecognized option - show help
      echo "Input parameter not recognized"
      usage
      ;;
  esac
done
shift $((OPTIND-1))

# Required Input / Output
if [ -z "$INPUT" ]; then
    echo "Input fasta file (-i) required."
    echo
    usage
    false
    exit 1
fi

if [ -z "$OUTNAME" ]; then
    echo "Output prefix (-o) required."
    usage
    false
    exit 1
fi

# If no explicit output directory set (-d)
# use OUTNAME as directory
if [ -z "$OUTDIR" ]; then
  OUTDIR=$PWD/$OUTNAME
fi

# # DEV TESTING
# INPUT='/home/serratus/data/murray.fa'
# OUTDIR='/home/serratus/murray/'
# OUTNAME='murray'

# Output options
#echo "Creating dir $OUTNAME"
mkdir -p $OUTDIR
cp $INPUT $OUTDIR/$OUTNAME.input.fa
cd $OUTDIR

# RZV =====================================================

# RNAfold ---------------------------------------
# man: https://www.tbi.univie.ac.at/RNA/index.html
relplot='perl /usr/local/share/ViennaRNA/bin/relplot.pl'

# Calculate MFE structure
RNAfold -i $OUTNAME.input.fa \
  --outfile="$OUTNAME.fold" \
  --id-prefix="$OUTNAME" \
  -p --circ --layout-type=2

$relplot -p "$OUTNAME"_0001_ss.ps "$OUTNAME"_0001_dp.ps \
  > $OUTNAME.ps

# Re-position legend
sed -i 's/0.1 0.1 colorbar/0.01 0.01 colorbar/g' $OUTNAME.ps
# Remove outline
sed -i 's/^drawoutline$/%drawoutline/g' $OUTNAME.ps
# remove arc-dashes, thicken lines
sed -i 's/\[9 3.01\] 9 setdash//g' $OUTNAME.ps
sed -i 's/0.7 setlinewidth/2 setlinewidth/g' $OUTNAME.ps

# TODO: Apply the entropy coloring which is used for
# the base-circles ('drawreliability') to the base-pairing
# arcs in `/drawpair`. Either modify relplot.pl or script
# the change in the post-script file directly

# Convert to PNG
convert -density 150 -alpha off $OUTNAME.ps $OUTNAME.png

# INFERNAL --------------------------------------

# Use -Z 1000 (1 Gbp search space for standardized reporting)
cmsearch -o $OUTNAME.inf --notextw \
  -A $OUTNAME.inf.align.tmp \
  --tblout $OUTNAME.tb.inf \
  -Z 1000 \
  $DB $OUTNAME.input.fa

# Translate -------------------------------------
seqkit translate -F -f 6 -w 50 $OUTNAME.input.fa \
  > $OUTNAME.xlate.fa

# HMMR ------------------------------------------

hmmsearch -o $OUTNAME.hmmsearch --notextw \
  -A $OUTNAME.align.tmp \
  --tblout $OUTNAME.tb.hmmsearch \
  $HMM $OUTNAME.xlate.fa

# Convert alignment hit to fasta file
if [ -s $OUTNAME.align.tmp ]
then
  grep -v "^[$//#]" $OUTNAME.align.tmp \
    | grep -v "^$" - \
    | sed 's/^/>/g' - \
    | sed 's/ /\n/g' - \
    | grep -v "^$" - \
    > $OUTNAME.dAg.fa

  rm $OUTNAME.align.tmp
else
  echo No dAg alignment found
  rm $OUTNAME.align.tmp
fi
