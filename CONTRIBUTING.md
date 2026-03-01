## Contributing to libvalacore
Thank you for building libvalacore with us.
Every report, patch, test, and review directly improves the Vala development experience.
Let's make Vala's standard library truly world-class together.

## Contributing as a Developer
### 1. Start with clear communication
- Bug report: Use the issue template and include reproducible steps, expected behavior, and actual behavior.
- New feature: Open an issue first so we can agree on direction before implementation.
- Bug fix or improvement: Open a PR with a clear problem statement and solution summary.

### 2. Keep the quality bar high
- Add or update unit tests when you add features or fix bugs.
- Maintain 80%+ line coverage. Always cover normal cases, error cases, and boundary values.
- Follow the design philosophy documented in [CLAUDE.md](./CLAUDE.md) (Value Objects, defensive programming, immutability).

### 3. Run checks before opening a PR
```shell
./scripts/format.sh            # Format code with uncrustify
./scripts/lint.sh              # Run vala-lint (requires Docker)
meson setup build              # Configure (if not done)
meson test -C build            # Run all tests
./scripts/format.sh --check    # Verify formatting
./scripts/coverage.sh --check  # Verify 80%+ line coverage (requires: sudo apt install lcov)
# If tests were already run with coverage enabled:
./scripts/coverage.sh --check --skip-test
```

### 4. Code style
All code must follow the conventions in [CLAUDE.md](./CLAUDE.md):
- Write code comments and Valadoc in English to accept international contributors
- Write detailed Valadoc with `@param`, `@return`, and example code for all public methods
- Format with uncrustify (`etc/uncrustify.cfg`) before committing
- Pass vala-lint checks (`vala-lint.conf`) before committing

## Contributing Outside of Coding
You can still make a huge impact even if you are not writing code:

- Give libvalacore a GitHub Star
- Share libvalacore with the Vala community
- Open issues with clear reproduction steps
- [Sponsor the project](https://github.com/sponsors/nao1215)
