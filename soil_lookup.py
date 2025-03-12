import rasterio

def determine_soil_type(lon, lat):

    # Define the file path to your IPCC Climate Zones .tif file
    #tif_path = "/home/amieo/Documents/data_for_climate/outputs/300_outputs/IPCC_Climate_Zones/IPCC_Climate_Zones_ts_3.25.tif"
    tif_path = "/home/amieo/Documents/data_for_climate/Soil_Texture_Class_Selected_Countries.tif"

    # Define GPS coordinates for York, UK
    #lon, lat = (-1.0815, 53.9590)  # Longitude, Latitude

    # Define climate zone mapping
    texture_classes = {
        0: 'No data',
        1: 'Clay',
        2: 'Silt Clay',
        3: 'Sandy Clay',
        4: 'Clay Loam',
        5: 'Silt Clay Loam',
        6: 'Sand Clay Loam',
        7: 'Loam',
        8: 'Silt Loam',
        9: 'Sand Loam',
        10: 'Silt',
        11: 'Loam Sand',
        12: 'Sand'
    }

    # Open the raster file and get the climate zone value
    with rasterio.open(tif_path) as dataset:
        # Convert (lon, lat) to raster row, column indices
        row, col = dataset.index(lon, lat)
        
        # Read the climate zone value from band 1
        zone_value = dataset.read(1)[row, col]
        print("zone value is:", zone_value)

    # Get the climate zone name (if available)
    climate_zone_name = texture_classes.get(zone_value, "Unknown Zone")

    if 0 < zone_value < 7:
        soil = "clay"
    elif 6 < zone_value < 13:
        soil = "sandy"

    print(f"The climate zone for Lincoln, UK ({lon}, {lat}) is: {climate_zone_name} (Zone {zone_value})")
    print("soil is:", soil)

    return soil

#determine_soil_type(-1.0815, 53.9590)

