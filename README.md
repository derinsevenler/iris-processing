## Welcome to IRIS Processing
IRIS (Interference Reflectance Imaging Sensor) is a label-free microarray technology, capable of making hundreds or thousands of measurements of biological affinity and concentration simultaneously. IRIS Processing is an essential utility for converting raw data collected with IRIS to measurements of molecular binding. 

You can learn more about IRIS on our lab website - https://ultra.bu.edu - or the following selected publications:
* G. G. Daaboul, R. S. Vedula, S. Ahn, C. A. Lopez, A. Reddington, E. Ozkumur, and M. S. Ünlü, ["LED-based Interferometric Reflectance Imaging Sensor for quantitative dynamic monitoring of biomolecular interactions,"](http://www.sciencedirect.com/science/article/pii/S0956566310006524) Biosensors and Bioelectronics, Vol. 26, January 2011, pp. 2221-2227
* E. Ozkumur, S. Ahn, A. Yalcin, C. A. Lopez, E. Cevik, R. Irani, C. DeLisi, M. Chiari, and M. S. Ünlü, ["Label-free microarray imaging for direct detection of DNA hybridization and single-nucleotide mismatches,"](http://www.sciencedirect.com/science/article/pii/S0956566309007106) Biosensors and Bioelectronics, Vol. 25, No. 7, 15 March 2010, pp. 1789-1795 
* E. Ozkumur, J. Needham, D. A. Bergstein, R. Gonzalez, M. Cabodi, J. Gershoni, B. B. Goldberg, and M. S. Ünlü, ["Label-free and dynamic detection of biomolecular interactions for high-throughput microarray applications,"](http://www.pnas.org/content/105/23/7988) Proceedings of the National Academy of Science, Vol. 105, 10 June 2008, pp. 7988-7992

## Getting Started 

### Dependencies
* IRIS Processing is supported on MATLAB version 2013a or later, on either Windows or OS X.
* It's helpful to have a specialized image viewing and analysis program. MATLAB works alright for this, but [ImageJ](http://imagej.nih.gov/ij/) is highly recomended.
* At this time, IRIS Processing does not provide any microarray analysis utilities (spot finding, etc). You will probably want to use a dedicated [microarray analysis software](https://duckduckgo.com/?q=microarray%20analyis%20software) later in your analysis pipeline.

### Setup
IRIS Processing functions and scripts are run entirely from the MATLAB command window. If you're new to programming however, don't worry - there's very little you need to know about MATLAB or programming in general.

Start by downloading the latest version of the program from http://dd7ler.github.io/iris-processing/ and unpacking it somewhere that you have write access. The MATLAB folder in your 'Documents' folder is not a bad place.

Next, edit and save your MATLAB path to include this directory. One way to do this is:
```
addpath(genpath('/full/path/to/iris-processing'));
```

