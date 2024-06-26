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
 * Center box; [x, y] define the center point of the box and [x_width, y_width]
 *     the width of the sides:
 *     centerbox [[x, y], [x_width, y_width]]
 * Rotated box; [x, y] define the center point of the box; [x_width, y_width]
 *     the width of the sides; rotang the rotation angle:
 *     rotbox [[x, y], [x_width, y_width], rotang]
 * Polygon; there could be many [x, y] corners; note that the last point will
 *     connect with the first point to close the polygon:
 *     poly [[x1, y1], [x2, y2], [x3, y3], ...]
 * Circle; center of the circle [x,y], r is the radius:
 *     circle [[x, y], r]
 * Annulus; center of the circle is [x, y], [r1, r2] are inner and outer radii:
 *     annulus [[x, y], [r1, r2]]
 * Ellipse; center of the ellipse is [x, y]; semi-axes are [b1, b2] starting
 *     with the vertical axis when first drawing the ellipse; position angle of 
 *     vertical axis is pa:
 *     ellipse [[x, y], [b1, b2], pa]
 */

var version = "v1.1.1";
var date = "20240618";
var changelog = "Fix read error with no crtf visual parameters";

// Global variables
var coordUnits = newArray ("deg", "rad", "arcmin", "arcsec", "pix");
var geometry = newArray ("symbol", "line", "polyline", "box", "centerbox", 
                         "rotbox", "poly", "circle", "annulus", "ellipse"); 

macro "Import ROIs from CARTA Action Tool - C037 T0608A T5608L T8608M Tf608A T2f10R T8f09o Tef09I" {
       // RoI: C037T0b10R T6b09o Tcb09I

    path = File.openDialog("Select a ROI File");
    fx = File.openAsString(path);

    rows = split(fx,"\n\r");                    // separate file into rows
    for (i=0; i<rows.length; i++) {             // iterate through csv list
        if (startsWith(rows[i],"#") == 0) {     // skip first line
            if (indexOf(rows[i], "coord=") != -1) {
                /* search the coord system string and store it */
                coordSystem = split(substring(rows[i], indexOf(rows[i],
                                              "coord=")), "=,");
                if (call("FITS_CARD.getStr","RADESYS") != coordSystem[1]) 
                    print("WARNING:  Coordinate system in ALMA Roi different "
                          + "than that in cube");
            }
            /* Separate the data into an array, data[0] contains the RoI type
            Some of these strings are preceded or followed by a blank space. 
            That is why later the 'if' conditions are not comparing data[0]
            with strings, but locating the position of the polygon string in 
            the array data[0] (i.e data[0] is "rotbox " and not "rotbox") */
            data = split(rows[i], "][,");

            // /* uncomment for quick data log */
            // print("New run");
            // for (j=0; j<data.length; j++) {
            //     print("data[" + j + "]: '" + data[j] + "'");
            // }

            /* POINT */
            if (indexOf(data[0], geometry[0]) == 0) {
                point = parseALMACoord(data[1], data[2]);
                x = parseFloat(point[0]);
                y = parseFloat(point[1]);
                makePoint(x, y);
                // print("painted: " + x + ", " + y);
            
            /* LINE */
            } else if (indexOf(data[0], geometry[1]) == 0) {
                point1 = parseALMACoord(data[1], data[2]);
                x1 = parseFloat(point1[0]);
                y1 = parseFloat(point1[1]);
                point2 = parseALMACoord(data[4], data[5]);
                x2 = parseFloat(point2[0]);
                y2 = parseFloat(point2[1]);
                makeLine(x1, y1, x2, y2);
                // print("from: " + x1 + ", " + y1);
                // print("to: " + x2 + ", " + y2);
            
            /* POLYLINE (almost the same as polygon) */
            } else if (indexOf(data[0], geometry[2]) == 0) {
                stop = 0;
                idx = 0;    // index of points
                numb = 1;   // index from which to start reading data array
                x = newArray(round(data.length/3));
                y = newArray(round(data.length/3));
                do {         
                    b = parseALMACoord(data[numb], data[numb+1]); 
                    x[idx] = 
                        parseFloat(call(
                            "CONVERT_PIXELS_COORDINATES.fits2ImageJX", b[0]));
                    y[idx] = 
                        parseFloat(call(
                            "CONVERT_PIXELS_COORDINATES.fits2ImageJY", b[1]));
                    /* stop when a double ]] appears in the ROI file (at the end
                    of the vertices). In the ROI file when ]] appears, the next
                    item is not a blank space, but a new keyword */
                    if (data[numb+2] != " ") {
                        stop=1;
                    }
                    idx++;
                    /* Jump to the next polygon vertex. The data object is 
                    separated: ...[Xn], [Yn], [ ], [Xn+1], [Yn+1], [ ]... */
                    numb = numb + 3;
                } while (stop != 1)
                /* trim extra elements of the array that were created before */
                x = Array.trim(x, idx);
                y = Array.trim(y, idx);
                makeSelection("polyline", x, y);
                Array.show(x, y);
    
            /* BOX (CASA) */
            } else if (indexOf(data[0], geometry[3]) == 0) {
                corner1 = parseALMACoord(data[1], data[2]);
                corner2 = parseALMACoord(data[4], data[5]);
                x1 = parseFloat(corner1[0]);
                y1 = parseFloat(corner1[1]);
                x2 = parseFloat(corner2[0]);
                y2 = parseFloat(corner2[1]);
                x_width = x2 - x1;
                y_width = y2 - y1;
                /* MADCUBA does the rounding when working with makeRectangle */
                makeRectangle(x1, y1, x_width, y_width);
    
            /* CENTER BOX (CARTA) */
            } else if (indexOf(data[0], geometry[4]) == 0) {
                center = parseALMACoord(data[1], data[2]);
                x_center = parseFloat(center[0]);
                y_center = parseFloat(center[1]);
                width = parseALMAarc(data[4]);
                height = parseALMAarc(data[5]);
                x1 = x_center - parseFloat(width/2);
                y1 = y_center - parseFloat(height/2);
                x_width = parseFloat(width);
                y_width = parseFloat(height);
                /* MADCUBA does the rounding when working with makeRectangle */
                makeRectangle(x1, y1, x_width, y_width);
    
            /* ROTATED BOX */
            } else if (indexOf(data[0], geometry[5]) == 0) {
                pa = parseALMAangle(data[6]);
                center = parseALMACoord(data[1], data[2]);
                b1 = parseALMAarc(data[4]);
                b2 = parseALMAarc(data[5]);
                rotatedRect(parseFloat(center[0]), parseFloat(center[1]),
                            b1/2, b2/2, pa);
    
            /* POLYGON */
            } else if (indexOf(data[0], geometry[6]) == 0) {
                stop = 0;
                idx = 0;    // index of points
                numb = 1;   // index from which to start reading data array
                x = newArray(round(data.length/3));
                y = newArray(round(data.length/3));
                do {
                    b = parseALMACoord(data[numb], data[numb+1]); 
                    x[idx] = 
                        parseFloat(call(
                            "CONVERT_PIXELS_COORDINATES.fits2ImageJX", b[0]));
                    y[idx] = 
                        parseFloat(call(
                            "CONVERT_PIXELS_COORDINATES.fits2ImageJY", b[1]));
                    /* stop when a double ]] appears in the ROI file (at the end
                    of the vertices). In the ROI file when ]] appears it has no
                    space afterwards, but a new keyword */
                    if (data[numb+2] != " ") {
                        stop=1;
                    }
                    idx++;
                    /* Jump to the next polygon vertex. The data object is 
                    separated: ...[Xn], [Yn], [. ], [Xn+1], [Yn+1], [. ]... */
                    numb = numb + 3;
                } while (stop != 1)
                /* trim extra elements of the array that were created before if
                the crtf file has more parameters at the end */
                x2 = Array.trim(x, idx);
                y2 = Array.trim(y, idx);
                makeSelection("polygon", x2, y2);
                // Array.show(x, y, x2, y2);
     
            /* CIRCLE  */
            } else if (indexOf(data[0], geometry[7]) == 0) {
                pa = 0;
                center = parseALMACoord(data[1], data[2] );
                xCenter = parseFloat(center[0]);
                yCenter = parseFloat(center[1]);
                radius = parseALMAarc(data[3]);
                toEllipse(xCenter, yCenter, parseFloat(abs(radius)),
                          parseFloat(abs(radius)), pa);
             
            /* ANNULUS */
            } else if (indexOf(data[0], geometry[8]) == 0) {
                center = parseALMACoord(data[1], data[2]);
                xCenter = parseFloat(center[0]);
                yCenter = parseFloat(center[1]);
                r1 = parseALMAarc(data[3]);
                r2 = parseALMAarc(data[4]);
                x2 = xCenter - parseFloat(r2);   // outer circle
                y2 = yCenter - parseFloat(r2);
                makeOval(x2, y2, r2*2, r2*2);
                x1 = xCenter - parseFloat(r1);   // inner circle
                y1 = yCenter - parseFloat(r1);
                setKeyDown("alt");
                makeOval(x1, y1, r1*2, r1*2);
                setKeyDown("none");
    
            /* ELLIPSE */
            } else if (indexOf(data[0], geometry[9]) == 0) {
                pa = parseALMAangle(data[6]);
                center = parseALMACoord(data[1], data[2]);
                xCenter = parseFloat(center[0]);
                yCenter = parseFloat(center[1]);
                /* For an ellipse the first axis in the code is the Yaxis.
                 * Lets change the order to have Xaxis first and then Yaxis. */
                ax_y = parseALMAarc(data[4]);
                ax_x = parseALMAarc(data[5]);
                /* Set the major axis and convert the position angle if needed.
                In 'toEllipse' the position angle is that of the major axis, but
                in CARTA it is the angle of the Y-axis. The position angle must
                be transformed to the angle of the biggest axis. Which is simply
                rotating it 90 degrees if the X-axis is the major axis */
                if (abs(ax_x) > abs(ax_y)) {
                    bmaj = ax_x;
                    bmin = ax_y;
                    pa = pa-PI/2;
                } else {
                    bmaj = ax_y;
                    bmin = ax_x;
                }
                toEllipse(xCenter, yCenter, parseFloat(abs(bmaj)), 
                          parseFloat(abs(bmin)), pa);
            }
            run("GET SPECTRUM", "roi");
        }
    }
}

macro "Import ROIs from CARTA Action Tool Options" {
    showMessage("Info", "<html>"
    + "<center><h2>ROI Import Tool</h2></center>"
    + "Custom made tool to convert CASA and CARTA ROIs to MADCUBA.<br><br>"
    + "<strong>Important</strong>: A cube or image must be opened and selected "
    + "before running this macro. <br><br>"
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
    // Returns four points in clockwise order starting from the top left.
    x1[0] = parseFloat(call("CONVERT_PIXELS_COORDINATES.fits2ImageJX", x + r1x));
    x1[1] = parseFloat(call("CONVERT_PIXELS_COORDINATES.fits2ImageJX", x + r2x));
    x1[2] = parseFloat(call("CONVERT_PIXELS_COORDINATES.fits2ImageJX", x - r1x));
    x1[3] = parseFloat(call("CONVERT_PIXELS_COORDINATES.fits2ImageJX", x - r2x));
    y1[0] = parseFloat(call("CONVERT_PIXELS_COORDINATES.fits2ImageJY", y + r1y));
    y1[1] = parseFloat(call("CONVERT_PIXELS_COORDINATES.fits2ImageJY", y + r2y));
    y1[2] = parseFloat(call("CONVERT_PIXELS_COORDINATES.fits2ImageJY", y - r1y));
    y1[3] = parseFloat(call("CONVERT_PIXELS_COORDINATES.fits2ImageJY", y - r2y));
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
function toEllipse(x, y, bmaj, bmin, pa) {
    x1 = x - bmaj*sin(pa);
    y1 = y + bmaj*cos(pa);
    x2 = x + bmaj*sin(pa);
    y2 = y - bmaj*cos(pa);
    e = bmin/bmaj;
    makeEllipse(x1, y1, x2, y2, e);
}

/**
 * Convert angle to radians
 *
 * @param val  Input angle with units
 * @return  Converted angle in radians
 */
function parseALMAangle (val) {
    coordUnits = newArray("deg", "rad", "arcmin", "arcsec");
    for (j=0; j<coordUnits.length; j++) 
        if (indexOf(val, coordUnits[j]) != -1) unitsval=j; // read units
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
    for (j=0; j<coordUnits.length; j++)
        if (indexOf(ra, coordUnits[j]) != -1) unitsval=j; // read units
    if (unitsval == 10) {   // Sexagesimal Coordinates
        // right ascension
        par = split(ra, "hdms:");
        if (par.length == 1 && indexOf(ra, ".") <= 5) {
            par = split(ra, ".");
            if (par.length > 3) par[2] = par[2] + "." + par[3];
        }
        rafin = (parseFloat(par[0]) + parseFloat(par[1])/60.0
                + parseFloat(par[2])/3600.0) * 15.0;
        // declination
        par = split(dec, "hdms:");
        if (par.length == 1 && indexOf(dec, ".") <= 5) {
            par = split(dec,".");
            if (par.length > 3) par[2] = par[2] + "." + par[3];
        }
        if (indexOf(dec, "-") != -1)
            decfin = parseFloat(par[0]) - parseFloat(par[1])/60.0
                     - parseFloat(par[2])/3600.0;
        else 
            decfin = parseFloat(par[0]) + parseFloat(par[1])/60.0
                     + parseFloat(par[2])/3600.0;

        output[0] = 
            call("CONVERT_PIXELS_COORDINATES.coord2FitsX", rafin, decfin, "");
        output[1] = 
            call("CONVERT_PIXELS_COORDINATES.coord2FitsY", rafin, decfin, "");
    } else {
        rafin = substring(ra, 0, indexOf(ra, coordUnits[unitsval]));
        decfin = substring(dec, 0, indexOf(dec, coordUnits[unitsval]));
        if (unitsval == 0 || unitsval == 1) {
            if (unitsval == 1) {
                rafin =  rafin*180.0/PI;
                decfin = decfin*180.0/PI;
            }
            output[0] = 
                call("CONVERT_PIXELS_COORDINATES.coord2FitsX", 
                     rafin, decfin, "");
            output[1] = 
                call("CONVERT_PIXELS_COORDINATES.coord2FitsY",
                     rafin, decfin, "");

        } else if ( unitsval == 2) {
            /* correction to change 0,0 starting point to 1,1 starting point
            (currently used in madcuba) when fits coordinates are properly
            implemented in MADCUBA this will have to change to 1.5 */
            corr = 1;
            output[0] = toString(parseFloat(rafin) + corr);
            output[1] = toString(parseFloat(decfin) + corr);
        }
    }
    return output;
}

/**
 * Convert arcs in the sky to pixels
 * Note that this function uses the CDELT2 header parameter. This will
 * not be accurate for non-linear projections where CDELT1 != CDELT2.
 *
 * @param val  arc in the sky with units
 * @return  Converted arc
 */
function parseALMAarc (val) {
    cdelt = parseFloat(call("FITS_CARD.getDbl","CDELT2"));
    coordUnits = newArray("deg", "rad", "arcmin", "arcsec", "pix");
    unitsval = -1;
    coord = -1;

    for (j=0; j<coordUnits.length; j++)
        if (indexOf(val, coordUnits[j]) != -1) unitsval=j; // read units
    // case of request without units to use with polygon
    if (unitsval == -1) return coord;

    value = parseFloat(substring(val, 0, indexOf(val, coordUnits[unitsval])));
    if      (unitsval == 0) coord = value / cdelt;
    else if (unitsval == 1) coord = (value*180.0/PI) / cdelt;
    else if (unitsval == 2) coord = (value/60.0) / cdelt;
    else if (unitsval == 3) coord = (value/3600.0) / cdelt;
    else if (unitsval == 4) coord = value;
    return coord;
}
