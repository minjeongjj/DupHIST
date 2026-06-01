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

DupHIST requires a configuration file to define input paths, statistical parameters, topology options, and program locations.

```ini
[required_option]
cds_fasta = test.cds.fa
pep_fasta = test.pep.fa
group_info = test.groupinfo
output_dir = Results

[topology_option]
custom_tree_list = NA

[ML_option]
size_threshold = 10

[statistical_option]
stat_lamda = 10
stat_alpha = 10
start_wraw = 1

[topology_option]
custom_tree_list = NA

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
result_filename = result_table_all.txt
result_dendrogram_dir = result_nwk
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

If you installed DupHIST via Bioconda, you do not need to install KaKs_Calculator separately or specify a manual path in most environments.

### Version and path customization

- **Default version**: DupHIST is optimized for KaKs_Calculator v2.0.
- **KaKs_Calculator v3.0**: v3.0 is not currently available via Conda. If you prefer to use v3.0 or a custom compiled version, download it manually and specify the absolute path in `config.txt`.

Example:

```ini
[program_path]
kaks_path = /usr/local/bin/KaKs_Calculator
```

---

## 📁 Input/Output Format

DupHIST requires three main input files.

For multi-copy gene families, comprehensive gene re-annotation is recommended before running DupHIST to improve inference accuracy.

---

### 1. Coding Sequence File (`CDS`)

A multi-FASTA file containing coding DNA sequences for all genes used in duplication inference.

Example:

```fasta
>ATHA_10034
ATGTCCTCGGATATGCGTGACGAGCGTTTCTTTTATCATCGATATCTTTCCGTTACAAATAGAAC...
>ATHA_1013
ATGAGAAAAGGAAATGAAGAGAAGAATTACCGTGAAGAAGAATATTTGCAACTCCCTCTGGATCT...
```

Requirements:

- Unique gene IDs
- CDS only
- No introns, UTRs, or translated protein sequences
- Sequence length divisible by 3
- IDs matching the protein and group information files
- No duplicated gene IDs

Important notes:

- Avoid special characters in gene IDs, such as colons `:` or pipes `|`.
- Avoid overly long gene IDs.
- Some tools, including PRANK and KaKs_Calculator, may fail or misinterpret complex FASTA headers.
- Gene sequences not divisible by 3 will be automatically excluded from analysis.

---

### 2. Protein Sequence File (`PEP`)

A multi-FASTA file containing protein sequences corresponding to the CDS file.

Example:

```fasta
>ATHA_10034
MSSDMRDERFFYHRYLSVTNRT...
>ATHA_1013
MRKGNEEKNYREEEYFQLPLDL...
```

Requirements:

- One-to-one correspondence with CDS entries
- Same gene IDs as the CDS file
- No duplicated gene IDs

---

### 3. Gene Group Information File

A tab-delimited file assigning genes to species-specific gene groups.

Example:

```text
ATHA    G1      ATHA_11701
ATHA    G1      ATHA_12068
ATHA    G1      ATHA_13566
ATHA    G1      ATHA_15941
ATHA    G1      ATHA_18753
```

Columns:

- **Column 1**: species abbreviation (e.g., `ATHA`). Must uniquely identify each species and remain consistent across the dataset.
- **Column 2**: group ID (e.g., `G1`).
- **Column 3**: gene ID matching the CDS FASTA headers.

Requirements:

- Species abbreviations must uniquely identify each species.
- Species abbreviations must remain consistent across the dataset.
- Group IDs must remain consistent across the dataset.
- Gene IDs must match the CDS and protein FASTA headers.

---

## 🔎 Precheck Validation

Before executing the main pipeline, DupHIST performs an automatic precheck step to validate input files.

This step checks input integrity and prevents downstream errors.

The precheck verifies:

### Naming rules

- Species abbreviations and group IDs must not contain underscores `_`.
- DupHIST uses underscores internally to combine species and group IDs.
- Example internal format: `ATHA_G1`

### Group composition

- Each species-group combination must include at least two genes.
- Groups with only one gene are considered invalid.

### Gene consistency

- All gene IDs in the group information file must exist in the CDS file.
- Missing or mismatched genes will trigger an error.

Precheck results are written to:

```text
duphist_precheck.log
```

If no errors are found, DupHIST proceeds to the main analysis.  
If issues are detected, they will be reported in the log, and the pipeline terminates before starting the main computation.

Please check `duphist_precheck.log` before interpreting missing outputs or errors.

---

## 🌳 User-supplied Tree Option

DupHIST supports user-supplied phylogenetic trees in Newick format.

### Default setting

```ini
[topology_option]
custom_tree_list = NA
```

- `NA`: DupHIST builds trees automatically.
- Custom tree list file: DupHIST uses user-provided tree topologies.

### Custom tree setting

```ini
[topology_option]
custom_tree_list = test.customtree.path
```

### Custom tree list format

The custom tree list must be a tab-delimited file with three columns:

Example:

```text
ATHA    G1    /user/path/ATHA_G1.nwk
ATHA    G2    /user/path/ATHA_G2.nwk
```

Columns:

- **Column 1**: species abbreviation (e.g., `ATHA`). Must uniquely identify each species and remain consistent across the dataset.
- **Column 2**: group ID (e.g., `G1`). Must match the group ID in `group_info`.
- **Column 3**: full path to the Newick tree file.

### Supported tree format

Each tree file should contain one complete Newick tree.

Example:

```text
((geneA:0.12,geneB:0.08):0.05,(geneC:0.10,geneD:0.11):0.04);
```

Required conditions:

- Standard parenthesis-based Newick format
- Terminal semicolon `;`
- Gene IDs as terminal labels
- Terminal gene IDs matching the corresponding group in `group_info`

### Important notes

The custom tree may cause an error if:

- Extra genes are present
- Some genes are missing
- Gene IDs differ from those in `group_info`
- Unsupported internal node labels are included
- The tree structure cannot be parsed correctly

Make sure each custom tree contains only the expected terminal genes for the corresponding species and group.

---

## 📤 Output Files

DupHIST generates the following output files:

- **`result_table_all.txt`**: summary table listing all duplication comparisons and inferred clusters
- **`result_nwk/`**: dendrograms for each gene family in Newick format
- **`raw_ks_values.txt`**: raw Ks values before smoothing
- **`temp_files/`**: intermediate files such as Ks matrices and alignments

### Example: `result_table_all.txt`

This file summarizes Ks values and inferred duplication clusters for each gene pair or node.

Example:

```text
Species Group   Node    Pair1           Pair2           Ks
ATHA    G1      node1   ATHA_12068      ATHA_18753      1.85607
ATHA    G1      node2   ATHA_15941      node1           2.05721
ATHA    G1      node3   ATHA_13566      node2           3.01953
ATHA    G1      node4   ATHA_11701      node3           3.16262
ATHA    G2      node1   ATHA_11178      ATHA_11395      2.06971
...
```

Columns:

| Column | Description |
|---|---|
| 1 | Species abbreviation |
| 2 | Group ID |
| 3 | Internal node ID assigned based on the ML topology |
| 4 | First gene ID or child node involved in the duplication |
| 5 | Second gene ID or child node involved in the duplication |
| 6 | Synonymous substitution rate, Ks |

The `node1`, `node2`, and other node identifiers represent internal nodes of the phylogenetic tree inferred by IQ-TREE, FastTree, or user-supplied tree topology.

---

## 🧪 Example Dataset

The example dataset is available in the `example/` directory of the DupHIST GitHub repository.

If you installed DupHIST via Conda, the example files are not included in your local environment. Please download them from the GitHub repository to test the pipeline.

### How to run the example

Clone the repository or download the `example` folder:

```bash
git clone https://github.com/minjeongjj/DupHIST.git
cd DupHIST/example
```

Run DupHIST with the default mode:

```bash
duphist test.config.txt
```

Run DupHIST with user-supplied trees:

```bash
duphist test.custom.config.txt
```

The `test.custom.config.txt` file is preconfigured to use `test.customtree.path`.

### Included example files

- **`test.cds.fa`**: sample coding sequences
- **`test.pep.fa`**: sample protein sequences matching the CDS file
- **`test.groupinfo`**: sample gene family mapping
- **`test.config.txt`**: configuration file for the default tree-building mode
- **`test.custom.config.txt`**: configuration file for running DupHIST with user-supplied trees
- **`test.customtree.path`**: tab-delimited list of custom Newick tree files

---

## 📄 License

This project is licensed under the MIT License.  
See `LICENSE` for details.

---

## 🤝 Contributing

We welcome contributions, feature requests, and bug reports.

To contribute:

1. Fork the repository
2. Create a feature or fix branch
3. Submit a pull request with a clear explanation

For major changes, please open an issue first.  
Example data contributions are also appreciated.

