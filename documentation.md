This document contains explanations, examples, and shenanigans that happen when working with Regions of Interest (RoIs) and their coordinates in MADCUBA.

# Coordinate systems

MADCUBA uses two forms of coordinates for images. The main coordinate system used in MADCUBA is a pseudo-standard FITS model. This coordinate system has been implemented into MADCUBA and is used in most RoIs. These coordinates start at the lower-left corner of the image with the 1,1 pixel (X,Y). In a pixel, the starting point for the coordinates (X.0, Y.0) is located at its lower-left corner, with the middle point (X.5, Y.5) being in the center. This subpixel coordinates are not in agreement with the FITS standard, which states that integer pixel numbers refer to the center of the pixel in each axis. For example, the first pixel in the image runs from 0.5 to 1.5 in each axis.

> This coordinate system is currently being worked on to properly reflect standard FITS coordinates. This would fix many problems MADCUAB currently suffers from coordinate conversion.

In addition to the FITS coordinates, MADCUBA also iherits ImageJ's coordinate system. In this system, the origin is located at the upper-left corner with the 0,0 pixel. The starting point of a pixel (X.0, Y.0) lies at its upper-left corner, with the (X.5, Y.5) point in the center. This coordinate system is used in some of the RoIs that have not been manually implemented into MADCUBA, but are still available to use from the ImageJ toolset.

To translate from the current pseudo-FITS to ImageJ coordinates, we must substract 1 from both the X and Y values (to effectively shift the image to a 0,0 starting point), and then the Y axis must be inverted (NAXIS2 - Y value). To convert ImageJ coordinates to FITS coordinates, the opposed operations must be applied: first an inversion of the Y axis and then the addition of 1 to the X and Y values.  

MADCUBA offers a plugin to convert between FITS, imageJ and celestial coordinates called `CONVERT_PIXELS_COORDINATES`. This plugin is not available through the graphical user interface (GUI), and has to be used in macros.
Currently this plugin does not convert between pseudo-FITS and ImageJ coordinates correctly, the Y value is just getting applied the inversion operation and not the substraction. 
In addition, further work is needed to change this correction number from 1 to 0.5 to properly implement the FITS coordinate system.

## Float values in coordinates

FITS images store information in pixels, which are its smallest units of information. With that in mind one must be very careful when using sub-pixel precision (decimals in pixels) in some Regions of Interest (RoIs). MADCUBA will always round to an integer pixel value when extracting information. The following sections of this document explain how MADCUBA processes each RoI and how it decides which pixels are inside a RoI and which ones are not.

# Regions of Interest (RoIs)

## MADCUBA Implemented RoIs

Implemented RoIs are the tool icons that appear on the cube and map visualizer window. These tools have been implemented by the MADCUBA team to work with FITS files and use FITS coordinates unless explicity stated otherwise.

### Rectangle

#### GUI Tool

When drawing a rectangle or moving it by hand using the Rectangle Tool, only integer pixels can be selected, following the standard FITS coordinates implemented into MADCUBA.

#### Definition

Macro definition for creating a rectangle in MADCUBA contains the pixel coordinates of the bottom-left corner of the rectangle followed by its width and height in number of pixels:

`makeRectangle(x, y, width, height)`

These pixel coordinates follow the FITS standard, with the origin of the point located at the bottom-left corner (see [coordinates](#coordinate-shenanigans) section).

#### Macro recorder

The macro recorder outputs the selected rectangle with no problems and is ready to be imported any time in the future.

#### Importing RoI from ImageJ macro

No problems whatsoever arise when selecting a rectangle region using this function with integer values, which should be most common ocasion, as FITS files do not store information in a sub-pixel level. 

However some caveats should be noted when working with non-integer coordinates for this selection. This is the case for RoIs from CARTA, which are coded in celestial coordinates and are converted info a float number pixel value. To represent these rectangles MADCUBA must first do a conversion to integer values.

The following explanation is based on trial and error. What appears to be happening is that internally MADCUBA is converting the FITS coordinates to ImageJ coordinates and then selects the region based on the original Rectangle RoI Tool of ImageJ that uses the ImageJ coordinate system. And using this system, the float numbers for the X and Y values appear to be truncated.

> Note that the truncation of the X and Y values is happening on the converted coordinates using the ImageJ system, in which the origin of the pixels is on the upper-left corner. This means that a coordinate in any point of a pixel is shifting to the left and the top of a pixel.

This behaviour makes sense knowing that the built in `makeRectangle` function of ImageJ uses the the upper-left corner of the selection for its definition ([source](https://imagej.net/ij/developer/macro/functions.html#makeRectangle)), unlike MADCUBA's version of this function which uses the lower-left corner, as stated above.

After this, the values for width and height appear to be rounded up to the next integer. Using these new integer values, the Rectangle gets selected using the imageJ coordinate system.

> Note that the ImageJ coordinate system is being used, so width extends to the right, but height extends from top to bottom.

An easy and illustrative way of understading this behaviour is that the way that the region gets selected is equivalent to:

1. MADCUBA first draws the rectangle using using sub-pixel accuracy.
2. Then MADCUBA moves the rectangle to cover the entirety of the pixel that its upper-left corner touches.
3. In this position, MADCUBA selects every pixel that is being touched by the rectangle (equivalent to rounding up width and height to).

Figure **X** shows an example of the selection of a Rectangle that MADCUBA processes. Note that even though the Y coordinate starts at 2.2 the pixels in line Y=2 do not get selected.
makeRectangle(2.8,2.2,2.1,2.9)

### Ellipse

#### GUI Tool

When drawing an ellipse by hand using the Ellipse Tool, both points of the major axis can be selected with sub-pixel precision. After the ellipse is set, the ellipticity can be changed by dragging the two remaining points (minor axis), and both points of the major axis can still be moved with sub-pixel precision. But when moving the entire ellipse to another location it can only be moved an integer amount of pixels to any direction, even if the point has sub-pixel precision. For example if any point of the ellipse is somewhere the middle of a pixel (e.g 7.57, 8.40), when trying to move the ellipse to the right, the closest possible position to that point is (8.57, 8.40).

#### Definition

Macro definition for creating an ellipse in MADCUBA contains the coordinates of both points of the major axis followed by the aspect ratio, which is the ratio between the major and minor axes (0 <= aspectRatio <= 1):

`makeEllipse(x1, y1, x2, y2, aspectRatio)`

#### Macro recorder

The macro recorder outputs pixel coordinates for the first four numbers in the definition using integer values and MADCUBA has to move these two points to the corners of pixels because in the corners is where the pixel value does not have decimals. For that, what appears to be happening is that MADCUBA extends the major axis to cover the entirety of the pixels in which its points are situated and places then on opposite corners. By doing so, and because the origin point of a pixel is located in its lower-left corner, the encoded pixel in the macro recorder is not the one where the point of the major axis was situated, but the pixel that has its origin point (X.0, Y.0) in the corner where it was moved to. Two different visual examples are presented in **Fig. X**. As can be seen in this figure, only in one case the encoded pixel matches the pixel where the point was located. When the other points get extended to a corner, that corner belongs to another pixel and that other pixel is the one getting encoded.

#### Importing RoI from macro

When importing an ellipse into MADCUBA the painted ellipse matches the pixel coordinates with subpixel precision, although the real selection that MADCUBA ends up selecting does not match the visual representation of the ellipse. As stated before, information in FITS files do not have sub-pixel precision and MADCUBA has to either select an entire pixel or not select it. With an Ellipse what appears to be happening is that MADCUBA selects the pixels that have more than 50% of its area inside the visual representation of the ellipse.

### Circle

The circle can either be created with the [Ellipse Tool](#ellipse) or the [Oval Tool](#oval). Although it is recommended that it be created as a secific case of the ellipse. In that case, everything noted for the ellipse is applicable to the circle.

#### Definition

The circle can be defined by an ellipse with an aspect ratio of 1.0.

`makeEllipse(x1, y1, x2, y2, 1)`

### Point

#### GUI Tool

Using the Point Tool, the selected point has sub-pixel precision, but and MADCUBA selects the entire pixel where the point is located.

#### Definition

Macro definition for creating a point in MADCUBA contains the pixel coordinates of the point with the Y value shited by 1:

`makePoint(x, y+1)`

Note that in the definition we have the Y value + 1. In this function MADCUBA codes the pixel above the one that is to be selected. For example, if you want to take information from the (18,18) pixel, you need to code it as `makePoint(18,19)` for MADCUBA to select the pixel. This definition is also equivalent to using a rectangle of width and height equal to unity but correctly set in the (18,18) pixel: `makeRectangle(18,18,1,1)`. These two commands select the same pixel but have a different encoded pixel. 

A possible explanation for this behaviour is the incorrect FITS to ImageJ coordinate conversion. It could be that in the implementation of `makePoint`, while testing the function it was seen that a different pixel was being selected, so it was manually set to the pixel above the one that wanted to be selected. An error that "solves" an error but leaves a trail of inconsistency.

Another possible explanation is that the implemented `makePoint` function was manually implemented trying to mimic the behaviour of the built-in counterpart. The ImageJ version uses ImageJ coordinate system and the origin of the sub-pixel coordinates lie at its upper-left corner. When reading a `makePoint` macro in MADCUBA the pixel is visually set to the upper-left corner of the pixel that is getting selected, but the codification of the command points to the pixel above because using FITS coordinates, this point lies at the lower-left corner of the pixel above.

#### Macro recorder

The macro recorder of MADCUBA, however does not output a correct codification of a point.
What the macro recorder does is output two commands:
1. A `makePoint(x_imagej, y_imagej)` definition like the one above, but using ImageJ coordinates instead of FITS coordinates. This is incorrect because the `makePoint` function was implemented into MADCUBA to use FITS coordinates and this command would paint the point in a different location. It seems that the macro recorder is outputting the built-in `makePoint` function of imageJ that uses ImageJ coordinates, but that function is not accesible since MADCUBA changed the function to work with FITS coordinates when it was implemented.
2. A `makePolygon(x, y+1)` definition using the correct FITS coordinates. This codification is incorrect because when trying to run amacro with this command, an error pops up saying that Polygons need to have at least 3 vertex.

Both of these definitions are incorrect and to have a correct command we have to use the `makePoint` function with the coordinates that the `makePolygon` command outputs.

#### Importing RoI from ImageJ macro

If the above inconsistency is being taken care of, importing a point from a macro has no problems.
When importing a point with decimals, the X value gets rounded down and the Y value gets rounded up (to coincide with the y+1 codification). It is just like clicking on the FITS pixel at this specific values.

### Line

The behaviour of a line is very particular. On first glance it appears that it is not using either the FITS or the ImageJ coordinate system. It appears to use a mix of the two in which the first pixel of the image is (1,1) at the lower-left corner of the image (just like FITS), but the origin point inside a pixel lies on its upper-left corner (like ImageJ). This is because this Line tool is using the built-in line implementation of ImageJ with the incorrect FITS to ImageJ conversion explained in the [coordinate section](#coordinate-systems).

This makes lines an unrealiable RoI in MADCUBA in its current implementation. Its behaviour is thoroughly explained in the following subsections.

#### GUI Tool

When drawing a line by hand using the Line Tool, both points of the line can be selected with sub-pixel precision. After the line is set, both points can still be moved with sub-pixel precision. Also, contrary to the ellipse, when moving the line to another location it can be moved a decimal amount of pixels to any direction.

The visual representation of a line is not really the same path that MADCUBA takes to decide which pixels to select along the line. What appears to be happening is that  MADCUBA selects the entirety of the pixels where both ends are located. Then creates an imaginary line between the centers of those pixels, and the pixels in between get selected according to where that imaginary line is going through. **Figure X** shows examples of these line selections that MADCUBA creates. Note that when an odd number of pixels separate the endpoints of a line in a given direction, the selected pixel in the middle is the one at the bottom for the X axis and the one on the right for the Y axis.

#### Definition

Macro definition for creating a line in MADCUBA contains the coordinates of the points of both ends of the line:

`makeLine(x1, y1-1, x2, y2-1)`

Note that in the definition we currently have the Y values - 1. This is because the incorrect conversion between FITS and ImageJ coordinates.

#### Macro recorder

The macro recorder outputs pixel coordinates for the pixels using integer values and MADCUBA has to move these two points to the corners of pixels because in the corners is where the pixel value does not have decimals. For that, what appears to be happening is that MADCUBA extends the line to cover the entirety of the pixels in which its endpoints are situated and places then on opposite corners. MADCUBA then encodes the pixel that has its origin point (X.0, Y.0) in this corner, which usually is not the same pixel where the endpoint of the line was located. This is a very similar behaviour to that seen for the ellipse, but with the origin of a pixel on another corner.

Apart from this corner issue, the Y value of the line is also misrepresented because the FITS to ImageJ coordinate conversion yields an incorrect pixel. In this implementation of the line, it gets painted on the pixel above. Most of the time this shift in coordinates gets countered by the point of origin on the pixel. Bit again, this is an error that solves another error, leaving a lot of inconsistency behind. 
This inconsistency is present when the macro recorder, because a line selected by hand via GUI will have a bad codification once exported into a macro. And when putting that codification back into another macro, the selected line is different.

Different visual examples are presented in **Fig. X**. As can be seen in this figure, only in one case the encoded pixel matches the pixel where the point was located. When the other points get extended to a corner, that corner belongs to another pixel and that other pixel is the one getting encoded.

#### Importing RoI from macro

When importing a line into MADCUBA the painted line matches the pixel coordinates with subpixel precision, but with the aforementioned shift of 1 in the Y value. The selection that MADCUBA performs then follows the same behaviour explained in the GUI subsection.

#### Line with more than 2 points (polyline)

The `makeLine` function can also be used with more than two points (polyline) when importing via macro. The GUI Line Tool cannot be used to select a polyline.
It is important to note that when a Line with three or more points is imported, the coordinate system changes and now the Y values for the points are not shifted 1 pixel above. In this case MADCUBA does not paint the line using sub-pixel precision, every coordinate gets rounded to the nearest integer value before representing the line. The final selection then follows the same behaviour as with the other lines, the pixel that gets selected is the one that has the vertex in its origin corner, which is the pixel located down to the right of this corner.

#### Polygon

#### GUI Tool

When drawing a polygon by hand using the implemented Polygon Tool, only integer pixels can be selected, following the standard FITS coordinates implemented into MADCUBA.

#### Definition

Macro definition for creating a polygon in MADCUBA contains the coordinates of the pixel whose lower-left corner gets touched by the polygon line:

`makePolygon(x1, y1, x2, y2, x3, y3, ..., xn, yn)`

> Note that the pixels in the codification are not all inside the polygon. It is just that the origin point (lower-left corner) of that pixel gets touched by the polygon delimiting line. **Fig. X** shows an example where the pixels from the top and right sides of the polygon are coded but not inside the polygon.

#### Macro recorder

The macro recorder outputs the selected polygon with no problems and is ready to be imported any time in the future.

#### Importing RoI from macro

Once a polygon has been imported into madcuba through a macro, each pixel has a vertex in the polygon shape. Each one of these vertices can be moved into another pixel without sub-pixel precision.

When importing a polygon shape with non-integer coordinates for the vertices, each one of these points gets rounded to the nearest integer value before selecting the polygon.



## ImageJ RoIs

This section covers other types of RoIs that are present in the ImageJ macro and function set, but that have not been individually implemented into the MADCUBA cube visualizer.

### Oval

Apart from ellipses, ImageJ also offers an oval shapes and it can also be used to create circles. Even though this has not been personally implemented into MADCUBA, this RoI uses the FITS coordinate system.

#### GUI Tool

The oval tool of ImageJ is not present in the Cube or Image Visualizer window. It can be selected by right-clicking the Ellipse Tool Icon on the ImageJ Toolbar and selecting 'Oval Selections'.

This tool only lets users select the corners of pixels without a sub-pixel precision. When an oval is set, its size and position can also be only changed by an integer amount of pixels.

#### Definition

Macro definition for creating an oval in MADCUBA is the same as for a rectangle of the same size. It contains the pixel coordinates of the bottom-left corner of the rectangle in which the oval is set followed by its width and height in number of pixels:

`makeOval(x, y, width, height)`

#### Macro recorder

The macro recorder outputs the selected oval with no problems and is ready to be imported any time in the future.

#### Importing RoI from ImageJ macro

This region can be imported into madcuba using both integer and float values for each one of its input parameters. When using float values, the oval gets drawn using sub-pixel precision. However the selection must have a pixel resolution. The mechanism for the rounding of the input values of the oval seems to be the same as for the rectangle tool. After that initial rounding the selection of the pixels that get selected seems to be based on percentage of pixel inside the oval.

### Selection: Polygon

Not to be confused with the Polygon Tool from MADCUBA. Using the built-in `selection` function a polygon can also be selected. The main difference is that with this tool the polygon can have float values for its vertices in the painted polygon, however the real selection that MADCUBA does at the end will always have a precision of one pixel when extracting information. 
This RoI uses the imageJ coordinate system, so a conversion must first be applied because MADCUBA works with FITS coordinates. This can be easily done with the `CONVERT_PIXELS_COORDINATES` plugin of MADCUBA.
How MADCUBA selects the pixels for the final selection before the extraction of information is not currently documented.

#### GUI Tool

This selection cannot be created using GUI elements and has to be coded and imported using a macro.

#### Definition

The polygon selection is coded by the keyword "polygon", and two arrays containing the X and Y values for every point that conforms the polygon:

`makeSelection("polygon", Xvalues, Yvalues)`

While the Polygon Tool of MADCUBA uses integer values of pixels to paint the region, this Polygon selection from ImageJ accepts float numbers and its vertices can be manually moved into sub-pixel locations. Even though the visual representation of a Polygon selection using this Selection Tool accepts float values, it is important to note that MADCUBA does not, and the final selection that MADCUBA processes only takes the totality of a pixel.

> Note that this RoI uses the ImageJ coordinate system, starting at (0,0) on the upper-left corner of the image and with pixels that have their origin of coordinates on their upper-left corner.

### Selection: Polyline

ImageJ offers a `selection` function that accepts different input parameters. Another one of them is "polyline". This selection works just like the Polygon Selection, and the same instructions can be apllied here.

#### Definition

The polyline selection is coded by the keyword "polyline", and two arrays containing the X and Y values for every point that conforms the polyline:

`makeSelection("polyline", Xvalues, Yvalues)`






### CARTA RoIs

RoIs selected from CARTA (and CASA) can be imported into MADCUBA using the newly developed Import RoIs from CARTA Tool. This plugin can be installed as a macro or as a tool following the instructions detailed [here](#plugin-installation).

### Rotated rectangle

A rotated rectangle from CARTA is imported into MADCUBA as a polygon selection from ImageJ. It is coded by two arrays containing the X and Y values for every point that conforms the polygon:

`makeSelection("polygon", Xvalues, Yvalues)`

### Annulus

The annulus is a RoI that has not been implemented as a tool in MADCUBA nor in ImageJ. Altough its shape can be obtained using the Oval tool from ImageJ by using the `alt` key modifier and substracting an oval selection from a larger oval selection.








# MADCUBA cheat-sheet

## Key modifierds

The following keys have been tested for ctrl-super-alt keyboards (sry macs).

Using the `alt` modifier key several shapes can be substracted from another shapes.

Using the `shift` key shapes can be added and/or stacked on top of eachother.

Using the `ctrl` key an alternative option is enabled for creating shapes. For the rectangle and the oval it changes the creation mode from from corner-to-corner to center-to-corner. For lines it makes the endpoints stick to pixel corners.

## Plugin installation

### Installation of macros

To install a macro in madcuba the macro code must be wrapped inside a macro function.
Macros in a macro set can use global variables to communicate with each other.

### Installation of tools

Macros can also be installed as tools to make them appear on the Toolset of imageJ.



