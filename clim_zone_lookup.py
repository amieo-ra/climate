import rasterio
from rasterio.sample import sample_gen

# Define the file path and coordinate
tif_path = "/home/amieo/Documents/data_for_climate/outputs/300_outputs/IPCC_Climate_Zones/IPCC_Climate_Zones_ts_3.25.tif"
lon, lat = (-75.0, 40.0)  # Replace with your GPS coordinates

# Open the raster file
with rasterio.open(tif_path) as dataset:
    # Convert (lon, lat) to raster index
    row, col = dataset.index(lon, lat)
    # Extract the climate zone value
    zone_value = dataset.read(1)[row, col]

print(f"The climate zone at ({lon}, {lat}) is: {zone_value}")
