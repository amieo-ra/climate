import os
import rasterio
import xarray as xr
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

# Define climate data directory
clim_dir = '/home/amieo/Documents/climate/'

def load_nc_files(subdir):
    """Loads NetCDF files from a subdirectory into an xarray dataset."""
    files = [os.path.join(clim_dir, subdir, f) for f in os.listdir(os.path.join(clim_dir, subdir)) if f.endswith('.nc')]
    return xr.open_mfdataset(files, combine='by_coords')

# Load climate datasets
temp = load_nc_files('tmp/')
pre = load_nc_files('pre/')
pet = load_nc_files('pet/')
frost = load_nc_files('frs/')

def aggregate_mean(dataset, time_window):
    """Aggregate data by computing the mean over the given time window."""
    return dataset.sel(time=slice(time_window[0], time_window[-1])).mean(dim='time')

# Define time window
time_window = pd.date_range('1985-01-01', '2016-01-01', freq='Y')
temp_agg = aggregate_mean(temp, time_window)
pre_agg = aggregate_mean(pre, time_window)
pet_agg = aggregate_mean(pet, time_window)
frost_agg = aggregate_mean(frost, time_window)

# Compute precipitation to PET ratio
pre_pet = pre_agg / pet_agg

# Define classification function
def classify_raster(data, thresholds, values):
    print("data[1] is:", data.astype)
    """Classify raster data based on thresholds."""
    classified = np.full(data.shape, np.nan)
    for (low, high), val in zip(thresholds, values):
        mask = (data >= low) & (data < high)
        classified[mask] = val
    return classified

# Define IPCC climate zones
tropical = classify_raster(temp_agg, [(18, np.inf)], [1]) * classify_raster(frost_agg, [(0, 7)], [1])
print("1")
tropical_wet = classify_raster(pre_agg, [(2000, np.inf)], [2])
print("2")
tropical_moist = classify_raster(pre_agg, [(1000, 2000)], [3])
print("3")
tropical_dry = classify_raster(pre_agg, [(0, 1000)], [4])
print("4")

# Merge classified data
ipcc_climate_zones = np.nan_to_num(tropical) + np.nan_to_num(tropical_wet) + np.nan_to_num(tropical_moist) + np.nan_to_num(tropical_dry)

# Save classified raster
output_path = '300_outputs/IPCC_Climate_Zones/IPCC_Climate_Zones.tif'
os.makedirs(os.path.dirname(output_path), exist_ok=True)
with rasterio.open(output_path, 'w', driver='GTiff', height=ipcc_climate_zones.shape[0], width=ipcc_climate_zones.shape[1], count=1, dtype=rasterio.float32) as dst:
    dst.write(ipcc_climate_zones, 1)

# Plot results
plt.imshow(ipcc_climate_zones, cmap='jet')
plt.colorbar()
plt.title('IPCC Climate Zones')
plt.savefig('300_outputs/IPCC_Climate_Zones/IPCC_Climate_Zones.png', dpi=300)
plt.show()
