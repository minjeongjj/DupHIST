# DupHIST

**DupHIST (Duplication History Inference with Substitution-integrated Topology)** is a computational pipeline that reconstructs the hierarchical timing and order of gene duplication events by integrating maximum likelihood (ML)-based phylogenetic topology with substitution-derived temporal information.

By combining topology-aware evolutionary relationships with statistically smoothed synonymous substitution rates (Ks), DupHIST infers a chronologically consistent and phylogenetically robust duplication history for paralogous genes within user-defined gene families.

---

## 🔬 Conceptual Overview

DupHIST is designed as a topology-integrated framework for duplication history inference. It:

- Establishes duplication relationships using ML-based phylogenetic reconstruction  
- Maps substitution-derived timing information onto the inferred topology  
- Detects temporal inconsistencies between Ks values and hierarchical structure  
- Applies topology-guided statistical smoothing  
- Produces evolutionarily coherent duplication hierarchies  

This ensures that inferred duplication timing reflects both evolutionary structure and substitution dynamics.

---

## 📦 Installation

Install via [Bioconda](https://anaconda.org/bioconda/duphist):

```bash
conda create -n duphist
conda activate duphist
conda install -c bioconda duphist
```

---

## ▶️ Quick Start

After preparing input files and configuration:


```bash
duphist config.txt
```

---

## ⚙️ Configuration File (`config.txt`)

DupHIST requires a configuration file to define input paths, statistical parameters, and program locations. Below is the updated template with the latest ML and statistical options.

```ini
[required_option]
cds_fasta = test.cds.fa
pep_fasta = test.pep.fa
group_info = test.groupinfo
output_dir = Results

[ML_option]
size_threshold = 10

[statistical_option]
stat_lamda = 10
stat_alpha = 10
start_wraw = 1

[kaks_cal_option]
genetic_code = 1
method = MYN

[PRANK_option]
iteration = 5
sleep_time = 3

[program_path]
mafft_path = fftns
iqtree_path = iqtree
fasttree_path = fasttree
prank_path = prank
kaks_path = KaKs_Calculator
perl = perl
R = Rscript

[Result]
result_filename = duphist_result.table
result_dendrogram_dir = duphist_result.nwk
temp_path = temp_files

[Thread]
thread_num = 1
```

---

## 🧰 Dependencies

Installed via Bioconda.

- MAFFT  
- IQ-TREE  
- FastTree  
- PRANK  
- KaKs_Calculator  
- R  
- Perl  

---

## 🧪 KaKs_Calculator Usage

**DupHIST includes KaKs_Calculator v2.0 by default.**  
If you installed DupHIST via Bioconda, you **do not need** to install KaKs_Calculator separately or specify a manual path in most environments.

### ⚠️ Version & Path Customization
*   **Default Version**: DupHIST is optimized for **v2.0**.
*   **KaKs_Calculator v3.0**: Note that v3.0 is not currently available via Conda. If you prefer to use v3.0 (or a custom compiled version), you must download it manually and specify the absolute path in your `config.txt`.

**Example (Custom Path):**
```ini
[program_path]
kaks_path = /usr/local/bin/KaKs_Calculator
```

---

## 📁 Input/Output Format

DupHIST requires three main input files:

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

### 🥩 2. Protein Sequence File (PEP)

A multi-FASTA file containing **Protein (amino acid) sequences** corresponding to the entries in the CDS file.

**Example (`test.pep.fa`):**
```fasta
>ATHA_10034
MSSDMRDERFFYHRYLSVTNRT...
>ATHA_1013
MRKGNEEKNYREEEYFQLPLDL...
```

- **Requirement**: There must be a strict **one-to-one correspondence** between Gene IDs in the PEP and CDS files.
- Each entry must use the exact same unique gene ID as its CDS counterpart (e.g., `>ATHA_10034`).

### 🧪 3. Gene Group Information File

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

---

### 📤 Output Files

DupHIST generates the following output files:

- **`duphist_result.table`**: Summary table listing all duplication comparisons and inferred clusters
- **`duphist_result.nwk/`**: Dendrograms for each gene family (Newick format)
- **`temp_files/`**: Intermediate results (e.g., Ks matrices and alignments)

### 📄 Example: `duphist_result.table`

This file summarizes Ks values and inferred duplication clusters for each gene pair or node.

**Example:**
```
Species Group   Node    Pair1           Pair2           Ks
ATHA    G1      node1   ATHA_12068      ATHA_18753      1.85607
ATHA    G1      node2   ATHA_15941      node1           2.05721
ATHA    G1      node3   ATHA_13566      node2           3.01953
ATHA    G1      node4   ATHA_11701      node3           3.16262
ATHA    G2      node1   ATHA_11178      ATHA_11395      2.06971
...
```

- **Column 1**: species abbreviation (e.g., `ATHA`)  
- **Column 2**: group ID (e.g., `G1`)  
- **Column 3**: The internal node ID assigned based on the ML topology.
- **Column 4**: The first gene ID or a child node involved in the duplication.
- **Column 5**: The second gene ID or a child node involved in the duplication. 
- **Column 6**: synonymous substitution rate (**Ks**)  

> 🔎 **Note on Nodes:**
> The `node1`, `node2`, etc., identifiers represent **internal nodes** of the phylogenetic tree inferred by **IQ-TREE** or **FastTree**. 

---

## 🧪 Example Dataset

The example dataset is available in the **`example/`** directory of the [DupHIST GitHub repository](https://github.com/minjeongjj/DupHIST).

> ⚠️ **Note:** If you installed DupHIST via **Conda**, the example files are not included in your local environment. Please download them from the GitHub repository to test the pipeline.

### How to run the example:

1.  **Clone the repository** (or download the `example` folder):

    ```bash
    git clone https://github.com/minjeongjj/DupHIST.git
    cd duphist/example
    ```

2.  **Run DupHIST** using the provided test configuration:

    ```bash
    duphist test.config.txt
    ```

### Included Example Files:

  - `test.cds.fa`: Sample coding sequences.
  - `test.pep.fa`: Sample protein sequences (matching the CDS).
  - `test.groupinfo`: Sample gene family mapping.
  - `test.config.txt`: A ready-to-use configuration file for the example run.

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
