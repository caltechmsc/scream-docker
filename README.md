# SCREAM (Docker Version)

A portable Docker environment for running the original, legacy **SCREAM** (Side-Chain Rotamer Excitation Analysis Method) software on modern Linux systems.

It encapsulates the complete CentOS 6 runtime environment, including Python 2.4.2 and all necessary libraries, allowing the pre-compiled legacy binaries to execute as they did on the original hardware.

## Tech Stack

- **Containerization**: Docker
- **Base OS**: CentOS 6
- **Runtime**: Python 2.4.2, Perl 5.10.1

## Getting Started

### Prerequisites

- Docker installed on your system. Follow the [official Docker installation guide](https://docs.docker.com/get-docker/) for your OS.
- A compatible Linux environment (e.g., Ubuntu 20.04 or CentOS 7) for running Docker.

### Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/caltechmsc/scream-docker.git && cd scream-docker
   ```

2. Build the Docker image & Setup Environment:

   ```bash
   chmod +x ./install && ./install
   ```

3. Run SCREAM:

   ```bash
   `scream-legacy <sub-command> [options]`
   ```

### Uninstallation

To remove the Docker image and clean up:

```bash
./uninstall
```

## Usage

Once installed, you can run SCREAM commands using the `scream-legacy` script. For example:

```bash
cd ./examples/standard
scream-legacy standard -i scream.par -o output.bgf
```

> More usage examples can be found in the `examples` directory.

> **Note**: Relative paths will be resolved based on the current working directory (outside the container). Absolute paths should be used with caution, as they will be interpreted within the container's filesystem (e.g., `/app/lib/*`).
