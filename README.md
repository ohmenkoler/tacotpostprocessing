# Post processing of the Tacot measurement files

## Step 1 : make light files

When a measurement is done, run `Step1_ExportTXTandMAT.m`. It loads the `.tdms` file, and stores the data and the acquisition parameters in a Conf object. Other parameters like the orientation, the canister type, etc. must be set manually.

### Removing the initial temperature of the thermocouples

The initial temperature of each thermocouple is calculated with the average on the $N_{beg} = 10 \times f_{sampling}$ first points of the temperature data, then substracted from each corresponding thermocouple.

### Light data

This program also makes light data by 

- Cutting data at a chosen end time,
- Resampling non-oscillating data (temperature, static pressure, etc.),
- Taking an integer number of periods $N_{end} = 20 \times f_{signal}$ for the oscillating quantities (acoustic pressure, acceleration, voltage and current, etc.), and only keeping the last $N_{end}$ points of these sensors.

### $\dot Q_a$ estimation

**For mesurements in 2 steps (1 : *water only*, 2 : with *acoustic* sources)**, you can either store a `.mat` file for the *water only* if this is the file you are processing, load the corresponding *water only* `.mat` if you are processing an *acoustic* measurement, or do nothing. This allows to better estimate the ambient heat flux $\dot Q_a$ removed by the ambient heat exchanger.

### Oscillating amplitudes and phase calculations

The amplitudes of pressure are calculated with a synchronous detection method, the drive ratio is deduced from the pressure amplitude for the 1st harmonic

### Storing

The program prompts you with a directory selection window to choose a folder in which files will be saved if you choose to do so. It then asks if you want to save the `.mat` files (Yes!), and the `.txt` files. For the latter, a subfolder is created if it doesn't exist already, and the files are saved inside it.


## Step 2 : plot those data

This program works with two files to compare. I have not tried with more than 2 yet but I don't need to plot more than that.

It plots:

1. The temperature as a function of time $T(t)$ **(stored as `Transient_Orientations_Amplitude.fig`)**
2. The temperature without initial temperature as a function of time $T(t) - T(t=0)$ **(stored as `Transient_0_Orientations_Amplitude.fig`)**
3. Temperature maps in the regenerator, averaged on the last 5 min of the measurement **(stored as `TMaps_Orientations_Amplitude.fig`)**
4. The 3 axial gradients (1 center, and 2 peripheral), in the regenerator only  **(stored as `AxProfile3_Orientations_Amplitude.fig`)**
5. The 3 axial gradients, on the entire core **(stored as `AxProfile5_Orientations_Amplitude.fig`)**

For limits on plots, the $T_{min}$ and $T_{max}$ are computed so that all the points are visible (except out of ambient HX as the sensors are dying), both for the plots with and without initial temperatures


## Step 3 : sumarise for quick analysis

From the selected `.mat` file, extracts 

- $\xi_1$
- $\xi_2$
- $p$
- DR
- $|Z_1|$ and $\angle Z_1$
- $|Z_2|$ and $\angle Z_2$
- $T_a$ and $<T_a>$
- $T_f$ and $<T_f>$
- $T_{Rix}$
- $Q_c$
- $Q_a$
- $COP$
- $COP_{carnot}$
- $COP/COP_{carnot}$
