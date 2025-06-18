# HPC Installation Guide (No Sudo Required)

## For HPC Systems Without Sudo Access

If you're on an HPC system without sudo privileges (like your case), use the conda-based installation instead.

### Prerequisites

- Access to conda/miniconda (most HPC systems have this as a module)
- Internet connectivity for downloading packages

### Step-by-Step Installation

#### 1. Load Conda Module (if needed)
```bash
# On most HPC systems, load conda as a module
module load conda
# or
module load miniconda
# or 
module load anaconda
```

#### 2. Install Dependencies via Conda
```bash
# Create conda environment with all dependencies
./scripts/install_dependencies_conda.sh
```

This will:
- Create a new conda environment called `ior-darshan`
- Install MPI, HDF5, compilers, and Python packages
- Create an activation script `activate_ior_env.sh`

#### 3. Activate Environment
```bash
# Activate the conda environment
source ./activate_ior_env.sh
```

#### 4. Install IOR
```bash
# Install IOR using conda dependencies
./scripts/install_ior_conda.sh
```

#### 5. Install Darshan
```bash
# Install Darshan using conda dependencies
./scripts/install_darshan_conda.sh
```

#### 6. Create Configurations
```bash
# Create all 15 benchmark configurations
./scripts/create_configs.sh
```

#### 7. Test Installation
```bash
# Run comprehensive tests
./scripts/run_tests_conda.sh
```

### Complete Installation Commands

```bash
# 1. Load conda (if it's a module)
module load conda

# 2. Install everything
./scripts/install_dependencies_conda.sh
source ./activate_ior_env.sh
./scripts/install_ior_conda.sh
./scripts/install_darshan_conda.sh
./scripts/create_configs.sh
./scripts/run_tests_conda.sh
```

### Using the Environment

Every time you want to use the benchmark:

```bash
# Activate the environment
source ./activate_ior_env.sh

# Run benchmarks
./scripts/run_posix_benchmark.sh
./scripts/run_hdf5_benchmark.sh
```

### What Gets Installed

The conda environment includes:
- **Compilers**: GCC, G++, Gfortran
- **MPI**: OpenMPI with mpicc, mpicxx
- **HDF5**: HDF5 library with parallel support
- **Python**: NumPy, Pandas, Matplotlib, Seaborn, PyDarshan
- **Build tools**: Make, CMake, Autotools

### Troubleshooting

**Conda not found**:
```bash
# Try loading conda module
module avail conda
module load conda/latest
```

**Compiler issues**:
```bash
# Check if environment is activated
echo $CONDA_PREFIX
# Should show path to conda environment
```

**MPI issues**:
```bash
# Verify MPI installation
which mpicc
mpicc --version
```

### Advantages of Conda Approach

✅ **No sudo required** - Everything installs in user space  
✅ **Reproducible** - Same environment across different systems  
✅ **Isolated** - Doesn't interfere with system packages  
✅ **Complete** - Includes all dependencies in one environment  
✅ **Portable** - Can be used on any HPC system with conda  

### File Locations

- **Conda environment**: `~/miniconda3/envs/ior-darshan/` (or similar)
- **IOR binary**: `$CONDA_PREFIX/bin/ior`
- **Darshan library**: `$CONDA_PREFIX/lib/libdarshan.so`
- **Source code**: `~/software/src/`
- **Results**: `./logs/`

This approach is specifically designed for HPC environments where users don't have administrative privileges.

