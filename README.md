# DupHIST

**DupHIST (Duplication History Inference via Substitution-based Timeframe)** is a fully automated pipeline that estimates the relative duplication time and order among paralogous genes within user-defined gene families. These inferences are based on pairwise synonymous substitution rates (Ks).

The pipeline performs the following key steps:
1. Calculates all pairwise Ks values for coding sequences within each gene family and converts them into distance matrices.
2. Applies multiple hierarchical clustering methods and selects the optimal strategy using the cophenetic correlation coefficient (CCC).
3. Outputs dendrograms and Ks tables representing the inferred duplication hierarchy for each gene family.

DupHIST supports both global and per-family clustering modes, and enables functional interpretation of duplication history through integration with gene/domain annotations.

---

## 🔧 Features

- Computes pairwise synonymous substitution rates (Ks) between paralogous genes within user-defined gene families
- Constructs distance matrices and performs hierarchical clustering to infer duplication order
- Supports multiple clustering strategies (e.g., average, complete, single linkage) and selects the optimal method using cophenetic correlation coefficient (CCC)
- Offers both global and per-family clustering modes for flexible inference resolution
- Provides output files including Ks matrices, duplication hierarchies (dendrograms), and summary tables
- Compatible with external tools such as PRANK (for codon alignment) and KaKs_Calculator 2.0 (for Ks estimation)
- Facilitates downstream analysis through integration with gene/domain annotation data

---

## 📦 Installation

You can install DupHIST using [Bioconda](https://anaconda.org/bioconda/duphist):

```bash
conda install -c bioconda duphist
```
### 🔗 KaKs_Calculator 2.0 Usage

DupHIST includes **KaKs_Calculator v2.0** by default, so users **do not need to install it separately** or specify an external path.

However, if you prefer to use a newer version such as **KaKs_Calculator v3.0**, you may download it manually from the official website:

[KaKs_Calculator v3.0 Download (CNCB/NGDC)](https://ngdc.cncb.ac.cn/biocode/tools/BT000001)

You do **not** need to add it to your PATH.  
Simply specify the path to the KaKs_Calculator binary in your configuration file `config.txt`:

```
[program_path]
kaks = /your/path/to/KaKs_Calculator
```
⚠️ DupHIST will return an error if the `kaks` path is not specified or is incorrect when using a custom version.

---

## ▶️ Quick Start

Once DupHIST is installed and input files are prepared, run the pipeline using a configuration file:

```bash
duphist config.txt
```

### 🔧 Example `config.txt`:

```ini
[required_option]
CDS_path = ./test.cds.fa
Group_information = ./test.groupinfo
Output_directory = ./Results

[statistical_option]
Hcluster_method = all
preferred_method_order = average,median,complete,ward.D,single

[kaks_cal_option]
genetic_code = 1
method = MYN

[PRANK_option]
iteration = 5
sleep_time = 10

[program_path]
PRANK = prank
perl = perl
kaks = KaKs_Calculator
R = Rscript

[Result]
result_filename = result_table_all.txt
result_dendrogram_dir = dendrograms
temp_path = temp_files

[Thread]
thread_num = 1
```

---

## 📁 Input/Output Format

DupHIST requires two main input files:

### 🧬 1. Coding Sequence File (CDS)

A multi-FASTA file containing **CDS (coding DNA sequence)** entries for all genes used in duplication inference.

**Example (`test.cds.fa`):**
```fasta
>ATHA_10034
ATGTCCTCGGATATGCGTGACGAGCGTTTCTTTTATCATCGATATCTTTCCGTTACAAATAGAAC...
>ATHA_1013
ATGAGAAAAGGAAATGAAGAGAAGAATTACCGTGAAGAAGAATATTTGCAACTCCCTCTGGATCT...
```

- Each entry must begin with a unique gene ID (e.g., `ATHA_10034`).
- ⚠️ **Avoid using special characters** (e.g., colons, pipes) or **overly long IDs** in gene names.  
  Some tools such as PRANK or KaKs_Calculator2 may fail or misinterpret headers with such patterns.
- CDS sequences must:
  - Represent **coding regions only** (no introns, UTRs, or protein translations)
  - Be **a multiple of 3 in length**, as required by codon-aware tools like PRANK and KaKs_Calculator2

### 🧪 2. Gene Group Information File

A tab-delimited file that assigns genes to orthologous groups within species.

**Example (`test.groupinfo`):**
```
ATHA    G1      ATHA_11701
ATHA    G1      ATHA_12068
ATHA    G1      ATHA_13566
ATHA    G1      ATHA_15941
ATHA    G1      ATHA_18753
...
```

- **Column 1**: species abbreviation (e.g., `ATHA`). Must uniquely identify each species and remain consistent across the dataset.
- **Column 2**: group ID (e.g., `G1`)
- **Column 3**: gene ID matching the CDS FASTA headers

### 📤 Output Files

DupHIST outputs the following files:

- `result_table_all.txt`: Final summary table of all duplication pairs and clustering results
- `dendrograms/`: Includes dendrograms for each gene family, represented in Newick (.nwk) format
- `temp_files/`: Contains intermediate outputs including pairwise Ks values and clustering matrices

All outputs are saved under the directory specified in `Output_directory` in your config file.

---

## 🧪 Example Dataset

A minimal example dataset is provided in the `example/` directory to help users test and understand how DupHIST works.

### ▶️ To run the example:

```bash
cd example
duphist test.config.txt
```

This script will:
- Use `test.cds.fa` and `test.groupinfo` as input
- Run DupHIST with the provided `config.txt`
- Save results in the `Results/` directories

### 📁 Files included in `example/`:
- `test.cds.fa` — Coding sequence (CDS) FASTA file
- `test.groupinfo` — Gene group assignment file
- `test.config.txt` — Configuration file with appropriate parameters and program paths
- `run_example.sh` — Shell script to execute the pipeline

---

## 📄 License

This project is licensed under the **MIT License**.  
You are free to use, modify, and distribute the code under the terms of the license.

See the full license text in [LICENSE](./LICENSE).

---

## 🤝 Contributing

We welcome contributions, feature suggestions, and bug reports!

If you would like to contribute to DupHIST:

1. Fork the repository
2. Create a new feature or bugfix branch
3. Submit a pull request with a clear description of your changes

For major changes, please open an issue first to discuss your ideas.  
We also welcome example data contributions to improve testing and usability.
