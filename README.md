# MADCUBA ROI Import Tool

[![GitHub Release](https://img.shields.io/github/v/release/dhaasler/madcuba-roi-import-tool)](https://github.com/dhaasler/madcuba-roi-import-tool/releases/tag/v1.3.0)
[![Static Badge](https://img.shields.io/badge/changelog-brightgreen)](CHANGELOG.md)

MADCUBA tool for importing regions from CARTA, CASA, DS9, and matplotlib as regions of interest (ROIs). [MADCUBA](https://cab.inta-csic.es/madcuba/) is a software developed in the spanish Center of Astrobiology (CSIC-INTA) to analyze astronomical datacubes, and is built using the ImageJ infrastructure. This tool will not work with any other ImageJ program.

This tool is developed to be used with MADCUBA v11. With this tool the user can import ROI files exported by CARTA and CASA in .crtf format, DS9 regions in .ds9 format, and matplotlib patches exported as a custom .pyroi format.

## Installation

Download the latest version of `ROI_Import_Tool.ijm` and install it in MADCUBA as a plugin (ImageJ window > Plugins > Install...)
The tool will then appear in the ImageJ Toolbar ready to be used.

## How to use

> A cube or map must opened and its window selected before running this macro.

Click on the tool icon in the toolbar and a window will appear asking the user to select the .crtf file from CARTA or CASA. The tool will automatically convert the ROI and create the selection in MADCUBA.

## Supported RoIs

### CASA and CARTA (.crtf)

- Point as coordinates: `symbol [x, y]`
- Line: `line [[x1, y1], [x2, y2]]`
  - The two coordinates are the vertices
- Polyline: `polyline [[x1, y1], [x2, y2], [x3, y3], ...]`
  - There can be many [x, y] vertices
- Rectangular box: `box [[x1, y1], [x2, y2]]`
  - The two coordinates are two opposite corners
- Center box: `centerbox [[x, y], [x_width, y_width]]`
  - [x, y] defines the center point of the box
  - [x_width, y_width] defines the width of the sides
- Rotated bo: `rotbox [[x, y], [x_width, y_width], pa]`
  - [x, y] defines the center point of the box
  - [x_width, y_width] defines the width of the sides
  - pa is the position angle (rotation)
- Polygon: `poly [[x1, y1], [x2, y2], [x3, y3], ...]`
  - There can be many [x, y] corners; note that the last point will connect with the first point to close the polygon
- Circle: `circle [[x, y], r]`
  - [x, y] defines the center of the circle
  - r is the radius
- Ellipse: `ellipse [[x, y], [b1, b2], pa]`
  - [x, y] defines the center of the ellipse
  - [b1, b2] define the semi-axes starting with the vertical axis when first drawing the ellipse
  - pa is the position angle of the vertical axis
- Annulus: `annulus [[x, y], [r1, r2]]`
  - This is a custom implementation of an annulus to import into madcuba following the universal .crtf format, but it is not official for CARTA or CASA.
  - [x, y] defines the center of the circle
  - [r1, r2] are the inner and outer radii

### DS9

- Point as coordinates: `point(x, y)`
- Line: `line(x1, y1, x2, y2)`
  - The two coordinates are the vertices
- Polyline: `polyline(x1, y1, x2, y2, x3, y3, ...)`
  - There can be many (x, y) vertices
- Box: `box(x, y, x_width, y_width, pa)`
  - (x, y) defines the center point of the box
  - x_width and y_width define the width of the sides
  - pa is the position angle (rotation)
- Polygon: `polygon(x1, y1, x2, y2, x3, y3, ...)`
  - There can be many (x, y) corners; note that the last point will connect with the first point to close the polygon
- Circle: `circle(x, y, r)`
  - (x, y) defines the center of the circle
  - r is the radius
- Ellipse: `ellipse(x, y, b1, b2, pa)`
  - (x, y) defines the center of the ellipse
  - b1 and b2 define the semi-axes starting with the vertical axis when first drawing the ellipse
  - pa is the position angle of the horizontal axis

### Matplotlib patches

With a custom function in python we extract patches from madcuba as .pyroi files with the coded parameters in image (pixel) or world coordinates.

- Rectangle: `Rectangle((x1, y1), width, height)`
  - (x1, y1) defines the lower-left corner of the rectangle
  - width and height define the width of the sides
- Rectangle: `RotatedRectangle((x1, y1), width, height, angle)`
  - (x1, y1) defines the lower-left corner of the rectangle
  - x_width and y_width define the width of the sides
  - pa is the position angle (rotation)
- Polygon: `Polygon(x1, y1, x2, y2, x3, y3, ...)`
  - There can be many (x, y) corners; note that the last point will connect with the first point to close the polygon
- Circle: `Circle((x, y), radius)`
  - (x, y) defines the center of the circle
  - radius is the radius
- Ellipse: `Ellipse((x, y), width, height, angle)`
  - (x, y) defines the center of the ellipse
  - width and height define the semi-axes
  - angle is the position angle of the horizontal axis
- Annulus: `Annulus((x, y), r1, r2)`
  - (x, y) defines the center of the ellipse
  - r1 is the inner radius
  - r2 is the outer radius
