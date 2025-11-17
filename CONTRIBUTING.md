# 🤝 Contribution Guidelines

<!-- textlint-disable ja-technical-writing/no-exclamation-question-mark,prh -->
Thank you for considering contributing to this project!
We hope that together we can build a better project with your collaboration.
<!-- textlint-enable -->

## 📝 How to Contribute

### 1. Creating Issues

Please report bugs or suggest features via [Issues](https://github.com/atsushifx/tech-article-reviewer/issues).

#### Before Creating an Issue

- Search existing Issues to check if a similar report already exists.
- Avoiding duplicates helps resolve issues more smoothly.

#### Types of Issues

This project accepts the following types of Issues:

- **Bug Reports** - Report malfunctions or unexpected behavior
- **Feature Requests** - Propose new features or improvements
- **Documentation Improvements** - Report documentation errors or suggest improvements
- **Questions** - Ask about usage or specifications

#### Information to Include in Issues

**For Bug Reports**:

- Steps to reproduce (as detailed as possible)
- Expected behavior
- Actual behavior
- Environment information (OS, Node.js version, etc.)
- Error messages or screenshots

**For Feature Requests**:

- Overview of the proposed feature
- Use cases you want to achieve
- Relationship with existing features
- Implementation ideas (if any)

### 2. Submitting Pull Requests

#### Basic Workflow

1. **Fork the Repository**

   Fork the repository on GitHub.

2. **Clone Locally**

   ```bash
   git clone https://github.com/<YOUR_USERNAME>/tech-article-reviewer.git
   cd tech-article-reviewer
   ```

3. **Create a Branch**

   Create a branch with a descriptive name for each feature or bug fix:

   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/bug-description
   ```

4. **Set Up Development Environment**

   ```bash
   pnpm install
   pnpm run prepare
   ```

5. **Make Changes**

   - Modify code or documentation.
   - Follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) for commit messages.
   - We recommend one commit per feature.

6. **Quality Checks**

   Run the following commands to verify quality before committing:

   ```bash
   dprint fmt                  # Formatting
   pnpm run check:spells       # Spell checking
   pnpm run lint:text          # Japanese linting
   pnpm run lint:markdown      # Markdown linting
   pnpm run lint:filename      # Filename validation
   pnpm run lint:secrets       # Secret detection
   ```

7. **Commit and Push**

   ```bash
   git add .
   git commit    # Git hooks will run automatically
   git push origin feature/your-feature-name
   ```

8. **Create Pull Request**

   - Create a pull request on GitHub.
   - Write a one-line summary of changes in the title.
   - Include the following in the description:
     - Purpose and background of changes
     - Details of changes
     - Related Issue number (if any, in the format `#123`)
     - Testing methods and verification points

#### Pull Request Guidelines

- Create pull requests against the `main` branch.
- Focus on one feature or fix per pull request.
- Respond to reviewer feedback as quickly as possible.
- Ensure all CI checks pass.

## 🛠️ Project Environment

### Tech Stack

| Category            | Tool         | Description                                      |
| ------------------- | ------------ | ------------------------------------------------ |
| **Package Manager** | pnpm         | Fast and efficient package management            |
| **Formatter**       | dprint       | 120 character width, 2 spaces, single quotes     |
| **Linters**         | textlint     | Japanese technical documentation style validation |
|                     | markdownlint | Markdown syntax validation                       |
|                     | ls-lint      | Filename convention validation                   |
| **Security**        | gitleaks     | Git repository secret scanning                   |
|                     | secretlint   | Text file secret detection                       |
| **Git Hooks**       | lefthook     | Including automatic commit message generation    |

### Coding Conventions

#### Conventional Commits

Follow this format for commit messages:

```text
<type>(<scope>): <subject>

<body>
```

**Standard Types**:

- `feat` - New feature
- `fix` - Bug fix
- `docs` - Documentation changes
- `test` - Test additions/modifications
- `refactor` - Refactoring
- `perf` - Performance improvements
- `ci` - CI configuration changes
- `chore` - Other changes

**Custom Types**:

- `config` - Configuration file changes
- `release` - Releases
- `merge` - Merge commits
- `build` - Build system changes
- `style` - Code style changes
- `deps` - Dependency updates

**Constraints**:

- Maximum 72 characters for header
- Scope is optional

#### Japanese Documentation Rules

Technical documentation style enforced by textlint:

- Maximum sentence length: 100 characters
- Maximum consecutive kanji: 8 characters
- Headings: declarative tone (である調)
- Body text: polite tone (ですます調)
- Spaces required between half-width and full-width characters
- Custom dictionary: `https://atsushifx.github.io/proof-dictionary/`

#### Code Formatting

- Maximum line width: 120 characters
- Indentation: 2 spaces
- Strings: Single quotes
- Line endings: LF (CRLF prohibited)

### Windows Environment Notes

This project primarily targets Windows environments.

- Git Bash required: For running bash scripts in `scripts/`
- LF line endings: Use LF even in Windows (do not auto-convert to CR+LF)
- Path length limitation: `core.longpaths true` is already configured

Git configuration:

```bash
git config core.autocrlf true
git config --global core.longpaths true
```

### Editing Prompt Files

The prompt files in the `tech-articles-prompt/` directory are core assets of this project.

- Consider changes carefully.
- For major changes, always discuss in an Issue before implementation.
- When changing the variable system or command syntax, consider the impact on existing users.

## Code of Conduct

All contributors must comply with the [Code of Conduct](CODE_OF_CONDUCT.ja.md).

## References

- [CLAUDE.md](./CLAUDE.md) - Project guide for AI and developers
- [README.md](./README.md) - Project overview
- [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)
- [GitHub Docs: Setting guidelines for repository contributors](https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/setting-guidelines-for-repository-contributors)

---

## 📬 Quick Links

<!-- textlint-disable @textlint-ja/ai-writing/no-ai-list-formatting -->
- [🐛 Create a Bug Report](https://github.com/atsushifx/tech-article-reviewer/issues/new?template=bug_report.yml)
- [✨ Create a Feature Request](https://github.com/atsushifx/tech-article-reviewer/issues/new?template=feature_request.yml)
- [📄 Report Documentation Issue](https://github.com/atsushifx/tech-article-reviewer/issues/new?template=documentation_improvement.yml)
- [❓ Ask a Question](https://github.com/atsushifx/tech-article-reviewer/issues/new?template=question.yml)
- [💬 Post a Free Topic](https://github.com/atsushifx/tech-article-reviewer/issues/new?template=open_topic.yml)
- [🔀 Create a Pull Request](https://github.com/atsushifx/tech-article-reviewer/compare)
<!-- textlint-enable -->

---

## 🤖 Powered by

This project's documentation and operations are supported by these AI agents:

- **Elpha** - Cool and precise support
- **Kobeni** - Gentle and caring assistance
- **Tsumugi** - Bright and energetic follow-up

Together, we aim for a better contribution experience.
