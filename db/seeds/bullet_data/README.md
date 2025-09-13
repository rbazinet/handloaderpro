# Bullet Data Import System

This directory contains the seed data files for bullet data imported from JBM Ballistics.

## Overview

The bullet data import system has been redesigned to separate data fetching from data import, making it more robust, testable, and maintainable.

## Architecture

### Two-Phase Approach

1. **Data Fetching** (`handloaderpro:bullet_data:fetch`)
   - Scrapes data from JBM Ballistics website
   - Saves raw data to structured JSON files
   - Includes metadata about the fetch operation
   - Can be run independently to update data

2. **Data Import** (`handloaderpro:bullet_data:import`)
   - Reads clean data from JSON files
   - Imports data into the database
   - Idempotent (safe to run multiple times)
   - Can be run offline once data is fetched

## Files

- `metadata.json` - Information about the data fetch (date, source, counts)
- `manufacturers.json` - Raw manufacturer data from JBM Ballistics
- `bullets.json` - Raw bullet data with specifications
- `manufacturers_cleaned.json` - Cleaned manufacturer data (after running clean task)
- `bullets_cleaned.json` - Cleaned bullet data (after running clean task)

## Usage

### Basic Workflow

```bash
# 1. Fetch fresh data from JBM Ballistics
rails handloaderpro:bullet_data:fetch

# 2. (Optional) Clean and validate the data
rails handloaderpro:bullet_data:clean

# 3. Import data into database
rails handloaderpro:bullet_data:import
```

### Fetch Strategies

The fetch task supports three different strategies:

```bash
# Replace strategy (default) - Completely overwrites existing data
rails handloaderpro:bullet_data:fetch
rails handloaderpro:bullet_data:fetch[replace]

# Backup strategy - Creates timestamped backup before overwriting
rails handloaderpro:bullet_data:fetch[backup]

# Incremental strategy - Merges new data with existing data
rails handloaderpro:bullet_data:fetch[incremental]
```

### Individual Tasks

```bash
# Fetch data from website
rails handloaderpro:bullet_data:fetch[backup]    # Safe with backup
rails handloaderpro:bullet_data:fetch[incremental] # Merge with existing

# Clean and validate fetched data
rails handloaderpro:bullet_data:clean

# Import data into database
rails handloaderpro:bullet_data:import

# Show statistics about the data
rails handloaderpro:bullet_data:stats
```

### Fetch Strategies Explained

#### Replace Strategy (Default)
- **Behavior**: Completely overwrites all existing data files
- **Use case**: When you want a completely fresh dataset
- **Risk**: Data loss if fetch fails partway through
- **Command**: `rails handloaderpro:bullet_data:fetch` or `rails handloaderpro:bullet_data:fetch[replace]`

#### Backup Strategy
- **Behavior**: Creates a timestamped backup of existing data before overwriting
- **Use case**: When you want fresh data but want to keep a backup
- **Risk**: Minimal - previous data is preserved in backups/
- **Command**: `rails handloaderpro:bullet_data:fetch[backup]`
- **Backup location**: `db/seeds/bullet_data/backups/YYYYMMDD_HHMMSS/`

#### Incremental Strategy
- **Behavior**: Merges new data with existing data, preserving existing items
- **Use case**: When you want to add new data without losing existing data
- **Risk**: Minimal - existing data is preserved and merged
- **Command**: `rails handloaderpro:bullet_data:fetch[incremental]`
- **Merging logic**: 
  - New items are added
  - Existing items are updated with new data
  - Items not in new fetch are preserved
  - Original `extracted_at` timestamps are preserved

## Data Structure

### Manufacturers Data
```json
{
  "name": "Sierra",
  "source_url": "/ballistics/lengths/sierra.shtml",
  "extracted_at": "2024-01-15T10:30:00Z"
}
```

### Bullets Data
```json
{
  "caliber": "0.223",
  "weight": 29.0,
  "name": "FMJ",
  "length": 0.750,
  "tip_length": 0.050,
  "manufacturer_name": "Sierra",
  "table_index": 0,
  "row_index": 5,
  "extracted_at": "2024-01-15T10:30:00Z"
}
```

## Benefits

### Separation of Concerns
- **Data fetching** handles network operations and parsing
- **Data import** handles database operations
- **Data cleaning** handles validation and normalization

### Reliability
- Raw data is preserved for inspection and debugging
- Import can be run multiple times safely
- Network failures don't affect database operations

### Maintainability
- Easy to inspect raw data before import
- Can modify cleaning logic without re-fetching
- Clear separation makes testing easier

### Performance
- No need to re-scrape website for testing
- Can run import offline
- Faster iteration during development

## Data Validation

The system includes several validation steps:

1. **Fetch-time validation**: Basic checks during scraping
2. **Clean-time validation**: Comprehensive data cleaning and validation
3. **Import-time validation**: Database-level constraints and validations

### Validation Rules

- Manufacturers must have non-empty names
- Bullets must have positive weight and caliber values
- Caliber values must be valid decimal numbers
- Manufacturer names are normalized (trimmed whitespace)

## Error Handling

- Network errors during fetch are caught and reported
- Invalid data is filtered out during cleaning
- Database errors during import are caught and reported
- All operations include detailed logging

## Development Notes

### Adding New Data Sources

To add support for additional bullet data sources:

1. Create new extraction methods in the fetch task
2. Add data cleaning rules for the new source
3. Update import logic to handle new data fields
4. Add tests for the new functionality

### Extending Data Fields

To add new bullet properties:

1. Update the extraction logic to capture new fields
2. Add cleaning rules for the new fields
3. Update the Bullet model if needed
4. Update import logic to handle new fields

## Troubleshooting

### Common Issues

**"No seed data found"**
- Run `rails handloaderpro:bullet_data:fetch` first

**"Network timeout"**
- Check internet connection
- JBM Ballistics website may be down
- Try again later

**"Invalid data"**
- Run `rails handloaderpro:bullet_data:clean` to clean the data
- Check the raw JSON files for data quality issues

**"Database errors"**
- Ensure database is set up correctly
- Check that required models exist (ManufacturerType, etc.)
- Run `rails db:seed` to ensure reference data exists

### Debugging

1. **Inspect raw data**: Check the JSON files in `db/seeds/bullet_data/`
2. **Check metadata**: Look at `metadata.json` for fetch information
3. **Run stats**: Use `rails handloaderpro:bullet_data:stats` to see data summary
4. **Check logs**: Look at Rails logs for detailed error information

## Future Improvements

- [ ] Add support for incremental updates
- [ ] Add data versioning and migration support
- [ ] Add automated testing for data quality
- [ ] Add support for additional bullet data sources
- [ ] Add data export functionality
- [ ] Add web interface for data management