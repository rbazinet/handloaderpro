# Hodgdon Data Import System

This directory contains the seed data files for Hodgdon reloading data imported from the Hodgdon RLDC (Reloading Data Center) website.

## Overview

The Hodgdon data import system has been redesigned to separate data fetching from data import, making it more robust, testable, and maintainable. This system handles four types of data: cartridges, bullet weights, manufacturers, and powders.

## Architecture

### Two-Phase Approach

1. **Data Fetching** (`handloaderpro:hodgdon_data:fetch`)
   - Uses Selenium WebDriver to scrape the Hodgdon RLDC website
   - Handles JavaScript-heavy dynamic content
   - Saves raw data to structured JSON files
   - Includes metadata about the fetch operation
   - Can be run independently to update data

2. **Data Import** (`handloaderpro:hodgdon_data:import`)
   - Reads clean data from JSON files
   - Imports data into the database in dependency order
   - Idempotent (safe to run multiple times)
   - Can be run offline once data is fetched

## Files

The data is organized by cartridge type:

```
db/seeds/hodgdon_data/
├── rifle/
│   ├── metadata.json          # Rifle data fetch information
│   ├── cartridges.json        # Rifle cartridge data
│   ├── bullet_weights.json    # Rifle bullet weight data
│   ├── manufacturers.json     # Rifle manufacturer data
│   ├── powders.json          # Rifle powder data
│   └── *_cleaned.json        # Cleaned rifle data
├── pistol/
│   ├── metadata.json          # Pistol data fetch information
│   ├── cartridges.json        # Pistol cartridge data
│   ├── bullet_weights.json    # Pistol bullet weight data
│   ├── manufacturers.json     # Pistol manufacturer data
│   ├── powders.json          # Pistol powder data
│   └── *_cleaned.json        # Cleaned pistol data
└── backups/
    └── YYYYMMDD_HHMMSS/      # Timestamped backups
```

## Usage

### Basic Workflow

```bash
# 1. Fetch fresh data from Hodgdon RLDC (rifle data)
rails handloaderpro:hodgdon_data:fetch[rifle]

# 2. Fetch pistol data
rails handloaderpro:hodgdon_data:fetch[pistol]

# 3. (Optional) Clean and validate the data
rails handloaderpro:hodgdon_data:clean[rifle]
rails handloaderpro:hodgdon_data:clean[pistol]

# 4. Import data into database
rails handloaderpro:hodgdon_data:import[rifle]
rails handloaderpro:hodgdon_data:import[pistol]
```

### Fetch Strategies

The fetch task supports three different strategies for each cartridge type:

```bash
# Replace strategy (default) - Completely overwrites existing data
rails handloaderpro:hodgdon_data:fetch[rifle]
rails handloaderpro:hodgdon_data:fetch[pistol]
rails handloaderpro:hodgdon_data:fetch[replace,rifle]
rails handloaderpro:hodgdon_data:fetch[replace,pistol]

# Backup strategy - Creates timestamped backup before overwriting
rails handloaderpro:hodgdon_data:fetch[backup,rifle]
rails handloaderpro:hodgdon_data:fetch[backup,pistol]

# Incremental strategy - Merges new data with existing data
rails handloaderpro:hodgdon_data:fetch[incremental,rifle]
rails handloaderpro:hodgdon_data:fetch[incremental,pistol]
```

### Individual Tasks

```bash
# Fetch data from Hodgdon RLDC website
rails handloaderpro:hodgdon_data:fetch[backup,rifle]    # Safe with backup
rails handloaderpro:hodgdon_data:fetch[incremental,pistol] # Merge with existing

# Clean and validate fetched data
rails handloaderpro:hodgdon_data:clean[rifle]
rails handloaderpro:hodgdon_data:clean[pistol]

# Import data into database
rails handloaderpro:hodgdon_data:import[rifle]
rails handloaderpro:hodgdon_data:import[pistol]

# Show statistics about the data
rails handloaderpro:hodgdon_data:stats[rifle]
rails handloaderpro:hodgdon_data:stats[pistol]
```

### Migration Tasks

```bash
# Run database migration to create association tables
bin/rails db:migrate

# Migrate existing data to use cartridge type associations
rails handloaderpro:migrate:cartridge_type_associations

# Show association statistics
rails handloaderpro:migrate:association_stats
```

### Fetch Strategies Explained

#### Replace Strategy (Default)
- **Behavior**: Completely overwrites all existing data files
- **Use case**: When you want a completely fresh dataset
- **Risk**: Data loss if fetch fails partway through
- **Command**: `rails handloaderpro:hodgdon_data:fetch` or `rails handloaderpro:hodgdon_data:fetch[replace]`

#### Backup Strategy
- **Behavior**: Creates a timestamped backup of existing data before overwriting
- **Use case**: When you want fresh data but want to keep a backup
- **Risk**: Minimal - previous data is preserved in backups/
- **Command**: `rails handloaderpro:hodgdon_data:fetch[backup]`
- **Backup location**: `db/seeds/hodgdon_data/backups/YYYYMMDD_HHMMSS/`

#### Incremental Strategy
- **Behavior**: Merges new data with existing data, preserving existing items
- **Use case**: When you want to add new data without losing existing data
- **Risk**: Minimal - existing data is preserved and merged
- **Command**: `rails handloaderpro:hodgdon_data:fetch[incremental]`
- **Merging logic**: 
  - New items are added
  - Existing items are updated with new data
  - Items not in new fetch are preserved
  - Original `extracted_at` timestamps are preserved

## Data Structure

### Cartridges Data
```json
{
  "name": ".223 Remington",
  "cartridge_type": "Rifle",
  "cartridge_type_id": 1,
  "extracted_at": "2024-01-15T10:30:00Z"
}
```

### Bullet Weights Data
```json
{
  "weight": 55.0,
  "weight_text": "55 gr",
  "cartridge_type": "Rifle",
  "cartridge_type_id": 1,
  "extracted_at": "2024-01-15T10:30:00Z"
}
```

### Manufacturers Data
```json
{
  "name": "Hodgdon",
  "manufacturer_type": "Powder",
  "cartridge_type": "Rifle",
  "cartridge_type_id": 1,
  "source_text": "AccurateHodgdonIMRRamshotWinchester",
  "extracted_at": "2024-01-15T10:30:00Z"
}
```

### Powders Data
```json
{
  "name": "H1000",
  "manufacturer_name": "Hodgdon",
  "cartridge_type": "Rifle",
  "cartridge_type_id": 1,
  "source_text": "H1000H110H335H380H414H4350H4831H4831SC...",
  "extracted_at": "2024-01-15T10:30:00Z"
}
```

## Data Categories

### Cartridges
- Rifle cartridges extracted from the filter interface
- Includes popular calibers like .223 Remington, .308 Winchester, etc.
- All cartridges are classified as "Rifle" type

### Bullet Weights
- Weight values in grains extracted from the filter interface
- Handles various formats (e.g., "55 gr", "150", "200gr")
- Automatically extracts numeric values

### Manufacturers
- Powder manufacturers: Accurate, Hodgdon, IMR, Ramshot, Winchester
- Extracted from concatenated text in the filter interface
- All classified as "Powder" manufacturer type

### Powders
- Comprehensive powder database with manufacturer associations
- Includes multiple powder series:
  - **H-Series**: H1000, H110, H335, H380, H414, H4350, H4831, etc.
  - **IMR Series**: IMR 3031, IMR 4064, IMR 4350, etc.
  - **SR Series**: SR 4756, SR 4759, etc.
  - **CFE Series**: CFE Pistol, CFE 223, etc.
  - **StaBALL Series**: StaBALL 6.5, StaBALL HD, etc.
  - **Numbered**: 700-X, No. 11FS, etc.
  - **Special**: BL-C(2), Big Game, Trail Boss, etc.

## Benefits

### Separation of Concerns
- **Data fetching** handles Selenium operations and JavaScript parsing
- **Data import** handles database operations
- **Data cleaning** handles validation and normalization

### Reliability
- Raw data is preserved for inspection and debugging
- Import can be run multiple times safely
- Network failures don't affect database operations
- Selenium timeouts are handled gracefully

### Maintainability
- Easy to inspect raw data before import
- Can modify cleaning logic without re-fetching
- Clear separation makes testing easier
- Comprehensive error handling and logging

### Performance
- No need to re-scrape website for testing
- Can run import offline
- Faster iteration during development
- Selenium WebDriver is properly managed and cleaned up

## Data Validation

The system includes several validation steps:

1. **Fetch-time validation**: Basic checks during scraping
2. **Clean-time validation**: Comprehensive data cleaning and validation
3. **Import-time validation**: Database-level constraints and validations

### Validation Rules

- Cartridges must have non-empty names
- Bullet weights must be positive numbers
- Manufacturers must have non-empty names
- Powder names must be non-empty and properly categorized
- Manufacturer associations are validated during import

## Error Handling

- Selenium WebDriver errors are caught and reported
- Network timeouts are handled gracefully
- Invalid data is filtered out during cleaning
- Database errors during import are caught and reported
- All operations include detailed logging
- WebDriver is properly cleaned up even on errors

## Dependencies

### Required Gems
- `selenium-webdriver` - For browser automation
- `nokogiri` - For HTML parsing
- `json` - For data serialization

### System Requirements
- Chrome browser (for Selenium WebDriver)
- Internet connection (for data fetching)

## Development Notes

### Selenium Configuration
The system uses headless Chrome with optimized options:
- `--headless` - Run without GUI
- `--no-sandbox` - Required for some environments
- `--disable-dev-shm-usage` - Prevents memory issues

### Wait Strategies
- Uses Selenium WebDriver Wait with 60-second timeout
- Waits for specific elements to be visible before processing
- Includes initial 5-second sleep for JavaScript initialization
- Handles timeout errors gracefully

### Data Extraction Logic
- Uses Nokogiri to parse HTML after JavaScript execution
- Extracts data from specific filter elements on the page
- Handles concatenated text parsing for manufacturers and powders
- Includes sophisticated regex patterns for powder name extraction

### Adding New Data Sources
To add support for additional Hodgdon data:

1. Create new extraction methods in the fetch task
2. Add data cleaning rules for the new source
3. Update import logic to handle new data fields
4. Add tests for the new functionality

### Extending Data Fields
To add new properties:

1. Update the extraction logic to capture new fields
2. Add cleaning rules for the new fields
3. Update the models if needed
4. Update import logic to handle new fields

## Troubleshooting

### Common Issues

**"No seed data found"**
- Run `rails handloaderpro:hodgdon_data:fetch` first

**"Selenium WebDriver errors"**
- Ensure Chrome browser is installed
- Check that ChromeDriver is compatible with your Chrome version
- Try running without `--headless` flag for debugging

**"Timeout waiting for elements"**
- Hodgdon website may be slow or down
- Check internet connection
- Try again later

**"Invalid data"**
- Run `rails handloaderpro:hodgdon_data:clean` to clean the data
- Check the raw JSON files for data quality issues

**"Database errors"**
- Ensure database is set up correctly
- Check that required models exist (CartridgeType, ManufacturerType, etc.)
- Run `rails db:seed` to ensure reference data exists

### Debugging

1. **Inspect raw data**: Check the JSON files in `db/seeds/hodgdon_data/`
2. **Check metadata**: Look at `metadata.json` for fetch information
3. **Run stats**: Use `rails handloaderpro:hodgdon_data:stats` to see data summary
4. **Check logs**: Look at Rails logs for detailed error information
5. **Test Selenium**: Run fetch task with verbose logging

### Performance Optimization

- The system automatically handles Selenium cleanup
- Uses efficient CSS selectors for data extraction
- Implements proper wait strategies to avoid unnecessary delays
- Processes data in batches to avoid memory issues

## Future Improvements

- [ ] Add support for incremental updates
- [ ] Add data versioning and migration support
- [ ] Add automated testing for data quality
- [ ] Add support for additional Hodgdon data sources
- [ ] Add data export functionality
- [ ] Add web interface for data management
- [ ] Add support for pistol cartridges and powders
- [ ] Add powder burn rate data extraction
- [ ] Add cartridge case capacity data