/* 
 * Custom made macro to convert CASA and CARTA ROIs to MADCUBA
 * A cube or image must be opened and selected before running this macro
 *
 * Possible ROIs:
 * Point as coordinates:
 *     symbol [x, y]
 * Line; the two coordinates are the vertices:
 *     line [[x1, y1], [x2, y2]]
 * Polyline; there could be many [x, y] vertices:
 *     polyline [[x1, y1], [x2, y2], [x3, y3], ...] 
 * Rectangular box; the two coordinates are two opposite corners:
 *     box [[x1, y1], [x2, y2]]
 * Center box; [x, y] define the cemnter point of the box and [x_width, y_width] the width of the sides:
 *     centerbox [[x, y], [x_width, y_width]]
 * Rotated box; [x, y] define the center point of the box; [x_width, y_width] the width of the sides; rotang the rotation angle:
 *     rotbox [[x, y], [x_width, y_width], rotang]
 * Polygon; there could be many [x, y] corners; note that the last point will connect with the first point to close the polygon:
 *     poly [[x1, y1], [x2, y2], [x3, y3], ...]
 * Circle; center of the circle [x,y], r is the radius:
 *     circle [[x, y], r]
 * Annulus; center of the circle is [x, y], [r1, r2] are inner and outer radii:
 *     annulus [[x, y], [r1, r2]]
 * Ellipse; center of the ellipse is [x, y]; semi-axes are [b1, b2] starting with the vertical axis when first drawing the ellipse; 
 *     position angle of vertical axis is pa:
 *     ellipse [[x, y], [b1, b2], pa]
 */

// Global variables
var version = "v1.0.0-alpha1";
var date = "20240419";
var changelog = "First release version candidate";
var coordUnits = newArray ("deg", "rad", "arcmin", "arcsec", "pix");
var geometry = newArray ("symbol", "line", "polyline", "box", "centerbox", "rotbox", "poly", "circle", "annulus", "ellipse"); 

macro "Import ROIs from CARTA Action Tool - C037 T0608A T5608L T8608M Tf608A T2f10R T8f09o Tef09I" {     // RoI: C037T0b10R T6b09o Tcb09I

    path = File.openDialog("Select a ROI File");
    fx = File.openAsString(path);

    rows = split(fx,"\n\r");                    // separate file into rows
    for (i=0; i<rows.length; i++) {             // iterate through csv list
        if (startsWith(rows[i],"#") == 0) {     // skip first line
            if (indexOf(rows[i], "coord=") != -1) {
                data = split(substring(rows[i], indexOf(rows[i], "coord="), indexOf(rows[i], "coord=")+30), "=,");
                        // search where the coord system is and store it at data[1]. +30 is arbitrary, to give enough characters for every possibility
                if (call("FITS_CARD.getStr","RADESYS") != data[1]) print("WARNING:  Coordinate system in ALMA Roi different that that in cube");
            }
            data = split(rows[i], "][,");   // store different important data in an array. Some of these strings are preceded by a blank space.
                                            // that is why later the 'if conditions' are not comparing data[0] () with strings, but locating the
                                            // position of the polygon string in the array data[0]. i.e data[0] is "rotbox " and not "rotbox"

            // // uncomment for quick data log
            // print("New run");
            // for (j=0; j<data.length; j++) {
            //     print("data[" + j + "]: '" + data[j] + "'");
            // }

            if (indexOf(data[0], geometry[0]) == 0) {           // POINT
                point = parseALMACoord(data[1], data[2]);
                corr = 0.5;
                x = parseFloat(point[0]) + corr;
                y = parseFloat(point[1]) + corr;
                makePoint(x, y);
                // print("painted: " + x + ", " + y);
    
            } else if (indexOf(data[0], geometry[1]) == 0) {    // LINE
                point1 = parseALMACoord(data[1], data[2]);
                corr = 0.5;
                x1 = parseFloat(point1[0]) + corr;
                y1 = parseFloat(point1[1]) + corr - 1;  // Madcuba takes the information from and paints the line in the pixel above the vertices
                point2 = parseALMACoord(data[4], data[5]);
                x2 = parseFloat(point2[0]) + corr;      // maybe it is a nomenclature problem like the one in point, also takes info from incorrect pixel
                y2 = parseFloat(point2[1]) + corr - 1;
                makeLine(x1, y1, x2, y2);
                // print("from: " + x1 + ", " + y1);
                // print("to: " + x2 + ", " + y2);
            
            } else if (indexOf(data[0], geometry[2]) == 0) {    // POLYLINE (almost the same as polygon)
                idx = 0;
                numb = 1;
                corr = 0.5;
                x = newArray(round(data.length/3));
                y = newArray(round(data.length/3));
                do {         
                    b = parseALMACoord(data[numb], data[numb+1]); 
                    x[idx] = parseFloat(call("CONVERT_PIXELS_COORDINATES.fits2ImageJX", b[0])) + corr;
                    y[idx] = parseFloat(call("CONVERT_PIXELS_COORDINATES.fits2ImageJY", b[1])) + corr;
                    idx++;
                    numb = numb + 3;        // Jump to the next polygon vertex. The data object is separated: ...[Xn], [Yn], [. ], [Xn+1], [Yn+1], [. ]...
                } while (b[0] != -1) 
                x = Array.trim(x, idx-1);   // Trim extra elements of the array that were created before
                y = Array.trim(y, idx-1);
                makeSelection("polyline", x, y);
    
            } else if (indexOf(data[0], geometry[3]) == 0) {    // BOX (CASA)
                corner1 = parseALMACoord(data[1], data[2]);
                corner2 = parseALMACoord(data[4], data[5]);
                corr = 0.5;                             // a correction of half a pixel must be done
                x1 = parseFloat(corner1[0]) + corr;     // Madcuba sets the coordinates of a pixel in the lower left corner in a FITS image
                y1 = parseFloat(corner1[1]) + corr;     // with this correction it gets shifted to the center of the pixel
                x2 = parseFloat(corner2[0]) + corr;
                y2 = parseFloat(corner2[1]) + corr;
                x_width = x2 - x1;
                y_width = y2 - y1;
                makeRectangle(x1, y1, x_width, y_width);    // Madcuba does the rounding when working with makeRectangle
    
            } else if (indexOf(data[0], geometry[4]) == 0) {    // CENTER BOX (CARTA)
                center = parseALMACoord(data[1], data[2]);
                corr = 0.5;
                x_center = parseFloat(center[0]) + corr;
                y_center = parseFloat(center[1]) + corr;
                widths = parseALMAxy(data[4], data[5]);
                x1 = x_center + parseFloat(widths[0]/2);    // + because RA increases to the left and madcuba uses the lower left corner
                y1 = y_center - parseFloat(widths[1]/2);
                x_width = -parseFloat(widths[0]);   // - because parseALMAxy calculated a positive width to the left 
                                                    //and madcuba needs a width to the right of the rectangle
                y_width = parseFloat(widths[1]);
                makeRectangle(x1, y1, x_width, y_width);    // Madcuba does the rounding when working with makeRectangle
    
            } else if (indexOf(data[0], geometry[5]) == 0) {    // ROTATED BOX
                pa = parseALMAangle(data[6]);
                center = parseALMACoord(data[1], data[2]);
                b = parseALMAxy(data[4], data[5]);
                rotatedRect(parseFloat(center[0]), parseFloat(center[1]), b[0]/2, b[1]/2, pa);
    
            } else if (indexOf(data[0], geometry[6]) == 0) {    // POLYGON
                stop = 0;
                idx = 0;        // index to trim later
                numb = 1;       // index from which to start to read data array
                corr = 0.5;     // ImageJ starts counting from the top-left of each pixel. The same correction as with FITS must be applied here
                x = newArray(round(data.length/3));
                y = newArray(round(data.length/3));
                do {
                    b = parseALMACoord(data[numb], data[numb+1]); 
                    x[idx] = parseFloat(call("CONVERT_PIXELS_COORDINATES.fits2ImageJX", b[0])) + corr;
                    y[idx] = parseFloat(call("CONVERT_PIXELS_COORDINATES.fits2ImageJY", b[1])) + corr;
                    if (data[numb+2] != " ") {      // stop when a double ]] appears (at the end of the vertices).
                        stop=1;                     // ]] means there is no space afterwards, but a new keyword
                    }
                    idx++;
                    numb = numb + 3;        // Jump to the next polygon vertex. The data object is separated: ...[Xn], [Yn], [. ], [Xn+1], [Yn+1], [. ]...
                } while (stop != 1)
                x2 = Array.trim(x, idx);    // Trim extra elements of the array that were created before
                y2 = Array.trim(y, idx);
                makeSelection("polygon", x2, y2);
                // Array.show(x, y, x2, y2);
     
            } else if (indexOf(data[0], geometry[7]) == 0) {    // CIRCLE 
                pa = 0;
                center = parseALMACoord(data[1], data[2] );
                corr = 0.5;
                x_center = parseFloat(center[0]) + corr;
                y_center = parseFloat(center[1]) + corr;
                radius = parseALMAxy(data[3], data[3]);
                toellipse(x_center, y_center, parseFloat(abs(radius[0])), parseFloat(abs(radius[1])), pa);
             
            } else if (indexOf(data[0], geometry[8]) == 0) {    // ANNULUS
                center = parseALMACoord(data[1], data[2]);
                corr = 0.5;
                x_center = parseFloat(center[0]) + corr;
                y_center = parseFloat(center[1]) + corr;
                r1 = parseALMAxy(data[3], data[3]);
                r2 = parseALMAxy(data[4], data[4]);
                x2 = x_center - parseFloat(r2[1]);   // outer circle
                y2 = y_center - parseFloat(r2[1]);
                makeOval(x2, y2, r2[1]*2, r2[1]*2);
                x1 = x_center - parseFloat(r1[1]);   // inner circle
                y1 = y_center - parseFloat(r1[1]);
                setKeyDown("alt");
                makeOval(x1, y1, r1[1]*2, r1[1]*2);
                setKeyDown("none");
                // annulus(round(center[0]), round(center[1]), round(abs(b[0])), round(abs(b[1])));    // old version
    
            } else if (indexOf(data[0], geometry[9]) == 0) {    // ELLIPSE
                pa = parseALMAangle(data[6]);
                center = parseALMACoord(data[1], data[2]);
                corr = 0.5;
                x_center = parseFloat(center[0]) + corr;
                y_center = parseFloat(center[1]) + corr;
                axes = parseALMAxy(data[5], data[4]);   // for an ellipse the first is y_width
                if (abs(axes[0]) > abs(axes[1])) {      // if x_width > y_width
                    bmaj = axes[0];
                    bmin = axes[1];
                    pa = pa-PI/2;  //change position angle to "change" x1, y1 to the biggest axis (madcuba accepts only ellipticity<=1)
                } else {
                    bmaj = axes[1];
                    bmin = axes[0];
                }
                toellipse(x_center, y_center, parseFloat(abs(bmaj)), parseFloat(abs(bmin)), pa);
            }
            run("GET SPECTRUM", "roi");
        }
    }
}

macro "Import ROIs from CARTA Action Tool Options" {
    showMessage("Info", "<html>"
    + "<center>Custom made tool to convert CASA and CARTA RoIs to MADCUBA.<br><br></center>"
    + "<strong>Important</strong>: A cube or image must be opened and selected before running this macro. <br><br>"
    + "<h3>Changelog</h3>"
    + "<font size=-1>"
    + version + " - " + date + " <br>"
    + changelog);
}

/*
 * ---------------------------------
 * ---------------------------------
 * ------ AUXILIARY FUNCTIONS ------
 * ---------------------------------
 * ---------------------------------
 */

/**
 * Draw a rotated rectangle given the input parameters
 * All parameters are in pixels except angle in radians
 *
 * @param x  X coordinates for the center of the rectangle
 * @param y  Y coordinates for the center of the rectangle
 * @param halfWidth  Half of the width of the rectangle
 * @param halfHeight  Half of the height of the rectangle
 * @param angle  Rotation Angle in a counterclockwise direction
 */
function rotatedRect(x, y, halfWidth, halfHeight, angle) {
    x1 = newArray(4);
    y1 = newArray(4);
    c = cos(angle);
    s = sin(angle);
    r1x = -halfWidth * c - halfHeight * s;
    r1y = -halfWidth * s + halfHeight * c;
    r2x =  halfWidth * c - halfHeight * s;
    r2y =  halfWidth * s + halfHeight * c;
    corr = 0.5;    // madcuba starts counting the pixels on the left and the top of each pixel for ImageJXY coords
    // Returns four points in clockwise order starting from the top left.
    x1[0] = parseFloat(call("CONVERT_PIXELS_COORDINATES.fits2ImageJX", x + r1x)) + corr;
    x1[1] = parseFloat(call("CONVERT_PIXELS_COORDINATES.fits2ImageJX", x + r2x)) + corr;
    x1[2] = parseFloat(call("CONVERT_PIXELS_COORDINATES.fits2ImageJX", x - r1x)) + corr;
    x1[3] = parseFloat(call("CONVERT_PIXELS_COORDINATES.fits2ImageJX", x - r2x)) + corr;
    y1[0] = parseFloat(call("CONVERT_PIXELS_COORDINATES.fits2ImageJY", y + r1y)) + corr;
    y1[1] = parseFloat(call("CONVERT_PIXELS_COORDINATES.fits2ImageJY", y + r2y)) + corr;
    y1[2] = parseFloat(call("CONVERT_PIXELS_COORDINATES.fits2ImageJY", y - r1y)) + corr;
    y1[3] = parseFloat(call("CONVERT_PIXELS_COORDINATES.fits2ImageJY", y - r2y)) + corr;
    makeSelection("polygon", x1, y1);
    // Array.show(x1, y1);
}

/**
 * Draw ellipse given the input parameters
 * All parameters are in pixels except pa in radians
 *
 * @param x  X coordinates for the center of the ellipse
 * @param y  Y coordinates for the center of the ellipse
 * @param bmaj  Major axis
 * @param bmin  Minor axis
 * @param pa  Position Angle of the major axis in a counterclockwise direction
 */
function toellipse(x, y, bmaj, bmin, pa) {
    x1 = x + bmaj*sin(pa);
    y1 = y - bmaj*cos(pa);
    x2 = x - bmaj*sin(pa);
    y2 = y + bmaj*cos(pa);
    e = bmin/bmaj;
    makeEllipse(x1, y1, x2, y2, e);
    // split(data[4], "deg");     // Jesus put this here but it does nothing of value?
}

/**
 * Convert angle to radians
 *
 * @param val  Input angle with units
 * @return  Converted angle in radians
 */
function parseALMAangle (val) {
    coordUnits = newArray("deg", "rad", "arcmin", "arcsec");
    for (j=0; j<coordUnits.length; j++) if (indexOf(val, coordUnits[j]) != -1)  unitsval=j;     // read coordinate unit
    angle = parseFloat(substring(val, 0, indexOf(val, coordUnits[unitsval])));
    if (unitsval == 0)  angle = angle*PI/180.0;
    else if (unitsval == 2) angle = (angle*PI/(180.0*60.0));
    else if (unitsval == 3) angle = (angle*PI/(180.0*3600.0));
    return angle;
}

/**
 * Convert coordinates to a FITS image pixel
 *
 * @param ra  RA with units
 * @param dec  DEC with units
 * @return  Pixel of the image containing input coordinates
 */
function parseALMACoord (ra, dec) {
    coordUnits = newArray ("deg", "rad", "pix");
    unitsval= 10;
    output = newArray(2);
    for (j=0; j<coordUnits.length; j++) if (indexOf(ra, coordUnits[j]) != -1) unitsval=j;       // read coordinate unit
    if (unitsval == 10) {   // Sexagesimal Coordinates
        // right ascension
        par = split(ra, "hdms:");
        if (par.length == 1 && indexOf(ra, ".") <= 5) {
            par = split(ra, ".");
            if (par.length > 3) par[2] = par[2] + "." + par[3];
        }
        rafin = (parseFloat(par[0]) + parseFloat(par[1])/60.0 + parseFloat(par[2])/3600.0) * 15.0;
        // declination
        par = split(dec, "hdms:");
        if (par.length == 1 && indexOf(dec, ".") <= 5) {
            par = split(dec,".");
            if (par.length > 3) par[2] = par[2] + "." + par[3];
        }
        if (indexOf(dec, "-") != -1) decfin = parseFloat(par[0]) - parseFloat(par[1])/60.0 - parseFloat(par[2])/3600.0;
        else decfin = parseFloat(par[0]) + parseFloat(par[1])/60.0 + parseFloat(par[2])/3600.0;

        output[0] = call("CONVERT_PIXELS_COORDINATES.coord2FitsX", rafin, decfin, "");
        output[1] = call("CONVERT_PIXELS_COORDINATES.coord2FitsY", rafin, decfin, "");
    } else {
        rafin = substring(ra, 0, indexOf(ra, coordUnits[unitsval]));
        decfin = substring(dec, 0, indexOf(dec, coordUnits[unitsval]));
        if (unitsval == 0 || unitsval == 1) {
            if (unitsval == 1) {
                rafin =  rafin*180.0/PI;
                decfin = decfin*180.0/PI;
            }
            output[0] = call("CONVERT_PIXELS_COORDINATES.coord2FitsX", rafin, decfin, "");
            print(decfin);
            output[1] = call("CONVERT_PIXELS_COORDINATES.coord2FitsY", rafin, decfin, "");
            print(output[1]);

        } else if ( unitsval == 2) {
            output[0] = toString(parseFloat(rafin) + 1);      // correction to change 0,0 starting point to 1,1 starting point (currently used in madcuba)
            output[1] = toString(parseFloat(decfin) + 1);     // when fits coordinates are properly implemented in MADCUBA this will have to change to 1.5
        }
    }
    return output;
}

/**
 * Convert an arc in the sky to pixels
 * Note that this function yields a negative width value because RA increases to the left instead of to the right
 * And this code calculates the width from left to right because MADCUBA has the origin of coordinates at the bottom-left
 *
 * @param valx  RA arc in the sky with units
 * @param valy  DEC arc in the sky with units
 * @return  Converted arc
 */
function parseALMAxy (valx,valy) {
    coordUnits = newArray("deg", "rad", "arcmin", "arcsec", "pix");
    unitsval = -1;
    coord = newArray(2);
    coord[0] = -1;

    for (j=0; j<coordUnits.length; j++) if (indexOf(valx, coordUnits[j]) != -1)  unitsval=j;    // read coordinate unit
    if (unitsval == -1) return coord;   // case of request without unit to use with polygon

    value = parseFloat (substring(valx, 0, indexOf(valx, coordUnits[unitsval])));
    if      (unitsval == 0) coord[0] = value / parseFloat(call("FITS_CARD.getDbl","CDELT1"));
    else if (unitsval == 1) coord[0] = (value*180.0/PI) / parseFloat(call("FITS_CARD.getDbl","CDELT1"));
    else if (unitsval == 2) coord[0] = (value/60.0) / parseFloat(call("FITS_CARD.getDbl","CDELT1"));
    else if (unitsval == 3) coord[0] = (value/3600.0) / parseFloat(call("FITS_CARD.getDbl","CDELT1"));
    else if (unitsval == 4) coord[0] = value;

    for (j=0; j<coordUnits.length; j++) if (indexOf(valy, coordUnits[j]) != -1)  unitsval=j;    // read coordinate unit
    value = parseFloat(substring(valy, 0, indexOf(valy, coordUnits[unitsval])));
    if      (unitsval == 0) coord[1] = value / parseFloat(call("FITS_CARD.getDbl","CDELT2"));
    else if (unitsval == 1) coord[1] = (value*180.0/PI) / parseFloat(call("FITS_CARD.getDbl","CDELT2"));
    else if (unitsval == 2) coord[1] = (value/60.0) / parseFloat(call("FITS_CARD.getDbl","CDELT2"));
    else if (unitsval == 3) coord[1] = (value/3600.0) / parseFloat(call("FITS_CARD.getDbl","CDELT2"));
    else if (unitsval == 4) coord[1] = value;
    return coord;
}
