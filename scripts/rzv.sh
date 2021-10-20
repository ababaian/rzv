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

PIPE_VERSION="$PALMIDVERSION"
CONTAINER_VERSION="rzv:$PALMIDVERSION"
AMI_VERSION='ami-0fdf24f2ce3c33243'


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
DB='/home/palmid/palmdb/palmdb'
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

# Output options
#echo "Creating dir $OUTNAME"
mkdir -p $OUTDIR
cp $INPUT $OUTDIR/$OUTNAME.input.fa

# RVID ====================================================
INPUT='murray.fa'
relplot='perl /home/ViennaRNA-2.4.18/src/Utils/relplot.pl'

# Calculate MFE structure
RNAfold -i $INPUT --outfile="$INPUT.fold" \
  --id-prefix="$INPUT" \
  -p --circ --layout-type=2

$relplot "$INPUT"_0001_ss.ps "$INPUT"_0001_dp.ps \
  > $INPUT.ps

# Re-position legend
sed -i 's/0.1 0.1 colorbar/0.01 0.01 colorbar/g' $INPUT.ps
# Remove outline
sed -i 's/^drawoutline$/%drawoutline/g' $INPUT.ps
# remove arc-dashes
sed -i 's/\[9 3.01\] 9 setdash//g' $INPUT.ps
# TODO: Apply the entropy coloring which is used for
# the base-circles ('drawreliability') to the base-pairing
# arcs in `/drawpair`. Either modify relplot.pl or script
# the change in the post-script file directly
