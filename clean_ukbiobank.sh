#!/bin/bash
#SBATCH --nodes=1
#SBATCH --time=5:00:00
#SBATCH --job-name=biobankQC

cd /data/
rm -rf cleanedandmerged/*

for i in {1..22}
do
    cp linkfiles/famfiles/ukb*_cal_chr"$i"_v2_s*.fam.gz cleanedandmerged/
    cp genotype/EGAD*/_001_ukb_cal_chr"$i"_v2.bed.gz  cleanedandmerged/
    cp genotype/EGAD*/_001_ukb_snp_chr"$i"_v2.bim.gz cleanedandmerged/
    gunzip cleanedandmerged/*chr"$i"*
    echo _001_ukb_cal_chr"$i"_v2.bed _001_ukb_snp_chr"$i"_v2.bim ukb*_cal_chr"$i"_v2_*.fam >> cleanedandmerged/allfiles.txt
    echo Just finished merging in chr"$i" files
done

cd cleanedandmerged/

./../code/plink --merge-list allfiles.txt --maf 0.001 --geno 0.03 --mind 0.1 --hwe 1e-20 --list-duplicate-vars --make-bed --out ukbio_clean
rm *_chr"$i"*
