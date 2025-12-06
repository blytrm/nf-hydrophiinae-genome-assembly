#!/bin/bash -ue
echo "=== MOCK MODE: Assessing quality of sample.fasta (sample: hmajor) ==="

echo "QUAST - N50: 28.0 Mb | Contigs: 1,896" > quast_report.txt
echo "BUSCO - Complete: 99.22% (D:0.47%) | Fragmented: 0.31% | Missing: 0.47%" > busco_summary.txt
echo "Merqury - QV: 45.2 | Completeness: 98.97% | k-mer completeness: 98.8%" > merqury_qv.txt
