import rasterio

def determine_zone(lon, lat):

    # Define the file path to your IPCC Climate Zones .tif file
    #tif_path = "/home/amieo/Documents/data_for_climate/outputs/300_outputs/IPCC_Climate_Zones/IPCC_Climate_Zones_ts_3.25.tif"
    tif_path = "/home/amieo/Documents/data_for_climate/ipcc_climate_1985-2015.tif"

    # Define GPS coordinates for York, UK
    #lon, lat = (-1.0815, 53.9590)  # Longitude, Latitude

    # Define climate zone mapping
    climate_zone_mapping = {
        1: "Tropical Montane",
        2: "Tropical Wet",
        3: "Tropical Moist",
        4: "Tropical Dry",
        5: "Warm Temperate Moist",
        6: "Warm Temperate Dry",
        7: "Cool Temperate Moist",
        8: "Cool Temperate Dry",
        9: "Boreal Moist",
        10: "Boreal Dry",
        11: "Polar Moist",
        12: "Polar Dry"
    }

    # Open the raster file and get the climate zone value
    with rasterio.open(tif_path) as dataset:
        # Convert (lon, lat) to raster row, column indices
        row, col = dataset.index(lon, lat)
        
        # Read the climate zone value from band 1
        zone_value = dataset.read(1)[row, col]

    # Get the climate zone name (if available)
    climate_zone_name = climate_zone_mapping.get(zone_value, "Unknown Zone")

    if "Temperate" in climate_zone_name:
        zone = "Temperate"
    else:
        zone = "Non-Temperate"

    print(f"The climate zone for York, UK ({lon}, {lat}) is: {climate_zone_name} (Zone {zone_value})")

    return zone

