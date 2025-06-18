# Simple Installation Guide (Conda + Pip)

## Your Preferred Approach: Simple Conda Environment

This guide follows your preferred method: create a basic conda environment with Python 3.9, then use pip for dependencies.

### Step-by-Step Installation

#### 1. Load Conda Module (if needed on HPC)
```bash
# On HPC systems, load conda as a module
module load conda
# or
module load miniconda
```

#### 2. Create Simple Conda Environment
```bash
# Create conda environment with just Python 3.9
conda create -n ior_env python=3.9 -y
```

#### 3. Activate Environment
```bash
# Activate the environment
conda activate ior_env
```

#### 4. Set Up Environment with Dependencies
```bash
# Run the setup script (installs minimal conda packages + pip packages)
./scripts/setup_conda_env.sh
```

#### 5. Install IOR
```bash
# Make sure environment is activated
conda activate ior_env

# Install IOR
./scripts/install_ior_simple.sh
```

#### 6. Install Darshan
```bash
# Install Darshan
./scripts/install_darshan_simple.sh
```

#### 7. Create Configurations
```bash
# Create all benchmark configurations
./scripts/create_configs.sh
```

#### 8. Test Everything
```bash
# Run tests to verify installation
./scripts/test_simple_setup.sh
```

### Complete Installation Commands

```bash
# 1. Load conda (if needed)
module load conda

# 2. Create and activate environment
conda create -n ior_env python=3.9 -y
conda activate ior_env

# 3. Install everything
./scripts/setup_conda_env.sh
./scripts/install_ior_simple.sh
./scripts/install_darshan_simple.sh
./scripts/create_configs.sh
./scripts/test_simple_setup.sh
```

### What Gets Installed

#### Via Conda (minimal system packages):
- **Compilers**: GCC, G++, Gfortran
- **MPI**: OpenMPI
- **HDF5**: HDF5 library
- **Build tools**: Make, CMake, pkg-config

#### Via Pip (Python packages):
- **Core**: numpy, pandas, matplotlib, seaborn
- **I/O**: h5py, mpi4py
- **Analysis**: scipy, jupyter, pydarshan

### Daily Usage

Every time you want to use the benchmark:

```bash
# Activate environment
conda activate ior_env

# Run benchmarks
./scripts/run_posix_benchmark.sh
./scripts/run_hdf5_benchmark.sh

# Or use different configurations
source configs/medium_scale.conf && ./scripts/run_posix_benchmark.sh
```

### Environment Structure

```
~/miniconda3/envs/ior_env/
├── bin/
│   ├── ior                 # IOR benchmark
│   ├── mpicc              # MPI compiler
│   ├── darshan-parser     # Darshan utilities
│   └── python             # Python 3.9
├── lib/
│   ├── libdarshan.so      # Darshan library
│   └── libhdf5.so         # HDF5 library
└── include/               # Header files
```

### Advantages of This Approach

✅ **Simple**: Just `conda create -n ior_env python=3.9 -y`  
✅ **Clean**: Minimal conda packages, pip for Python dependencies  
✅ **Fast**: Quick environment creation  
✅ **Familiar**: Uses your preferred workflow  
✅ **Portable**: Works on any system with conda  

### Troubleshooting

**Environment activation issues**:
```bash
# Make sure conda is initialized
conda init bash
# Restart shell or source bashrc
source ~/.bashrc
```

**Compiler not found**:
```bash
# Check if environment is activated
echo $CONDA_DEFAULT_ENV  # Should show "ior_env"
```

**MPI issues**:
```bash
# Test MPI
mpicc --version
mpirun --version
```

This approach gives you exactly what you wanted: a simple conda environment with Python 3.9 and pip-installed dependencies!

