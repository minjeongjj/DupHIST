# DupHIST

**DupHIST (Duplication History Inference via Substitution-based Timeframe)** is an automated pipeline for inferring the relative duplication timing and order among paralogous genes within user-defined gene families. It leverages pairwise synonymous substitution rates (**Ks**) to reconstruct duplication history.

---

## 🔍 Key Features

- Calculates pairwise Ks values for coding sequences within gene families
- Constructs distance matrices and infers duplication order via hierarchical clustering
- Supports various clustering methods (e.g., average, complete, single linkage), with **cophenetic correlation coefficient (CCC)** used to select the optimal one
- Offers both **global** and **per-family** clustering modes
- Generates dendrograms, Ks tables, and summary outputs
- Compatible with tools like **PRANK** (for codon alignment) and **KaKs_Calculator 2.0** (for Ks estimation)
- Supports downstream integration with gene/domain annotation data

---

## 📦 Installation

Install via [Bioconda](https://anaconda.org/bioconda/duphist):

```bash
conda install -c bioconda duphist
```

---

## 🧪 KaKs_Calculator Usage

**DupHIST includes KaKs_Calculator v2.0 by default.**  
You **do not need** to install it separately or specify a path.

> ⚠️ **Note:** KaKs_Calculator v3.0 is not available via Conda.  
> If you prefer v3.0, download it manually and specify its path in `config.txt`.

**Example:**
```
[program_path]
kaks = /your/path/to/KaKs_Calculator
```

If you use a custom version, DupHIST will raise an error if the path is incorrect or missing.

---

## ▶️ Quick Start

After preparing your input files and configuration:

```bash
duphist config.txt
```

---

## ⚙️ Sample `config.txt`

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
- Contain **only coding regions** (no introns, UTRs, or translations)
- Have a length that is a **multiple of 3**, as required by codon-aware tools like PRANK and KaKs_Calculator2

  ⚠️ Gene sequences not divisible by 3 will be automatically excluded from analysis.

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

### 🔎 Precheck Validation

Before executing the main pipeline, **DupHIST performs an automatic precheck step** to validate the input files. This step ensures the integrity and consistency of user-provided data and prevents downstream errors.

The precheck verifies the following:

1. **Naming rules**
   - Species abbreviations and group IDs must **not contain underscores (`_`)**.
   - DupHIST uses underscores internally to combine species and group IDs (e.g., `ATHA_G1`), so underscores in input names may cause parsing errors.

2. **Group composition**
   - Each species–group combination must include **at least two genes**.
   - Groups with only one gene are considered invalid and will be blocked.

3. **Gene consistency**
   - All gene IDs listed in the group information file must have corresponding entries in the CDS file.
   - Any mismatch or missing gene will trigger an error.

Precheck results are written to a log file named **`duphist_precheck.log`**.

- If **no errors are found**, DupHIST proceeds to the main analysis.
- If **any issues are detected**, they will be reported in the log, and **the pipeline will terminate** without starting the main computation.

> 🛠️ Please check `duphist_precheck.log` before interpreting missing outputs or errors.

### 📤 Output Files

DupHIST generates the following output files:

- **`result_table_all.txt`**: Summary table listing all pairwise duplication comparisons and inferred clusters
- **`dendrograms/`**: Dendrograms for each gene family (Newick format)
- **`temp_files/`**: Intermediate results (e.g., Ks matrices and alignments)

### 📄 Example: `result_table_all.txt`

This file summarizes Ks values and inferred duplication clusters for each gene pair or node.

**Example:**
```
ATHA    G1      ATHA_11701      ATHA_13566      0.619739
ATHA    G1      ATHA_12068      ATHA_15941      1.81918
ATHA    G1      ATHA_18753      G2              2.18202
ATHA    G1      G1              G3              2.64991
ATHA    G2      ATHA_1013       ATHA_10965      1.30532
...
```

- **Column 1**: species abbreviation (e.g., `ATHA`)  
- **Column 2**: group ID (e.g., `G1`)  
- **Column 3**: first gene or internal node  
- **Column 4**: second gene or internal node  
- **Column 5**: synonymous substitution rate (**Ks**)  

> 🔎 **Note:** `G1`, `G2`, etc. are internal nodes automatically assigned by R’s `hclust` and represent inferred duplication events—not actual gene names.

---

## 🧪 Example Dataset

An example dataset is provided in the `example/` directory.

To run it:

```bash
cd example
duphist test.config.txt
```

Includes:
- `test.cds.fa` — coding sequence file  
- `test.groupinfo` — group mapping file  
- `test.config.txt` — ready-to-use configuration  
- `run_example.sh` — shell script to run the pipeline

---

## 📄 License

This project is licensed under the **MIT License**.  
See [LICENSE](./LICENSE) for details.

---

## 🤝 Contributing

We welcome contributions, feature requests, and bug reports.

To contribute:

1. Fork the repository  
2. Create a feature or fix branch  
3. Submit a pull request with a clear explanation

For major changes, please open an issue first.  
Example data contributions are also appreciated!
