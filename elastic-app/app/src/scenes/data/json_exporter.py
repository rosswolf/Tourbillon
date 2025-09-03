import json
import csv
import requests  # type: ignore
import argparse
import sys
import os
from io import StringIO

class PublicSheetsToJsonExporter:
    def __init__(self, array_separator="|"):
        """
        Initialize the exporter for public Google Sheets.
        
        Args:
            array_separator (str): Character(s) used to separate array values in cells (default: "|")
        """
        self.array_separator = array_separator
    
    def get_public_sheet_data(self, spreadsheet_id, gid=0):
        """
        Retrieve data from a publicly accessible Google Sheets document.
        
        Args:
            spreadsheet_id (str): The ID of the Google Sheets document
            gid (int): Sheet ID (0 for first sheet, check URL for others)
            
        Returns:
            list: Parsed CSV data from the spreadsheet
        """
        try:
            # Construct the CSV export URL for public sheets
            url = f"https://docs.google.com/spreadsheets/d/{spreadsheet_id}/export?format=csv&usp=sharing"
            
            print(f"Fetching data from GID {gid}")
            
            # Make the request
            response = requests.get(url)
            response.raise_for_status()  # Raise an exception for bad status codes
            
            # Parse the CSV data
            csv_data = StringIO(response.text)
            reader = csv.reader(csv_data)
            data = list(reader)
            
            if not data:
                print('No data found in the spreadsheet.')
                return []
            
            print(f"Successfully retrieved {len(data)} rows of data")
            return data
            
        except requests.exceptions.RequestException as e:
            print(f"Error fetching sheet data: {e}")
            print("Make sure the sheet is publicly accessible (Anyone with the link can view)")
            raise
        except Exception as e:
            print(f"Error parsing sheet data: {e}")
            raise
    
    def convert_to_json(self, data):
        """
        Convert spreadsheet data to JSON format.
        First row becomes keys, subsequent rows become values.
        Skips columns that start with "NOEX".
        Special handling for "params" fields - expands them to top-level properties.
        Validates for duplicate column names.
        Omits empty values entirely.
        Supports enum prefixes in column headers (e.g., "color:My.Enum.Path").
        
        Args:
            data (list): Raw spreadsheet data
            
        Returns:
            list: List of dictionaries in JSON format
        """
        if not data or len(data) < 2:
            print("Insufficient data to convert (need at least header + 1 data row)")
            return []
        
        # First row contains the keys
        headers = data[0]
        
        # Find columns to include (skip those starting with "NOEX")
        included_columns = []
        excluded_columns = []
        all_column_names = set()  # Track all column names for duplicate detection
        column_enum_prefixes = {}  # Track enum prefixes for each column
        
        for i, header in enumerate(headers):
            header_clean = header.strip()
            if header_clean.upper().startswith("NOEX"):
                excluded_columns.append((i, header_clean))
            else:
                # Check if header contains enum prefix
                if ':' in header_clean:
                    actual_header, enum_prefix = header_clean.split(':', 1)
                    actual_header = actual_header.strip()
                    enum_prefix = enum_prefix.strip()
                    column_enum_prefixes[i] = enum_prefix
                    included_columns.append((i, actual_header))
                    
                    # Check for duplicate column names
                    if actual_header.lower() in all_column_names:
                        raise ValueError(f"Duplicate column name found: '{actual_header}'. Column names must be unique.")
                    all_column_names.add(actual_header.lower())
                    
                    print(f"Column '{actual_header}' will use enum prefix: {enum_prefix}")
                else:
                    included_columns.append((i, header_clean))
                    
                    # Check for duplicate column names
                    if header_clean.lower() in all_column_names:
                        raise ValueError(f"Duplicate column name found: '{header_clean}'. Column names must be unique.")
                    all_column_names.add(header_clean.lower())
        
        # Log what we're including/excluding
        included_headers = [header for _, header in included_columns]
        print(f"Including {len(included_columns)} columns: {included_headers}")
        
        if excluded_columns:
            excluded_headers = [header for _, header in excluded_columns]
            print(f"Excluding {len(excluded_columns)} columns starting with 'NOEX': {excluded_headers}")
        
        json_data = []
        
        # Process each subsequent row
        for row_index, row in enumerate(data[1:], 1):
            # Skip empty rows
            if not any(cell.strip() for cell in row if cell):
                continue
                
            # Create dictionary for this row (only including allowed columns)
            row_dict = {}
            used_keys = set()  # Track keys used in this row for conflict detection
            
            # Map each cell to its corresponding header (only for included columns)
            for column_index, header in included_columns:
                # Handle cases where row might be shorter than headers
                raw_value = row[column_index] if column_index < len(row) else ""
                
                # Skip empty values entirely - don't add them to the dict
                if not raw_value or not raw_value.strip():
                    continue
                
                # Get enum prefix for this column if it exists
                enum_prefix = column_enum_prefixes.get(column_index, None)
                
                # Convert value (handles arrays, numbers, booleans, etc.)
                converted_value = self._convert_value(raw_value, header, enum_prefix)
                row_dict[header] = converted_value
                
                # Special handling for "params" fields - expand key:value pairs to top-level properties
                if header.lower() == "params" and isinstance(raw_value, str) and raw_value.strip():
                    # Check if this contains key:value pairs (either single or multiple with separators)
                    if ':' in raw_value:
                        # Note: Don't pass enum_prefix here since params fields handle their own keys
                        params_dict = self._parse_params_field(raw_value)
                        
                        # Check for conflicts between params and existing columns
                        for param_key in params_dict.keys():
                            param_key_lower = param_key.lower()
                            if param_key_lower in used_keys:
                                raise ValueError(f"Row {row_index + 1}: Parameter '{param_key}' from params field conflicts with existing column name.")
                            if param_key_lower in all_column_names:
                                raise ValueError(f"Row {row_index + 1}: Parameter '{param_key}' from params field conflicts with column '{param_key}'.")
                            used_keys.add(param_key_lower)
                        
                        # Add each param as a top-level property (only if not empty)
                        for param_key, param_value in params_dict.items():
                            if param_value is not None and str(param_value).strip():
                                row_dict[param_key] = param_value
                
                # If this field contains arrays (has separators), also create a dict version
                elif isinstance(raw_value, str) and raw_value.strip() and self.array_separator in raw_value:
                    # For non-params fields, create indexed dict version
                    dict_version = self._create_array_dict(converted_value, header)
                    if dict_version:  # Only add if we successfully created a dict
                        row_dict[f"{header}_dict"] = dict_version
                
                used_keys.add(header.lower())
            
            json_data.append(row_dict)
        
        return json_data
    
    def _apply_enum_prefix(self, value, enum_prefix):
        """
        Apply enum prefix to a value if appropriate.
        Only applies if the value looks like an enum constant (all caps or mixed case identifier).
        
        Args:
            value (str): The value to potentially prefix
            enum_prefix (str): The enum prefix to apply
            
        Returns:
            str: The value with prefix applied if appropriate
        """
        if not enum_prefix or not isinstance(value, str):
            return value
        
        value = value.strip()
        
        # Don't apply prefix if:
        # 1. Value already contains the prefix
        # 2. Value already contains a dot (suggesting it's already a full path)
        # 3. Value is a number or boolean literal
        # 4. Value starts with "__CONFIG_REF__" (configuration reference)
        if (enum_prefix in value or 
            '.' in value or 
            value.isdigit() or 
            value.lower() in ['true', 'false'] or
            value.startswith("__CONFIG_REF__")):
            return value
        
        # Apply prefix if value looks like an enum constant
        # (contains only letters, numbers, and underscores)
        if value.replace('_', '').replace('-', '').isalnum():
            return f"{enum_prefix}.{value}"
        
        return value
    
    def _convert_value(self, value, field_name="", enum_prefix=None):
        """
        Convert a cell value to the appropriate data type.
        Handles arrays separated by the configured separator.
        Handles configuration references in format configurationData.key_name.
        Special handling for key:value pairs - always converts to dictionary.
        Applies enum prefixes when provided.
        
        Args:
            value (str): Raw cell value
            field_name (str): Name of the field (for context)
            enum_prefix (str): Optional enum prefix to apply to appropriate values
            
        Returns:
            Various types: Converted value (string, int, float, bool, list, or dict)
        """
        if not value or not value.strip():
            return None  # This will be filtered out by the caller
        
        value = value.strip()
        
        # Check if this contains key:value pairs (always convert to dict if so)
        if ':' in value:
            # Try to parse as key:value pairs first
            try:
                parsed_dict = self._parse_params_field(value, enum_prefix)
                if parsed_dict:  # If we successfully parsed key:value pairs, return the dict
                    return parsed_dict
            except:
                # If parsing as key:value fails, continue with other processing
                pass
        
        # Check if value contains the array separator (for regular arrays)
        if self.array_separator in value:
            # Split into array and process each element
            array_items = [item.strip() for item in value.split(self.array_separator)]
            
            # Convert each array item to appropriate type
            converted_array = []
            for item in array_items:
                if not item:  # Skip empty items
                    continue
                
                # Check for configuration reference in array item
                converted_item = self._resolve_configuration_reference(item)
                
                # Apply enum prefix if appropriate
                if enum_prefix and isinstance(converted_item, str):
                    converted_item = self._apply_enum_prefix(converted_item, enum_prefix)
                
                if isinstance(converted_item, str) and converted_item.isdigit():
                    converted_array.append(int(converted_item))
                elif isinstance(converted_item, str) and self._is_float(converted_item):
                    converted_array.append(float(converted_item))
                elif isinstance(converted_item, str) and converted_item.lower() in ['true', 'false']:
                    converted_array.append(converted_item.lower() == 'true')
                else:
                    converted_array.append(converted_item)
            
            return converted_array
        
        # Check for configuration reference in single value
        resolved_value = self._resolve_configuration_reference(value)
        
        # Apply enum prefix if appropriate (before type conversion)
        if enum_prefix and isinstance(resolved_value, str):
            resolved_value = self._apply_enum_prefix(resolved_value, enum_prefix)
        
        # Single value conversion
        if isinstance(resolved_value, str):
            if resolved_value.isdigit():
                return int(resolved_value)
            elif self._is_float(resolved_value):
                return float(resolved_value)
            elif resolved_value.lower() in ['true', 'false']:
                return resolved_value.lower() == 'true'
            else:
                return resolved_value
        else:
            # If resolve_configuration_reference returned a non-string, return as-is
            return resolved_value

    def _resolve_configuration_reference(self, value):
        """
        Resolve configuration references in format configurationData.key_name.
        
        Args:
            value (str): Value that might contain a configuration reference
            
        Returns:
            The resolved value from configuration data, or the original value if not a reference
        """
        if not isinstance(value, str):
            return value
            
        value = value.strip()
        
        # Check if this is a configuration reference
        if value.lower().startswith("configurationdata."):
            # Extract the key name (everything after "configurationData.")
            config_key = value[18:]  # len("configurationdata.") = 18
            
            # Store this reference for later resolution in Godot
            # We'll use a special format that Godot can recognize and resolve
            return f"__CONFIG_REF__{config_key}"
        
        return value

    def _parse_params_field(self, value, enum_prefix=None):
        """
        Parse parameter field in format A:B|C:D into dictionary.
        Handles configuration references in parameter values.
        Keys are kept as strings and might have enum prefix applied.
        Values are kept as strings for later enum resolution in Godot.
        
        Args:
            value (str): Parameter string in format key:value|key:value
            enum_prefix (str): Optional enum prefix to apply to keys
            
        Returns:
            dict: Dictionary with parsed key-value pairs (all keys and values as strings)
        """
        if not value or not isinstance(value, str):
            return {}
        
        value = value.strip()
        if not value:
            return {}
        
        params_dict = {}
        used_param_keys = set()
        
        # Split by separator to get individual key:value pairs
        pairs = [pair.strip() for pair in value.split(self.array_separator)]
        
        for pair in pairs:
            if not pair:
                continue
                
            # Split each pair by colon
            if ':' in pair:
                key, val = pair.split(':', 1)  # Split only on first colon
                key = key.strip()
                val = val.strip()
                
                # Apply enum prefix to the KEY if appropriate
                if enum_prefix and isinstance(key, str):
                    prefixed_key = self._apply_enum_prefix(key, enum_prefix)
                else:
                    prefixed_key = key
                
                # Check for duplicate keys within params (case-insensitive for conflict detection)
                key_lower = prefixed_key.lower()
                if key_lower in used_param_keys:
                    raise ValueError(f"Duplicate parameter key found in params field: '{prefixed_key}'")
                used_param_keys.add(key_lower)
                
                # Resolve configuration references in parameter values
                resolved_val = self._resolve_configuration_reference(val)
                
                # Store with prefixed key
                params_dict[prefixed_key] = resolved_val
            else:
                # Handle malformed pairs - treat as key with empty value
                key = pair.strip()
                
                # Apply enum prefix to the KEY if appropriate
                if enum_prefix and isinstance(key, str):
                    prefixed_key = self._apply_enum_prefix(key, enum_prefix)
                else:
                    prefixed_key = key
                    
                key_lower = prefixed_key.lower()
                if key_lower in used_param_keys:
                    raise ValueError(f"Duplicate parameter key found in params field: '{prefixed_key}'")
                used_param_keys.add(key_lower)
                params_dict[prefixed_key] = ""
        
        return params_dict
    
    def _create_array_dict(self, array_value, field_name):
        """
        Create a dictionary version of an array field for easier access.
        
        Args:
            array_value: The converted array value
            field_name (str): Name of the field (for logging)
            
        Returns:
            dict: Dictionary with array indices as keys, or None if not applicable
        """
        if not isinstance(array_value, list):
            return None
            
        if len(array_value) == 0:
            return {}
        
        # Create dictionary with indices as keys
        result_dict = {}
        for i, item in enumerate(array_value):
            result_dict[str(i)] = item
            
        return result_dict
    
    def _is_float(self, value):
        """Check if a string represents a float."""
        try:
            float(value)
            return '.' in value
        except ValueError:
            return False
    
    def export_to_file(self, json_data, output_file):
        """
        Export JSON data to a file.
        
        Args:
            json_data (list): Data to export
            output_file (str): Output file path
        """
        try:
            with open(output_file, 'w', encoding='utf-8') as f:
                json.dump(json_data, f, indent=2, ensure_ascii=False)
            print(f"Data successfully exported to {output_file}")
            
        except Exception as e:
            print(f"Error writing to file: {e}")
            raise
    
    def export_sheet_to_json(self, spreadsheet_id, output_file, gid=0):
        """
        Complete workflow: get data from public sheet and export to JSON file.
        
        Args:
            spreadsheet_id (str): Google Sheets document ID
            output_file (str): Output JSON file path
            gid (int): Sheet ID (0 for first sheet)
        """
        print(f"Fetching data from spreadsheet: {spreadsheet_id}")
        print(f"Array separator: '{self.array_separator}'")
        data = self.get_public_sheet_data(spreadsheet_id, gid)
        
        print("Converting to JSON format...")
        
        # Just use standard converter for everything
        json_data = self.convert_to_json(data)
        
        print(f"Exporting to {output_file}...")
        self.export_to_file(json_data, output_file)
        
        print(f"Export complete! {len(json_data)} records exported.")
        return json_data


def parse_arguments():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(
        description='Export a public Google Sheets document to JSON format',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python sheets_to_json.py 1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms my_data.json
  python sheets_to_json.py -s 1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms -o output.json
  python sheets_to_json.py --sheet-id YOUR_SHEET_ID --output results.json --gid 123456789
        """
    )
    
    parser.add_argument(
        'sheet_id', 
        nargs='?',
        help='Google Sheets document ID (from the URL)'
    )
    
    parser.add_argument(
        'output_file', 
        nargs='?',
        help='Output JSON file name'
    )
    
    parser.add_argument(
        '-s', '--sheet-id',
        dest='sheet_id_flag',
        help='Google Sheets document ID (alternative to positional argument)'
    )
    
    parser.add_argument(
        '-o', '--output',
        dest='output_flag',
        help='Output JSON file name (alternative to positional argument)'
    )
    
    parser.add_argument(
        '-g', '--gid',
        type=int,
        default=0,
        help='Sheet GID (default: 0 for first sheet)'
    )
    
    args = parser.parse_args()
    
    # Use flag versions if positional arguments not provided
    sheet_id = args.sheet_id or args.sheet_id_flag
    output_file = args.output_file or args.output_flag
    
    # Validate required arguments
    if not sheet_id:
        parser.error("Sheet ID is required. Provide it as a positional argument or use --sheet-id")
    
    if not output_file:
        parser.error("Output file is required. Provide it as a positional argument or use --output")
    
    return sheet_id, output_file, args.gid


def main():
    """Main function - exports specified sheets from hardcoded spreadsheet IDs."""
    
    ARRAY_SEPARATOR = "|"  # Change this to use a different separator
    
    # Hardcoded mapping of spreadsheet IDs to output filenames
    # Each entry represents one complete Google Sheets document (always reads GID 0)
    sheets_to_export = {
        # Tourbillon card spreadsheet (new format)
        "1zoNrBnX2od6nrTL3G4wS_QMYig69laRn0XYH-KOUqTk": "card_data.json",
        # Add more spreadsheet IDs here:
        "1TlOn39AXlw0y2tlkE4kvIpvoZ9SpNQTkDGgOptvqSgM": "mob_data.json",
        "1vqf7i3FQPI4C9p0ME3kDnCa9u6fGjIg7Z1loQryfIz0": "configuration_data.json",
        "1xa8_S08EFnjsSBAaKCZ4okflLWUSzm9vcjAQcHIY2os": "goals_data.json",
        "163_WvC6Vsa9Q5mAgRh296npPyaEmd2iEPF7OAki7b5Q": "relic_data.json",
        "1rJPpGNARZ-ZtTRWjehFTeM_ru6Urf6qB-UuxzzeSsMY": "icon_data.json",
        "1fIkbi6B80U6fXNYX1Gq3w4UqOP-z_vpqEsyAEKcb2ss": "hero_data.json"
    }

    print("📊 Hardcoded Google Sheets to JSON Exporter")
    print("=" * 60)
    print(f"Found {len(sheets_to_export)} sheet(s) to export")
    print(f"Array separator: '{ARRAY_SEPARATOR}'")
    print("=" * 60)
    
    try:
        # Initialize the exporter
        exporter = PublicSheetsToJsonExporter(array_separator=ARRAY_SEPARATOR)
        
        successful_exports = 0
        failed_exports = 0
        
        # Export each configured sheet
        for spreadsheet_id, output_filename in sheets_to_export.items():
            print(f"\n🔄 Exporting: {output_filename}")
            print(f"   Spreadsheet ID: {spreadsheet_id}")
            print(f"   GID: 0 (first sheet)")
            print("-" * 40)
            
            try:
                # Export this sheet (always GID 0)
                exporter.export_sheet_to_json(
                    spreadsheet_id=spreadsheet_id,
                    output_file=output_filename,
                    gid=0
                )
                successful_exports += 1
                print(f"✅ Successfully exported {output_filename}")
                
            except Exception as e:
                failed_exports += 1
                print(f"❌ Failed to export {output_filename}: {e}")
                continue
        
        # Summary
        print("\n" + "=" * 60)
        print("📋 EXPORT SUMMARY")
        print("=" * 60)
        print(f"✅ Successful exports: {successful_exports}")
        print(f"❌ Failed exports: {failed_exports}")
        print(f"📁 Total sheets processed: {len(sheets_to_export)}")
        
        if successful_exports > 0:
            print(f"\n📄 Exported files:")
            for output_filename in sheets_to_export.values():
                if os.path.exists(output_filename):
                    file_size = os.path.getsize(output_filename)
                    print(f"   • {output_filename} ({file_size:,} bytes)")
        
        if failed_exports > 0:
            print(f"\n⚠️  {failed_exports} exports failed. Check the error messages above.")
            sys.exit(1)
        else:
            print(f"\n🎉 All exports completed successfully!")
        
    except KeyboardInterrupt:
        print("\n⏹️  Operation cancelled by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n💥 Unexpected error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()