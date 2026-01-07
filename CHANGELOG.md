# Changelog

All notable changes to this project will be documented in this file.

## [1.3.0] - 2026-01-07

### Added
- **Title Functionality**: Added ability to name and edit titles for roll records in history
  - Roll records can now have custom titles
  - Double-tap roll history cards to edit titles
  - Titles are displayed in roll history
  
- **Exploding Dice**: Implemented exploding dice functionality
  - Added toggle to enable/disable exploding dice
  - Dice that roll maximum value automatically re-roll and add to total
  - Exploded dice count displayed in roll breakdown
  
- **Target Number System**: Added target value functionality
  - Set a target number to compare roll results against
  - Visual feedback shows whether roll met/exceeded target
  - Target value persists across rolls and is saved in history
  
- **Critical Roll Detection**: Added visual indicators for critical rolls
  - Minimum possible roll displays in red
  - Maximum possible roll displays in green
  - Big number display flashes appropriate color briefly when rolling a crit
  - Individual dice in breakdown show colored crits
  
- **Negative Modifiers**: Allowed negative values in modifier input dialog

### Changed
- Updated minimum window height for desktop platforms to accommodate new UI elements
- Reset dice count and modifier when a preset is selected
- Improved alignment of target value control with other card elements

### Fixed
- UI layout improvements for better element alignment
