# MADCUBA ROI Import Tool

[![GitHub Release](https://img.shields.io/github/v/release/dhaasler/madcuba-roi-import-tool)](https://github.com/dhaasler/madcuba-roi-import-tool/releases/tag/v1.1.1)
[![Static Badge](https://img.shields.io/badge/changelog-brightgreen)](CHANGELOG.md)

MADCUBA tool for importing CARTA and CASA regions of interest (ROIs). [MADCUBA](https://cab.inta-csic.es/madcuba/) is a software developed in the spanish Center of Astrobiology (CSIC-INTA) to analyze astronomical datacubes, and is built using the ImageJ infrastructure. This tool will not work with any other ImageJ program.

This tool is developed to be used with MADCUBA v11. With this tool the user can import ROI files exported by CARTA and CASA in .crtf format (currently only world coordinates are implemented). The available ROIS are:

- Point
- Line
- Polyline
- Box
- Center box
- Rotated box
- Circle
- Ellipse
- Polygon
- Annulus. Although not a ROI from CARTA or CASA, the annulus has also been implemented in this tool.

## Installation

Download the latest version of `ROI_Import_Tool.ijm` and install it in MADCUBA as a plugin (ImageJ window > Plugins > Install...)
The tool will then appear in the ImageJ Toolbar ready to be used.

## How to use

> A cube or map must opened and its window selected before running this macro.

Click on the tool icon in the toolbar and a window will appear asking the user to select the .crtf file from CARTA or CASA. The tool will automatically convert the ROI and create the selection in MADCUBA.
