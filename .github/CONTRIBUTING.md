# Contributing to RK3588 Model Zoo

First off, thank you for considering contributing to RK3588 Model Zoo! It's people like you that make this project great.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
  - [Reporting Bugs](#reporting-bugs)
  - [Suggesting Enhancements](#suggesting-enhancements)
  - [Adding a New Model](#adding-a-new-model)
  - [Pull Requests](#pull-requests)
- [Development Setup](#development-setup)
- [Commit Guidelines](#commit-guidelines)
- [License](#license)

## Code of Conduct

This project and everyone participating in it is governed by our [Code of Conduct](./CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

## How Can I Contribute?

### Reporting Bugs

Before creating a bug report, please check the existing issues to avoid duplicates. When creating a bug report, please include:

- **Clear title and description**
- **Hardware info**: Board model (e.g., Radxa Rock 5T), OS version
- **Software info**: RKNN toolkit version, Python version, model name
- **Steps to reproduce** the issue
- **Expected vs. actual behavior**
- **Relevant logs** and error messages

You can use our [Bug Report Template](./ISSUE_TEMPLATE/bug_report.md) to file a bug.

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, please include:

- **Clear title and description**
- **Use case**: Why is this enhancement needed?
- **Proposed solution**: How should it work?
- **Alternatives considered**: What other approaches have you considered?

You can use our [Feature Request Template](./ISSUE_TEMPLATE/feature_request.md) to suggest a feature.

### Adding a New Model

We welcome contributions of new model deployments for the RK3588 platform! To add a new model:

1. **Check existing issues/PRs** to ensure the model isn't already being worked on
2. **Open an issue** first to discuss the model you want to add and get feedback
3. **Follow the project structure** — create a new directory named `<model-name>-rk3588/`
4. **Include the following** in your model directory:
   - `README.md` with detailed deployment instructions
   - `RUN_ON_RK3588.md` with board-specific instructions (if applicable)
   - Build scripts (`build.sh`, `CMakeLists.txt`, etc.)
   - Runtime setup scripts (`setup.sh`)
   - Test scripts and sample data
   - Source code for inference
5. **Ensure compatibility** — your model must work on the RK3588 NPU with RKNN/RKLLM
6. **Document everything** — include clear setup, build, and run instructions
7. **Test thoroughly** — verify on actual RK3588 hardware when possible

### Pull Requests

1. **Fork** the repository
2. **Create a feature branch** from `main`:
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Make your changes** and commit them with clear messages
4. **Test your changes** thoroughly
5. **Push** to your fork:
   ```bash
   git push origin feature/your-feature-name
   ```
6. **Open a Pull Request** against the `main` branch

#### PR Guidelines

- Fill in the [Pull Request Template](./PULL_REQUEST_TEMPLATE.md) completely
- Keep PRs focused — one feature or fix per PR
- Include relevant documentation updates
- Ensure all existing functionality still works
- Add tests for new functionality when possible

## Development Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/YOUR_USERNAME/rk3588-model-zoo.git
   cd rk3588-model-zoo
   ```

2. Set up the development environment following our guides:
   - [Clone Guide](../CLONE_GUIDE.md) — Import official dependency repositories
   - [Conda Setup Guide](../CONDA_GUIDE.md) — Configure the development environment

3. Install system dependencies:
   ```bash
   apt-get install libglib2.0-0
   apt-get install libgl1-mesa-glx libgl1-mesa-dev
   ```

## Commit Guidelines

- Use clear, descriptive commit messages
- Start with a capitalized verb in the imperative mood (e.g., `Add`, `Fix`, `Update`)
- Keep commits focused and atomic
- Reference related issues when applicable (e.g., `Fix #123`)

Examples:
```
Add Whisper ASR model deployment
Fix memory leak in image encoder
Update README with new model listing
```

## License

By contributing to this project, you agree that your contributions will be licensed under the [Apache License 2.0](../LICENSE).
