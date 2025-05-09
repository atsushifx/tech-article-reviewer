// src: configs/commitlint.config.js
// @(#) : commitlint configuration for this workspace
/**
 * @version   1.0.0
 * @author    atsushifx <atsushifx@gmail.com>
 * @since     2025-04-12
 * @license   MIT
 *
 * @description<<
 *
 * This file defines commitlint rules for this project.
 * It loads the standard configuration from @commitlint/config-conventional
 * and applies a formatter for CLI output.
 *
 * <<
 */

// type check for typescript
// import type { UserConfig } from '@commitlint/types'//;

// commit lint common configs
const baseConfig = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'type-enum': [2, 'always', [
      'feat',
      'fix',
      'chore',
      'docs',
      'test',
      'refactor',
      'perf',
      'ci',
      'merge',
	  "build",
	  "style",
	  "deps",
    ]],
    'subject-case': [2, 'never', ['start-case', 'pascal-case']], // etc
    'header-max-length': [2, 'always', 72],
  },
};

// export
export default baseConfig;
